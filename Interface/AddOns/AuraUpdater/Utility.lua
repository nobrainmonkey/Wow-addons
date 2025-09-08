---@diagnostic disable: deprecated
local _, LUP = ...

local bytetoB64 = {
    [0]="a","b","c","d","e","f","g","h",
    "i","j","k","l","m","n","o","p",
    "q","r","s","t","u","v","w","x",
    "y","z","A","B","C","D","E","F",
    "G","H","I","J","K","L","M","N",
    "O","P","Q","R","S","T","U","V",
    "W","X","Y","Z","0","1","2","3",
    "4","5","6","7","8","9","(",")"
}

-- Generates a unique random 11 digit number in base64
-- Taken from WeakAuras
function LUP:GenerateUniqueID()
    local s = {}

    for _ = 1, 11 do
        tinsert(s, bytetoB64[math.random(0, 63)])
    end

    return table.concat(s)
end

-- Rounds a value, optionally to a certain number of decimals
function LUP:Round(value, decimals)
    if not decimals then decimals = 0 end
    
    local p = math.pow(10, decimals)
    
    value = value * p
    value = Round(value)
    value = value / p
    
    return value
end

-- Same as the game's SecondsToClock, except adds a single decimal to the seconds
function LUP:SecondsToClock(seconds, displayZeroHours)
	local units = ConvertSecondsToUnits(seconds)

	if units.hours > 0 or displayZeroHours then
		return format("%.2d:%.2d:%04.1f", units.hours, units.minutes, units.seconds + units.milliseconds)
	else
		return format("%.2d:%04.1f", units.minutes, units.seconds + units.milliseconds)
	end
end

-- Iterates group units
-- Usage: <for unit in LRP:IterateGroupMembers() do>
-- Taken from WeakAuras
function LUP:IterateGroupMembers(reversed, forceParty)
    local unit = (not forceParty and IsInRaid()) and "raid" or "party"
    local numGroupMembers = unit == "party" and GetNumSubgroupMembers() or GetNumGroupMembers()
    local i = reversed and numGroupMembers or (unit == "party" and 0 or 1)

    return function()
        local ret

        if i == 0 and unit == "party" then
            ret = "player"
        elseif i <= numGroupMembers and i > 0 then
            ret = unit .. i
        end

        i = i + (reversed and -1 or 1)

        return ret
    end
end

-- Takes an icon ID and returns an in-line icon string
function LUP:IconString(iconID)
    return CreateTextureMarkup(iconID, 64, 64, 0, 0, 5/64, 59/64, 5/64, 59/64)
end

function LUP:ClassColorName(unit)
    if not UnitExists(unit) then return unit end
    
    local name = UnitNameUnmodified(unit)
    local class = UnitClassBase(unit)

    local colorStr = RAID_CLASS_COLORS[class].colorStr
    
    return string.format("|c%s%s|r", colorStr, name)
end