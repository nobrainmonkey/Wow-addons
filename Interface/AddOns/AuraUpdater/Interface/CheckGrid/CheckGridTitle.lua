local _, LUP = ...

local MIN_WIDTH = 90 -- The minimum width a title (and thus column) should be

local framePool = {}

local function Acquire()
    local index, frame = next(framePool)

    if not frame then return end

    framePool[index] = nil

    return frame
end

function LUP:CreateCheckGridTitle(parent)
    local checkGridTitle = Acquire()

    if not checkGridTitle then
        checkGridTitle = CreateFrame("Frame")

        checkGridTitle:SetHeight(1)

        checkGridTitle.title = checkGridTitle:CreateFontString()
        checkGridTitle.title:SetFontObject(LiquidFont15)
        checkGridTitle.title:SetPoint("BOTTOM", checkGridTitle, "BOTTOM")

        function checkGridTitle:SetTitle(title)
            checkGridTitle.title:SetFormattedText("|cff%s%s|r", LUP.gs.visual.colorStrings.white, title)

            -- GetUnboundedStringWidth undershoots the width on the frame that the text is set
            -- 1.1 is an arbitrary factor to account for this somewhat
            checkGridTitle:SetWidth(math.max(MIN_WIDTH, checkGridTitle.title:GetUnboundedStringWidth() * 1.1))
        end

        function checkGridTitle:Release()
            checkGridTitle:Hide()

            table.insert(framePool, checkGridTitle)
        end
    end

    checkGridTitle:SetParent(parent)
    checkGridTitle:Show()

    return checkGridTitle
end