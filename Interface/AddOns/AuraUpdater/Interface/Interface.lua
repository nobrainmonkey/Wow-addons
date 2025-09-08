local _, LUP = ...

-- Main window
local MIN_WINDOW_WIDTH = 600
local MIN_WINDOW_HEIGHT = 400

local updateButton, auraCheckButton, otherCheckButton
local updateList, auraCheckGrid, otherCheckGrid

local function ResizeHeaderButtons(_, buttonFrameWidth)
    local combinedButtonWidth = buttonFrameWidth - 16

    updateButton:SetWidth(combinedButtonWidth / 3)
    auraCheckButton:SetWidth(combinedButtonWidth / 3)
end

-- Called when the installed version of an aura supplied by AuraUpdater changes for the player
function LUP:OnPlayerAuraUpdate()
    updateList:Rebuild()
end

-- Called when we receive a new nickname for a unit
function LUP:OnNicknameUpdate(unit, nickname)
    auraCheckGrid:UpdateDisplayNameForUnit(unit, nickname)
    otherCheckGrid:UpdateDisplayNameForUnit(unit, nickname)
end

-- Called whenever the versions table for a group member changes (including our own)
function LUP:OnVersionsTableUpdate(unit, versionsTable)
    auraCheckGrid:UpdateVersionsTableForUnit(unit, versionsTable)
    otherCheckGrid:UpdateVersionsTableForUnit(unit, versionsTable)
end

-- When the MRT hash changes for the player, we want to fully rebuild the other check grid
-- The reason for this, is that the MRT cell for every row is compared to ours
function LUP:OnMRTHashUpdate()
    otherCheckGrid:UpdateVersionsTableForUnit("player", LUP:GetPlayerVersionsTable())

    otherCheckGrid:FullRebuild()
end

-- Called when we receive a highest addon/weakaura version than those we had previously seen
-- We want to fully rebuild the checker grids, since this change has to be reflected in every row
function LUP:OnHighestSeenVersionsUpdate()
    updateList:Rebuild()

    auraCheckGrid:FullRebuild()
    otherCheckGrid:FullRebuild()
end

-- Updates the minimum resize bounds for the AuraUpdater window, based on the min width of the check grids
-- This is called whenever the titles for a check grid header change
function LUP:UpdateWindowResizeBounds()
    local auraCheckGridWidth = auraCheckGrid and auraCheckGrid:GetMinimumWidth() or 0
    local otherCheckGridWidth = otherCheckGrid and otherCheckGrid:GetMinimumWidth() or 0

    local minWidth = math.max(MIN_WINDOW_WIDTH, auraCheckGridWidth, otherCheckGridWidth)
    local minHeight = MIN_WINDOW_HEIGHT

    LUP.window:SetResizeBounds(minWidth, minHeight)

    -- If the size of the window is currently smaller than the minimum size, increase it
    local currentWidth, currentHeight = LUP.window:GetSize()

    LUP.window:SetSize(
        math.max(currentWidth, minWidth),
        math.max(currentHeight, minHeight)
    )
end

