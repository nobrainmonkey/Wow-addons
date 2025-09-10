local _, LUP = ...

LUP.nicknameInitFunctions = {} -- AddOn name -> initialization function. Run when their respective addon loads.
LUP.nicknameUpdateFunctions = {} -- AddOn name -> update function. Run after a nickname updates through LUP:UpdateNicknameForUnit.

local nicknameToCharacterCache = {} -- For use in GetCharacterInGroup()

local presetNicknames = {
    ["Algo#2565"] = "Algo",
    ["Azortharion#2528"] = "Azor",
    ["Balanciz#2330"] = "Balanciz",
    ["Naemesis#2526"] = "Bart",
    ["Chaos#26157"] = "Chaos",
    ["c1nder#21466"] = "Cinder",
    ["EffyxWoW#2713"] = "Effy",
    ["Freddynqkken#2913"] = "Freddy",
    ["J3T#21747"] = "Fystin",
    ["botond#2484"] = "Hiero",
    ["Jhonz#2356"] = "Jon",
    ["Mithos#2752"] = "Kratos",
    ["Kantom#2289"] = "Mini",
    ["Mytheos#1649"] = "Mytheos",
    ["Sors#2676"] = "Nick",
    ["Nightwanta#2473"] = "Night",
    ["Saunderz#2405"] = "Olly",
    ["Ottojj#2715"] = "Otto",
    ["Rose#22507"] = "Rose",
    ["Ryler#1217"] = "Ryler",
    ["Drarrven#2327"] = "Soul",
    ["Tínie#2208"] = "Tinie",
    ["Vespion#2971"] = "Vespion",
    ["Wrexad#21129"] = "Wrexa",
}

-- Pescorus players have preset nicknames associated with their BattleTag
-- This returns their preset nickname
function LUP:GetPresetNickname()
    local _, battleTag = BNGetInfo()
    
    return battleTag and presetNicknames[battleTag]
end

-- Returns Name-Realm for a unit
-- Nicknames are always stored using Name-Realm as indices
local function RealmIncludedName(unit)
    local name, realm = UnitNameUnmodified(unit)

    if not realm then
        realm = GetNormalizedRealmName()
    end

    if not realm then return end -- Called before PLAYER_LOGIN

    return string.format("%s-%s", name, realm)
end

function LUP:UpdateNicknameForUnit(unit, nickname)
    -- Nicknames are always stored using Name-Realm as indices (even for your own characters)
    local realmIncludedName = RealmIncludedName(unit)

    if not realmIncludedName then return end

    -- Nicknames should not have leading or trailing spaces (this shouldn't be possible if set through AuraUpdater, but still)
    -- If a nickname is an empty string, set it to nil so we remove the entry from the database entirely
    nickname = nickname and strtrim(nickname)

    if nickname == "" then nickname = nil end

    -- Update nicknameToCharacterCache for use in GetCharacterInGroup()
    -- This has the potential to nil others' nicknames if two players share the same nickname, but take care of that inside GetCharacterInGroup()
    local oldNickname = LiquidUpdaterSaved.nicknames[realmIncludedName]

    if oldNickname then
        nicknameToCharacterCache[oldNickname] = nil
    end

    if nickname then
        nicknameToCharacterCache[nickname] = unit
    end

    LiquidUpdaterSaved.nicknames[realmIncludedName] = nickname

	-- Update nicknames for installed addons
	for _, updateFunction in pairs(LUP.nicknameUpdateFunctions) do
		updateFunction(unit, realmIncludedName, oldNickname, nickname)
	end
end

function AuraUpdater:GetNickname(unit)
    if not unit then return end
    if not UnitExists(unit) then return end

    if not UnitIsPlayer(unit) then
        return GetUnitName(unit)
    end

    local realmIncludedName = RealmIncludedName(unit)
    local nickname = LiquidUpdaterSaved.nicknames[realmIncludedName or ""]

    if not nickname then
        nickname = UnitNameUnmodified(unit)
    end

    local formatString = "%s"
    local classFileName = UnitClassBase(unit)

    if classFileName then
        formatString = string.format("|c%s%%s|r", RAID_CLASS_COLORS[classFileName].colorStr)
    end

    return nickname, formatString
end

-- For a given nickname, returns the character in the group that is associated with it
-- This could either be a name or an actual unit id (no guarantees)
function AuraUpdater:GetCharacterInGroup(nickname)
    local character = nicknameToCharacterCache[nickname]

    if not character then
        for unit in LUP:IterateGroupMembers() do
            local _nickname = AuraUpdater:GetNickname(unit)

            if _nickname == nickname then
                return unit
            end
        end
    end

    return character
end

-- Initialization
function LUP:InitializeNicknames()
	for addOnName, initFunction in pairs(LUP.nicknameInitFunctions) do
		if C_AddOns.IsAddOnLoaded(addOnName) then
			initFunction()
		end
	end
end

local nicknameInitFrame = CreateFrame("Frame")

nicknameInitFrame:RegisterEvent("ADDON_LOADED")
nicknameInitFrame:SetScript(
	"OnEvent",
	function(_, _, addOnName)
		local initFunction = LUP.nicknameInitFunctions[addOnName]

		if initFunction then initFunction() end
	end
)