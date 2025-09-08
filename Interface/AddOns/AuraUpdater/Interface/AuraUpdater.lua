---@diagnostic disable: undefined-field
local addOnName, LUP = ...

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")
local LDBIcon = LibStub("LibDBIcon-1.0")
local AceComm = LibStub("AceComm-3.0")

local updatePopupWindow

local spacing = 4
local lastUpdate = 0
local updateQueued = false

local broadcastTimer

local auraImportElementPool = {}
local UIDToID = {} -- Installed aura UIDs to ID (ID is required for WeakAuras.GetData call)
local guidToVersionsTable = {}

local allAurasUpdatedText
local UpdateVersionsForUnit = function(_, _) end

local function BuildAuraImportElements()
    lastUpdate = GetTime()
    updateQueued = false

    -- Check if addon requires an update
    local addOnVersionsBehind = LUP:GetHighestSeenAddOnVersion() - LUP:GetPlayerVersionsTable().addOn

    -- Check which auras require updates
    local aurasToUpdate = {}

    for displayName, highestSeenVersion in pairs(LUP:GetHighestSeenAuraVersions()) do
        local auraData = LiquidUpdaterSaved.WeakAuras[displayName]
        local uid = auraData and auraData.d.uid
        local importedVersion = auraData and auraData.d.liquidVersion or 0
        local installedAuraID = uid and UIDToID[uid]
        local installedVersion = installedAuraID and WeakAuras.GetData(installedAuraID).liquidVersion or 0

        if installedVersion < highestSeenVersion then
            table.insert(
                aurasToUpdate,
                {
                    displayName = displayName,
                    installedVersion = installedVersion,
                    importedVersion = importedVersion,
                    highestSeenVersion = highestSeenVersion
                }
            )
        end
    end

    table.sort(
        aurasToUpdate,
        function(auraData1, auraData2)
            local versionsBehind1 = auraData1.highestSeenVersion - auraData1.installedVersion
            local versionsBehind2 = auraData2.highestSeenVersion - auraData2.installedVersion

            if versionsBehind1 ~= versionsBehind2 then
                return versionsBehind1 > versionsBehind2
            else
                return auraData1.displayName < auraData2.displayName
            end
        end
    )

    -- Build the aura import elements
    local parent = LUP.updateWindow

    for _, element in ipairs(auraImportElementPool) do
        element:Hide()
    end

    -- AddOn element
    if addOnVersionsBehind > 0 then
        local auraImportFrame = auraImportElementPool[1] or LUP:CreateAuraImportElement(parent)

        auraImportFrame:SetDisplayName("AuraUpdater")
        auraImportFrame:SetVersionsBehind(addOnVersionsBehind)
        auraImportFrame:SetRequiresAddOnUpdate(true)

        auraImportFrame:Show()
        auraImportFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", spacing, -spacing)
        auraImportFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -spacing, -spacing)
        
        auraImportElementPool[1] = auraImportFrame
    end

    -- Aura elements
    for index, auraData in ipairs(aurasToUpdate) do
        -- If the addon requires an update, the first element indicates that
        -- Aura updates should use subsequent elements
        local i = addOnVersionsBehind > 0 and index + 1 or index
        local auraImportFrame = auraImportElementPool[i] or LUP:CreateAuraImportElement(parent)

        auraImportFrame:SetDisplayName(auraData.displayName)
        auraImportFrame:SetVersionsBehind(auraData.highestSeenVersion - auraData.installedVersion)
        auraImportFrame:SetRequiresAddOnUpdate(auraData.highestSeenVersion > auraData.importedVersion)

        auraImportFrame:Show()
        auraImportFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", spacing, -(i - 1) * (auraImportFrame.height + spacing) - spacing)
        auraImportFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -spacing, -(i - 1) * (auraImportFrame.height + spacing) - spacing)
        
        auraImportElementPool[i] = auraImportFrame
    end

    LUP.upToDate = addOnVersionsBehind <= 0 and next(aurasToUpdate) == nil

    allAurasUpdatedText:SetShown(LUP.upToDate)

    LUP:UpdateMinimapIcon()
end

-- TODO: get this back
function LUP:QueueUpdate()
    if updateQueued then return end

    -- Don't update more than once per second
    -- This is mostly to prevent the update function from running when a large number of auras get added simultaneously
    local timeSinceLastUpdate = GetTime() - lastUpdate

    if timeSinceLastUpdate > 1 then
        BuildAuraImportElements()
    else
        updateQueued = true

        C_Timer.After(1 - timeSinceLastUpdate, BuildAuraImportElements)
    end
end



function LUP:InitializeAuraUpdater()
    allAurasUpdatedText = LUP.updateWindow:CreateFontString(nil, "OVERLAY")

    allAurasUpdatedText:SetFontObject(LiquidFont21)
    allAurasUpdatedText:SetPoint("CENTER", LUP.updateWindow, "CENTER")
    allAurasUpdatedText:SetText(string.format("|cff%sAll auras up to date!|r", LUP.gs.visual.colorStrings.green))

    LUP:UpdateAuraVersions()
end