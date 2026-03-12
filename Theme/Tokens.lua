-------------------------------------------------------------------------------
-- Tokens.lua
-- Color token registry and retrieval API
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local format = format
local type = type
local pairs = pairs
local error = error
local tostring = tostring

local ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

-------------------------------------------------------------------------------
-- Shared texture
-------------------------------------------------------------------------------

LDF.WHITE8X8 = "Interface\\Buttons\\WHITE8x8"

-------------------------------------------------------------------------------
-- Color constructor
-------------------------------------------------------------------------------

local function MakeColor(r, g, b, a)
    a = a or 1
    local hex = format("|c%02x%02x%02x%02x", a * 255, r * 255, g * 255, b * 255)
    return { r, g, b, a, hex }
end

-------------------------------------------------------------------------------
-- Core palette
-------------------------------------------------------------------------------

local colors = LDF.colors

colors.bg0         = MakeColor(0.05, 0.05, 0.05, 0.95)  -- deep background
colors.bg1         = MakeColor(0.08, 0.08, 0.08, 0.95)  -- panel background
colors.bg2         = MakeColor(0.15, 0.15, 0.15, 1)     -- widget background
colors.border      = MakeColor(0,    0,    0,    1)     -- standard border
colors.borderLight = MakeColor(0.25, 0.25, 0.25, 1)     -- light border (input focus)
colors.text        = MakeColor(1,    1,    1,    1)      -- primary text
colors.textMuted   = MakeColor(0.7,  0.7,  0.7,  1)     -- secondary text
colors.textDim     = MakeColor(0.5,  0.5,  0.5,  1)     -- disabled text
colors.accentGold  = MakeColor(1,    0.82, 0,    1)      -- Dragon gold accent
colors.success     = MakeColor(0,    1,    0,    1)      -- green
colors.danger      = MakeColor(1,    0,    0,    1)      -- red
colors.highlight   = MakeColor(1,    1,    1,    0.25)  -- hover highlight
colors.shadow      = MakeColor(0,    0,    0,    0.25)  -- shadow effects
colors.headerBg    = MakeColor(0.127, 0.127, 0.127, 1)  -- header background

-------------------------------------------------------------------------------
-- Quality colors
-------------------------------------------------------------------------------

local QUALITY_FALLBACK = {
    [0] = { 0.62, 0.62, 0.62 }, -- Poor
    [1] = { 1,    1,    1    }, -- Common
    [2] = { 0.12, 1,    0    }, -- Uncommon
    [3] = { 0,    0.44, 0.87 }, -- Rare
    [4] = { 0.64, 0.21, 0.93 }, -- Epic
    [5] = { 1,    0.5,  0    }, -- Legendary
    [6] = { 0.9,  0.8,  0.5  }, -- Artifact
    [7] = { 0,    0.8,  1    }, -- Heirloom
}

for i = 0, 7 do
    local key = "quality" .. i
    local qc = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[i]
    if qc then
        colors[key] = MakeColor(qc.r, qc.g, qc.b, 1)
    else
        local fb = QUALITY_FALLBACK[i]
        colors[key] = MakeColor(fb[1], fb[2], fb[3], 1)
    end
end

-------------------------------------------------------------------------------
-- Class colors
-------------------------------------------------------------------------------

if RAID_CLASS_COLORS then
    for className, cc in pairs(RAID_CLASS_COLORS) do
        colors["class_" .. className] = MakeColor(cc.r, cc.g, cc.b, 1)
    end
end

-------------------------------------------------------------------------------
-- Retrieval API
-------------------------------------------------------------------------------

--- Return r, g, b, a for a named color token.
function LDF.GetColor(name)
    local c = colors[name]
    if not c then error("GetColor: unknown token '" .. tostring(name) .. "'", 2) end
    return c[1], c[2], c[3], c[4]
end

--- Return the full color table { r, g, b, a, hex }.
function LDF.GetColorTable(name)
    local c = colors[name]
    if not c then error("GetColorTable: unknown token '" .. tostring(name) .. "'", 2) end
    return c
end

--- Return the WoW hex color string "|cAARRGGBB".
function LDF.GetColorHex(name)
    local c = colors[name]
    if not c then error("GetColorHex: unknown token '" .. tostring(name) .. "'", 2) end
    return c[5]
end

-------------------------------------------------------------------------------
-- Extension API
-------------------------------------------------------------------------------

--- Register a single color token.
function LDF.AddColor(name, r, g, b, a)
    if type(name) ~= "string" or name == "" then
        error("AddColor: 'name' must be a non-empty string", 2)
    end
    colors[name] = MakeColor(r, g, b, a)
end

--- Batch-register color tokens from a table { name = {r, g, b, a}, ... }.
function LDF.AddColors(colorTable)
    if type(colorTable) ~= "table" then
        error("AddColors: expected a table", 2)
    end
    for name, rgba in pairs(colorTable) do
        colors[name] = MakeColor(rgba[1], rgba[2], rgba[3], rgba[4])
    end
end

-------------------------------------------------------------------------------
-- Per-addon accent
-------------------------------------------------------------------------------

--- Register accent color variants for a specific addon.
--- Creates accent_NAME, accentNormal_NAME, and accentHover_NAME tokens.
function LDF.SetAccentColor(addonName, r, g, b)
    if type(addonName) ~= "string" or addonName == "" then
        error("SetAccentColor: 'addonName' must be a non-empty string", 2)
    end
    local key = addonName:upper()
    colors["accent_" .. key]       = MakeColor(r, g, b, 1)
    colors["accentNormal_" .. key] = MakeColor(r, g, b, 0.3)
    colors["accentHover_" .. key]  = MakeColor(r, g, b, 0.6)
end
