std = "lua51"
max_line_length = 120
codes = true

ignore = {
    "212/self",
    "211/LIB_NAME",
    "211/_.*",
    "213/_.*",
}

globals = {
    "LibDragonFramework",
    "LDF_BaseMixin",
}

read_globals = {
    -- Lua builtins
    "table", "string", "math", "pairs", "ipairs", "type", "tostring", "tonumber",
    "select", "unpack", "wipe", "strsplit", "strmatch", "strtrim", "format",
    "pcall", "sort", "next", "rawset", "rawget", "setmetatable", "getmetatable",
    "error", "assert",
    -- WoW API
    "CreateFrame", "CreateFont", "GetTime", "UIParent", "GameTooltip", "PlaySound", "SOUNDKIT",
    "C_Timer", "_G", "GetPhysicalScreenSize", "Mixin", "BackdropTemplateMixin",
    "STANDARD_TEXT_FONT", "UISpecialFrames", "GameFontNormal", "GameFontHighlight",
    "ColorPickerFrame", "StaticPopupDialogs", "StaticPopup_Show", "ShowUIPanel",
    "ITEM_QUALITY_COLORS", "RAID_CLASS_COLORS",
    "InCombatLockdown",
    "GetItemInfo", "GetCursorInfo", "ClearCursor",
    -- Libs
    "LibStub",
}

files = {
    -- Classic API requires setting fields on ColorPickerFrame directly
    ["Widgets/ColorPicker.lua"] = {
        globals = { "ColorPickerFrame" },
    },
}
