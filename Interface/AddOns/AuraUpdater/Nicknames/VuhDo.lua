local _, LUP = ...

local ADDON_NAME = "VuhDo"

local vuhDoHooks = {}
local vuhDoPanelSettings = {}

local function UpdateVuhDoName(unit, nameText, buttonName)
    local name = LiquidUpdaterSaved.settings.vuhDoNicknames and AuraUpdater:GetNickname(unit) or UnitName(unit)

    -- Respect the max character option (if set)
    local panelNumber = buttonName and buttonName:match("^Vd(%d+)")
    panelNumber = tonumber(panelNumber)

    local maxChars = panelNumber and vuhDoPanelSettings[panelNumber] and vuhDoPanelSettings[panelNumber].maxChars
    
    if name and maxChars and maxChars > 0 then
        name = name:sub(1, maxChars)
    end

    nameText:SetFormattedText(name or "") -- SetText is hooked, so we use this instead
end

local function RefreshVuhDoNameForUnit(unit)
    if not VUHDO_UNIT_BUTTONS then return end
    if not unit then return end
    if not UnitExists(unit) then return end

    for vuhDoUnit, unitButtons in pairs(VUHDO_UNIT_BUTTONS) do
        if UnitIsUnit(unit, vuhDoUnit) then
            for _, button in ipairs(unitButtons) do
                local unitButtonName = button:GetName()
                local nameText = _G[unitButtonName .. "BgBarIcBarHlBarTxPnlUnN"]
                
                UpdateVuhDoName(unit, nameText, unitButtonName)
            end

            break
        end
     end
end

function LUP:RefreshAllVuhDoNames()
    if not VUHDO_UNIT_BUTTONS then return end

    for unit, unitButtons in pairs(VUHDO_UNIT_BUTTONS) do
        for _, button in ipairs(unitButtons) do
            local unitButtonName = button:GetName()
            local nameText = _G[unitButtonName .. "BgBarIcBarHlBarTxPnlUnN"]

            UpdateVuhDoName(unit, nameText, unitButtonName)
        end
     end
end

-- Hooks VuhDo unit frames' text update function to override it with nicknames
LUP.nicknameInitFunctions[ADDON_NAME] = function()
    if VUHDO_PANEL_SETUP then
        for i, settings in pairs(VUHDO_PANEL_SETUP) do
            local textSettings = type(settings) == "table" and settings.PANEL_COLOR and settings.PANEL_COLOR.TEXT

            vuhDoPanelSettings[i] = textSettings
        end
    end

	hooksecurefunc(
		"VUHDO_getBarText",
		function(unitHealthBar)
			local unitFrameName = unitHealthBar and unitHealthBar.GetName and unitHealthBar:GetName()

			if not unitFrameName then return end

			local nameText = _G[unitFrameName .. "TxPnlUnN"]

			if not nameText then return end
			if vuhDoHooks[nameText] then return end

            local unitButton = _G[unitFrameName:match("(.+)BgBarIcBarHlBar")]

            if not unitButton then return end

			hooksecurefunc(
				nameText,
				"SetText",
				function(self)
                    local unit = unitButton.raidid

                    UpdateVuhDoName(unit, self, unitFrameName)
				end
			)

			vuhDoHooks[nameText] = true
		end
	)
end

LUP.nicknameUpdateFunctions[ADDON_NAME] = function(unit)
	RefreshVuhDoNameForUnit(unit)
end