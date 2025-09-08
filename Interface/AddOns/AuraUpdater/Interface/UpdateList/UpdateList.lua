-- This file builds the update list, which shows auras that are out of date,
-- as well as warnings for things like having duplicate auras etc.

local _, LUP = ...

local ELEMENT_HEIGHT = 40
local ELEMENT_SPACING = 4

function LUP:CreateUpdateList(parent)
    local updateElements = {}

    local updateList = CreateFrame("Frame", nil, parent)

    -- Scroll frame
    local scrollFrame = LUP:CreateScrollFrame(updateList)

    scrollFrame:SetAllPoints()
    scrollFrame:SetScrollDistance(ELEMENT_HEIGHT + ELEMENT_SPACING)

    scrollFrame.scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -8, 16)
    scrollFrame.scrollFrame:SetPoint("BOTTOMRIGHT", scrollFrame.scrollBar, "BOTTOMLEFT", -10, -15)

    -- All auras up to date text
    updateList.requiresUpdateText = updateList:CreateFontString()

    updateList.requiresUpdateText:SetFontObject(LiquidFont21)
    updateList.requiresUpdateText:SetAllPoints(scrollFrame.scrollFrame)
    updateList.requiresUpdateText:SetFormattedText("|cff%sAll auras up to date!|r", LUP.gs.visual.colorStrings.green)

    local function ReleaseAllUpdateElements()
        for index, cell in pairs(updateElements) do
            cell:Release()

            updateElements[index] = nil
        end
    end

    -- Called any time the player's versions table updates, or when highest seen versions update
    function updateList:Rebuild()
        ReleaseAllUpdateElements()

        local versionsTable = LUP:GetPlayerVersionsTable()

        local installedAddOnVersion = versionsTable.addOn
        local installedAuraVersions = versionsTable.auras

        local highestSeenAddOnVersion = LUP:GetHighestSeenAddOnVersion()
        local highestSeenAuraVersions = LUP:GetHighestSeenAuraVersions()

        local importedVersions = {}

        for displayName, auraData in pairs(LiquidUpdaterSaved.WeakAuras) do
            importedVersions[displayName] = auraData.d.liquidVersion or 0
        end

        -- Create update elements for auras
        for displayName, highestSeenVersion in pairs(highestSeenAuraVersions) do
            local installedVersion = installedAuraVersions[displayName]
            local importedVersion = importedVersions[displayName]

            if importedVersion then
                local versionsBehind = highestSeenVersion - installedVersion

                if versionsBehind > 0 then
                    local requiresAddOnUpdate = importedVersion < highestSeenVersion

                    local updateElement = LUP:CreateUpdateElement(scrollFrame.contentFrame, displayName)

                    updateElement:SetVersionsBehind(versionsBehind)
                    updateElement:SetRequiresAddOnUpdate(requiresAddOnUpdate)

                    table.insert(updateElements, updateElement)
                end
            end
        end

        -- Sort aura update elements
        table.sort(
            updateElements,
            function(elementA, elementB)
                local versionsBehindA = elementA.versionsBehind
                local versionsBehindB = elementB.versionsBehind

                if versionsBehindA ~= versionsBehindB then
                    return versionsBehindA > versionsBehindB
                else
                    return elementA.auraName < elementB.auraName
                end
            end
        )

        -- Create addon update element
        local addOnVersionsBehind = highestSeenAddOnVersion - installedAddOnVersion

        if addOnVersionsBehind > 0 then
            local updateElement = LUP:CreateUpdateElement(scrollFrame.contentFrame, "AuraUpdater")

            updateElement:SetVersionsBehind(addOnVersionsBehind)
            updateElement:SetRequiresAddOnUpdate(true)

            table.insert(updateElements, 1, updateElement)
        end

        -- Position elements
        for i, updateElement in ipairs(updateElements) do
            updateElement:SetPoint("BOTTOMLEFT", scrollFrame.contentFrame, "TOPLEFT", ELEMENT_SPACING, -i * (ELEMENT_HEIGHT + ELEMENT_SPACING))
            updateElement:SetPoint("BOTTOMRIGHT", scrollFrame.contentFrame, "TOPRIGHT", -ELEMENT_SPACING, -i * (ELEMENT_HEIGHT + ELEMENT_SPACING))
        end

        -- Show the green "all auras up to date" text if no update elements exist
        updateList.requiresUpdateText:SetShown(#updateElements == 0)

        -- Update scroll frame
        scrollFrame.contentFrame:SetHeight(#updateElements * (ELEMENT_HEIGHT + ELEMENT_SPACING) + ELEMENT_SPACING)

        scrollFrame:FullUpdate()

        -- Might as well run this here, so we don't have to do the above checks anywhere else
        LUP.upToDate = #updateElements == 0

        LUP:UpdateMinimapIcon()
    end

    return updateList
end