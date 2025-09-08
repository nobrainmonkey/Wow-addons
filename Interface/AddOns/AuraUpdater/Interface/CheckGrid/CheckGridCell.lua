local _, LUP = ...

local CELL_SIZE = 24 -- Size of the icons in the cells

local QUESTION_MARK_ATLAS = "QuestTurnin"
local CHECK_ATLAS = "common-icon-checkmark"
local CROSS_ATLAS = "common-icon-redx"

local framePool = {}

local function Acquire()
    local index, frame = next(framePool)

    if not frame then return end

    framePool[index] = nil

    return frame
end

function LUP:CreateCheckGridCell(parent)
    local checkGridCell = Acquire()

    if not checkGridCell then
        checkGridCell = CreateFrame("Frame")

        checkGridCell:SetSize(CELL_SIZE, CELL_SIZE)

        -- Texture
        checkGridCell.tex = checkGridCell:CreateTexture(nil, "BACKGROUND")

        checkGridCell.tex:SetAllPoints()
        checkGridCell.tex:SetSnapToPixelGrid(false)
        checkGridCell.tex:SetTexelSnappingBias(0)

        -- Count
        checkGridCell.count = checkGridCell:CreateFontString()

        checkGridCell.count:SetPoint("CENTER")
        checkGridCell.count:SetFontObject(LiquidFont21)

        function checkGridCell:SetQuestionMark()
            checkGridCell.OK = false
            checkGridCell.hasData = false
            checkGridCell.value = 0

            checkGridCell.count:Hide()
            checkGridCell.tex:Show()

            checkGridCell.tex:SetAtlas(QUESTION_MARK_ATLAS)
            checkGridCell.tex:SetDesaturated(false)
        end

        function checkGridCell:SetQuestionMarkDesaturated()
            checkGridCell.OK = false
            checkGridCell.hasData = false
            checkGridCell.value = 0

            checkGridCell.count:Hide()
            checkGridCell.tex:Show()

            checkGridCell.tex:SetAtlas(QUESTION_MARK_ATLAS)
            checkGridCell.tex:SetDesaturated(true)
        end

        function checkGridCell:SetCheck()
            checkGridCell.OK = true
            checkGridCell.hasData = true
            checkGridCell.value = 0

            checkGridCell.count:Hide()
            checkGridCell.tex:Show()

            checkGridCell.tex:SetAtlas(CHECK_ATLAS)
            checkGridCell.tex:SetDesaturated(false)
        end

        function checkGridCell:SetCross()
            checkGridCell.OK = false
            checkGridCell.hasData = true
            checkGridCell.value = 0

            checkGridCell.count:Hide()
            checkGridCell.tex:Show()

            checkGridCell.tex:SetAtlas(CROSS_ATLAS)
            checkGridCell.tex:SetDesaturated(false)
        end

        function checkGridCell:SetCount(count)
            checkGridCell.OK = false
            checkGridCell.hasData = true
            checkGridCell.value = count

            checkGridCell.count:Show()
            checkGridCell.tex:Hide()

            checkGridCell.count:SetFormattedText("|cff%s%d|r", LUP.gs.visual.colorStrings.red, count)
        end

        function checkGridCell:SetTooltip(tooltip)
            LUP.LiquidUI:AddTooltip(checkGridCell, tooltip)
        end

        function checkGridCell:Release()
            checkGridCell:Hide()

            table.insert(framePool, checkGridCell)
        end
    end

    checkGridCell.identifier = nil -- Equal to the title of the column that this cell exist in

    -- These two fields are used for sorting the rows
    checkGridCell.OK = false -- True if (and only if) the cell shows a checkmark
    checkGridCell.hasData = false -- True if (and only if) the cell does NOT show a questionmark
    checkGridCell.value = 0 -- Equal to count if the cell shows a number, otherwise 0

    checkGridCell:ClearAllPoints()
    checkGridCell:SetParent(parent)
    checkGridCell:Show()
    
    return checkGridCell
end