local _, namespace = ...

-- Takes care of raising windows above other windows when they're clicked
-- Also makes ESC close the most top-level window
-- Both of these only apply to windows that RaiseOnClick was called on
-- This is a global frame. If multiple addons implement LiquidUI, the one with the highest version takes precedent.
local raiserFrame = _G["LIQUID_WINDOW_RAISER"] or CreateFrame("Frame", "LIQUID_WINDOW_RAISER")
local version = raiserFrame.VERSION

if not version or version < namespace.LiquidUI.VERSION then
    raiserFrame.VERSION = namespace.LiquidUI.VERSION

    -- This table contains all the windows that participate in the layering
    -- Their order in this array matches their order on the screen
    -- The window at index 1 is behind the window at index 2, which in turn is behind the window at index 3, etc.
    raiserFrame.windows = raiserFrame.windows or {}

    -- Sets frame levels of the windows based on their index in raiserFrame.windows
    -- Frame levels are set per frame strata, since windows on a lower strata cannot be in front of those with a higher one
    local function UpdateFrameLevels()
        local highestFrameLevel = {} -- Frame strata to highest frame level

        for index, window in ipairs(raiserFrame.windows) do
            local frameStrata = window:GetFrameStrata()
            local frameLevel = (highestFrameLevel[frameStrata] or 0) + 100

            window:SetFrameLevel(index * 100)

            highestFrameLevel[frameStrata] = frameLevel
        end
    end

    local function RaiseWindow(window)
        local index = tIndexOf(raiserFrame.windows, window)

        table.remove(raiserFrame.windows, index)
        table.insert(raiserFrame.windows, window)
        
        UpdateFrameLevels()
    end

    function raiserFrame:AddWindow(window)
        tInsertUnique(raiserFrame.windows, window)

        window:SetScript("OnShow", RaiseWindow) -- When a window is opened, it should appear above other windows that were already opened

        UpdateFrameLevels()
    end

    -- When a window is clicked, raise it above the other windows
    raiserFrame:RegisterEvent("GLOBAL_MOUSE_DOWN")
    raiserFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

    raiserFrame:SetScript(
        "OnEvent",
        function(_, event)
            if event == "GLOBAL_MOUSE_DOWN" then
                local frame = GetMouseFoci()[1]
                
                for _ = 1, 10 do
                    if not frame then return end
                    if frame:IsForbidden() then return end

                    if tContains(raiserFrame.windows, frame) then
                        RaiseWindow(frame)

                        return
                    else
                        frame = frame.GetParent and frame:GetParent()
                    end
                end
            elseif event == "PLAYER_REGEN_DISABLED" then
                raiserFrame:SetPropagateKeyboardInput(true)
            end
        end
    )

    -- When escape is pressed, close the most top level window
    raiserFrame:SetScript(
        "OnKeyDown",
        function(_, key)
            if InCombatLockdown() then return end

            if key == "ESCAPE" then
                for _, window in ipairs_reverse(raiserFrame.windows) do
                    if window:IsShown() then
                        raiserFrame:SetPropagateKeyboardInput(false)

                        window:Hide()

                        return
                    end
                end
            end

            raiserFrame:SetPropagateKeyboardInput(true)
        end
    )
end
