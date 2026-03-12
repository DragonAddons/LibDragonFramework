-------------------------------------------------------------------------------
-- Typography.lua
-- Font presets and FontString factory
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

-- WoW API cache
local CreateFont = CreateFont
local error = error
local type = type
local pcall = pcall

-------------------------------------------------------------------------------
-- Font path
-------------------------------------------------------------------------------

local FONT_PATH = "Fonts\\FRIZQT__.TTF"
LDF.FONT_PATH = FONT_PATH

-------------------------------------------------------------------------------
-- LSM integration (optional)
-------------------------------------------------------------------------------

local LSM = nil
if LibStub then
    local ok, lib = pcall(LibStub, "LibSharedMedia-3.0", true)
    if ok and lib then LSM = lib end
end
LDF.LSM = LSM

local function ResolveFontPath(pathOrKey)
    if LSM and LSM:IsValid("font", pathOrKey) then
        return LSM:Fetch("font", pathOrKey)
    end
    return pathOrKey
end

-------------------------------------------------------------------------------
-- Preset colors
-------------------------------------------------------------------------------

local PRESET_COLORS = {
    title = { 1, 0.82, 0 },
    body  = { 1, 1, 1 },
    small = { 0.7, 0.7, 0.7 },
    meta  = { 0.5, 0.5, 0.5 },
}

local SHADOW = { 0, 0, 0, 1, 1, -1 } -- r, g, b, a, offsetX, offsetY

-------------------------------------------------------------------------------
-- Font presets
-------------------------------------------------------------------------------

LDF.fonts = {
    title = { FONT_PATH, 14, "" },
    body  = { FONT_PATH, 13, "" },
    small = { FONT_PATH, 11, "" },
    meta  = { FONT_PATH, 10, "" },
}

-------------------------------------------------------------------------------
-- Font object cache
-------------------------------------------------------------------------------

local fontObjectCache = {}

local function GetFontObject(presetName)
    if fontObjectCache[presetName] then return fontObjectCache[presetName] end

    local preset = LDF.fonts[presetName]
    if not preset then return nil end

    local fontObj = CreateFont("LDF_Font_" .. presetName)
    fontObj:SetFont(ResolveFontPath(preset[1]), preset[2], preset[3])

    local color = PRESET_COLORS[presetName]
    if color then fontObj:SetTextColor(color[1], color[2], color[3]) end

    fontObj:SetShadowColor(SHADOW[1], SHADOW[2], SHADOW[3], SHADOW[4])
    fontObj:SetShadowOffset(SHADOW[5], SHADOW[6])

    fontObjectCache[presetName] = fontObj
    return fontObj
end

-------------------------------------------------------------------------------
-- Internal apply
-------------------------------------------------------------------------------

local function ApplyPreset(fs, presetName)
    local preset = LDF.fonts[presetName]
    if not preset then
        error("ApplyPreset: unknown font preset \"" .. tostring(presetName) .. "\"", 3)
    end

    fs:SetFont(ResolveFontPath(preset[1]), preset[2], preset[3])

    local color = PRESET_COLORS[presetName]
    if color then fs:SetTextColor(color[1], color[2], color[3]) end

    fs:SetShadowColor(SHADOW[1], SHADOW[2], SHADOW[3], SHADOW[4])
    fs:SetShadowOffset(SHADOW[5], SHADOW[6])
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function LDF.CreateFontString(parent, preset, text)
    if not parent then error("CreateFontString: 'parent' must not be nil", 2) end

    preset = preset or "body"
    if not LDF.fonts[preset] then
        error("CreateFontString: unknown font preset \"" .. tostring(preset) .. "\"", 2)
    end

    local fs = parent:CreateFontString(nil, "OVERLAY")
    ApplyPreset(fs, preset)

    if text then fs:SetText(text) end
    return fs
end

function LDF.SetFontPreset(fontString, preset)
    if not fontString then error("SetFontPreset: 'fontString' must not be nil", 2) end
    if not preset then error("SetFontPreset: 'preset' must not be nil", 2) end
    if not LDF.fonts[preset] then
        error("SetFontPreset: unknown font preset \"" .. tostring(preset) .. "\"", 2)
    end

    ApplyPreset(fontString, preset)
end

function LDF.AddFontPreset(name, path, size, flags, r, g, b)
    if type(name) ~= "string" or name == "" then
        error("AddFontPreset: 'name' must be a non-empty string", 2)
    end

    LDF.fonts[name] = { path, size, flags or "" }
    if r and g and b then
        PRESET_COLORS[name] = { r, g, b }
    end

    -- Invalidate cached font object so it rebuilds on next access
    fontObjectCache[name] = nil
end

function LDF.GetFontObject(presetName)
    if not presetName then error("GetFontObject: 'presetName' must not be nil", 2) end
    if not LDF.fonts[presetName] then
        error("GetFontObject: unknown font preset \"" .. tostring(presetName) .. "\"", 2)
    end
    return GetFontObject(presetName)
end
