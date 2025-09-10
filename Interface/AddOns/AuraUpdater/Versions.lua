-- This file maintains the player's versions table, containing information about
-- the player's installed addons, weakauras, and some additional info about MRT notes, ignored group members, etc.
-- It also maintains the highest seen addon/weakaura versions, as broadcast by other players
-- Whenever this info changes, the appropriate handlers are notified (e.g. LUP:OnHighestSeenVersionsUpdate() etc.)

local _, LUP = ...

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

-- Contains information about all our (the player's) installed addon/aura versions
-- as well as some additional info about e.g. ignored group members, MRT note, etc.
-- It's stored in the exact format that we broadcast to other players
-- The exact layout of this table is:
-- versionsTable = {
--     addOn = <addOn version (number)>,
--     auras = {
--         [aura name 1] = <aura 1 version (number)>,
--         [aura name 2] = <aura 2 version (number)>,
--         [aura name 3] = <aura 3 version (number)>,
--         etc.
--     },
--     ignores = {
--         [1] = <ignored player name 1 (string)>,
--         [2] = <ignored player name 2 (string)>,
--         etc.
--     },
--     mrtNoteHash = <hash (number)>,
--     RCLC = <RCLC version (string)>,
--     nickname = <nickname (string)>
-- }
local versionsTable = {
    addOn = tonumber(C_AddOns.GetAddOnMetadata("AuraUpdater", "Version")),
    auras = {},
    ignores = {},
    nickname = LiquidUpdaterSaved and LiquidUpdaterSaved.nickname
}

-- These reflect the highest seen versions of both the addon(s)/weakauras as broadcast by group/guild members
-- Our own verion's are compared to these to determine whether our addon is outdated
-- e.g. if the highest version available on our addon is 12, and a group member has version 13 installed
-- we know that our addon should be updated to pull in the latest weakaura changes
local highestSeenAddOnVersion = 0
local highestSeenRCLCVersion = "0.0.0"
local highestSeenAuraVersions = {}

-- Exact copy of versionsTable, except serialized so it can be broadcast to others
-- shouldSerialize is set to true whenever something in versionsTable changes
local serializedVersionsTable
local shouldSerialize

local auraUIDs = {} -- UIDs of AuraUpdater auras, both those installed and not installed

local UIDToID = {} -- Maps installed weakaura UIDs (their internal unique ID) to their IDs (display names)
local weakAurasHooked = false -- Whether the WeakAuras hook (to maintain UIToID) is already in place

local mrtHooked = false -- Whether the MRT hook is in place to update the note hash

-- These timers get (re)set whenever a change to the mrt note/nickname is detected
-- The update is only broadcast to the group when the timer runs out
-- This is done so that when the user is actively typing in the mrt note (or nickname), it doesn't constantly broadcast
local UPDATE_TIMER_LENGTH = 3
local mrtUpdateTimer
local nicknameUpdateTimer

-- This function serializes the versionsTable to prepare for braodcast
-- It's called every time the serialized versionsTable is requested via LUP:GetSerializedPlayerVersionsTable
-- However, it only serializes it if shouldSerialize is true (i.e. if something changed in versionsTable)
local function SerializeVersionsTable()
    if not shouldSerialize then return end

    local serialized = LibSerialize:Serialize(versionsTable)
    local compressed = LibDeflate:CompressDeflate(serialized, {level = 9})
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)

    serializedVersionsTable = encoded
end

-- This function is called whenever something in the player's versionsTable changes
local function OnPlayerVersionsTableUpdate()
    shouldSerialize = true

    LUP:BroadcastVersions()
end

-- Updates the highest seen addon/weakaura versions
-- The receivedVersionsTable argument is not (necessarily) the player's versions table
-- It's any versions table we receive from group/guild members
-- This function is called any time we receive a versions table
function LUP:UpdateHighestSeenVersions(receivedVersionsTable)
    local changed = false

    -- Update the highest seen AuraUpdater version
    local receivedAddOnVersion = receivedVersionsTable.addOn

    -- There seem to be AuraUpdater versions going around with an inflated version number
    -- If it's higher than 1000, discard it
    if receivedAddOnVersion > 1000 then return end

    changed = receivedAddOnVersion > highestSeenAddOnVersion

    highestSeenAddOnVersion = math.max(receivedAddOnVersion, highestSeenAddOnVersion)

    -- Update the highest seen RCLC version
    local receivedRCLCVersion = receivedVersionsTable.RCLC

    if receivedRCLCVersion and LUP:CompareRCLCVersions(highestSeenRCLCVersion, receivedRCLCVersion) == 1 then
        highestSeenRCLCVersion = receivedRCLCVersion

        changed = true
    end

    -- Update highest seen aura versions
    -- Only do so if the user is actually running a newer AuraUpdater version than ours
    -- Some UI packs creators seem to include the Liquid Anchors (especially), with an inflated version number
    if receivedVersionsTable.addOn > LUP:GetPlayerVersionsTable().addOn then
        for displayName, receivedVersion in pairs(receivedVersionsTable.auras) do
            local currentVersion = highestSeenAuraVersions[displayName] or 0

            if receivedVersion > currentVersion then
                highestSeenAuraVersions[displayName] = receivedVersion

                changed = true
            end
        end
    end

    -- Notify if something changed
    if changed then
        LUP:OnHighestSeenVersionsUpdate()
    end
