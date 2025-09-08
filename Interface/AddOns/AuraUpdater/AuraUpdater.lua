-- The purpose of this file is to handle the update process of auras
-- It takes care of preserving some of the user's settings (never load, sounds, etc.)
-- as well as making sure that essential parts of the aura gets updated (code in actions tab etc.)

local _, LUP = ...

-- Called before updating an aura
-- Checks if the user already has the aura installed
-- If so, apply "load: never" settings from the existing aura (group) to the aura being imported
-- If "forceenable" is included in the description of an aura, always uncheck "load: never"
local function ApplyLoadSettings(auraData, installedAuraData)
    if installedAuraData and installedAuraData.load and not (installedAuraData.regionType == "group" or installedAuraData.regionType == "dynamicgroup") then
        auraData.load.use_never = installedAuraData.load.use_never

        if auraData.desc and type(auraData.desc) == "string" and auraData.desc:match("forceenable") then
            auraData.load.use_never = nil
        end
    end
end

-- Similar to ApplyLoadSettings: preserves sound settings in action tab
local function ApplySoundSettings(auraData, installedAuraData)
    if not (installedAuraData and installedAuraData.actions) then return end

    local start = installedAuraData.actions.start
    local finish = installedAuraData.actions.finish

    -- Preserve on show sounds
    if start then
        if not auraData.actions.start then auraData.actions.start = {} end

        auraData.actions.start.do_sound = start.do_sound
        auraData.actions.start.do_loop = start.do_loop
        auraData.actions.start.sound = start.sound
        auraData.actions.start.sound_channel = start.sound_channel
        auraData.actions.start.sound_repeat = start.sound_repeat
    end

    -- Preserve on hide sounds
    if finish then
        if not auraData.actions.finish then auraData.actions.finish = {} end

        auraData.actions.finish.do_sound = finish.do_sound
        auraData.actions.finish.do_sound_fade = finish.do_sound_fade
        auraData.actions.finish.sound = finish.sound
        auraData.actions.finish.sound_channel = finish.sound_channel
        auraData.actions.finish.stop_sound = finish.stop_sound
        auraData.actions.finish.stop_sound_fade = finish.stop_sound_fade
    end
end

-- Similar to the above: miscellaneous auras do not have an anchor associated with them
-- We don't want users to have to uncheck "group arrangement", so apply position settings of installed miscellaneous auras
-- We only do this for direct children of miscellaneous groups, not for children of children etc.
local function ApplyMiscellaneousPositionSettings(groupAuraData)
    if not groupAuraData.c then return end

    -- Collect names of miscellaneous auras
    local miscellaneousAuraNames = {}

    for _, childAuraData in pairs(groupAuraData.c) do
        local isGroup = childAuraData.regionType == "group"
        local isMiscellaneousGroup = isGroup and childAuraData.groupIcon == "map-icon-ignored-bluequestion" and childAuraData.id:match("Miscellaneous")
        local miscellaneousGroupChildren = isMiscellaneousGroup and childAuraData.controlledChildren

        if miscellaneousGroupChildren then
            for _, auraName in ipairs(miscellaneousGroupChildren) do
                miscellaneousAuraNames[auraName] = true
            end
        end
    end

    -- Fill UID to auraData table for miscellaneous auras
    -- We want to use UIDs over IDs, since players may have renamed auras
    local uidToAuraData = {}

    for _, childAuraData in pairs(groupAuraData.c) do
        local auraName = childAuraData.id

        if miscellaneousAuraNames[auraName] then
            uidToAuraData[childAuraData.uid] = childAuraData
        end
    end

    -- Apply position settings
    for uid, auraData in pairs(uidToAuraData) do
        local auraID = LUP:AuraUIDToID(uid)
        local installedAuraData = auraID and WeakAuras.GetData(auraID)

        if installedAuraData then
            local xOffset = installedAuraData.xOffset
            local yOffset = installedAuraData.yOffset

            if xOffset and auraData.xOffset and yOffset and auraData.yOffset then
                auraData.xOffset = xOffset
                auraData.yOffset = yOffset
            end
        end
    end
end

-- Force updates the on init code, even if the user unchecked "actions" when importing
-- Users often do this to preserve their sounds/glow colors/etc. but it can break assignment functionality
local function ForceUpdateOnInit(customOnInit)
    for id, customCode in pairs(customOnInit) do
        local data = WeakAuras.GetData(id)

        if data and data.actions and data.actions.init then
            data.actions.init.do_custom = true
            data.actions.init.custom = customCode
        end
    end
end

-- Takes in some auraData (typically as stored in LiquidUpdaterSaved.WeakAuras), and prepares it for update by the user
-- This is done because the raw aura data we stores in SavedVariables isn't necessarily fit for import
-- Among other things, we want to make sure that some of the changes users make to their auras are preserved
-- We do this by applying these changes to the aura data that is being imported, before the import starts
-- This function also creates a table of aura IDs mapped to their custom "on init" code
-- This table is used in PostAuraUpdate to forcefully update the code (see ForceUpdateOnInit)
function PreAuraUpdate(auraData)
    local modifiedAuraData = CopyTable(auraData)
    local installedAuraID = LUP:AuraUIDToID(modifiedAuraData.uid)
    local installedAuraData = installedAuraID and WeakAuras.GetData(installedAuraID)

    -- This should only be necessary if the user manually imported a version of the aura with a different UID, after logging in
    LUP:MatchInstalledUID(auraData.d)

    ApplyLoadSettings(modifiedAuraData.d, installedAuraData) -- Preserve "load: never" settings
    ApplyMiscellaneousPositionSettings(modifiedAuraData) -- Preserve positioning of miscellaneous auras (they do not have an anchor)

    -- If we are updating a group, do the same for all child auras
    if modifiedAuraData.c then
        for _, childAuraData in pairs(modifiedAuraData.c) do
            local installedChildAuraID = LUP:AuraUIDToID(childAuraData.uid)
            local installedChildAuraData = installedChildAuraID and WeakAuras.GetData(installedChildAuraID)

            ApplyLoadSettings(childAuraData, installedChildAuraData)
            ApplySoundSettings(childAuraData, installedChildAuraData)
        end
    end

    -- Loop through children and save IDs of auras that have custom code on init
    -- [aura_id] = custom_code (string)
    local customOnInit = {}

    for _, childData in ipairs(auraData.c or {auraData.d}) do
        local doCustom = childData.actions and childData.actions.init and childData.actions.init.do_custom
        local customCode = doCustom and childData.actions.init.custom

        if doCustom and customCode and customCode ~= "" then
            customOnInit[childData.id] = customCode
        end
    end

    return modifiedAuraData, customOnInit
end

-- Takes in the aura data (post update), and ensures essential data (such as init code) is updated
-- The customOnInit argument is produced by PreAuraUpdate()
function PostAuraUpdate(auraData, version, customOnInit)
    auraData.preferToUpdate = true
    auraData.ignoreWagoUpdate = true
    auraData.liquidVersion = version

    ForceUpdateOnInit(customOnInit)
end

-- This function initiates the aura update process for some aura data (as stored in LiquidUpdaterSaved.WeakAuras)
-- This is typically executed when the user clicks the "update" button for some aura
function LUP:UpdateAura(auraData, version)
    local modifiedAuraData, customOnInit = PreAuraUpdate(auraData)

    WeakAuras.Import(
        modifiedAuraData,
        nil,
        function(success, auraID)
            if not success then return end

            local updatedAuraData = WeakAuras.GetData(auraID)

            PostAuraUpdate(updatedAuraData, version, customOnInit)
            
            LUP:UpdateAuraVersions()
        end
    )
end