local addOnName, namespace = ...

local TEXTURE = string.format("Interface\\AddOns\\%s\\LiquidUI\\Media\\Textures\\Help-i.tga", addOnName)
local HIGHLIGHT_TEXTURE = string.format("Interface\\AddOns\\%s\\LiquidUI\\Media\\Textures\\Help-i-highlight.tga", addOnName)

local DEFAULT_SIZE = 20

function namespace:CreateInfoButton(parent, tooltip)
    local infoButton = CreateFrame("Button", nil, parent)

    infoButton:SetSize(DEFAULT_SIZE, DEFAULT_SIZE)
    infoButton:SetHighlightTexture(HIGHLIGHT_TEXTURE, "ADD")
    infoButton:SetMouseMotionEnabled(true)

    infoButton.tex = infoButton:CreateTexture()
    infoButton.tex:SetAllPoints(infoButton)
    infoButton.tex:SetTexture(TEXTURE)
    infoButton.tex:SetSnapToPixelGrid(false)
    infoButton.tex:SetTexelSnappingBias(0)

    namespace.LiquidUI:AddTooltip(infoButton, tooltip)

    return infoButton
end
