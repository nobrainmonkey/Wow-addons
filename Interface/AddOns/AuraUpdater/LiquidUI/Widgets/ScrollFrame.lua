local _, namespace = ...

local LUI = namespace.LiquidUI

local BORDER_COLOR = LUI.settings.BORDER_COLOR

local SPACING = 6 -- Spacing between scroll frame and scroll bar
local PADDING_RIGHT = 8

function namespace:CreateScrollFrame(parent)
    local parentFrame = CreateFrame("Frame", nil, parent)

    -- Scroll bar
    parentFrame.scrollBar = CreateFrame("EventFrame", nil, parentFrame, "MinimalScrollBar")
    parentFrame.scrollBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -PADDING_RIGHT, 0)
    parentFrame.scrollBar:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -PADDING_RIGHT, 0)

    -- Scroll frame
    parentFrame.scrollFrame = CreateFrame("Frame", nil, parentFrame, "WowScrollBox")
    parentFrame.scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 1, -1)
    parentFrame.scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame.scrollBar, "BOTTOMLEFT", -SPACING - 2, 1)

    parentFrame.scrollFrame.wheelPanScalar = 1 -- By default this is 2, making scroll wheel scroll twice as fast as clicking the arrows

    -- Custom border implementation, since the generic one sets the frame we apply a border to as the parent
    -- Since we want the border to be offset by 1, this would hide it as the scroll frame clips its children
    local border = {
        top = parentFrame:CreateTexture(nil, "OVERLAY"),
        bottom = parentFrame:CreateTexture(nil, "OVERLAY"),
        left = parentFrame:CreateTexture(nil, "OVERLAY"),
        right = parentFrame:CreateTexture(nil, "OVERLAY"),
    }

    border.top:SetHeight(1)
    border.top:SetPoint("TOPLEFT", parentFrame.scrollFrame, "TOPLEFT", -1, 1)
    border.top:SetPoint("TOPRIGHT", parentFrame.scrollFrame, "TOPRIGHT", 1, 1)
    border.top:SetSnapToPixelGrid(false)
    border.top:SetTexelSnappingBias(0)
    border.top:SetColorTexture(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b)

    border.bottom:SetHeight(1)
    border.bottom:SetPoint("BOTTOMLEFT", parentFrame.scrollFrame, "BOTTOMLEFT", -1, -1)
    border.bottom:SetPoint("BOTTOMRIGHT", parentFrame.scrollFrame, "BOTTOMRIGHT", 1, -1)
    border.bottom:SetSnapToPixelGrid(false)
    border.bottom:SetTexelSnappingBias(0)
    border.bottom:SetColorTexture(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b)

    border.left:SetWidth(1)
    border.left:SetPoint("TOPLEFT", parentFrame.scrollFrame, "TOPLEFT", -1, 1)
    border.left:SetPoint("BOTTOMLEFT", parentFrame.scrollFrame, "BOTTOMLEFT", -1, -1)
    border.left:SetSnapToPixelGrid(false)
    border.left:SetTexelSnappingBias(0)
    border.left:SetColorTexture(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b)

    border.right:SetWidth(1)
    border.right:SetPoint("TOPRIGHT", parentFrame.scrollFrame, "TOPRIGHT", 1, 1)
    border.right:SetPoint("BOTTOMRIGHT", parentFrame.scrollFrame, "BOTTOMRIGHT", 1, -1)
    border.right:SetSnapToPixelGrid(false)
    border.right:SetTexelSnappingBias(0)
    border.right:SetColorTexture(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b)

    parentFrame.scrollFrame.border = border

    -- Content frame
    -- The width of this frame is always kept the same as that of the scroll frame
    -- Whenever the height of this frame changes (through SetHeight()), remember to call FullUpdate()
    parentFrame.contentFrame = CreateFrame("Frame", nil, parentFrame.scrollFrame)
    parentFrame.contentFrame.scrollable = true

    -- View
    local view = CreateScrollBoxLinearView()

    -- Init
    ScrollUtil.InitScrollBoxWithScrollBar(parentFrame.scrollFrame, parentFrame.scrollBar, view)

    function parentFrame:FullUpdate()
        parentFrame.scrollFrame:FullUpdate()
    end

    -- Sets the distance (in pixels) that a single scroll should cover
    -- A "scroll" is either a tick of the scroll wheel, or a click of the arrow
    function parentFrame:SetScrollDistance(distance)
        parentFrame.scrollFrame:SetPanExtent(distance)
    end

    return parentFrame
end