--------------------------------------------------------------------------------
-- ConfigUI.lua for CooldownManagerCustomizer
--------------------------------------------------------------------------------

local addonName, addonTable = ...
if not addonTable then DEFAULT_CHAT_FRAME:AddMessage("|cffff0000ERROR:|r CooldownManagerCustomizer - ConfigUI.lua loaded but addonTable is missing!", 1.0, 0.1, 0.1) return end

local db = nil

local hideShowListFrames = {}
local movementListFrames = {} 

local CONFIG_FRAME_NAME = addonName .. "ConfigFrame"
local selectedTabIndex = 1 


--------------------------------------------------------------------------------
-- Helper
-- I kept all of my debug stuff in here. Debugging lua in wow is awful.
--------------------------------------------------------------------------------
local function GetTrackableSpellsFromAPI()
    -- print(addonName .. ": === GetTrackableSpellsFromAPI START ===") -- DEBUG Start
    local trackableSpells = {}
    local spellCount = 0

    local categoriesToScan = {
        { Enum = Enum.CooldownViewerCategory.Essential, Name = "Essential" },
        { Enum = Enum.CooldownViewerCategory.Utility, Name = "Utility" },
        { Enum = Enum.CooldownViewerCategory.TrackedBuff, Name = "TrackedBuff" },
        { Enum = Enum.CooldownViewerCategory.TrackedBar, Name = "TrackedBar" },
    }


    local originalGetCategorySet = C_CooldownViewer.GetCooldownViewerCategorySet
    if not originalGetCategorySet then
        print(addonName..": GetTrackable - ERROR: Original C_CooldownViewer.GetCooldownViewerCategorySet reference missing?")
        originalGetCategorySet = function() return {} end
    end

    for _, categoryData in ipairs(categoriesToScan) do
        local categoryEnum = categoryData.Enum
        local categoryName = categoryData.Name
        -- print(addonName .. ":  Scanning Category:", categoryName, "(Enum:", categoryEnum, ")") -- DEBUG Category

        local results = { originalGetCategorySet(categoryEnum) }
        local categoryCooldownIDs = {}
        for i, res in ipairs(results) do
            if type(res) == "number" then table.insert(categoryCooldownIDs, res)
            elseif type(res) == "table" then for k, v in pairs(res) do if type(v) == "number" then table.insert(categoryCooldownIDs, v) end end end
        end
        -- print(addonName .. ":   Found CooldownIDs for category:", table.concat(categoryCooldownIDs, ", ")) -- DEBUG IDs found

        for _, cooldownID in ipairs(categoryCooldownIDs) do
            -- print(addonName .. ":    Processing CooldownID:", cooldownID) -- Optional DEBUG spam
            local success_ci, cooldownInfo = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, cooldownID)
            if success_ci and cooldownInfo and cooldownInfo.spellID then
                local spellID = cooldownInfo.spellID
                -- print(addonName .. ":      Got SpellID:", spellID) -- Optional DEBUG spam
                if spellID > 0 and not trackableSpells[spellID] then
                    local success_s, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
                    if success_s and type(spellInfo) == "table" and spellInfo.name and spellInfo.iconID then
                        -- print(addonName .. ":      --> Adding Spell: ID", spellID, "| Name:", spellInfo.name, "| Icon:", spellInfo.iconID) -- DEBUG Spell Added
                        trackableSpells[spellID] = {
                            spellID = spellID,
                            spellName = spellInfo.name,
                            icon = spellInfo.iconID,
                            -- category = categoryName -- optional-adds some changes but nothing notable. leaving it for later reference.
                        }
                        spellCount = spellCount + 1
                    else
                        print(addonName .. ":      --> Skipping SpellID", spellID, "- Result:", tostring(spellInfo)) -- DEBUG SpellInfo failure
                    end
                end
            else
                 -- print(addonName .. ":     --> Skipping CooldownID", cooldownID, "- GetCooldownInfo failed or no spellID. Error/Result:", tostring(cooldownInfo)) -- DEBUG CooldownInfo failure
            end
        end
    end

    local finalList = {}
    for id, data in pairs(trackableSpells) do table.insert(finalList, data) end
    table.sort(finalList, function(a,b) return (a.spellName or "") < (b.spellName or "") end)

    -- print(addonName .. ": === GetTrackableSpellsFromAPI END - Returning", #finalList, "spells ===") -- DEBUG End
    return finalList
end


--------------------------------------------------------------------------------
-- UI creation
--------------------------------------------------------------------------------
function addonTable:CreateConfigUI()
    if _G[CONFIG_FRAME_NAME] then return end
    local mainFrame = CreateFrame("Frame", CONFIG_FRAME_NAME, UIParent, "BasicFrameTemplate"); if not mainFrame then return end
    mainFrame:SetSize(450, 450); mainFrame:SetPoint("CENTER"); mainFrame:SetMovable(true); mainFrame:EnableMouse(true); mainFrame:RegisterForDrag("LeftButton"); mainFrame:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartSizing() else self:StartMoving() end end); mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing); mainFrame:SetClampedToScreen(true); mainFrame:SetFrameStrata("MEDIUM"); mainFrame:SetToplevel(true); mainFrame:Hide()
    mainFrame.tabButtons = {}; mainFrame.contentFrames = {}
    C_Timer.After(0, function()
        if not mainFrame or not mainFrame:GetName() then return end; if not db and _G.CooldownViewerFilterDB then db = _G.CooldownViewerFilterDB end; if not db then return end
        if not mainFrame.myTitleText then local tt=mainFrame:CreateFontString(CONFIG_FRAME_NAME.."MyTitleText","ARTWORK","GameFontNormalLarge"); tt:SetPoint("TOP",0,-3); tt:SetText(addonName.." Config"); mainFrame.myTitleText=tt end
        -- at one point I had to make my own close button, then it started showing 2. I don't know why. Keeping this as a future reference.
        -- if not mainFrame.myCloseButton then local cb=CreateFrame("Button",CONFIG_FRAME_NAME.."MyCloseButton",mainFrame,"UIPanelCloseButton"); cb:SetPoint("TOPRIGHT",-4,-4); cb:SetSize(30,30); cb:SetScript("OnClick",function() mainFrame:Hide() end); mainFrame.myCloseButton=cb end
        -- I condensed all of this into one line just to save scrolling time. For techies - the semicolon in lua makes it think it's a new line!
        local tabNames={"Hide/Show", "Rearrange"}; local btnW=100; local btnH=22; local btnP=5
        for i=1, #tabNames do local btn=CreateFrame("Button",CONFIG_FRAME_NAME.."TabButton"..i,mainFrame,"UIPanelButtonTemplate"); if btn then btn:SetID(i); btn:SetText(tabNames[i]); btn:SetSize(btnW,btnH); if i==1 then btn:SetPoint("TOPLEFT",10,-30) else if mainFrame.tabButtons[i-1] then btn:SetPoint("LEFT",mainFrame.tabButtons[i-1],"RIGHT",btnP,0) end end; mainFrame.tabButtons[i]=btn; btn:SetScript("OnClick",function(self) PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON); addonTable:SelectConfigTab(self:GetID()) end) end end
        for i=1, #tabNames do local content=CreateFrame("Frame",CONFIG_FRAME_NAME.."Content"..i,mainFrame); if mainFrame.tabButtons[1] then content:SetPoint("TOPLEFT",mainFrame.tabButtons[1],"BOTTOMLEFT",-10,-5) else content:SetPoint("TOPLEFT",5,-55) end; content:SetPoint("BOTTOMRIGHT",-6,6); content:Hide(); table.insert(mainFrame.contentFrames,content); local scroll=CreateFrame("ScrollFrame",CONFIG_FRAME_NAME.."Scroll"..i,content,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",5,-5); scroll:SetPoint("BOTTOMRIGHT",-25,5); local child=CreateFrame("Frame",CONFIG_FRAME_NAME.."ScrollChild"..i,scroll); local scrollW=scroll:GetWidth() or 300; child:SetWidth(scrollW-5); child:SetHeight(10); scroll:SetScrollChild(child); content.scrollFrame=scroll; content.scrollChild=child end
        addonTable:SelectConfigTab(selectedTabIndex)
    end)
