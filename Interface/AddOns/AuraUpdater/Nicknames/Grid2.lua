local _, LUP = ...

local ADDON_NAME = "Grid2"

local Grid2NicknameStatus

-- Can be found under Miscellaneous -> AuraUpdater Nickname
LUP.nicknameInitFunctions[ADDON_NAME] = function()
    local statusName = "AuraUpdater Nickname"

    Grid2NicknameStatus = Grid2.statusPrototype:new(statusName)
    Grid2NicknameStatus.IsActive = Grid2.statusLibrary.IsActive

    function Grid2NicknameStatus:UNIT_NAME_UPDATE(_, unit)
        self:UpdateIndicators(unit)
    end

    function Grid2NicknameStatus:OnEnable()
        self:RegisterEvent("UNIT_NAME_UPDATE")
    end

    function Grid2NicknameStatus:OnDisable()
        self:UnregisterEvent("UNIT_NAME_UPDATE")
    end

    function Grid2NicknameStatus:GetText(unit)
        return AuraUpdater:GetNickname(unit) or ""
    end

    local function Create(baseKey, dbx)
        Grid2:RegisterStatus(Grid2NicknameStatus, {"text"}, baseKey, dbx)

        return Grid2NicknameStatus
    end

    Grid2.setupFunc[statusName] = Create

    Grid2:DbSetStatusDefaultValue(statusName, {type = statusName})
end

LUP.nicknameUpdateFunctions[ADDON_NAME] = function(unit)
	if Grid2NicknameStatus then
        for groupUnit in LUP:IterateGroupMembers() do
            if UnitIsUnit(unit, groupUnit) then
                Grid2NicknameStatus:UpdateIndicators(groupUnit)

                break
            end
        end
    end
end

local function AddGrid2Options()
    if Grid2NicknameStatus then
        Grid2Options:RegisterStatusOptions("AuraUpdater Nickname", "misc", function() end)
    end
end

-- When Grid2Options loads, add an empty set of options for AuraUpdater Nicknames
-- If this is not done, viewing the status throws a Lua error
local f = CreateFrame("Frame")

f:RegisterEvent("ADDON_LOADED")

f:SetScript(
    "OnEvent",
    function(_, _, addOnName)
        if addOnName == "Grid2Options" then
            AddGrid2Options()
        end
    end
)