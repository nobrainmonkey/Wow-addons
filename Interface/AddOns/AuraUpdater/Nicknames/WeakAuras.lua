local _, LUP = ...

local ADDON_NAME = "WeakAuras"

LUP.nicknameInitFunctions[ADDON_NAME] = function()
	local CustomNames = C_AddOns.IsAddOnLoaded("CustomNames") and LibStub("CustomNames")

	if WeakAuras and not CustomNames and not LiquidAPI then
		if WeakAuras.GetName then
			WeakAuras.GetName = function(name)
				if not name then return end

				return AuraUpdater:GetNickname(name) or name
			end
		end

		if WeakAuras.UnitName then
			WeakAuras.UnitName = function(unit)
				if not unit then return end

				local name, realm = UnitName(unit)

				if not name then return end

				return AuraUpdater:GetNickname(unit) or name, realm
			end
		end

		if WeakAuras.GetUnitName then
			WeakAuras.GetUnitName = function(unit, showServerName)
				if not unit then return end

				if not UnitIsPlayer(unit) then
					return GetUnitName(unit)
				end

				local name = UnitNameUnmodified(unit)
				local nameRealm = GetUnitName(unit, showServerName)
				local suffix = nameRealm:match(".+(%s%(%*%))") or nameRealm:match(".+(%-.+)") or ""

				return string.format("%s%s", AuraUpdater:GetNickname(unit) or name, suffix)
			end
		end

		if WeakAuras.UnitFullName then
			WeakAuras.UnitFullName = function(unit)
				if not unit then return end

				local name, realm = UnitFullName(unit)

				if not name then return end

				return AuraUpdater:GetNickname(unit) or name, realm
			end
		end
	end
end
