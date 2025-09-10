local _, LUP = ...

local NAME_MARGIN = 8 -- Distance between left side of the row, and the display name
local ROW_HEIGHT = 32

local NAME_COLUMN_WIDTH = 135

local framePool = {}

local function Acquire()
    local index, frame = next(framePool)

    if not frame then return end

    framePool[index] = nil

    return frame
end

function LUP:CreateCheckGridRow(parent, unit, columnTitles)
    local shouldUpdateData = true

    local cells = {}

    local checkGridRow = Acquire()

    if not checkGridRow then
        checkGridRow = CreateFrame("Frame")

        checkGridRow:SetHeight(ROW_HEIGHT)

        -- Name
        checkGridRow.displayName = checkGridRow:CreateFontString()

        checkGridRow.displayName:SetPoint("LEFT", checkGridRow, "LEFT", NAME_MARGIN, 0)
        checkGridRow.displayName:SetFontObject(LiquidFont21)

        -- Releases (and hides) all cells present in this row
        -- Should be called when the number of cells changes, or when the row itself is released
        local function ReleaseAllCells()
            for index, cell in pairs(cells) do
                cell:Release()

                cells[index] = nil
            end
        end

        -- Sets the player name back to class colored (from grayed out)
        -- This is only called inside Rebuild, and the cells are updated inside of there after calling this
        local function SetOnline()
            checkGridRow.connected = true

            local classColor = RAID_CLASS_COLORS[checkGridRow.class]

            checkGridRow.displayName:SetTextColor(classColor.r, classColor.g, classColor.b)
        end

        -- Colors the display name gray, and sets the icon in every cell to a gray questionmark
        -- Data for the unit is set to an empty table
        -- We do not save the data for this unit, since we can't guarantee it'll stay the same through the logout
        -- This is only called inside of Rebuild, so we do not need to call Rebuild after calling this
        local function SetOffline()
            checkGridRow.connected = false
            checkGridRow.data = {}
            checkGridRow.okCount = 0
            checkGridRow.hasData = false

            checkGridRow.displayName:SetTextColor(0.6, 0.6, 0.6)

            for _, cell in pairs(cells) do
                cell:SetQuestionMarkDesaturated()
                cell:SetTooltip("Player is offline")
            end
        end

        -- Creates the appropriate number of cells for this row, according to the column titles (based on the header)
        -- The cellArray is an array of header titles (identifiers), ordered from left to right
        function checkGridRow:SetCells(_columnTitles)
            ReleaseAllCells()

            -- Create new cells
            for _, identifier in ipairs(_columnTitles) do
                local cell = LUP:CreateCheckGridCell(checkGridRow)

                cell.identifier = identifier
                
                table.insert(cells, cell)
            end

            shouldUpdateData = true
        end

        -- Positions the cells horizontally
        -- These offsets are provided by the CheckGridRowHeader, since their spacing depends on the header titles
        function checkGridRow:SetCellOffsets(offsets)
            -- Position cells
            for index, cell in ipairs(cells) do
                cell:SetPoint("CENTER", checkGridRow, "LEFT", NAME_COLUMN_WIDTH + (offsets[index] or 0), 0)
            end
        end

        -- Updates the name of the unit that this row is for
        -- Should be called whenever the unit's nickname changes
        function checkGridRow:SetDisplayName(name)
            if not name then
                name = AuraUpdater:GetNickname(checkGridRow.unit) or UnitNameUnmodified(checkGridRow.unit)
            end

            checkGridRow.name = name
            checkGridRow.displayName:SetText(name)
        end

        -- Updates the values used for sorting rows (hasData, okCount, totalValue)
        local function UpdateSortValues()
            -- Whether this row shows anything but questionmarks
            checkGridRow.hasData = false

            for _, cell in pairs(cells) do
                if cell.hasData then
                    checkGridRow.hasData = true

                    break
                end
            end

            -- Number of green checkmarks in this row
            checkGridRow.okCount = 0

            for _, cell in pairs(cells) do
                if cell.OK then
                    checkGridRow.okCount = checkGridRow.okCount + 1
                end
            end

            -- Cumulative value of all cells that display a number
            checkGridRow.totalValue = 0

            for _, cell in pairs(cells) do
                checkGridRow.totalValue = checkGridRow.totalValue + cell.value
            end
        end

        -- Updates the data for this unit
        -- Data is formatted as follows:
        -- data = {
        --     ["header 1"] = {
        --         value = <bool/number>,
        --         tooltip = <string (optional)>
        --     },
        --     ["header 2"] = {
        --         value = <bool/number>,
        --         tooltip = <string (optional)>
        --     },
        --     etc.
        -- }
        -- Value can either be a bool (in which case a check or cross is displayed), or a number (in which case the number is displayed)
        function checkGridRow:SetData(data)
            if not data then data = {} end
            
            checkGridRow.data = data

            shouldUpdateData = true
        end

        -- Updates the connection status of the unit
        -- Updates every cell (only if the data for them actually changed
        -- This function does NOT update the nickname of the unit, this should be done separately through SetDisplayName()
        function checkGridRow:Rebuild()
            if not UnitExists(checkGridRow.unit) then return end

            -- If the unit's connection status changed, reflect it
            local isConnected = UnitIsConnected(checkGridRow.unit)

            if isConnected ~= checkGridRow.connected then
                if isConnected then
                    SetOnline()

                    shouldUpdateData = true -- To make sure the gray questionmarks are updated to yellow ones
                else
                    -- If the unit is offline, display them as such and invalidate all their data
                    -- We do not save any data, since we cannot guarantee they'll still be up to date when they come back online
                    SetOffline()

                    shouldUpdateData = false

                    return
                end
            end

            if not shouldUpdateData then return end

            for _, cell in pairs(cells) do
                local identifier = cell.identifier
                local data = checkGridRow.data[identifier]

                if data then
                    local value = data.value
                    local tooltip = data.tooltip

                    if type(value) == "boolean" then
                        if value then
                            cell:SetCheck()
                        else
                            cell:SetCross()
                        end
                    elseif type(value) == "number" then
                        if value == 0 then
                            cell:SetCheck()
                        else
                            cell:SetCount(value)
                        end
                    end

                    cell:SetTooltip(tooltip)
                else
                    cell:SetQuestionMark()
                    cell:SetTooltip("No data received")
                end
            end

            UpdateSortValues()

            shouldUpdateData = false
        end

        function checkGridRow:Release()
            ReleaseAllCells()

            checkGridRow:Hide()

            table.insert(framePool, checkGridRow)
        end
    end

    checkGridRow.data = {}
    checkGridRow.unit = GetUnitName(unit, true) -- Save name of the unit, since it'll stay consistent (unlike raid1, party1, etc.)
    checkGridRow.GUID = UnitGUID(unit)
    checkGridRow.class = UnitClassBase(unit)
    checkGridRow.name = nil
    checkGridRow.connected = nil

    -- These are used for sorting
    checkGridRow.okCount = 0 -- Number of green checkmarks in this row
    checkGridRow.hasData = false -- False if (and only if) this row exclusively shows questionmarks
    checkGridRow.totalValue = 0 -- The value (i.e. if a number is shown) of all cells combined

    checkGridRow:SetDisplayName()
    checkGridRow:SetCells(columnTitles)

    checkGridRow:Rebuild()
    checkGridRow:SetParent(parent)
    checkGridRow:Show()

    return checkGridRow
end