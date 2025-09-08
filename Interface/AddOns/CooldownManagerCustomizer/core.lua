--------------------------------------------------------------------------------
-- Core.lua for CooldownManagerCustomizer
-- Reverted to C_ hooking.
-- taint risk, but reliable! report bugs/errors to me
--------------------------------------------------------------------------------

local addonName, addonTable = ...
if not addonTable then DEFAULT_CHAT_FRAME:AddMessage(...) return end
_G[addonName] = addonTable
local db = nil
local originalGetCategorySet = C_CooldownViewer.GetCooldownViewerCategorySet


local function HookedGetCooldownViewerCategorySet(category)
    local results = { originalGetCategorySet(category) }
    local originalIDsTable = {}
    for _, res in ipairs(results) do
        if type(res) == "number" then
            table.insert(originalIDsTable, res)
        elseif type(res) == "table" then
            for k, v in pairs(res) do
                if type(v) == "number" then table.insert(originalIDsTable, v) end
            end
        end
    end

    if not db or not db.hiddenSpells or not db.spellOrderOffsets then
        return originalIDsTable
    end

    local processingList = {}
    for originalIndex, cooldownID in ipairs(originalIDsTable) do
        local success, cooldownInfo = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cooldownID)
        if success and cooldownInfo and cooldownInfo.spellID then
            local spellID = cooldownInfo.spellID
            local offset = db.spellOrderOffsets[spellID] or 0
            local sortIndex = originalIndex + offset
            table.insert(processingList, { id = cooldownID, index = sortIndex, spellID = spellID })
        end
    end
    table.sort(processingList, function(a, b) return a.index < b.index end)

    local finalIDsTable = {}
    for _, itemData in ipairs(processingList) do
        if not db.hiddenSpells[itemData.spellID] then
            table.insert(finalIDsTable, itemData.id)
        end
    end
    return finalIDsTable
end

--------------------------------------------------------------------------------
-- Addon Core Functions
--------------------------------------------------------------------------------
function addonTable:RefreshCooldownViewers()
    local viewerNames = {"EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer", "BuffBarCooldownViewer"}
    for _, frameName in ipairs(viewerNames) do
        local frame = _G[frameName]
        if frame and frame.RefreshLayout then
            frame:RefreshLayout()
        end
    end
end


function addonTable:OnInitialize()
    if not db then
        CooldownViewerFilterDB = CooldownViewerFilterDB or {}
        CooldownViewerFilterDB.hiddenSpells = CooldownViewerFilterDB.hiddenSpells or {}
        CooldownViewerFilterDB.spellOrderOffsets = CooldownViewerFilterDB.spellOrderOffsets or {}
        db = CooldownViewerFilterDB
        -- print(addonName .. ": Database initialized.") Debug thing. Leaving it for reference
    end

    if C_CooldownViewer.GetCooldownViewerCategorySet == originalGetCategorySet then
        C_CooldownViewer.GetCooldownViewerCategorySet = HookedGetCooldownViewerCategorySet
    else
        -- If it's already hooked then another addon is interfering
        -- report this to me if you see it, along with a list of your addons!
        print(addonName..": Warning - C_CooldownViewer.GetCooldownViewerCategorySet was already modified!")
        print(addonName..": Report this error to Mango - include a list of your addons!")
    end
    -- print(addonName .. ": OnInitialize finished.") debug thing
end

--------------------------------------------------------------------------------
-- Event Handler
--------------------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        addonTable:OnInitialize()
        self:UnregisterAllEvents()
    end
end)

