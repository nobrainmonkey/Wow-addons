local _, LUP = ...

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local eventFrame = CreateFrame("Frame")

-- Updates the visibility and look of the minimap icon
-- When the player's addons/auras are up to date, and there are no warnings the icon is either white or hidden
-- If they are not, the icon is red
-- This is called whenever the player's version table updates, and whenever the highest seen versions update
function LUP:UpdateMinimapIcon()
    -- Create minimap icon if it doesn't exist yet
    if not LUP.LDB then
        LUP.LDB = LDB:NewDataObject(
            "Aura Updater",
            {
                type = "data source",
                text = "Aura Updater",
                icon = [[Interface\Addons\AuraUpdater\Media\Textures\minimap_logo.tga]],
                OnClick = function() LUP.window:SetShown(not LUP.window:IsShown()) end
            }
        )

        LDBIcon:Register("Aura Updater", LUP.LDB, LiquidUpdaterSaved.minimap)
    end

    -- Update color
    if LUP.upToDate then
        LUP.LDB.icon = [[Interface\Addons\AuraUpdater\Media\Textures\minimap_logo.tga]]
    else
        LUP.LDB.icon = [[Interface\Addons\AuraUpdater\Media\Textures\minimap_logo_red.tga]]
    end

    -- Update visibility
    if LUP.upToDate and LiquidUpdaterSaved.settings.hideMinimapIcon then
        LDBIcon:Hide("Aura Updater")
    else
        LDBIcon:Show("Aura Updater")
    end
end

-- There seems to be an issue on certain bosses (e.g. Sprocketmonger) where too many sounds play at the same time
-- If the number of sound channels is too low, this quickly becomes an issue causing text-to-speech files to not play
-- This sets the user's sound channel number to the maximum to hopefully prevent this as much as possible
local function SetSoundNumChannels()
    if not InCombatLockdown() then
        SetCVar("Sound_NumChannels", 128)
    end
end

-- Ensures the necessary addon settings is SavedVariables all exist and have sane values
local function EnsureSettings()
    if not LiquidUpdaterSaved then LiquidUpdaterSaved = {} end
    if not LiquidUpdaterSaved.minimap then LiquidUpdaterSaved.minimap = {} end
    if not LiquidUpdaterSaved.settings then LiquidUpdaterSaved.settings = {} end
    if not LiquidUpdaterSaved.settings.frames then LiquidUpdaterSaved.settings.frames = {} end
    if not LiquidUpdaterSaved.nicknames then LiquidUpdaterSaved.nicknames = {} end
    if LiquidUpdaterSaved.settings.readyCheckPopup == nil then LiquidUpdaterSaved.settings.readyCheckPopup = true end
    if LiquidUpdaterSaved.settings.disableBigWigsAssignments == nil then LiquidUpdaterSaved.settings.disableBigWigsAssignments = true end
end

-- The addon used to be called "LiquidUpdater", and having that old version installed causes issues with AuraUpdater
-- If the user still has LiquidUpdater active, show a warning that prompts them to disable it
local function ShowLiquidUpdaterWarning()
    if C_AddOns.IsAddOnLoaded("LiquidUpdater") then
        local liquidUpdaterPopup = LUP:CreatePopupWindowWithButton()

        liquidUpdaterPopup:SetHideOnClickOutside(false)
        liquidUpdaterPopup:SetText("LiquidUpdater is active, and interferes with AuraUpdater.|n|nPlease disable it.")
        liquidUpdaterPopup:SetButtonText(string.format("|cff%sDisable and reload|r", LUP.gs.visual.colorStrings.green))
        liquidUpdaterPopup:SetButtonOnClick(
            function()
                C_AddOns.DisableAddOn("LiquidUpdater")

                C_UI.Reload()
            end
        )

        liquidUpdaterPopup:Pop()
        liquidUpdaterPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    end
end

local function Initialize()
    EnsureSettings()
    SetSoundNumChannels()

    LUP.LiquidUI:Initialize(LiquidUpdaterSaved)

    LUP:InitializeNicknames()
    LUP:InitializeBigWigsDisabler()
    LUP:InitializeWeakAurasImporter()
    LUP:InitializeInterface()
    LUP:InitializeTransmission()
    LUP:InitializeVersions()

    ShowLiquidUpdaterWarning()

    -- For some reason the minimap icon doesn't hide if this code runs on the same frame it's being created
    -- In other words, if all auras are up to date, and the user hides the minimap icon, it doesn't hide on log (or reload)
    RunNextFrame(function() LUP:UpdateMinimapIcon() end)
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript(
    "OnEvent",
    function(_, event, ...)
        if event == "ADDON_LOADED" then
            local addOnName = ...

            if addOnName == "AuraUpdater" then
                Initialize()
            end
        end
    end
)

SLASH_AURAUPDATER1 = "/lu"
SLASH_AURAUPDATER2 = "/auraupdate"
SLASH_AURAUPDATER3 = "/auraupdater"
SLASH_AURAUPDATER4 = "/au"

function SlashCmdList.AURAUPDATER()
    LUP.window:SetShown(not LUP.window:IsShown())
end