end

-- Updates the versions of installed auras in versionsTable
-- Should be called whenever an aura supplied by AuraUpdater is changed (i.e. installed, updated, or deleted)
-- Calls OnVersionsTableUpdate if the version changed
function LUP:UpdateAuraVersions()
    if not WeakAuras then return end

    local changed = false

    for displayName, auraData in pairs(LiquidUpdaterSaved.WeakAuras) do
        local uid = auraData.d.uid
        local installedAuraID = uid and UIDToID[uid]
        local installedVersion = installedAuraID and WeakAuras.GetData(installedAuraID).liquidVersion or 0

        if versionsTable.auras[displayName] ~= installedVersion then
            changed = true
        end

        versionsTable.auras[displayName] = installedVersion
    end

    if changed then
        OnPlayerVersionsTableUpdate()

        LUP:OnPlayerAuraUpdate()
    end
end

-- Updates the ignores table in versionsTable
-- This table is an array of all ignored group members
-- Should be called on IGNORELIST_UPDATE, i.e. when a new player is (un)ignored
-- Should also be called on GROUP_ROSTER_UPDATE, in case an ignored player joins/leaves the group
-- Calls UpdateRCLCVersion if the list of ignored group members changed
local function UpdateIgnoredPlayers()
    local changed = false
    local newIgnoredNames = {}

    for unit in LUP:IterateGroupMembers() do
        if C_FriendList.IsIgnored(unit) then
            local name = UnitNameUnmodified(unit)

            table.insert(newIgnoredNames, name)
        end
    end

    table.sort(newIgnoredNames)

    if not tCompare(newIgnoredNames, versionsTable.ignores) then
        changed = true
    end

    versionsTable.ignores = newIgnoredNames

    if changed then
        OnPlayerVersionsTableUpdate()
    end
end

-- Compares two RCLC TOC versions
-- Returns -1 if version1 is higher, 0 if they are equal, 1 if version2 is higher
function LUP:CompareRCLCVersions(version1, version2)
    if version1 == version2 then return 0 end
    if not version1 then return 1 end
    if not version2 then return -1 end

    local major1, minor1, patch1 = version1:match("(%d+).(%d+).(%d+)")
    local major2, minor2, patch2 = version2:match("(%d+).(%d+).(%d+)")

    if major1 ~= major2 then
        major1 = tonumber(major1)
        major2 = tonumber(major2)

        return major1 > major2 and -1 or 1
    elseif minor1 ~= minor2 then
        minor1 = tonumber(minor1)
        minor2 = tonumber(minor2)

        return minor1 > minor2 and -1 or 1
    elseif patch1 ~= patch2 then
        patch1 = tonumber(patch1)
        patch2 = tonumber(patch2)

        return patch1 > patch2 and -1 or 1
    else
        return 0
    end
end

-- Updates the RCLC version in the versionsTable
-- Calls OnVersionsTableUpdate if the version changed
local function UpdateRCLCVersion()
	local version = C_AddOns.GetAddOnMetadata("RCLootCouncil", "Version")
    local changed = versionsTable.RCLC ~= version

    if C_AddOns.IsAddOnLoaded("RCLootCouncil") then
	    versionsTable.RCLC = version
    end

    highestSeenRCLCVersion = C_AddOns.GetAddOnMetadata("RCLootCouncil", "Version")

    if changed then
        OnPlayerVersionsTableUpdate()
    end
end

-- This hooks a number of WeakAuras functions (Add, Rename, Delete) to maintain the UIDToID table
local function HookWeakAuras()
    if weakAurasHooked then return end

	if WeakAuras and WeakAurasSaved and WeakAurasSaved.displays then
        for id, auraData in pairs(WeakAurasSaved.displays) do
            UIDToID[auraData.uid] = id
        end

        hooksecurefunc(
            WeakAuras,
            "Add",
            function(data)
                local uid = data.uid

                if uid then
                    UIDToID[uid] = data.id
                end
            end
        )

        hooksecurefunc(
            WeakAuras,
            "Rename",
            function(data, newID)
                local uid = data.uid

                if uid then
                    UIDToID[uid] = newID
                end
            end
        )

        hooksecurefunc(
            WeakAuras,
            "Delete",
            function(data)
                local uid = data.uid

                if uid then
                    UIDToID[uid] = nil

                    if auraUIDs[uid] then
                        LUP:UpdateAuraVersions()
                    end
                end
            end
        )
    end
end

