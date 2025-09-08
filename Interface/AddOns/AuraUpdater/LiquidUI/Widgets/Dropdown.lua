local addOnName, namespace = ...

local LUI = namespace.LiquidUI

local BORDER_COLOR = LUI.settings.BORDER_COLOR
local BACKGROUND_COLOR = LUI.settings.WIDGET_BACKGROUND_COLOR

local ARROW_TEXTURE = string.format("Interface\\AddOns\\%s\\LiquidUI\\Media\\Textures\\ArrowDown.tga", addOnName)
local ARROW_PUSHED_TEXTURE = string.format("Interface\\AddOns\\%s\\LiquidUI\\Media\\Textures\\ArrowDownPushed.tga", addOnName)

local DEFAULT_WIDTH = 150
local DEFAULT_HEIGHT = 24

function namespace:CreateDropdown(parent, title, _infoTable, OnValueChanged, initialValue)
    local infoTable, i, selectedIndices
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")

    dropdown:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)

    -- Tooltip purposes
    dropdown.OnEnter = function() end
    dropdown.OnLeave = function() end

    dropdown:SetScript("OnEnter", function(_self) _self.OnEnter() end)
    dropdown:SetScript("OnLeave", function(_self) _self.OnLeave() end)

    -- Title
    local dropdownTitle = dropdown:CreateFontString()

    dropdownTitle:SetFontObject(LiquidFont13)
    dropdownTitle:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT")
    dropdownTitle:SetText(string.format("|cFFFFCC00%s|r", title or ""))

    local function IsSelected(index)
        if not selectedIndices then return end

        return selectedIndices[index]
    end

    local function SetSelected(indices, values, text)
        selectedIndices = indices

        dropdown:OverrideText(text)

        OnValueChanged(unpack(values))
    end

    local function MakeSubmenu(parentButton, subInfoTable, values, parentSelectionIndices)
        local selectionIndices = CopyTable(parentSelectionIndices)

        i = i + 1
        subInfoTable.selectionIndex = i
        selectionIndices[i] = true

        local text = subInfoTable.text
        local icon = subInfoTable.icon
        local iconString = icon and namespace:IconString(icon)

        if iconString then
            text = string.format("%s %s", iconString, text)
        end

        local button = parentButton:CreateRadio(
            subInfoTable.text,
            IsSelected,
            subInfoTable.children and function() end or
            function()
                selectedIndices = selectionIndices

                SetSelected(selectionIndices, values, text)
            end,
            i
        )

        button:AddInitializer(
            function(_button)
                -- Text
                local fontString = _button.fontString

                -- Icon
                local iconTexture = _button:AttachTexture()

                iconTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                iconTexture:SetSize(18, 18)
                iconTexture:SetPoint("RIGHT", _button, "RIGHT", subInfoTable.children and -20 or 0, 0)

                if subInfoTable.icon then
                    if C_Texture.GetAtlasInfo(subInfoTable.icon) then
                        iconTexture:SetAtlas(subInfoTable.icon)
                    else
                        iconTexture:SetTexture(subInfoTable.icon)
                    end
                end

                iconTexture:SetSnapToPixelGrid(false)
                iconTexture:SetTexelSnappingBias(0)
                
                -- Calculate size
                local arrowWidth = subInfoTable.children and 20 or 0
                local padding = 32

                local buttonWidth = padding + arrowWidth + fontString:GetUnboundedStringWidth() + iconTexture:GetWidth()

                return buttonWidth, 20
            end
        )

        parentButton:SetScrollMode(20 * 24);

        if not subInfoTable.children then return end

        for index, childInfoTable in ipairs(subInfoTable.children) do
            local value = childInfoTable.value or index
            local childValues = CopyTable(values)
            
            table.insert(childValues, value)

            MakeSubmenu(button, childInfoTable, childValues, selectionIndices)
        end
    end

    function dropdown:SetValue(infoTableIndices)
        if not next(infoTable) then return end

        local values = {}
        local node = infoTable
        local newSelectionIndices = {}
        local text

        for _, index in ipairs(infoTableIndices) do
            if not node then break end
            if not node[index] then break end

            table.insert(values, node[index].value or index)

            text = node[index].text

            local icon = node[index].icon
            local iconString = icon and namespace:IconString(icon)

            if iconString then
                text = string.format("%s %s", iconString, text)
            end

            newSelectionIndices[node[index].selectionIndex] = true
            node = node[index].children
        end

        if not next(newSelectionIndices) then return end

        SetSelected(newSelectionIndices, values, text)

        dropdown:GenerateMenu()
    end

    -- Effectively the same as SetValue, except it keeps choosing index 1 until it reaches a leaf node
    function dropdown:SetDefaultValue()
		if not next(infoTable) then return end

        local values = {}
        local node = infoTable
        local newSelectionIndices = {}
        local text

        while node and node[1] do
            table.insert(values, node[1].value or 1)

            text = node[1].text

            local icon = node[1].icon
            local iconString = icon and namespace:IconString(icon)

            if iconString then
                text = string.format("%s %s", iconString, text)
            end

            newSelectionIndices[node[1].selectionIndex] = true
            node = node[1].children
        end

        if not next(newSelectionIndices) then return end

        SetSelected(newSelectionIndices, values, text)

        dropdown:GenerateMenu()
	end

    function dropdown:SetInfoTable(__infoTable)
        infoTable = __infoTable

        dropdown:SetupMenu(
            function(_, rootNode)
                i = 0
    
                for index, childInfoTable in ipairs(infoTable) do
                    local value = childInfoTable.value or index
    
                    MakeSubmenu(rootNode, childInfoTable, {value}, {})
                end
            end
        )
    end

    dropdown:SetInfoTable(_infoTable)

    if initialValue then
        dropdown:SetValue(initialValue)
	else
        dropdown:SetDefaultValue()
    end

    -- Skinning
    LUI:AddBorder(dropdown, 1, 0)
    dropdown:SetBorderColor(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b)

    dropdown.Background:Hide()
    dropdown.Arrow:Hide()

    -- Background
    dropdown.LRBackground = dropdown:CreateTexture(nil, "BACKGROUND")
    dropdown.LRBackground:SetAllPoints(dropdown)
    dropdown.LRBackground:SetColorTexture(BACKGROUND_COLOR.r, BACKGROUND_COLOR.g, BACKGROUND_COLOR.b, BACKGROUND_COLOR.a)
    dropdown.LRBackground:SetSnapToPixelGrid(false)
    dropdown.LRBackground:SetTexelSnappingBias(0)

    -- Arrow
    dropdown.LRArrowFrame = CreateFrame("Frame", nil, dropdown)
    dropdown.LRArrowFrame:SetSize(DEFAULT_HEIGHT, DEFAULT_HEIGHT)
    dropdown.LRArrowFrame:SetPoint("RIGHT")

    LUI:AddBorder(dropdown.LRArrowFrame)
    dropdown.LRArrowFrame:SetBorderColor(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b)

    dropdown:ClearHighlightTexture()
    dropdown:ClearDisabledTexture()

    dropdown:SetNormalTexture(ARROW_TEXTURE)
    dropdown:GetNormalTexture():SetAllPoints(dropdown.LRArrowFrame)

    dropdown:SetPushedTexture(ARROW_PUSHED_TEXTURE)
    dropdown:GetPushedTexture():SetAllPoints(dropdown.LRArrowFrame)

    dropdown:GetNormalTexture():SetAllPoints(dropdown.LRArrowFrame)

    LUI:AddHoverHighlight(dropdown, dropdown.LRArrowFrame)

    -- Text
    dropdown.Text:AdjustPointsOffset(0, -1)
    dropdown.Text:SetFontObject(LiquidFont13)
    dropdown.Text:SetDrawLayer("ARTWORK")
    
    dropdown.Text:ClearAllPoints()
    dropdown.Text:SetPoint("LEFT", dropdown, "LEFT", 6, 0)
    dropdown.Text:SetPoint("RIGHT", dropdown, "RIGHT", -DEFAULT_HEIGHT - 6, 0)
    dropdown.Text:SetJustifyH("RIGHT")

    return dropdown
end