end

--------------------------------------------------------------------------------
-- Category Buttons
--------------------------------------------------------------------------------
function addonTable:SelectConfigTab(index)
    local mainFrame = _G[CONFIG_FRAME_NAME]
    if not mainFrame or not mainFrame.tabButtons or not mainFrame.contentFrames then return end

    selectedTabIndex = index
    for i, button in ipairs(mainFrame.tabButtons) do 
        local sel=(i==index); button:SetEnabled(not sel)
        local fs=button:GetFontString()
        if fs then if sel then fs:SetTextColor(1,0.82,0) else fs:SetTextColor(1,1,1) end 
        end 
    end 
    for i, frame in ipairs(mainFrame.contentFrames) do 
        if i==index then frame:Show()
            if i==1 then addonTable:RefreshHideShowTab() 
            elseif i==2 then addonTable:RefreshMovementTab() end 
            else frame:Hide() 
        end 
    end
end

--------------------------------------------------------------------------------
-- Hide/Show List
--------------------------------------------------------------------------------
function addonTable:RefreshHideShowTab()
    if not db and _G.CooldownViewerFilterDB then db=_G.CooldownViewerFilterDB end; if not db then return end
    local mainFrame=_G[CONFIG_FRAME_NAME]; if not mainFrame then return end; local cf=mainFrame.contentFrames and mainFrame.contentFrames[1]; local sc=cf and cf.scrollChild; if not sc then return end
    for _,f in ipairs(hideShowListFrames) do if f and f.Hide then f:Hide() end end; wipe(hideShowListFrames)

    local spells = GetTrackableSpellsFromAPI()
    if not spells or #spells == 0 then sc:SetHeight(10); return end

    local yO=-5; local lH=20; local pad=2; local lW=sc:GetWidth()-10; if lW<=0 then lW=300 end

    for i, sData in ipairs(spells) do
        if type(sData)=="table" and sData.spellID and sData.spellName then
            local sID=sData.spellID; local sName=sData.spellName; local iconID = sData.icon or 135907; local hidden=db.hiddenSpells[sID]==true
            local line=CreateFrame("Frame",nil,sc);
            if line then
                line:SetSize(lW,lH); line:SetPoint("TOPLEFT",5,yO)
                local cb=CreateFrame("CheckButton",CONFIG_FRAME_NAME.."HideCheck"..sID,line,"UICheckButtonTemplate");
                if cb then
                    cb:SetSize(20,20); cb:SetPoint("LEFT",0,0); cb:SetChecked(hidden); cb.spellID=sID
                    cb:SetScript("OnClick",function(self) local id=self.spellID
                    local chk=self:GetChecked()
                    db.hiddenSpells[id]=chk or nil
                    C_Timer.After(0.1,function() if _G[addonName] and _G[addonName].RefreshCooldownViewers then 
                        _G[addonName]:RefreshCooldownViewers() end end)
                    addonTable:RefreshMovementTab() end)
                    local lbl=line:CreateFontString(nil,"ARTWORK","GameFontNormal");
                    if lbl then
                        lbl:SetPoint("LEFT",cb,"RIGHT",5,0); lbl:SetPoint("RIGHT",line,"RIGHT",-5,0);
                        lbl:SetText(string.format("|T%s:16:16:0:0:64:64:4:60:4:60|t %s (%d)", iconID, sName, sID)) -- Use Spell Name and Icon ID
                        lbl:SetJustifyH("LEFT")
                        line:Show(); table.insert(hideShowListFrames,line); yO=yO-lH-pad
                    else line:Hide() end
                else line:Hide() end
            end
        end
    end
    sc:SetHeight(math.max(10,math.abs(yO)+5))
