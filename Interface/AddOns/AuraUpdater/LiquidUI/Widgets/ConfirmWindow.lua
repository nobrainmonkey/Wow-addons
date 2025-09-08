-- WIP

local _, namespace = ...

local DEFAULT_WIDTH = 240
local SPACING = 16
local window, confirmButton, cancelButton, title, textWrapper

-- Frame cover
-- This frame is shared between all popup windows
local frameCover = CreateFrame("Frame")

frameCover:SetFrameLevel(1000)
frameCover:SetFixedFrameLevel(true)
frameCover:Hide()

frameCover.tex = frameCover:CreateTexture(nil, "OVERLAY", nil, 7)
frameCover.tex:SetAllPoints()
frameCover.tex:SetColorTexture(0, 0, 0, 0.5)
frameCover.tex:SetSnapToPixelGrid(false)
frameCover.tex:SetTexelSnappingBias(0)

local function UpdateWindowSize()
    C_Timer.After(
        0,
        function()
            window:SetHeight(title:GetHeight() + 2 * SPACING + 32 + 10)
        end
    )
end

function namespace:CreatePopupWindow(parent, text, onConfirm)
    local buttons = {}
    local checkButton

    local popupWindow = CreateFrame("Frame", nil, parent)

    function popupWindow:AddButton(title, onClick)
        if #buttons == 2 then return end -- Maximum of two buttons are supported

        local button = namespace:CreateButton()

        return button
    end

    function popupWindow:AddCheckButton(title, onClick)
        if checkButton then return end -- Maximum of one check button is supported

        local checkButton = namespace:CreateCheckButton()

        return checkButton
    end

    frameCover:Show()
    frameCover:SetParent(parent)
    frameCover:SetAllPoints(parent)

    window:Show()
    window:SetParent(parent)
    window:ClearAllPoints()
    window:SetPoint("CENTER")

    title:SetText(text)
    confirmButton:SetScript(
        "OnClick",
        function()
            onConfirm()

            frameCover:Hide()
            window:Hide()
        end
    )

    UpdateWindowSize()
end

function namespace:InitializeConfirmWindow()
    window = namespace:CreateWindow()
    namespace.confirmWindow = window

    window:SetFrameLevel(1001)
    window:SetFixedFrameLevel(true)
    window:SetWidth(DEFAULT_WIDTH)
    window:Hide()

    confirmButton = namespace:CreateButton(window, "|cff00ff00Confirm|r", function() end)
    confirmButton:SetPoint("BOTTOMRIGHT", window, "BOTTOM", -4, 10)

    cancelButton = namespace:CreateButton(window, "|cffff0000Cancel|r", function() frameCover:Hide(); window:Hide() end)
    cancelButton:SetPoint("BOTTOMLEFT", window, "BOTTOM", 4, 10)

    title = window:CreateFontString()
    title:SetFontObject(LiquidFont16)
    title:SetPoint("TOP", window, "TOP", 0, -SPACING)
    title:SetWordWrap(true)
    title:SetWidth(DEFAULT_WIDTH - 2 * SPACING)

    textWrapper = CreateFrame("Frame")
    textWrapper:SetAllPoints(title)
    textWrapper:SetScript("OnSizeChanged", UpdateWindowSize)
end

-- When the user clicks outside the confirm window, hide it
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("GLOBAL_MOUSE_DOWN")
eventFrame:SetScript(
    "OnEvent",
    function()
        if window:IsShown() then
            local frame = GetMouseFoci()[1]
            
            for _ = 1, 5 do
                if not frame then break end
                if frame:IsForbidden() then break end
                if frame == window then return end
                
                frame = select(2, frame:GetPoint(1))
            end

            frameCover:Hide()
            window:Hide()
        end
    end
)