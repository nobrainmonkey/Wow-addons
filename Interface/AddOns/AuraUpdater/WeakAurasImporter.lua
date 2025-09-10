-- The purpose of this file is to import auras from WeakAuras.lua (i.e. auras "uploaded" to the addon)
-- Importing them entails deserializing/decoding them, and storing them in SavedVariables
-- Auras are only imported if they haven't been imported before, as determined by their version number

local _, LUP = ...

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

-- Names of the auras that should receive the AuraUpdater custom options (just ignoreAnchor for now)
local shouldAddCustomOptions = {
    ["Manaforge Omega"] = true
}

-- These custom options are added to all auras inside the groups specified in shouldAddCustomOptions
local auraUpdaterCustomOptions = {
    {
        type = "header",
        text = "AuraUpdater",
        useName = true,
        width = 1
    },
    {
        type = "toggle",
        name = "Ignore anchor",
        key = "ignoreAnchor",
        desc = "If checked, anchor options are ignored for this aura.|n|nThis allows you to customize it individually, e.g. by adjusting its size.",
        useDesc = true,
        width = 1,
        default = false
    }
}

-- The parent of child auras are matched against these strings
-- Custom options are only added if they pass
local parentMatchForCustomOptions = {
    ["%- Bars$"] = true,
    ["%- Special Bars$"] = true,
    ["%- Lists$"] = true,
    ["%- Raid Leader Lists$"] = true,
    ["%- Big Icons$"] = true,
    ["%- Icons$"] = true,
    ["%- Circles$"] = true,
    ["%- Texts$"] = true,
    ["%- Assignments$"] = true,
    ["%- Tank Warnings$"] = true,
    ["%- Tank Icons$"] = true,
    ["%- Co%-Tank Icons$"] = true,
}

-- The region type of the aura must be one of these to receive custom options
local regionTypeForCustomOptions = {
    text = true,
    aurabar = true,
    icon = true,
    progresstexture = true
}

-- Table that decides if AuraUpdater auras are relevant for the current patch
-- We don't want to always delete them from the addon completely, because they may become relevant in the future (e.g. fated)
-- This also allows for different auras to show on PTR/beta than on live
-- The before/after fields are interface versions, as returned by GetBuildInfo()
-- before is exclusive, after is inclusive
local auraRelevancy = {
    ["Nerub-ar Palace"] = {
        before = 110100
    },
    ["Liberation of Undermine"] = {
        before = 110200,
        after = 110100
    },
    ["Manaforge Omega"] = {
        after = 110200
    }
}

-- Checks if we already have this aura installed (by display name)
-- If so, makes sure that the version of the aura we are importing matches its UID
-- This is called both on importing of auras (from LUP.WeakAuras), as well as on updating an aura
-- The goal is to properly update/recognise installed versions of the auras, even if their UID is different
-- This function exists in the addon namespace because it's repeated just before auras get updated (for safety)
function LUP:MatchInstalledUID(auraData)
    local displayName = auraData and auraData.id
    local installedAuraData = displayName and WeakAuras.GetData(displayName)
    
    if not installedAuraData then return end

    auraData.uid = installedAuraData.uid
end

-- Returns whether an aura is relevant based on the auraRelevancy table
-- This is done by displayName, so it can be tested before importing the aura from WeakAuras.lua
local function IsRelevantWeakAura(displayName)
    local relevancyTable = auraRelevancy[displayName]

    if not relevancyTable then return true end

    local interfaceVersion = select(4, GetBuildInfo())
    local beforeOK = true
    local afterOK = true

    if relevancyTable.before then
        beforeOK = interfaceVersion < relevancyTable.before
    end

    if relevancyTable.after then
        afterOK = interfaceVersion >= relevancyTable.after
    end

    return beforeOK and afterOK
end

-- Adds AuraUpdater-specific custom options to imported auras
local function AddCustomOptions(auraData)
    for _, childData in pairs(auraData.c) do
        local regionType = childData.regionType
        local validRegionType = regionTypeForCustomOptions[regionType]
        local authorOptions = childData.authorOptions

        if validRegionType and authorOptions then
            local parent = childData.parent
            local validParent = false

            for toMatch in pairs(parentMatchForCustomOptions) do
                if parent:match(toMatch) then
                    validParent = true

                    break
                end
            end

            if validParent then
                local shouldAdd = true

                for _, customOption in pairs(authorOptions) do
                    if customOption.key == "ignoreAnchor" then
                        shouldAdd = false

                        break
                    end
                end

                if shouldAdd then
                    tAppendAll(authorOptions, auraUpdaterCustomOptions)
                end
            end
        end
    end
end

-- Takes an auraInfo table as input, and deserializes the WeakAuras string, then stores the result in LiquidUpdaterSaved.WeakAuras
-- auraInfo tables are how auras are stored in WeakAuras.lua. They are structured as such:
-- auraInfo = {
--     displayName = <string>,
--     version = <number>,
--     data = <string>
-- }
-- This function only imports auras that have a version number higher than what we've imported before
-- Similarly, it does not import them if they are deemed irrelevant by IsRelevantAura
local function ImportAura(auraInfo)
    local displayName = auraInfo.displayName

    if not IsRelevantWeakAura(displayName) then return end -- Do not import irrelevant auras

    local version = auraInfo.version
    local importedVersion = LiquidUpdaterSaved.WeakAuras[displayName] and LiquidUpdaterSaved.WeakAuras[displayName].d and LiquidUpdaterSaved.WeakAuras[displayName].d.liquidVersion

    if importedVersion and importedVersion >= version then return end -- Do not import auras that we've imported before

    -- Deserialize the WeakAuras string
    local toDecode = auraInfo.data:match("!WA:2!(.+)")

    local decoded = LibDeflate:DecodeForPrint(toDecode)
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    local _, data = LibSerialize:Deserialize(decompressed)

    -- Add a liquidVersion field for version checking
    -- This is what AuraUpdater checks against to detect if a newer version is available compared to what is installed
    data.d.liquidVersion = version

    -- These fields are set to nil to prevent WeakAuras companion/Wago app from (mistakenly) suggesting there's updates available
    data.d.url = nil
    data.d.wagoID = nil

    if shouldAddCustomOptions[displayName] then
        AddCustomOptions(data)
    end

    if data.c then
        for _, childData in pairs(data.c) do
            childData.url = nil
            childData.wagoID = nil
        end
    end

    LiquidUpdaterSaved.WeakAuras[displayName] = data
end

-- Takes WeakAura strings from LUP.WeakAuras, decodes them, and saves them to LiquidUpdaterSaved.WeakAuras
-- Only decodes new auras (or new versions of auras)
function LUP:InitializeWeakAurasImporter()
    if not LiquidUpdaterSaved.WeakAuras then LiquidUpdaterSaved.WeakAuras = {} end

    for _, auraInfo in ipairs(LUP.WeakAuras) do
        ImportAura(auraInfo)
    end

    -- Delete irrelevant auras from SavedVariables
    for displayName in pairs(LiquidUpdaterSaved.WeakAuras) do
        if not IsRelevantWeakAura(displayName) then
            LiquidUpdaterSaved.WeakAuras[displayName] = nil
        end
    end

    -- Match imported aura UIDs to installed aura UIDs
    for _, auraData in pairs(LiquidUpdaterSaved.WeakAuras) do
        LUP:MatchInstalledUID(auraData.d)
    end
end
