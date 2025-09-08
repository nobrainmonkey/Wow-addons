local _, LUP = ...

local ADDON_NAME = "Cell"

-- Updates the nicknames in Cell's own nickname list
-- May want to change this in the future to not actually override the Cell nicknames, since those are permanent
LUP.nicknameInitFunctions[ADDON_NAME] = function()
    if not CellDB then return end
    if not CellDB.nicknames then return end

    -- Budget solution to disable AuraUpdater Cell nicknames while they are enabled inside Cell itself
    if LiquidUpdaterSaved.settings.cellNicknames == false then return end

    -- Insert nicknames
    for name, nickname in pairs(LiquidUpdaterSaved.nicknames) do
        local cellFormat = string.format("%s:%s", name, nickname)

        -- Insert nickname if it doesn't already exist, and refresh unit frame if necessary
        if tInsertUnique(CellDB.nicknames.list, cellFormat) then
            Cell.Fire("UpdateNicknames", "list-update", name, nickname)
        end
    end
end

LUP.nicknameUpdateFunctions[ADDON_NAME] = function(_, realmIncludedName, oldNickname, nickname)
	if Cell and CellDB and CellDB.nicknames and LiquidUpdaterSaved.settings.cellNicknames ~= false then
        local oldEntry = oldNickname and string.format("%s:%s", realmIncludedName, oldNickname)
        local newEntry = nickname and string.format("%s:%s", realmIncludedName, nickname)

        local cellIndex -- Index in CellDB.nicknames.list of name:oldNickname (if any)

        if oldEntry then
            cellIndex = tIndexOf(CellDB.nicknames.list, oldEntry)
        end

        if cellIndex then -- Update existing nickname entry
            if newEntry then
                CellDB.nicknames.list[cellIndex] = newEntry
            else
                table.remove(CellDB.nicknames.list, cellIndex)
            end
        else -- Create new nickname entry
            table.insert(CellDB.nicknames.list, newEntry)
        end

        Cell.Fire("UpdateNicknames", "list-update", realmIncludedName, nickname)
    end
end