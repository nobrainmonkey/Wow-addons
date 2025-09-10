local _, LUP = ...

local TOOLTIP_NAME_COLOR = "98f8fa" -- Color of the addon/aura name in grid cell tooltips
local guidToVersionsTable = {}

-- Displays the addon/weakaura versions for all group members
function LUP:CreateAuraCheckGrid(parent)
    local checkGrid = LUP:CreateCheckGrid(parent)

    -- Set the column titles
    -- These are sorted alphabetically
    -- We want AuraUpdater (the addon version) to show first, which works out this way
    local titles = {"AuraUpdater"}

    for displayName in pairs(LiquidUpdaterSaved.WeakAuras) do
        table.insert(titles, displayName)
    end

    table.sort(titles)

    checkGrid:SetTitles(titles)

    local function GenerateTooltip(displayName, versions)
        if versions <= 0 then
            return string.format("|cff%s%s|r is up to date", TOOLTIP_NAME_COLOR, displayName)
        else
            return string.format(
                "|cff%s%s|r is |cff%s%d|r version(s) behind",
                TOOLTIP_NAME_COLOR,
                displayName,
                LUP.gs.visual.colorStrings.red,
                versions
            )
        end
    end

    -- Takes in a versions table, and returns a formatted table that the check grid can interpret
    local function FormatVersionsTable(versionsTable)
        local data = {}

        local highestSeenAddOnVersion = LUP:GetHighestSeenAddOnVersion()
        local highestSeenAuraVersions = LUP:GetHighestSeenAuraVersions()

        -- AddOn version
        local addOnValue = highestSeenAddOnVersion - (versionsTable.addOn or 0)
        local addOnTooltip = GenerateTooltip("AuraUpdater", addOnValue)

        data.AuraUpdater = {
            value = addOnValue,
            tooltip = addOnTooltip
        }

        -- Aura versions
        for displayName, version in pairs(versionsTable.auras) do
            local value = (highestSeenAuraVersions[displayName] or 0) - version
            local tooltip = GenerateTooltip(displayName, value)

            data[displayName] = {
                value = value,
                tooltip = tooltip
            }
        end

        return data
    end

    -- This receives the versions table (exactly as broadcast) from a unit, and transforms it such that the grid can display it
    -- This function does not check if the versionsTable for this unit actually changed (TODO somewhere else)
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