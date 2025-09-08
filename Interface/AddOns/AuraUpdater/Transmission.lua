-- This file handles the sending/receiving of versions tables

local _, LUP = ...

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")
local AceComm = LibStub("AceComm-3.0")

-- Broadcasts of versions tables are throttled in two ways
-- Firstly, whenever a broadcast is queued, it sets a timer equal to BROADCAST_DELAY
-- If another broadcast is queued during this time, it's thrown away
-- The broadcast happens when this timer runs out
-- This is to prevent multiple broadcasts to be queued simultaneously
-- Secondly, an interval equal to BROADCAST_INTERVAL is forced between broadcasts
local BROADCAST_DELAY = 2
local BROADCAST_INTERVAL = 3
local broadcastQueued = false
local lastBroadcastTime = 0

-- Maps unit GUIDs to versions tables
-- This is exclusively used to check whether a newly received versions table differs from what was previously received
local guidToVersionsTable = {}
local guidToUnitName = {} -- Used to check if GUIDs are still in group

-- Returns whether a newly received versions table differs from what was previously received
-- This is important because versions tables are broadcast fairly frequently
-- and we only want to make changes to the UI whenever we actually receive something new
local function IsVersionsTableChanged(GUID, newVersionsTable)
    local oldVersionsTable = guidToVersionsTable[GUID] or {}

    if not oldVersionsTable then return true end

    return not tCompare(oldVersionsTable, newVersionsTable, 8)
end

-- Loops over GUIDs in guidToVersionsTable/guidToUnitName, and removes entries for GUIDs that are no longer in group
-- This is important, because units may leave and re-join the group
-- If we save their versionsTable during that time, and their versions haven't changed
-- The addon will think that their versionsTable hasn't changed, and won't update the interface
local function DeleteVersionsTablesForInvalidGUIDs()
    for GUID, unit in pairs(guidToUnitName) do
        if not UnitExists(unit) then
            guidToVersionsTable[GUID] = nil
            guidToUnitName[GUID] = nil
        end
    end
end

local function UpdateVersionsTableForUnit(unit, versionsTable)
    -- If the unit exists, they are in our group and we (potentially) want to update check grids
    if UnitExists(unit) then
        local GUID = UnitGUID(unit)

        -- If there's no change compared to last time we received this player's versions table, do nothing
        if not IsVersionsTableChanged(GUID, versionsTable) then return end

        guidToVersionsTable[GUID] = CopyTable(versionsTable)
        guidToUnitName[GUID] = GetUnitName(unit, true)

        -- If the unit's nickname changed, update it
        local oldNickname = AuraUpdater:GetNickname(unit)
        local nickname = versionsTable.nickname

        if oldNickname ~= nickname then
            LUP:UpdateNicknameForUnit(unit, nickname)

            LUP:OnNicknameUpdate(unit, nickname)
        end

        LUP:UpdateHighestSeenVersions(versionsTable)
        LUP:OnVersionsTableUpdate(unit, versionsTable)
    else -- If the player is not in our group (i.e. they're just in our guild), only update highest seen versions
        LUP:UpdateHighestSeenVersions(versionsTable)
    end
end

local function ReceiveVersions(_, payload, _, sender)
    if UnitIsUnit(sender, "player") then return end -- We handle our own versions directly, not through addon messages

    local decoded = LibDeflate:DecodeForWoWAddonChannel(payload)
    if not decoded then return end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return end

    local success, versionsTable = LibSerialize:Deserialize(decompressed)
    if not success then return end

    -- If the versions table does not contain an auras subtable, the user is running a (very) old versions of AuraUpdater
    -- Do not handle their broadcast at all, since everything would be incredibly out of date anyway
    if not versionsTable.auras then return end
    
    UpdateVersionsTableForUnit(sender, versionsTable)
end

local function RequestVersions(chatType)
    AceComm:SendCommMessage("AU_Request", " ", chatType)
end

local function ReceiveRequest(_, _, _, sender)
    if UnitIsUnit(sender, "player") then return end

    LUP:BroadcastVersions()
end

function LUP:BroadcastVersions()
    -- Always update our own versions directly
    UpdateVersionsTableForUnit("player", LUP:GetPlayerVersionsTable())

    -- If the timer is active, we do not have to do anything: the broadcast will happen at the end of it
    if broadcastQueued then return end

    -- The next broadcast should happen at least BROADCAST_DELAY from now (to prevent simultaneous broadcasts)
    -- And it should happen at least BROADCAST_INTERVAL since the last broadcast
    local timeToNextBroadcast = BROADCAST_DELAY
    local timeSinceLastBroadcast = GetTime() - lastBroadcastTime

    if timeSinceLastBroadcast < BROADCAST_INTERVAL then
        timeToNextBroadcast = math.max(BROADCAST_DELAY, BROADCAST_INTERVAL - timeSinceLastBroadcast)
    end

    C_Timer.After(
        timeToNextBroadcast,
        function()
            local serializedTable = LUP:GetSerializedPlayerVersionsTable()

            AceComm:SendCommMessage("AU_Versions", serializedTable, "GUILD")

            if IsInGroup() then
                local chatType = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or "PARTY"

                AceComm:SendCommMessage("AU_Versions", serializedTable, chatType)
            end

            broadcastQueued = false
            timeSinceLastBroadcast = GetTime()
        end
    )

    broadcastQueued = true
end

function LUP:InitializeTransmission()
    AceComm:RegisterComm("AU_Request", ReceiveRequest)
    AceComm:RegisterComm("AU_Versions", ReceiveVersions)
end

local function OnEvent(_, event, ...)
    if event == "GROUP_JOINED" or event == "GROUP_FORMED" then
        local chatType = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or "PARTY"

        LUP:BroadcastVersions()

        RequestVersions(chatType)
    elseif event == "PLAYER_ENTERING_WORLD" then
        local chatType = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or "PARTY"

        LUP:BroadcastVersions()

        RequestVersions(chatType)
        RequestVersions("GUILD")
    elseif event == "GROUP_ROSTER_UPDATE" then
        DeleteVersionsTablesForInvalidGUIDs()
    end
end

local f = CreateFrame("Frame")

f:RegisterEvent("GROUP_JOINED")
f:RegisterEvent("GROUP_FORMED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", OnEvent)