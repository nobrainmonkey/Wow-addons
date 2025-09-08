local _, LUP = ...

local ADDON_NAME = "CustomNames"
local CustomNames

function LUP:RegisterCustomNamesNicknames()
    if not CustomNames then return end

    for name, nickname in pairs(LiquidUpdaterSaved.nicknames) do
        CustomNames.Set(name, nickname)
    end
end

function LUP:UnregisterCustomNamesNicknames()
    if not CustomNames then return end

    for name, nickname in pairs(LiquidUpdaterSaved.nicknames) do
        local customNamesNickname = CustomNames.Get(name)

        if customNamesNickname == nickname then
            CustomNames.Set(name)
        end
    end
end

LUP.nicknameUpdateFunctions[ADDON_NAME] = function(unit, _, _, nickname)
	-- Set nicknames in CustomNames addon if installed (used by several other addons)
    -- Check if the nickname already exists in CustomNames before we do, otherwise it spam prints
    -- Don't delete any CustomNames nicknames (if nickname is nil)
    if nickname and CustomNames and LiquidUpdaterSaved.settings.CustomNames then
        local customNamesNickname = CustomNames.Get(unit)

        if not customNamesNickname or customNamesNickname ~= nickname then
            CustomNames.Set(unit, nickname)
        end
    end
end