local _, namespace = ...

local LUI = namespace.LiquidUI

local BORDER_COLOR = LUI.settings.BORDER_COLOR
local BACKGROUND_COLOR = LUI.settings.WIDGET_BACKGROUND_COLOR

local DEFAULT_HEIGHT = 26

function namespace:CreateButton(parent, title, OnClick)
    local button = CreateFrame("Button", nil, parent)
    local fixedWidth = false

    button.OnEnter = function() end
    button.OnLeave = function() end

    button:SetScript("OnEnter", function(_self) _self.OnEnter() end)
    button:SetScript("OnLeave", function(_self) _self.OnLeave() end)

    button.OnClick = OnClick
    
    -- If no title is present, or the title is an empty string, no font string is created
    button:SetText(" ") -- Force font string creation
    button:SetText(title) -- Set text equal to title (even if it's nil or an empty string)
    button:SetNormalFontObject(LiquidFont13)
    button:SetHighlightFontObject(LiquidFont13)
    button:SetDisabledFontObject(LiquidFont13)
    button:SetScript("OnClick", button.OnClick)

    local function UpdateWidth()
        button:SetSize(button:GetFontString():GetUnboundedStringWidth() + 20, DEFAULT_HEIGHT)
    end

    function button:SetFixedWidth(isFixed)
        fixedWidth = isFixed
    end

    hooksecurefunc(
        button,
        "SetText",
        function()
            if not fixedWidth then
                UpdateWidth()
            end
        end
    )

    hooksecurefunc(
        button,
        "SetNormalFontObject",
        function()
            if not fixedWidth then
                UpdateWidth()
            end
        end
    )

    -- Background
    button.tex = button:CreateTexture(nil, "BACKGROUND")
    button.tex:SetAllPoints()
    button.tex:SetColorTexture(BACKGROUND_COLOR.r, BACKGROUND_COLOR.g, BACKGROUND_COLOR.b, BACKGROUND_COLOR.a)
    button.tex:SetSnapToPixelGrid(false)
    button.tex:SetTexelSnappingBias(0)

    -- Border
    LUI:AddBorder(button)
    button:SetBorderColor(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b)

    -- Highlight
    LUI:AddHoverHighlight(button)

    UpdateWidth()
    
    return button
end
