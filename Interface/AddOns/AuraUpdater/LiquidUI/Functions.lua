local _, namespace = ...

local LUI = namespace.LiquidUI

-- Adds a 1 pixel border to a frame
function LUI:AddBorder(parent, thickness, horizontalOffset, verticalOffset)
    if not thickness then thickness = 1 end
    if not horizontalOffset then horizontalOffset = 0 end
    if not verticalOffset then verticalOffset = 0 end
    
    parent.border = {
        top = parent:CreateTexture(nil, "OVERLAY"),
        bottom = parent:CreateTexture(nil, "OVERLAY"),
        left = parent:CreateTexture(nil, "OVERLAY"),
        right = parent:CreateTexture(nil, "OVERLAY"),
    }

    parent.border.top:SetHeight(thickness)
    parent.border.top:SetPoint("TOPLEFT", parent, "TOPLEFT", -horizontalOffset, verticalOffset)
    parent.border.top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", horizontalOffset, verticalOffset)
    parent.border.top:SetSnapToPixelGrid(false)
    parent.border.top:SetTexelSnappingBias(0)

    parent.border.bottom:SetHeight(thickness)
    parent.border.bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", -horizontalOffset, -verticalOffset)
    parent.border.bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", horizontalOffset, -verticalOffset)
    parent.border.bottom:SetSnapToPixelGrid(false)
    parent.border.bottom:SetTexelSnappingBias(0)

    parent.border.left:SetWidth(thickness)
    parent.border.left:SetPoint("TOPLEFT", parent, "TOPLEFT", -horizontalOffset, verticalOffset)
    parent.border.left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", -horizontalOffset, -verticalOffset)
    parent.border.left:SetSnapToPixelGrid(false)
    parent.border.left:SetTexelSnappingBias(0)

    parent.border.right:SetWidth(thickness)
    parent.border.right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", horizontalOffset, verticalOffset)
    parent.border.right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", horizontalOffset, -verticalOffset)
    parent.border.right:SetSnapToPixelGrid(false)
    parent.border.right:SetTexelSnappingBias(0)

    function parent:SetBorderColor(r, g, b)
        for _, tex in pairs(parent.border) do
            tex:SetColorTexture(r, g, b)
        end
    end

    function parent:ShowBorder()
        for _, tex in pairs(parent.border) do
            tex:Show()
        end
    end

    function parent:HideBorder()
        for _, tex in pairs(parent.border) do
            tex:Hide()
        end
    end

    function parent:SetBorderShown(shown)
        if shown then
            parent:ShowBorder()
        else
            parent:HideBorder()
        end
    end

    parent:SetBorderColor(0, 0, 0)
end

-- Adds a highlight to a frame, displayed when the cursor hovers over it
-- If an alt frame is provided, the highlight will show on the alt frame when the cursor is hovered over the main frame
function LUI:AddHoverHighlight(frame, altFrame, width, r, g, b, a)
    if not altFrame then altFrame = frame end

    if not frame.highlight then
        frame.highlight = {
            top = frame:CreateTexture(nil, "HIGHLIGHT"),
            left = frame:CreateTexture(nil, "HIGHLIGHT"),
            bottom = frame:CreateTexture(nil, "HIGHLIGHT"),
            right = frame:CreateTexture(nil, "HIGHLIGHT")
        }
        
        frame.highlight.top:SetPoint("TOPLEFT", altFrame, "TOPLEFT", 1, -1)
        frame.highlight.top:SetPoint("TOPRIGHT", altFrame, "TOPRIGHT", -1, -1)

        frame.highlight.bottom:SetPoint("BOTTOMLEFT", altFrame, "BOTTOMLEFT", 1, 1)
        frame.highlight.bottom:SetPoint("BOTTOMRIGHT", altFrame, "BOTTOMRIGHT", -1, 1)
        
        frame.highlight.left:SetPoint("TOPLEFT", frame.highlight.top, "BOTTOMLEFT")
        frame.highlight.left:SetPoint("BOTTOMLEFT", frame.highlight.bottom, "TOPLEFT")

        frame.highlight.right:SetPoint("TOPRIGHT", frame.highlight.top, "BOTTOMRIGHT")
        frame.highlight.right:SetPoint("BOTTOMRIGHT", frame.highlight.bottom, "TOPRIGHT")
    end

    for _, tex in pairs(frame.highlight) do
        tex:SetColorTexture(r or (56/255), g or (119/255), b or (245/255), a or 0.6)
        tex:SetHeight(width or 1)
        tex:SetSnapToPixelGrid(false)
        tex:SetTexelSnappingBias(0)
    end
