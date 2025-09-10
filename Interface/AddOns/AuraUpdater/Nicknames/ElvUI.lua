local _, LUP = ...

local ADDON_NAME = "ElvUI"

-- Adds "nickname-lenX" tag, where X is the length between 1 and 12
LUP.nicknameInitFunctions[ADDON_NAME] = function()
    if ElvUF and ElvUF.Tags then
        ElvUF.Tags.Events["nickname"] = "UNIT_NAME_UPDATE"
        ElvUF.Tags.Methods["nickname"] = function(unit)
            return AuraUpdater:GetNickname(unit) or ""
        end

        for i = 1, 12 do
            ElvUF.Tags.Events["nickname-len" .. i] = "UNIT_NAME_UPDATE"
            ElvUF.Tags.Methods["nickname-len" .. i] = function(unit)
                local nickname = AuraUpdater:GetNickname(unit)

                return nickname and nickname:sub(1, i) or ""
            end
        end
    end
end