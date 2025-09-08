local _, LUP = ...

local updatePopupWindow

local function OnEvent(_, event, ...)
    if event == "READY_CHECK" then
        if not updatePopupWindow then
            updatePopupWindow = LUP:CreatePopupWindowWithButton()

            updatePopupWindow:SetHideOnClickOutside(false)
            updatePopupWindow:SetText(string.format("|cff%sWarning|r|n|nYour addon/auras are outdated!", LUP.gs.visual.colorStrings.red))
            updatePopupWindow:SetButtonText(string.format("|cff%sOK|r", LUP.gs.visual.colorStrings.green))
            updatePopupWindow:AddCheckButton("Don't show again")
            updatePopupWindow:SetButtonOnClick(
                function(dontShowAgain)
                    LUP:SetNotifyOnReadyCheck(not dontShowAgain)

                    updatePopupWindow.checkButton:SetChecked(false)
                end
            )
        end

        if LiquidUpdaterSaved.settings.readyCheckPopup and not LUP.upToDate then
            updatePopupWindow:Pop()
            updatePopupWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("READY_CHECK")
f:SetScript("OnEvent", OnEvent)