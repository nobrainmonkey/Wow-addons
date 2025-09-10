local _, namespace = ...

local LUI = namespace.LiquidUI

local BORDER_COLOR = LUI.settings.BORDER_COLOR
local BACKGROUND_COLOR = LUI.settings.WIDGET_BACKGROUND_COLOR

local DEFAULT_WIDTH = 100
local DEFAULT_HEIGHT = 20

function namespace:CreateSlider(parent, title, min, max, OnValueChanged, initialValue)
    local slider = CreateFrame("Slider", nil, parent, "UISliderTemplateWithLabels")

    slider.OnEnter = function() end
    slider.OnLeave = function() end

    slider:SetScript("OnEnter", function(_self) _self.OnEnter() end)
    slider:SetScript("OnLeave", function(_self) _self.OnLeave() end)

    slider:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)

    -- Title
    slider.Text:SetFontObject(LiquidFont13)
    slider.Text:SetText(string.format("|cFFFFCC00%s|r", title))
    slider.Text:SetShadowOffset(0, 0)

    -- Low text
    slider.Low:SetFontObject(LiquidFont13)
    slider.Low:SetText(min)
    slider.Low:SetShadowOffset(0, 0)
    slider.Low:ClearAllPoints()
    slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 2, 0)

    -- High text
    slider.High:SetFontObject(LiquidFont13)
    slider.High:SetText(max)
    slider.High:SetShadowOffset(0, 0)
    slider.High:ClearAllPoints()
    slider.High:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", -2, 0)

    -- Current text
    slider.Current = slider:CreateFontString()

    slider.Current:SetFontObject(LiquidFont13)
    slider.Current:SetText(string.format("|cFFFFCC00%d|r", math.floor(max / 2)))
    slider.Current:SetPoint("TOP", slider, "BOTTOM", 0, 0)

    -- Background
    slider.background = slider:CreateTexture(nil, "BACKGROUND")

    slider.background:SetPoint("TOPLEFT", slider.NineSlice, "TOPLEFT", 0, -3)
    slider.background:SetPoint("BOTTOMRIGHT", slider.NineSlice, "BOTTOMRIGHT", 0, 3)
    slider.background:SetColorTexture(BACKGROUND_COLOR.r, BACKGROUND_COLOR.g, BACKGROUND_COLOR.b, BACKGROUND_COLOR.a)
    slider.background:SetSnapToPixelGrid(false)
    slider.background:SetTexelSnappingBias(0)

    slider:SetScript(
        "OnValueChanged",
        function(_, value)
            OnValueChanged(value)

            slider.Current:SetText(string.format("|cFFFFCC00%d|r", value))
        end
    )

    slider.NineSlice.TopEdge:Hide()
    slider.NineSlice.BottomEdge:Hide()
    slider.NineSlice.LeftEdge:Hide()
    slider.NineSlice.RightEdge:Hide()

    slider.NineSlice.TopLeftCorner:Hide()
    slider.NineSlice.TopRightCorner:Hide()
    slider.NineSlice.BottomLeftCorner:Hide()
    slider.NineSlice.BottomRightCorner:Hide()

    slider.NineSlice.Center:Hide()
    
    LUI:AddBorder(slider, 1, 0, -3)
    slider:SetBorderColor(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b)
    
    if initialValue then
        slider:SetValue(initialValue)
    else
        slider:SetValue(math.floor(max / 2))
    end

    return slider
end