end

--------------------------------------------------------------------------------
-- Rearrange List
--------------------------------------------------------------------------------
function addonTable:RefreshMovementTab()
    if not db and _G.CooldownViewerFilterDB then db=_G.CooldownViewerFilterDB end; if not db then return end
    local mainFrame=_G[CONFIG_FRAME_NAME]
    if not mainFrame then return end
    local cf=mainFrame.contentFrames and mainFrame.contentFrames[2]
    local sc=cf and cf.scrollChild; if not sc then return end
    for _,f in ipairs(movementListFrames) do if f and f.Hide then f:Hide() end end
    wipe(movementListFrames)

    local allTrackableSpells = GetTrackableSpellsFromAPI()
    local visibleSpells = {}
    if allTrackableSpells then
        for _, spellData in ipairs(allTrackableSpells) do
            if spellData and spellData.spellID and not db.hiddenSpells[spellData.spellID] then
                table.insert(visibleSpells, spellData)
            end
        end
    end

    local tempSort={};
    for i, spellData in ipairs(visibleSpells) do
        spellData.sortIndex = (db.spellOrderOffsets[spellData.spellID] or 0) + 10000 + i -- in 10 years I may have to change this to 100000
        table.insert(tempSort, spellData)
    end
    table.sort(tempSort, function(a,b) return a.sortIndex < b.sortIndex end)
    visibleSpells = tempSort 

    local yO=-5; local lH=22; local pad=2; local lW=sc:GetWidth()-10; if lW<=0 then lW=300 end

    if #visibleSpells==0 then sc:SetHeight(10); return end

    for i, sData in ipairs(visibleSpells) do
        local sID=sData.spellID; local sName=sData.spellName or "Unk"; local iconID = sData.icon or 135907; local cOffset=db.spellOrderOffsets[sID] or 0
        local line=CreateFrame("Frame",nil,sc);
        if line then
            line:SetSize(lW,lH); line:SetPoint("TOPLEFT",5,yO)
            local lbl=line:CreateFontString(nil,"ARTWORK","GameFontNormalSmall");
            if lbl then
                lbl:SetPoint("LEFT",45,0); lbl:SetJustifyH("LEFT");
                lbl:SetText(string.format("|T%s:16:16:0:0:64:64:4:60:4:60|t %s (%d) | Off: %d",iconID, sName, sID, cOffset)) -- Use Spell Name and Icon ID
                --lbl:SetText(string.format("%d. %s (%d) | Off: %d",i,sName,sID,cOffset)) 
            end
            local upBtn=CreateFrame("Button",nil,line,"UIPanelButtonTemplate");
            if upBtn then upBtn:SetSize(20,20); upBtn:SetPoint("LEFT",0,0); upBtn:SetText("<"); upBtn.spellID=sID; upBtn:SetScript("OnClick",function(self) addonTable:MoveSpell(self.spellID,-1) end); end --upBtn:SetEnabled(i>1) 
            local downBtn=CreateFrame("Button",nil,line,"UIPanelButtonTemplate");
            if downBtn then local aTo=upBtn or line; local rP=upBtn and "RIGHT" or "LEFT"; local xO=upBtn and 1 or 21; downBtn:SetSize(20,20); downBtn:SetPoint("LEFT",aTo,rP,xO,0); downBtn:SetText(">"); downBtn.spellID=sID; downBtn:SetScript("OnClick",function(self) addonTable:MoveSpell(self.spellID,1) end); end -- downBtn:SetEnabled(i<#visibleSpells) 
            local resetBtn=CreateFrame("Button",nil,line,"UIPanelButtonTemplate");
            if resetBtn then resetBtn:SetSize(45,18); resetBtn:SetPoint("RIGHT",0,0); resetBtn:SetText("Reset"); resetBtn:GetFontString():SetFontObject("GameFontNormalSmall"); resetBtn.spellID=sID; resetBtn:SetScript("OnClick",function(self) addonTable:ResetSpellOrder(self.spellID) end); resetBtn:SetEnabled(cOffset~=0) end

            line:Show(); table.insert(movementListFrames,line); yO=yO-lH-pad
        end
    end
    sc:SetHeight(math.max(10,math.abs(yO)+5))
end

------------
-- Reordering
------------------------
function addonTable:MoveSpell(spellID, direction) if not db or not db.spellOrderOffsets then return end
db.spellOrderOffsets[spellID] = (db.spellOrderOffsets[spellID] or 0) + direction
addonTable:RefreshMovementTab()
C_Timer.After(0.1, function() if _G[addonName] and _G[addonName].RefreshCooldownViewers then 
    _G[addonName]:RefreshCooldownViewers() end end) 
end

function addonTable:ResetSpellOrder(spellID) if not db or not db.spellOrderOffsets then return end 
if db.spellOrderOffsets[spellID] then db.spellOrderOffsets[spellID] = nil
addonTable:RefreshMovementTab()
C_Timer.After(0.1, function() if _G[addonName] and _G[addonName].RefreshCooldownViewers then 
    _G[addonName]:RefreshCooldownViewers() end end) end 
end

--------------------------------------------------------------------------------
-- UI Functions misc
--------------------------------------------------------------------------------
function addonTable:HideSpellFromConfig(spellID) -- Called only by manual Add ID button
    if not spellID then return end
    if not db then return end 
    if db.hiddenSpells[spellID] then return end
    db.hiddenSpells[spellID] = true
    addonTable:RefreshHideShowTab() 
    addonTable:RefreshMovementTab()
    C_Timer.After(0.1, function() if _G[addonName] and _G[addonName].RefreshCooldownViewers then 
        _G[addonName]:RefreshCooldownViewers() end end)
end


function addonTable:ToggleConfigUI()
    local fn=CONFIG_FRAME_NAME; 
    if not _G[fn] then addonTable:CreateConfigUI(); 
        C_Timer.After(0.2, function() addonTable:ToggleConfigUI() 
        end); return end; 
    local mf=_G[fn]; 
    if mf then 
        if mf:IsShown() then mf:Hide() else 
            if not db and _G.CooldownViewerFilterDB then db=_G.CooldownViewerFilterDB end; 
            if db then if selectedTabIndex==1 then addonTable:RefreshHideShowTab() 
            elseif selectedTabIndex==2 then addonTable:RefreshMovementTab() 
            end end; mf:Show() end end
end