-- Calculates checksum for the player's public MRT note
-- Original code by Mikk (https://warcraft.wiki.gg/wiki/StringHash)
local function GetMRTNoteHash()
    local text = VMRT and VMRT.Note.Text1

    if not text then return end

    local counter = 1
    local len = string.len(text)

    for i = 1, len, 3 do 
        counter = math.fmod(counter * 8161, 4294967279) + (string.byte(text, i) * 16776193) + ((string.byte(text, i + 1) or (len - i + 256)) * 8372226) + ((string.byte(text, i + 2) or (len - i + 256)) * 3932164)
    end

    return math.fmod(counter, 4294967291)
end

-- Update the MRT note hash in the versionsTable
-- Calls OnVersionsTableUpdate if the hash changed
local function UpdateMRTNoteHash()
    if not (VMRT and VMRT.Note and VMRT.Note.Text1) then return end

    local hash = GetMRTNoteHash()
    local changed = versionsTable.mrtNoteHash ~= hash

    versionsTable.mrtNoteHash = hash

    if changed then
        OnPlayerVersionsTableUpdate()

        LUP:OnMRTHashUpdate()
    end
end

-- Hooks the SetText function of the public MRT note, so that this code runs whenever a change is made to it
-- Every time a change is detected, a timer is started (of length UPDATE_TIMER_LENGTH)
-- If the timer was already active at the time of detection, then it's canceled and started again
-- The purpose of the timer is to only run UpdateMRTNoteHash() when the user stopped editing the MRT note
-- Without the timer, we would queue up a versions broadcast continually while the user is editing the note
local function HookMRT()
    if mrtHooked then return end

    if MRTNote and MRTNote.text then
        hooksecurefunc(
            MRTNote.text,
            "SetText",
            function()
                -- During encounters, the user may have visual MRT timers
                -- Don't update on those
                if IsEncounterInProgress() then return end

                if mrtUpdateTimer and not mrtUpdateTimer:IsCancelled() then
                    mrtUpdateTimer:Cancel()
                end

                mrtUpdateTimer = C_Timer.NewTimer(UPDATE_TIMER_LENGTH, UpdateMRTNoteHash)
            end
        )
    end
end

-- Update the player's nickname in the versionsTable
-- Calls OnVersionsTableUpdate if the nickname changed
local function UpdateNickname(nickname)
    nickname = strtrim(nickname)

    if nickname == "" then nickname = nil end

    local changed = versionsTable.nickname ~= nickname

    LiquidUpdaterSaved.nickname = nickname -- Save the nickname so that we can restore it on reload
    versionsTable.nickname = nickname

    if changed then
        OnPlayerVersionsTableUpdate()
    end
end

-- This function is called from the nickname edit box (in settings)
-- It's similar to what happens in the HookMRT function, where it (re)sets a timer whenever a change is detected
-- The UpdateNickname function is only called when the timer runs out
function LUP:QueueNicknameUpdate(nickname)
    if nicknameUpdateTimer and not nicknameUpdateTimer:IsCancelled() then
        nicknameUpdateTimer:Cancel()
    end

    nicknameUpdateTimer = C_Timer.NewTimer(
        UPDATE_TIMER_LENGTH,
        function()
            UpdateNickname(nickname)
        end
    )
end

-- Expose the UID to ID to the addon table, since it's useful in other places as well
function LUP:AuraUIDToID(uid)
    return UIDToID[uid]
end

function LUP:GetPlayerVersionsTable()
    return versionsTable
end

function LUP:GetSerializedPlayerVersionsTable()
    SerializeVersionsTable()

    return serializedVersionsTable
end

function LUP:GetHighestSeenAddOnVersion()
    return highestSeenAddOnVersion
end

function LUP:GetHighestSeenAuraVersions()
    return highestSeenAuraVersions
end

function LUP:GetHighestSeenRCLCVersion()
    return highestSeenRCLCVersion
end

function LUP:InitializeVersions()
    for _, auraData in pairs(LiquidUpdaterSaved.WeakAuras) do
        auraUIDs[auraData.d.uid] = true
    end

    -- Set the highest seen versions to whatever our version of AuraUpdater supplies
    highestSeenAddOnVersion = tonumber(C_AddOns.GetAddOnMetadata("AuraUpdater", "Version"))
    
    for displayName, data in pairs(LiquidUpdaterSaved.WeakAuras) do
        highestSeenAuraVersions[displayName] = data.d.liquidVersion
    end

    -- Attempt these here in case they loaded before AuraUpdater
    HookWeakAuras()
    HookMRT()

    UpdateIgnoredPlayers()
    UpdateMRTNoteHash()
    UpdateRCLCVersion()

    LUP:UpdateAuraVersions()
end

local function OnEvent(_, event, ...)
    if event == "GROUP_ROSTER_UPDATE" then
        UpdateIgnoredPlayers()
    elseif event == "IGNORELIST_UPDATE" then
        UpdateIgnoredPlayers()
    elseif event == "ADDON_LOADED" then
		local name = ...
	
        if name == "RCLootCouncil" then
			UpdateRCLCVersion()
		elseif name == "WeakAuras" then
			HookWeakAuras()

            LUP:UpdateAuraVersions()
		elseif name == "MRT" then
			HookMRT()
            UpdateMRTNoteHash()
		end
	end
end

local f = CreateFrame("Frame")

f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("IGNORELIST_UPDATE")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", OnEvent)