function LUP:InitializeInterface()
    -- Window
    LUP.window = LUP:CreateWindow(nil, true, true, true)

    LUP.window:RaiseOnClick()
    LUP.window:SetFrameStrata("HIGH")
    LUP.window:SetPoint("CENTER")
    LUP.window:Hide()

    LUP.window:AddButton(
        "Interface\\Addons\\AuraUpdater\\Media\\Textures\\Cogwheel.tga",
        "Settings",
        function()
            LUP.settingsWindow:SetShown(not LUP.settingsWindow:IsShown())
        end
    )

    -- Button frame
    local buttonFrame = CreateFrame("Frame", nil, LUP.window)

    buttonFrame:SetPoint("TOPLEFT", LUP.window.moverFrame, "BOTTOMLEFT")
    buttonFrame:SetPoint("TOPRIGHT", LUP.window.moverFrame, "BOTTOMRIGHT")

    buttonFrame:SetHeight(32)
    buttonFrame:SetScript("OnSizeChanged", ResizeHeaderButtons)

    -- Update button
    updateButton = CreateFrame("Frame", nil, LUP.window)

    updateButton:SetPoint("TOPLEFT", buttonFrame, "TOPLEFT", 4, -4)
    updateButton:SetPoint("BOTTOMLEFT", buttonFrame, "BOTTOMLEFT", 4, 0)
    updateButton:EnableMouse(true)

    updateButton.highlight = updateButton:CreateTexture(nil, "HIGHLIGHT")
    updateButton.highlight:SetColorTexture(1, 1, 1, 0.05)
    updateButton.highlight:SetAllPoints()
    updateButton.highlight:SetSnapToPixelGrid(false)
    updateButton.highlight:SetTexelSnappingBias(0)

    updateButton.text = updateButton:CreateFontString(nil, "OVERLAY")
    updateButton.text:SetFontObject(LiquidFont17)
    updateButton.text:SetPoint("CENTER", updateButton, "CENTER")
    updateButton.text:SetText(string.format("|cff%sUpdate|r", LUP.gs.visual.colorStrings.white))

    updateButton:SetScript(
        "OnMouseDown",
        function()
            LUP.updateWindow:Show()
            LUP.auraCheckWindow:Hide()
            LUP.otherCheckWindow:Hide()
        end
    )

    local borderColor = LUP.LiquidUI.settings.BORDER_COLOR
    LUP.LiquidUI:AddBorder(updateButton)
    updateButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Aura check button
    auraCheckButton = CreateFrame("Frame", nil, LUP.window)

    auraCheckButton:SetPoint("TOPLEFT", updateButton, "TOPRIGHT", 4, 0)
    auraCheckButton:SetPoint("BOTTOMLEFT", updateButton, "BOTTOMRIGHT", 4, 0)
    auraCheckButton:EnableMouse(true)

    auraCheckButton.highlight = auraCheckButton:CreateTexture(nil, "HIGHLIGHT")
    auraCheckButton.highlight:SetColorTexture(1, 1, 1, 0.05)
    auraCheckButton.highlight:SetAllPoints()
    auraCheckButton.highlight:SetSnapToPixelGrid(false)
    auraCheckButton.highlight:SetTexelSnappingBias(0)

    auraCheckButton.text = auraCheckButton:CreateFontString(nil, "OVERLAY")
    auraCheckButton.text:SetFontObject(LiquidFont17)
    auraCheckButton.text:SetPoint("CENTER", auraCheckButton, "CENTER")
    auraCheckButton.text:SetText(string.format("|cff%sAura check|r", LUP.gs.visual.colorStrings.white))

    auraCheckButton:SetScript(
        "OnMouseDown",
        function()
            LUP.updateWindow:Hide()
            LUP.auraCheckWindow:Show()
            LUP.otherCheckWindow:Hide()
        end
    )

    LUP.LiquidUI:AddBorder(auraCheckButton)
    auraCheckButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Other check button
    otherCheckButton = CreateFrame("Frame", nil, LUP.window)

    otherCheckButton:SetPoint("TOPLEFT", auraCheckButton, "TOPRIGHT", 4, 0)
    otherCheckButton:SetPoint("BOTTOMRIGHT", buttonFrame, "BOTTOMRIGHT", -4, 0)
    otherCheckButton:EnableMouse(true)

    otherCheckButton.highlight = otherCheckButton:CreateTexture(nil, "HIGHLIGHT")
    otherCheckButton.highlight:SetColorTexture(1, 1, 1, 0.05)
    otherCheckButton.highlight:SetAllPoints()
    otherCheckButton.highlight:SetSnapToPixelGrid(false)
    otherCheckButton.highlight:SetTexelSnappingBias(0)

    otherCheckButton.text = otherCheckButton:CreateFontString(nil, "OVERLAY")
    otherCheckButton.text:SetFontObject(LiquidFont17)
    otherCheckButton.text:SetPoint("CENTER", otherCheckButton, "CENTER")
    otherCheckButton.text:SetText(string.format("|cff%sOther check|r", LUP.gs.visual.colorStrings.white))

    otherCheckButton:SetScript(
        "OnMouseDown",
        function()
            LUP.updateWindow:Hide()
            LUP.auraCheckWindow:Hide()
            LUP.otherCheckWindow:Show()
        end
    )

    LUP.LiquidUI:AddBorder(otherCheckButton)
    otherCheckButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Sub windows
    LUP.updateWindow = CreateFrame("Frame", nil, LUP.window)
    LUP.updateWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    LUP.updateWindow:SetPoint("BOTTOMRIGHT", LUP.window, "BOTTOMRIGHT")

    LUP.auraCheckWindow = CreateFrame("Frame", nil, LUP.window)
    LUP.auraCheckWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    LUP.auraCheckWindow:SetPoint("BOTTOMRIGHT", LUP.window, "BOTTOMRIGHT")

    LUP.otherCheckWindow = CreateFrame("Frame", nil, LUP.window)
    LUP.otherCheckWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    LUP.otherCheckWindow:SetPoint("BOTTOMRIGHT", LUP.window, "BOTTOMRIGHT")

    LUP.auraCheckWindow:Hide()
    LUP.otherCheckWindow:Hide()

    LUP:InitializeSettings()

    -- When escape is pressed, close the main window
    LUP.window:SetScript(
        "OnKeyDown",
        function(_, key)
            if InCombatLockdown() then return end

            if key == "ESCAPE" then
                LUP.window:SetPropagateKeyboardInput(false)

                LUP.window:Hide()
            else
                LUP.window:SetPropagateKeyboardInput(true)
            end
        end
    )

    -- Update list
    updateList = LUP:CreateUpdateList(LUP.updateWindow)

    updateList:SetPoint("TOPLEFT", LUP.updateWindow, "TOPLEFT", 4, -4)
    updateList:SetPoint("BOTTOMRIGHT", LUP.updateWindow, "BOTTOMRIGHT", -1, 4)

    -- Aura check grid
    auraCheckGrid = LUP:CreateAuraCheckGrid(LUP.auraCheckWindow)

    auraCheckGrid:SetPoint("TOPLEFT", LUP.auraCheckWindow, "TOPLEFT", 4, -4)
    auraCheckGrid:SetPoint("BOTTOMRIGHT", LUP.auraCheckWindow, "BOTTOMRIGHT", -1, 4)

    -- Other check grid
    otherCheckGrid = LUP:CreateOtherCheckGrid(LUP.otherCheckWindow)

    otherCheckGrid:SetPoint("TOPLEFT", LUP.otherCheckWindow, "TOPLEFT", 4, -4)
    otherCheckGrid:SetPoint("BOTTOMRIGHT", LUP.otherCheckWindow, "BOTTOMRIGHT", -1, 4)

    LUP:UpdateWindowResizeBounds()

    -- -- Test
    -- local window = LUP:CreateWindow(nil, true, true, true)

    -- window:SetPoint("CENTER")

    -- local checkGrid = LUP:CreateAuraCheckGrid(window)

    -- checkGrid:SetPoint("TOPLEFT", window.moverFrame, "BOTTOMLEFT", 4, -4)
    -- checkGrid:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -4, 4)

    -- window:SetResizeBounds(checkGrid:GetMinimumWidth(), 400)
    -- window:SetSize(checkGrid:GetMinimumWidth(), 400)

    -- LUP.auraCheckGrid = checkGrid
end