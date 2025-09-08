local addOnName = ...

local MIN_FONT_SIZE = 11
local MAX_FONT_SIZE = 21

local ROMAN_FILE = string.format("Interface\\Addons\\%s\\LiquidUI\\Media\\Fonts\\PTSansNarrow.ttf", addOnName)
local KOREAN_FILE = "Fonts\\2002.TTF"
local SIMPLIFIED_CHINESE_FILE = "Fonts\\ARKai_C.ttf"
local TRADITIONAL_CHINESE_FILE = string.format("Interface\\Addons\\%s\\LiquidUI\\Media\\Fonts\\arheiuhk_bd.ttf", addOnName)
local RUSSIAN_FILE = "Fonts\\FRIZQT___CYR.TTF"

for fontSize = MIN_FONT_SIZE, MAX_FONT_SIZE do
    -- Regular font
    local fontName = string.format("LiquidFont%d", fontSize)

    if not _G[fontName] then
        CreateFontFamily(
            fontName,
            {
                {alphabet = "roman", file = ROMAN_FILE, height = fontSize, flags = ""},
                {alphabet = "korean", file = KOREAN_FILE, height = fontSize, flags = ""},
                {alphabet = "simplifiedchinese", file = SIMPLIFIED_CHINESE_FILE, height = fontSize, flags = ""},
                {alphabet = "traditionalchinese", file = TRADITIONAL_CHINESE_FILE, height = fontSize, flags = ""},
                {alphabet = "russian", file = RUSSIAN_FILE, height = fontSize, flags = ""},
            }
        )
    end

    -- Outline font
    local fontNameOutline = string.format("LiquidFont%d_Outline", fontSize)

    if not _G[fontNameOutline] then
        CreateFontFamily(
            fontNameOutline,
            {
                {alphabet = "roman", file = ROMAN_FILE, height = fontSize, flags = "OUTLINE"},
                {alphabet = "korean", file = KOREAN_FILE, height = fontSize, flags = "OUTLINE"},
                {alphabet = "simplifiedchinese", file = SIMPLIFIED_CHINESE_FILE, height = fontSize, flags = "OUTLINE"},
                {alphabet = "traditionalchinese", file = TRADITIONAL_CHINESE_FILE, height = fontSize, flags = "OUTLINE"},
                {alphabet = "russian", file = RUSSIAN_FILE, height = fontSize, flags = "OUTLINE"},
            }
        )
    end
end