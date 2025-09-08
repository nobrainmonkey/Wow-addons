local _, namespace = ...

namespace.LiquidUI = {
	VERSION = 1
}

local LUI = namespace.LiquidUI

-- Tooltip
CreateFrame("GameTooltip", "LUITooltip", UIParent, "GameTooltipTemplate")

LUI.Tooltip = _G["LUITooltip"]
LUI.Tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

LUI.Tooltip:AddFontStrings(
	LUI.Tooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"),
	LUI.Tooltip:CreateFontString("$parentTextRight1", nil, "GameTooltipText")
)

if WOW_PROJECT_ID == 1 then -- Retail
    LUI.Tooltip.TextLeft1:SetFontObject(LiquidFont13)
    LUI.Tooltip.TextRight1:SetFontObject(LiquidFont13)
end

-- Compatibility between retail/classic
function LUI.GetSpellInfo(spell)
	if C_Spell and C_Spell.GetSpellInfo then
		return C_Spell.GetSpellInfo(spell)
	else
		local name, rank, iconID, castTime, minRange, maxRange, spellID, originalIconID = GetSpellInfo(spell)

		if name then
			return {
				name = name,
				iconID = iconID,
				originalIconID = originalIconID,
				castTime = castTime,
				minRange = minRange,
				maxRange = maxRange,
				spellID = spellID,
				rank = rank
			}
		end
	end
end

-- savedTable is a table in the addon's SavedVariables where LiquidUI can save some of its persistent data
-- This function should be called before any of the other LiquidUI functions are
function LUI:Initialize(savedTable)
	if not savedTable.LiquidUI then savedTable.LiquidUI = {} end
    if not savedTable.LiquidUI.spellDescriptionCache then savedTable.LiquidUI.spellDescriptionCache = {} end -- Used in SpellIcon widget
	if not savedTable.LiquidUI.frameSettings then savedTable.LiquidUI.frameSettings = {} end

    LUI.spellDescriptionCache = savedTable.LiquidUI.spellDescriptionCache
	LUI.frameSettings = savedTable.LiquidUI.frameSettings
end