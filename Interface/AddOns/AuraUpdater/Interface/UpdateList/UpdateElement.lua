local _, LUP = ...

local ADDON_TEXTURE = "Interface\\Addons\\AuraUpdater\\Media\\Textures\\Bart.tga"
local MARGIN = 8 -- Distance between the outer edge of the element, and the frames inside it
local ICON_SIZE = 24
local ELEMENT_HEIGHT = 40
local TOOLTIP_NAME_COLOR = "98f8fa" -- Color of the addon/aura name in tooltips

local framePool = {}

local function Acquire()
    local index, frame = next(framePool)

    if not frame then return end

    framePool[index] = nil

    return frame
end

function LUP:CreateUpdateElement(parent, auraName)
    local updateElement = Acquire()

    if not updateElement then
        updateElement = CreateFrame("Frame", nil, parent)

        updateElement:SetHeight(ELEMENT_HEIGHT)
        updateElement:EnableMouse(true)

        -- Highlight
        updateElement.highlight = updateElement:CreateTexture(nil, "HIGHLIGHT")

        updateElement.highlight:SetColorTexture(1, 1, 1, 0.05)
        updateElement.highlight:SetAllPoints()
        updateElement.highlight:SetSnapToPixelGrid(false)
        updateElement.highlight:SetTexelSnappingBias(0)

        -- Border
        LUP.LiquidUI:AddBorder(updateElement)

        local borderColor = LUP.LiquidUI.settings.BORDER_COLOR

        updateElement:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

        -- Icon
        updateElement.icon = CreateFrame("Frame", nil, updateElement)

        updateElement.icon:SetSize(ICON_SIZE, ICON_SIZE)
        updateElement.icon:Hide()
        updateElement.icon:SetPoint("LEFT", updateElement, "LEFT", MARGIN, 0)

        updateElement.icon.tex = updateElement.icon:CreateTexture(nil, "BACKGROUND")
        updateElement.icon.tex:SetAllPoints(updateElement.icon)
        updateElement.icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        updateElement.icon.tex:SetSnapToPixelGrid(false)
        updateElement.icon.tex:SetTexelSnappingBias(0)

        -- Version count
        updateElement.versionCount = updateElement:CreateFontString()

        updateElement.versionCount:SetFontObject(LiquidFont17)
        updateElement.versionCount:SetPoint("CENTER", updateElement, "CENTER")

        -- Display name
        updateElement.displayName = updateElement:CreateFontString()

        updateElement.displayName:SetFontObject(LiquidFont17)
        updateElement.displayName:SetPoint("LEFT", updateElement, "LEFT", MARGIN, 0)

        -- Import button
        updateElement.importButton = LUP:CreateButton(updateElement, "Update", function() end)

        updateElement.importButton:SetNormalFontObject(LiquidFont15)
        updateElement.importButton:SetHighlightFontObject(LiquidFont15)
        updateElement.importButton:SetDisabledFontObject(LiquidFont15)

        updateElement.importButton:SetPoint("RIGHT", updateElement, "RIGHT", -MARGIN, 0)

        -- Requires addon update text
        updateElement.requiresUpdateText = updateElement:CreateFontString()

        updateElement.requiresUpdateText:SetFontObject(LiquidFont17)
        updateElement.requiresUpdateText:SetPoint("RIGHT", updateElement, "RIGHT", -MARGIN, 0)
        updateElement.requiresUpdateText:SetFormattedText("|cff%sUpdate addon!|r", LUP.gs.visual.colorStrings.red)
        updateElement.requiresUpdateText:Hide()

        local function UpdateTooltip()
            local tooltip = string.format(
                "|cff%s%s|r is |cff%s%d|r version(s) behind",
                TOOLTIP_NAME_COLOR,
                updateElement.auraName,
                LUP.gs.visual.colorStrings.red,
                updateElement.versionsBehind
            )

            if updateElement.requiresUpdate and updateElement.auraName ~= "AuraUpdater" then
                tooltip = tooltip .. "|n|nYou must update AuraUpdater before this version is available to you."
            end
            
            LUP.LiquidUI:AddTooltip(updateElement, tooltip)
        end

        function updateElement:SetVersionsBehind(count)
            updateElement.versionsBehind = count

            updateElement.versionCount:SetFormattedText("|cff%s%d version(s)|r", LUP.gs.visual.colorStrings.red, count)

            UpdateTooltip()
        end

        function updateElement:SetRequiresAddOnUpdate(requiresUpdate)
            updateElement.requiresUpdate = requiresUpdate

            updateElement.versionCount:SetShown(not requiresUpdate)
            updateElement.importButton:SetShown(not requiresUpdate)
            updateElement.requiresUpdateText:SetShown(requiresUpdate)

            UpdateTooltip()
        end

        function updateElement:Release()
            updateElement:Hide()

            table.insert(framePool, updateElement)
        end
    end

    updateElement.auraName = auraName
    updateElement.versionsBehind = 0
    updateElement.requiresUpdate = false
    updateElement.displayName:SetFormattedText("|cff%s%s|r", LUP.gs.visual.colorStrings.white, auraName)
    
    -- If this element shows an addon update instead of an aura update, don't add an update button script
    -- Icon is also hardcoded, rather than taken from aura data (there is no aura)
    if auraName == "AuraUpdater" then
        updateElement.icon.tex:SetTexture(ADDON_TEXTURE)
        updateElement.icon:Show()
        updateElement.displayName:SetPoint("LEFT", updateElement, "LEFT", 38, 0)
    else
        local auraData = LiquidUpdaterSaved.WeakAuras[auraName]
        local version = LiquidUpdaterSaved.WeakAuras[auraName].d.liquidVersion

        updateElement.importButton:SetScript(
            "OnClick",
            function()
                LUP:UpdateAura(auraData, version)
            end
        )

        local icon = auraData.d.groupIcon

        if icon then
            updateElement.icon.tex:SetTexture(icon)
        end

        updateElement.icon:SetShown(icon)
        updateElement.displayName:SetPoint("LEFT", updateElement, "LEFT", icon and 38 or 8, 0)
    end

    updateElement:Show()

    return updateElement
end