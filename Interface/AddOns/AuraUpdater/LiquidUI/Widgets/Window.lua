local addOnName, namespace = ...

local LUI = namespace.LiquidUI

local BORDER_COLOR = LUI.settings.BORDER_COLOR

local BUTTON_SIZE = 18
local BUTTON_MARGIN_X = 4
local BUTTON_MARGIN_Y = 2

local MOVER_FRAME_HEIGHT = BUTTON_SIZE + 2 * BUTTON_MARGIN_Y

-- Name is used to save position/size of the window (if set)
function namespace:CreateWindow(name, exitable, movable, resizable)
    local window = CreateFrame("Frame", nil, UIParent)

    window.buttons = {}

    window:SetScript("OnMouseWheel", function() end) -- Stop scroll wheel propagation
    window:EnableMouse(true)

    -- Background
    window.upperTexture = window:CreateTexture(nil, "BACKGROUND")
    window.upperTexture:SetPoint("TOPLEFT", window, "TOPLEFT")
    window.upperTexture:SetPoint("BOTTOMRIGHT", window, "RIGHT")
    window.upperTexture:SetTexture("Interface/Buttons/WHITE8x8")
    window.upperTexture:SetGradient("VERTICAL", CreateColor(0/255, 21/255, 56/255, 1), CreateColor(17/255, 62/255, 127/255, 1))
    window.upperTexture:SetSnapToPixelGrid(false)
    window.upperTexture:SetTexelSnappingBias(0)
    
    window.lowerTexture = window:CreateTexture(nil, "BACKGROUND")
    window.lowerTexture:SetPoint("TOPLEFT", window, "LEFT")
    window.lowerTexture:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT")
    window.lowerTexture:SetColorTexture(0/255, 21/255, 56/255)
    window.lowerTexture:SetSnapToPixelGrid(false)
    window.lowerTexture:SetTexelSnappingBias(0)

    -- Border
    LUI:AddBorder(window, 1, 1, 1)
    window:SetBorderColor(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b)

    function window:AddButton(texture, tooltip, onClick)
        if not window.buttonFrame then
            window.buttonFrame = CreateFrame("Button", nil, window.moverFrame)
            window.buttonFrame:SetPoint("TOPRIGHT", window)
            window.buttonFrame:SetHeight(MOVER_FRAME_HEIGHT)
        end

        local button = CreateFrame("Button", nil, window.buttonFrame)

        button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
        button:SetPoint("RIGHT", window.buttonFrame, "RIGHT", -#window.buttons * (BUTTON_SIZE + BUTTON_MARGIN_X) - BUTTON_MARGIN_Y, 0)

        window.buttonFrame:SetWidth((#window.buttons + 1) * (BUTTON_SIZE + BUTTON_MARGIN_X))
        
        button.tex = button:CreateTexture(nil, "ARTWORK")
        button.tex:SetTexture(texture)
        button.tex:SetVertexColor(0.5, 0.5, 0.5)
        button.tex:SetSnapToPixelGrid(false)
        button.tex:SetTexelSnappingBias(0)
        button.tex:SetAllPoints(button)

        button:SetScript(
            "OnEnter",
            function()
                button.tex:SetVertexColor(0.85, 0.85, 0.85)
            end
        )
        
        button:SetScript(
            "OnLeave",
            function()
                button.tex:SetVertexColor(0.5, 0.5, 0.5)
            end
        )
        
        button:SetScript(
            "OnClick",
            onClick
        )

        if tooltip then
            LUI:AddTooltip(button, tooltip)
        end

        table.insert(window.buttons, button)
    end

    -- Restores the previous (prior to relog/reload) size/position of the window, if any
    -- Returns whether a saved size/position existed, so that the user can apply some default sizing/positioning if not
    function window:RestoreSize()
        return LUI:RestoreSize(window, name)
    end

    function window:RestorePosition()
        return LUI:RestorePosition(window, name)
    end

    -- Layers this window in front of other windows when clicked
    -- Only layers in front of other windows that have RaiseOnClick set
    -- LIQUID_WINDOW_RAISER is a global frame, and windows from multiple addons can be added to it
    -- This function should be called AFTER parenting to another frame, since parenting overrides frames strata
    function window:RaiseOnClick()
        LIQUID_WINDOW_RAISER:AddWindow(window)
    end
    
    -- Mover frame
    if movable then
        window:SetMovable(true)

        window.moverFrame = CreateFrame("Frame", nil, window)
        window.moverFrame:SetPoint("TOPLEFT", window)
        window.moverFrame:SetPoint("TOPRIGHT", window)
        window.moverFrame:SetHeight(MOVER_FRAME_HEIGHT)

        window.moverFrame.tex = window.moverFrame:CreateTexture(nil, "BACKGROUND")
        window.moverFrame.tex:SetPoint("TOPLEFT", window)
        window.moverFrame.tex:SetPoint("BOTTOMRIGHT", window, "TOPRIGHT", 0, -MOVER_FRAME_HEIGHT)
        window.moverFrame.tex:SetColorTexture(0/255, 15/255, 41/255)
        window.moverFrame.tex:SetSnapToPixelGrid(false)
        window.moverFrame.tex:SetTexelSnappingBias(0)

        window.moverFrame:SetScript(
            "OnEnter",
            function()
                window.moverFrame.tex:SetColorTexture(0/255, 21/255, 56/255)
            end
        )

        window.moverFrame:SetScript(
            "OnLeave",
            function()
                window.moverFrame.tex:SetColorTexture(0/255, 15/255, 41/255)
            end
        )

        window.moverFrame:SetScript(
            "OnMouseDown",
            function(_, button)
                if button == "LeftButton" then
                    window:StartMoving()
                end
            end
        )

        window.moverFrame:SetScript(
            "OnMouseUp",
            function(_, button)
                if button == "LeftButton" then
                    window:StopMovingOrSizing()

                    LUI:SavePosition(window, name)
                end
            end
        )
    end

    -- Exit cross
    if exitable then
        window:AddButton(
            string.format("Interface\\Addons\\%s\\LiquidUI\\Media\\Textures\\ExitCross.tga", addOnName),
            nil,
            function()
                window:Hide()
            end
        )
    end

    -- Resize frame
    if resizable then
        window:SetResizable(true)

        window.resizeFrame = CreateFrame("Frame", nil, window)
        window.resizeFrame:SetSize(24, 24)
        window.resizeFrame:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT")

        window.resizeFrame.tex = window.resizeFrame:CreateTexture(nil, "BACKGROUND")
        window.resizeFrame.tex:SetTexture(string.format("Interface\\Addons\\%s\\LiquidUI\\Media\\Textures\\ResizeTriangle.tga", addOnName))
        window.resizeFrame.tex:SetVertexColor(0.5, 0.5, 0.5)
        window.resizeFrame.tex:SetSnapToPixelGrid(false)
        window.resizeFrame.tex:SetTexelSnappingBias(0)
        window.resizeFrame.tex:SetAllPoints(window.resizeFrame)
        
        window.resizeFrame:SetScript(
            "OnEnter",
            function()
                window.resizeFrame.tex:SetVertexColor(0.85, 0.85, 0.85)
            end
        )
        
        window.resizeFrame:SetScript(
            "OnLeave",
            function()
                window.resizeFrame.tex:SetVertexColor(0.5, 0.5, 0.5)
            end
        )
        
        window.resizeFrame:SetScript(
            "OnMouseDown",
            function(_, button)
                if button == "LeftButton" then
                    window:StartSizing()
                end
            end
        )
        
        window.resizeFrame:SetScript(
            "OnMouseUp",
            function(_, button)
                if button == "LeftButton" then
                    window:StopMovingOrSizing()

                    LUI:SaveSize(window, name)
                end
            end
        )
    end

    return window
end