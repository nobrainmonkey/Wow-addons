local _, namespace = ...

local DEFAULT_WIDTH = 240
local SPACING = 16

-- Creates a popup window with just text
-- This is used as a base for other popup windows that may have buttons, check buttons, etc.
function namespace:CreatePopupWindow()
    local additionalHeight = 0

    -- Window
    local popupWindow = namespace:CreateWindow()

    popupWindow:SetFrameLevel(1001)
    popupWindow:SetFixedFrameLevel(true)
    popupWindow:SetWidth(DEFAULT_WIDTH)
    popupWindow:Hide()

    -- The text shown in the popup window
    popupWindow.text = popupWindow:CreateFontString()

    popupWindow.text:SetFontObject(LiquidFont16)
    popupWindow.text:SetPoint("TOP", popupWindow, "TOP", 0, -SPACING)
    popupWindow.text:SetWordWrap(true)
    popupWindow.text:SetWidth(DEFAULT_WIDTH - 2 * SPACING)

    -- This is overlaid on top of the popup window's parent window (unless it's UIParent)
    -- It darkens the window that it's overlaid on top of, so that the popup window is more distinctly visible
    popupWindow.frameCover = CreateFrame("Frame")

    popupWindow.frameCover:SetFrameLevel(1000)
    popupWindow.frameCover:SetFixedFrameLevel(true)
    popupWindow.frameCover:Hide()

    popupWindow.frameCover.tex = popupWindow.frameCover:CreateTexture(nil, "OVERLAY", nil, 7)
    popupWindow.frameCover.tex:SetAllPoints()
    popupWindow.frameCover.tex:SetColorTexture(0, 0, 0, 0.5)
    popupWindow.frameCover.tex:SetSnapToPixelGrid(false)
    popupWindow.frameCover.tex:SetTexelSnappingBias(0)

    -- Shows the popup window
    function popupWindow:Pop(parent)
        if not parent then parent = UIParent end

        popupWindow:Show()
        popupWindow:SetParent(parent)
        popupWindow:ClearAllPoints()
        popupWindow:SetPoint("CENTER")

        if parent ~= UIParent then
            popupWindow.frameCover:Show()
            popupWindow.frameCover:SetParent(parent)
            popupWindow.frameCover:SetAllPoints(parent)
        end
    end

    -- Update the height of the popup window according to the text height
    -- By default this is just the text height, plus the default spacing on top/bottom
    -- additionalHeight is added to this, which can be set through SetAdditionalHeight()
    local function UpdateHeight()
        popupWindow:SetHeight(popupWindow.text:GetHeight() + 2 * SPACING + additionalHeight)
    end

    function popupWindow:SetAdditionalHeight(height)
        additionalHeight = height

        UpdateHeight()
    end

    function popupWindow:SetText(text)
        popupWindow.text:SetText(text)

        UpdateHeight()
    end

    -- Sets whether the popup window should hide when the user clicks outside of it
    -- This is true by default
    function popupWindow:SetHideOnClickOutside(shouldHide)
        if shouldHide then
            popupWindow:RegisterEvent("GLOBAL_MOUSE_DOWN")
        else
            popupWindow:UnregisterEvent("GLOBAL_MOUSE_DOWN")
        end
    end

    popupWindow:RegisterEvent("GLOBAL_MOUSE_DOWN")
    popupWindow:SetScript(
        "OnEvent",
        function()
            if popupWindow:IsShown() then
                local frame = GetMouseFoci()[1]
                
                for _ = 1, 10 do
                    if not frame then break end
                    if frame:IsForbidden() then break end
                    if frame == popupWindow then return end
                    
                    frame = select(2, frame:GetPoint(1))
                end

                popupWindow:Hide()
                popupWindow.frameCover:Hide()
            end
        end
    )

    return popupWindow
end
