local _, namespace = ...

local BUTTON_MARGIN = 10

-- Creates a popup window with a single button, and optionally a check button
-- The button's OnClick function receives the state (boolean) of the check button as its only argument
-- The popup window and frame cover are always hidden after the button is clicked, no need to include it in the OnClick function
function namespace:CreatePopupWindowWithButton()
    local popupWindow = namespace:CreatePopupWindow()

    popupWindow.button = namespace:CreateButton(
        popupWindow,
        "",
        function()
            popupWindow.button.OnClick(popupWindow.checkButton and popupWindow.checkButton:IsChecked())

            popupWindow:Hide()
            popupWindow.frameCover:Hide()
        end
    )

    popupWindow.button:SetPoint("BOTTOM", popupWindow, "BOTTOM", 0, BUTTON_MARGIN)

    popupWindow:SetAdditionalHeight(popupWindow.button:GetHeight() + BUTTON_MARGIN)

    function popupWindow:AddCheckButton(text)
        if popupWindow.checkButton then return end

        popupWindow.checkButton = namespace:CreateCheckButton(popupWindow, text, function() end)

        popupWindow.checkButton:SetPoint("BOTTOMLEFT", popupWindow.button, "TOP", -0.5 * popupWindow.checkButton:GetTotalWidth(), BUTTON_MARGIN)

        popupWindow:SetAdditionalHeight(popupWindow.button:GetHeight() + popupWindow.checkButton:GetHeight() + 2 * BUTTON_MARGIN)
    end

    function popupWindow:SetButtonText(text)
        popupWindow.button:SetText(text)
    end

    function popupWindow:SetButtonOnClick(OnClick)
        popupWindow.button.OnClick = OnClick
    end

    return popupWindow
end
