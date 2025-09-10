local _, LUP = ...

local TITLE_SPACING = 12

function LUP:CreateCheckGridHeader(parent)
    local minimumSpacing = 0 -- Minimum spacing between any two columns, based on the width of their titles
    local minimumWidth = 0 -- Minimum width the header should be to fit all titles
    local columnOffsets = {}

    local titles = {}

    local checkGridHeader = CreateFrame("Frame", nil, parent)

    -- Updates the minimum spacing required between columns (i.e. icons)
    -- This is done based on the width of each title
    local function UpdateMinimumSpacing()
        minimumSpacing = 0

        for index = 1, #titles - 1 do
            local left = titles[index]
            local right = titles[index + 1]
            local spacing = 0.5 * (left:GetWidth() + right:GetWidth()) + TITLE_SPACING

            minimumSpacing = math.max(minimumSpacing, spacing)
        end
    end

    -- Updates the minimum width of the combined titles
    -- This is used for determining how large the window should be to not make titles overlap
    local function UpdateMinimumWidth()
        if #titles == 1 then
            return titles[1]:GetWidth()
        end

        if #titles == 2 then
            return titles[1]:GetWidth() + titles[#titles]:GetWidth() + TITLE_SPACING
        end

        minimumWidth =  0.5 * (titles[1]:GetWidth() + titles[#titles]:GetWidth()) + (#titles - 1) * minimumSpacing
    end

    -- Calculates the horizontal position of each column relative to the left of the header
    -- These offsets can be passed to rows to position their cells correctly
    local function UpdateColumnOffsets()
        columnOffsets = {}

        if #titles == 0 then return end

        -- Left-most column is aligned left, and made as small as possible
        local headerWidth = checkGridHeader:GetWidth()

        columnOffsets[1] = 0.5 * titles[1]:GetWidth()

        if #titles == 1 then return end

        -- Right-most column is aligned right, and made as small as possible
        columnOffsets[#titles] = headerWidth - 0.5 * titles[#titles]:GetWidth()

        if #titles == 2 then return end

        -- All other columns are spaced equally between the left and right-most ones
        local columnSpacing = (headerWidth - 0.5 * (titles[1]:GetWidth() + titles[#titles]:GetWidth())) / (#titles - 1)

        for index = 2, #titles - 1 do
            columnOffsets[index] = columnOffsets[1] + (index - 1) * columnSpacing
        end
    end

    -- Positions the titles based on the offsets calculated in UpdateColumnOffsets
    function checkGridHeader:PositionTitles()
        UpdateColumnOffsets()

        for index, title in ipairs(titles) do
            local offset = columnOffsets[index]

            title:SetPoint("BOTTOM", checkGridHeader, "BOTTOMLEFT", offset, 0)
        end
    end

    -- Expects an array of titles
    function checkGridHeader:SetTitles(newTitles)
        -- Release all existing titles
        for index, titleFrame in pairs(titles) do
            titleFrame:Release()

            titles[index] = nil
        end

        for _, title in ipairs(newTitles) do
            local checkGridTitle = LUP:CreateCheckGridTitle(checkGridHeader)
            
            checkGridTitle:SetTitle(title)

            table.insert(titles, checkGridTitle)
        end

        -- Update minimum width
        minimumWidth = 0

        for _, titleFrame in pairs(titles) do
            minimumWidth = minimumWidth + titleFrame:GetWidth()
        end

        UpdateMinimumSpacing()
        UpdateMinimumWidth()

        checkGridHeader:PositionTitles()
    end

    -- Returns the minimum width the header should have before the titles start overlapping
    function checkGridHeader:GetMinimumWidth()
        return minimumWidth
    end

    -- Returns the offset (relative to the left of the scroll frame) of each column's center
    -- This is used to position CheckGridCells correctly
    -- The left-most and right-most column are usually smaller than the rest, since we don't want too much blank space on either side
    -- It's good to remember that column offsets are calculated only when PositionTitles() is called
    -- Meaning if you want to use these offsets to position cells (in rows), they should be queried only after positioning the titles
    function checkGridHeader:GetColumnOffsets()
        return columnOffsets
    end

    return checkGridHeader
end