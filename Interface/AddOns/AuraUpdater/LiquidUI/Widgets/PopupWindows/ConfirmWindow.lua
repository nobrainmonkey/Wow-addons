local _, namespace = ...

local BUTTON_MARGIN = 10

function namespace:CreateConfirmWindow()
    local popupWindow = namespace:CreatePopupWindow()

    -- Confirm button
    popupWindow.confirmButton = namespace:CreateButton(
        popupWindow,
        "|cff00ff00Confirm|r",
        function()
            popupWindow.confirmButton.OnClick()

            popupWindow:Hide()
            popupWindow.frameCover:Hide()
        end
    )

    popupWindow.confirmButton:SetPoint("BOTTOMRIGHT", popupWindow, "BOTTOM", -0.5 * BUTTON_MARGIN, BUTTON_MARGIN)

    function popupWindow:SetOnConfirm(OnConfirm)
        popupWindow.confirmButton.OnClick = OnConfirm
    end

    -- Cancel button
    popupWindow.cancelButton = namespace:CreateButton(
        popupWindow,
        "|cffff0000Cancel|r",
        function()
            popupWindow:Hide()
            popupWindow.frameCover:Hide()
        end
    )

    popupWindow.cancelButton:SetPoint("BOTTOMLEFT", popupWindow, "BOTTOM", 0.5 * BUTTON_MARGIN, BUTTON_MARGIN)

    popupWindow:SetAdditionalHeight(popupWindow.confirmButton:GetHeight() + BUTTON_MARGIN)

    return popupWindow
end