--------------------------------------------------------------------------------
-- Slash Command Handler (No changes needed from last working version)
--------------------------------------------------------------------------------
SLASH_COOLDOWNMANAGERFILTER1 = "/cmc"
SlashCmdList["COOLDOWNMANAGERFILTER"] = function(msg) local AddonGlobalTable = _G[addonName]; if not AddonGlobalTable or not AddonGlobalTable.RefreshCooldownViewers then print(addonName .. ": Error - Addon not ready."); return end; if not db then print(addonName .. ": Error - Database not ready."); return end; if not db.spellOrderOffsets then db.spellOrderOffsets = {} end; if not db.hiddenSpells then db.hiddenSpells = {} end
    msg = msg and strtrim(msg) or ""
        local cmd, arg = msg:match("^(%S*)%s*(.*)$")
            if not cmd then cmd = "" 
        end 
    cmd = cmd:lower() 
    arg = strtrim(arg)
    local needsRefresh = false
    local spellID = tonumber(arg)
        if cmd == "config" or cmd == "cfg" then 
            if AddonGlobalTable.ToggleConfigUI then 
                AddonGlobalTable:ToggleConfigUI() else 
                    print(addonName..": Error - ToggleConfigUI function not found.") 
                end
            needsRefresh = false 
        elseif cmd == "hide" then 
            if spellID then 
                if db.hiddenSpells[spellID] then print(addonName .. ": SpellID", spellID, "is already hidden.") else 
                    db.hiddenSpells[spellID] = true
                    print(addonName .. ": Hiding SpellID", spellID) 
                    needsRefresh = true 
                end 
            else print(addonName .. ": Usage: /cmc hide <SpellID>") 
            end 
        elseif cmd == "show" then 
            if spellID then 
                if not db.hiddenSpells[spellID] then 
                    print(addonName .. ": SpellID", spellID, "is already shown.") 
                else db.hiddenSpells[spellID] = nil
                    print(addonName .. ": Showing SpellID", spellID)
                    needsRefresh = true 
                end 
                    else print(addonName .. ": Usage: /cmc show <SpellID>") 
            end 
        elseif cmd == "toggle" then 
            if spellID then 
                if db.hiddenSpells[spellID] then 
                    db.hiddenSpells[spellID] = nil
                    print(addonName .. ": Toggling SpellID", spellID, "to SHOWN") 
                else db.hiddenSpells[spellID] = true
                    print(addonName .. ": Toggling SpellID", spellID, "to HIDDEN") 
                end
                needsRefresh = true 
                else print(addonName .. ": Usage: /cmc toggle <SpellID>") 
            end 
        elseif cmd == "moveup" then 
            if spellID then 
                db.spellOrderOffsets[spellID] = (db.spellOrderOffsets[spellID] or 0) - 1
                print(addonName..": Moving SpellID", spellID, "UP (Offset: "..db.spellOrderOffsets[spellID]..")")
                needsRefresh = true 
            else print(addonName..": Usage: /cmc moveup <SpellID>") 
            end 
        elseif cmd == "movedown" then 
            if spellID then db.spellOrderOffsets[spellID] = (db.spellOrderOffsets[spellID] or 0) + 1
                print(addonName..": Moving SpellID", spellID, "DOWN (Offset: "..db.spellOrderOffsets[spellID]..")")
                needsRefresh = true 
            else print(addonName..": Usage: /cmc movedown <SpellID>") 
            end 
        elseif cmd == "resetorder" then 
            if spellID then 
                if db.spellOrderOffsets[spellID] then 
                    db.spellOrderOffsets[spellID] = nil
                    print(addonName..": Resetting order for SpellID", spellID)
                    needsRefresh = true 
                else print(addonName..": SpellID", spellID, "order was not changed.") 
                end 
            else print(addonName..": Usage: /cmc resetorder <SpellID>") 
            end 
        elseif cmd == "resetallorder" then 
            wipe(db.spellOrderOffsets)
            print(addonName..": Resetting order for ALL spells.")
            needsRefresh = true 
        elseif cmd == "list" then 
            print(addonName .. ": Currently Hidden Spell IDs:")
            local found = false
            for id, hidden in pairs(db.hiddenSpells) do 
                if hidden == true then 
                    print("- " .. id)
                    found = true 
                end 
            end
            if not found then 
                print("(None)") 
            end
            needsRefresh = false 
        elseif cmd == "refresh" then 
            print(addonName .. ": Manual refresh requested.")
            needsRefresh = true 
        elseif cmd == "" then 
            needsRefresh = false
            print(addonName .. ": Commands:")
            print("/cmc config")
            print("/cmc hide <ID> | show <ID> | toggle <ID>")
            print("/cmc list")
            print("/cmc moveup <ID> | movedown <ID>")
            print("/cmc resetorder <ID> | resetallorder")
            print("/cmc refresh") 
        else 
            print(addonName .. ": Unknown command '" .. cmd .. "'. Type /cmc for help.")
            needsRefresh = false 
        end
    if needsRefresh then 
        C_Timer.After(0.1, function() local CurrentAddonTable = _G[addonName]
            if CurrentAddonTable and CurrentAddonTable.RefreshCooldownViewers then 
                CurrentAddonTable:RefreshCooldownViewers() 
            else 
                print(addonName .. ": Error - Addon table/refresh function not found in delayed timer.") 
                end 
            end) 
        end 
    end

---------------------
---- Adding spell and aura ID's to tooltip by default
---------------------
local function AddSpellIDToTooltip(tooltip, data)
    local spellName, spellID = tooltip:GetSpell()
        if spellID then
            local idAlreadyPresent = false
            for i = 1, tooltip:NumLines() do
                local lineText = _G[tooltip:GetName() .. "TextLeft" .. i] and _G[tooltip:GetName() .. "TextLeft" .. i]:GetText() or ""
                if string.find(lineText, "Spell ID: " .. tostring(spellID), 1, true) then
                    idAlreadyPresent = true
                    break
                end
            end
    
            if not idAlreadyPresent then
                tooltip:AddLine(" ")
                tooltip:AddLine("Spell ID: " .. tostring(spellID), 1, 1, 1)
            end
        end
    end
    
    local function AddAuraIDToTooltip(tooltip, data)
    local auraSpellId = data and data.id
        if auraSpellId then
            local idAlreadyPresent = false
            for i = 1, tooltip:NumLines() do
                 local lineText = _G[tooltip:GetName() .. "TextLeft" .. i] and _G[tooltip:GetName() .. "TextLeft" .. i]:GetText() or ""
                if string.find(lineText, "Aura ID: " .. tostring(auraSpellId), 1, true) then
                    idAlreadyPresent = true
                    break
                end
            end
            
            if not idAlreadyPresent then
               tooltip:AddLine(" ")
               tooltip:AddLine("Aura ID: " .. tostring(auraSpellId), 1, 1, 1)
            end
        end
    end
    
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, AddSpellIDToTooltip)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, AddAuraIDToTooltip)
    