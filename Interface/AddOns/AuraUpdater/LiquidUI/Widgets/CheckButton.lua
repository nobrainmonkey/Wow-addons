local _, namespace = ...

local LUI = namespace.LiquidUI

local BORDER_COLOR = LUI.settings.BORDER_COLOR
local BACKGROUND_COLOR = LUI.settings.WIDGET_BACKGROUND_COLOR

local SPACING = 4
local DEFAULT_SIZE = 20

function namespace:CreateCheckButton(parent, title, OnValueChanged, labelLeft)
    local checkButton = CreateFrame("Button", nil, parent)
    local enabled = true

    checkButton.OnEnter = function() end
    checkButton.OnLeave = function() end

    checkButton:SetScript("OnEnter", function(_self) _self.OnEnter() end)
    checkButton:SetScript("OnLeave", function(_self) _self.OnLeave() end)

    local isChecked = false

    checkButton:SetSize(DEFAULT_SIZE, DEFAULT_SIZE)
    LUI:AddHoverHighlight(checkButton)

    checkButton.OnValueChanged = OnValueChanged

    -- Background
    checkButton.tex = checkButton:CreateTexture(nil, "BACKGROUND")
    checkButton.tex:SetAllPoints()
    checkButton.tex:SetColorTexture(BACKGROUND_COLOR.r, BACKGROUND_COLOR.g, BACKGROUND_COLOR.b, BACKGROUND_COLOR.a)
    checkButton.tex:SetSnapToPixelGrid(false)
    checkButton.tex:SetTexelSnappingBias(0)

    function checkButton:SetBackgroundColor(r, g, b, a)
        checkButton.tex:SetColorTexture(r, g, b, a)
    end

    -- Border
    LUI:AddBorder(checkButton)
    checkButton:SetBorderColor(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b)

    -- Title
    checkButton.title = checkButton:CreateFontString()

    checkButton.title:SetFontObject(LiquidFont13)
    checkButton.title:SetText(string.format("|cFFFFCC00%s|r", title))

    if labelLeft then
        checkButton.title:SetPoint("RIGHT", checkButton, "LEFT", -SPACING, -1)
    else
        checkButton.title:SetPoint("LEFT", checkButton, "RIGHT", SPACING, -1)
    end

    -- Check
    checkButton.checkmark = checkButton:CreateTexture(nil, "OVERLAY")
    checkButton.checkmark:SetAllPoints()
    checkButton.checkmark:SetAtlas("common-icon-checkmark-yellow")
    checkButton.checkmark:SetSnapToPixelGrid(false)
    checkButton.checkmark:SetTexelSnappingBias(0)
    checkButton.checkmark:Hide()

    function checkButton:SetChecked(checked)
        isChecked = checked

        checkButton.checkmark:SetShown(checked)
    end

    function checkButton:IsChecked()
        return isChecked
    end

    -- Returns the total width of the check button + the text + the space in between
    function checkButton:GetTotalWidth()
        return checkButton:GetWidth() + SPACING + checkButton.title:GetUnboundedStringWidth()
    end

    checkButton:SetScript(
        "OnClick",
        function()
            if enabled then
                checkButton:SetChecked(not isChecked)
            end
        end
    )

    hooksecurefunc(
        checkButton,
        "SetChecked",
        function(_, checked, dontRun)
            if dontRun then return end -- To avoid recursion

            checkButton.OnValueChanged(checked)
        end
    )

    -- Enable/disable
    function checkButton:Enable()
        enabled = true

        checkButton.checkmark:SetDesaturated(false)
        checkButton.title:SetText(string.format("|cFFFFCC00%s|r", title))

        LUI:AddHoverHighlight(checkButton)
    end

    function checkButton:Disable()
        enabled = false
        
        checkButton.checkmark:SetDesaturated(true)
        checkButton.title:SetText(string.format("|cFFBBBBBB%s|r", title))

        LUI:AddHoverHighlight(checkButton, nil, nil, 0.5, 0.5, 0.5)
    end

    return checkButton
end