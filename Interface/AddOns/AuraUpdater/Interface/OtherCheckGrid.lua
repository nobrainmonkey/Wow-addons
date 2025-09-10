local _, LUP = ...

local TOOLTIP_NAME_COLOR = "62f2f5"
local guidToVersionsTable = {}

-- Displays some miscellaneous checks, such as whether MRT notes are synced, RCLC versions, etc.
function LUP:CreateOtherCheckGrid(parent)
    local checkGrid = LUP:CreateCheckGrid(parent)

    -- Set the column titles
    checkGrid:SetTitles(
        {
            "MRT note",
            "Ignore list",
            "RCLC"
        }
    )

    -- Takes in a versions table, and returns a formatted table that the check grid can interpret
    local function FormatVersionsTable(versionsTable)
        local data = {}

        -- MRT note
        local mrtNoteHash = versionsTable.mrtNoteHash

        if mrtNoteHash then
            local playerMRTNoteHash = LUP:GetPlayerVersionsTable().mrtNoteHash

            if playerMRTNoteHash == mrtNoteHash then
                data["MRT note"] = {
                    value = true,
                    tooltip = string.format("|cff%sMRT|r note is the same as yours", TOOLTIP_NAME_COLOR)
                }
            else
                data["MRT note"] = {
                    value = false,
                    tooltip = string.format("|cff%sMRT|r note is |cff%snot|r the same as yours", TOOLTIP_NAME_COLOR, LUP.gs.visual.colorStrings.red)
                }
            end
        end

        -- RCLC
        if versionsTable.RCLC then
            local highestSeenRCLCVersion = LUP:GetHighestSeenRCLCVersion()
            local upToDate = LUP:CompareRCLCVersions(versionsTable.RCLC, highestSeenRCLCVersion) < 1

            if upToDate then
                data["RCLC"] = {
                    value = true,
                    tooltip = string.format("|cff%sRCLC|r is up to date", TOOLTIP_NAME_COLOR)
                }
            else
                data["RCLC"] = {
                    value = false,
                    tooltip = string.format("|cff%sRCLC|r is |cff%snot|r up to date", TOOLTIP_NAME_COLOR, LUP.gs.visual.colorStrings.red)
                }
            end
        end

        -- Ignores
        local ignores = versionsTable.ignores

        if ignores and next(ignores) then
            local ignoredPlayers = ""

            for _, ignoredPlayer in ipairs(ignores) do
                ignoredPlayers = string.format("%s|n%s", ignoredPlayers, LUP:ClassColorName(ignoredPlayer))
            end

            data["Ignore list"] = {
                value = false,
                tooltip = string.format("Players on ignore:%s", ignoredPlayers)
            }
        else
            data["Ignore list"] = {
                value = true,
                tooltip = "No group members on ignore"
            }
        end

        return data
    end

    -- This receives the versions table (exactly as broadcast) from a unit, and transforms it such that the grid can display it
    -- This function does not check if the versionsTable for this unit actually changed
    function checkGrid:UpdateVersionsTableForUnit(unit, versionsTable)
        -- Save the versionsTable so that we can reference it in FullRebuild
        local GUID = UnitGUID(unit)

        guidToVersionsTable[GUID] = versionsTable

        -- Update data
        local data = FormatVersionsTable(versionsTable)

        checkGrid:UpdateDataForUnit(unit, data)
        checkGrid:PositionRows()
    end

    -- Fully rebuilds every row in the grid, then re-positions them
    -- This typically happens whenever a new highest addon/aura version is seen
    -- This is also done whenever the MRT note hash changes, since that impacts every row
    function checkGrid:FullRebuild()
        for GUID, versionsTable in pairs(guidToVersionsTable) do
            if checkGrid:ContainsGUID(GUID) then
                local data = FormatVersionsTable(versionsTable)

                checkGrid:UpdateDataForGUID(GUID, data)
            else
                guidToVersionsTable[GUID] = nil
            end
        end

        checkGrid:PositionRows()
    end

    return checkGrid
end