end

-- Adds a tooltip to a frame
-- Can be called repeatedly to change the tooltip
function LUI:AddTooltip(frame, tooltipText, secondaryTooltipText) 
    if not tooltipText then tooltipText = "" end

    frame.secondaryTooltipText = secondaryTooltipText -- Used for stuff like warnings/additional info that shouldn't change the main tooltip text

    -- If this frame already has a tooltip applied to it, simply change the tooltip text
    if frame.tooltipText then
        frame.tooltipText = tooltipText
    else
        frame.tooltipText = tooltipText

        -- The tooltip should be handled in a hook, in case the OnEnter/OnLeave script changes later on
        -- If there is no OnEnter/OnLeave script present, add an empty one
        if not frame:HasScript("OnEnter") then
            frame:SetScript("OnEnter", function() end)
        end

        if not frame:HasScript("OnLeave") then
            frame:SetScript("OnLeave", function() end)
        end

        frame:HookScript(
            "OnEnter",
            function()
                if not frame.tooltipText or frame.tooltipText == "" then return end
                
                LUI.Tooltip:Hide()
                LUI.Tooltip:SetOwner(frame, "ANCHOR_RIGHT")

                if frame.secondaryTooltipText and frame.secondaryTooltipText ~= "" then
                    LUI.Tooltip:SetText(string.format("%s|n|n%s", frame.tooltipText, frame.secondaryTooltipText), 0.9, 0.9, 0.9, 1, true)
                else
                    LUI.Tooltip:SetText(frame.tooltipText, 0.9, 0.9, 0.9, 1, true)
                end

                LUI.Tooltip:Show()
            end
        )

        frame:HookScript(
            "OnLeave",
            function()
                LUI.Tooltip:Hide()
            end
        )
    end
end

-- Refreshes the tooltip that is currently showing
-- Useful mainly for when editbox vlaues in reminder config are changed, and tooltip warnings are added/hidden as a result
function LUI:RefreshTooltip()
    if LUI.Tooltip:IsVisible() then
        local frame = LUI.Tooltip:GetOwner()

        if frame and frame.tooltipText then
            if frame.secondaryTooltipText and frame.secondaryTooltipText ~= "" then
                LUI.Tooltip:SetText(string.format("%s|n|n%s", frame.tooltipText, frame.secondaryTooltipText), 0.9, 0.9, 0.9, 1, true)
            else
                LUI.Tooltip:SetText(frame.tooltipText, 0.9, 0.9, 0.9, 1, true)
            end

            LUI.Tooltip:Show()
        else
            LUI.Tooltip:Hide()
        end
    end
end

-- Save the size/position of a frame in SavedVariables, keyed by some name
function LUI:SaveSize(frame, name)
    if not name then return end

    if not LUI.frameSettings[name] then
        LUI.frameSettings[name] = {}
    end

    local width, height = frame:GetSize()

    LUI.frameSettings[name].width = width
    LUI.frameSettings[name].height = height
end

function LUI:SavePosition(frame, name)
    if not name then return end

    if not LUI.frameSettings[name] then
        LUI.frameSettings[name] = {}
    end

    LUI.frameSettings[name].points = {}

    local numPoints = frame:GetNumPoints()

    for i = 1, numPoints do
        local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint(i)

        if relativeTo == nil or relativeTo == UIParent then -- Only consider points relative to UIParent
            table.insert(
                LUI.frameSettings[name].points,
                {
                    point = point,
                    relativePoint = relativePoint,
                    offsetX = offsetX,
                    offsetY = offsetY
                }
            )
        end
    end
end

-- Restore and apply saved size/position to a frame, keyed by some name
-- Returns whether this was successful, so the user can apply some default values if not
function LUI:RestoreSize(frame, name)
    if not name then return false end

    local settings = LUI.frameSettings[name]

    if not settings then return false end
    if not settings.width then return false end
    if not settings.height then return false end

    frame:SetSize(settings.width, settings.height)

    return true
end

function LUI:RestorePosition(frame, name)
    if not name then return false end

    local points = name and LUI.frameSettings[name] and LUI.frameSettings[name].points

    if not points then return false end

    for _, pointInfo in ipairs(points) do
        frame:SetPoint(pointInfo.point, UIParent, pointInfo.relativePoint, pointInfo.offsetX, pointInfo.offsetY)
    end

    return true
end