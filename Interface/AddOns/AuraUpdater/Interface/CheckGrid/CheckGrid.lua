local _, LUP = ...

local HEADER_HEIGHT = 24
local HEADER_MARGIN = 4 -- Space between the header and the scroll frame
local NAME_COLUMN_WIDTH = 135
local ROW_HEIGHT = 32

function LUP:CreateCheckGrid(parent)
    local columnTitles = {} -- Identifiers for each column, as set by SetTitles()
    local rows = {}

    local checkGrid = CreateFrame("Frame", nil, parent)

    -- Scroll frame
    local scrollFrame = LUP:CreateScrollFrame(checkGrid)

    scrollFrame:SetPoint("TOPLEFT", checkGrid, "TOPLEFT", 0, -HEADER_HEIGHT)
    scrollFrame:SetPoint("BOTTOMRIGHT", checkGrid, "BOTTOMRIGHT")
    scrollFrame:SetScrollDistance(ROW_HEIGHT)

    scrollFrame.scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -8, 16)
    scrollFrame.scrollFrame:SetPoint("BOTTOMRIGHT", scrollFrame.scrollBar, "BOTTOMLEFT", -10, -15)

    -- Header
    local header = LUP:CreateCheckGridHeader(checkGrid)

    header:SetHeight(HEADER_HEIGHT)
    header:SetPoint("BOTTOMLEFT", scrollFrame.scrollFrame, "TOPLEFT", NAME_COLUMN_WIDTH, HEADER_MARGIN)
    header:SetPoint("BOTTOMRIGHT", scrollFrame.scrollFrame, "TOPRIGHT", 0, HEADER_MARGIN)

    -- Used to sort the rows (i.e. their order in the rows array)
    -- May be overwritten using SetSortFunction()
    local function SortFunction(rowA, rowB)
        local connectedA = rowA.connected
        local connectedB = rowB.connected

        if connectedA ~= connectedB then
            return connectedA
        end

        local hasDataA = rowA.hasData
        local hasDataB = rowB.hasData

        if hasDataA ~= hasDataB then
            return hasDataA
        end

        local okCountA = rowA.okCount
        local okCountB = rowB.okCount

        if okCountA ~= okCountB then
            return okCountA < okCountB
        end

        local totalValueA = rowA.totalValue
        local totalValueB = rowB.totalValue

        if totalValueA ~= totalValueB then
            return totalValueA > totalValueB
        end

        local nameA = rowA.name
        local nameB = rowB.name

        if nameA ~= nameB then
            if not nameA then return false end
            if not nameB then return true end

            return nameA < nameB
        end

        return rowA.GUID < rowB.GUID
    end

    -- Overrides the row sort function
    function checkGrid:SetSortFunction(newSortFunction)
        SortFunction = newSortFunction

        checkGrid:PositionRows()
    end

    -- Positions (and sorts) the rows
    -- Should be called whenever a row is added/removed, when a player (dis)connects, or when nicknames of units change
    function checkGrid:PositionRows()
        if not checkGrid:IsVisible() then return end

        table.sort(rows, SortFunction)

        for i, row in ipairs(rows) do
            row:SetPoint("BOTTOMLEFT", scrollFrame.contentFrame, "TOPLEFT", 0, -i * ROW_HEIGHT)
            row:SetPoint("BOTTOMRIGHT", scrollFrame.contentFrame, "TOPRIGHT", 0, -i * ROW_HEIGHT)
        end
    end

    -- Positions the titles and cells based on the width of the check grid
    -- Should be called whenever the grid is resized
    local function PositionColumns()
        if not checkGrid:IsVisible() then return end

        header:PositionTitles()

        local offsets = header:GetColumnOffsets()

        for _, row in pairs(rows) do
            row:SetCellOffsets(offsets)
        end
    end

    local function GetRowByGUID(GUID)
        for _, row in pairs(rows) do
            if row.GUID == GUID then
                return row
            end
        end
    end

    -- Adds a new row for a unit
    -- This function does not check if a row for said unit already exists
    -- Make sure to call checkGrid:PositionRows after adding units!
    local function AddRowForUnit(unit)
        local offsets = header:GetColumnOffsets()
        local row = LUP:CreateCheckGridRow(scrollFrame.contentFrame, unit, columnTitles)

        row:SetCellOffsets(offsets)

        table.insert(rows, row)

        return row
    end

    -- Adds rows for group members that do not have one yet
    -- Typically called on GROUP_ROSTER_UPDATE
    local function AddRowsForNewUnits()
        local queue = false
        local shouldPosition = false
        local existingGUIDs = {}

        for _, row in pairs(rows) do
            existingGUIDs[row.GUID] = true
        end

        for unit in LUP:IterateGroupMembers() do
            -- If UnitName returns UNKNOWNOBJECT, the unit hasn't loaded into our world properly yet
            -- In that case, we don't add it yet, but queue another run of AddRowsForNewUnits
            local unitLoaded = UnitName(unit) ~= UNKNOWNOBJECT

            if unitLoaded then
                local GUID = UnitGUID(unit)

                if not existingGUIDs[GUID] then
                    AddRowForUnit(unit)

                    shouldPosition = true
                end
            else
                queue = true
            end
        end

        if shouldPosition then
            checkGrid:PositionRows()

            scrollFrame.contentFrame:SetHeight(#rows * ROW_HEIGHT)

            scrollFrame:FullUpdate()
        end

        if queue then
            C_Timer.After(1, AddRowsForNewUnits)
        end
    end

    -- Removes rows for units that are no longer in group
    -- Typically called on GROUP_ROSTER_UPDATE
    local function RemoveRowsForInvalidUnits()
        local shouldPosition = false

        -- Remove rows for units that do not exist anymore
        for index, row in ipairs_reverse(rows) do
            local unit = row.unit

            if not UnitExists(unit) then
                row:Release()

                table.remove(rows, index)

                shouldPosition = true
            end
        end

        if shouldPosition then
            scrollFrame.contentFrame:SetHeight(#rows * ROW_HEIGHT)

            checkGrid:PositionRows()

            scrollFrame:FullUpdate()
        end
    end

    -- Returns the minimum width that the full check grid should be
    -- This is used to clamp (lower bound) the size of the window
    function checkGrid:GetMinimumWidth()
        return NAME_COLUMN_WIDTH + header:GetMinimumWidth() + 16 -- 16 is to account for scroll bar width
    end

    -- Expects an array of column titles
    -- This function makes sure each row has a number of cells equal to the number of titles
    -- Each cell can be retrieved by calling on a row GetCellByIdentifier(title)
    function checkGrid:SetTitles(newTitles)
        columnTitles = newTitles

        header:SetTitles(columnTitles)

        for _, row in pairs(rows) do
            row:SetCells(columnTitles)
            row:Rebuild()
        end

        checkGrid:PositionRows()
        PositionColumns()

        LUP:UpdateWindowResizeBounds()
    end

    -- Should be called whenever the nickname for a unit changes
    -- This function is not very expensive, so there is no harm in calling it any time data for a unit is received
    function checkGrid:UpdateDisplayNameForUnit(unit, name)
        local GUID = UnitGUID(unit)
        local row = GetRowByGUID(GUID)

        if not row then return end

        row:SetDisplayName(name)

        checkGrid:PositionRows()
    end

    -- Updates the status of each of the cells for a unit, based on the data provided
    -- The rows are only rebuilt if data actually changed (this is checked inside the CheckGridRow)
    -- If data is updated for a unit that does not have a row yet, one is created
    -- This should generally never happen, but is mostly here as a fail safe
    -- This function does NOT position the rows after adding/changing
    function checkGrid:UpdateDataForUnit(unit, data)
        local GUID = UnitGUID(unit)

        if not GUID then return end

        local row = GetRowByGUID(GUID)

        -- If no row for this unit exists, create one
        if not row then
            row = AddRowForUnit(unit)

            scrollFrame.contentFrame:SetHeight(#rows * ROW_HEIGHT)
            scrollFrame:FullUpdate()
        end

        row:SetData(data)
        row:Rebuild()
    end

    -- Similar to UpdateDataForUnit
    -- This does NOT create a new row for GUIDs do not yet have one
    function checkGrid:UpdateDataForGUID(GUID, data)
        local row = GetRowByGUID(GUID)

        row:SetData(data)
        row:Rebuild()
    end

    -- Returns whether a row for some GUID exists
    function checkGrid:ContainsGUID(GUID)
        return GetRowByGUID(GUID) ~= nil
    end

    -- Position columns horizontally whenever the grid size changes
    -- We do this when the header size changes (instead of the grid), since the positioning is done based on the header titles
    -- If we SetScript on the grid itself, header:GetWidth() sometimes evaluates to 0 when called in PositionColumns
    header:SetScript("OnSizeChanged", PositionColumns)

    -- We do not update row/column positions while the check grid is hidden
    -- When it's shown, make sure it's updated
    checkGrid:SetScript(
        "OnShow",
        function()
            checkGrid:PositionRows()
            PositionColumns()
        end
    )

    checkGrid:RegisterEvent("GROUP_ROSTER_UPDATE")
    checkGrid:RegisterEvent("PLAYER_ENTERING_WORLD")
    checkGrid:RegisterEvent("UNIT_CONNECTION")

    checkGrid:SetScript(
        "OnEvent",
        function(_, event, ...)
            if event == "GROUP_ROSTER_UPDATE" then
                RemoveRowsForInvalidUnits()
                AddRowsForNewUnits()
            elseif event == "PLAYER_ENTERING_WORLD" then
                RemoveRowsForInvalidUnits()
                AddRowsForNewUnits()
            elseif event == "UNIT_CONNECTION" then
                local unit = ...
                local GUID = UnitGUID(unit)
                local row = GetRowByGUID(GUID)

                if not row then return end

                row:Rebuild()

                checkGrid:PositionRows()
            end
        end
    )

    return checkGrid
end