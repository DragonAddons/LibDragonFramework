-------------------------------------------------------------------------------
-- Spacing.lua
-- Layout spacing and size constants
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local type = type
local error = error

-------------------------------------------------------------------------------
-- Spacing scale
-------------------------------------------------------------------------------

LDF.spacing = {
    XS  = 2,
    SM  = 4,
    MD  = 8,
    LG  = 12,
    XL  = 16,
    XXL = 24,
}

-------------------------------------------------------------------------------
-- Control heights
-------------------------------------------------------------------------------

LDF.heights = {
    CONTROL_SM = 20,    -- small controls (checkbox box, color swatch)
    CONTROL    = 24,    -- standard control height (buttons, dropdowns)
    CONTROL_LG = 28,    -- large controls
    TAB        = 28,    -- tab button height
    TITLE      = 28,    -- title bar height
    SLIDER     = 17,    -- slider track height
    INPUT      = 22,    -- text input height
    SCROLLBAR  = 14,    -- scrollbar width
    SEPARATOR  = 1,     -- separator line height
}

-------------------------------------------------------------------------------
-- Widget dimensions
-------------------------------------------------------------------------------

LDF.dims = {
    DROPDOWN_WIDTH      = 200,
    DROPDOWN_ITEM       = 20,
    DROPDOWN_MAX_HEIGHT = 200,
    EDITBOX_WIDTH       = 50,   -- inline editbox on slider
    SWATCH_SIZE         = 24,   -- color picker swatch
    BUTTON_WIDTH        = 120,  -- default button width
    INPUT_WIDTH         = 200,  -- default text input width
    SCROLL_STEP         = 20,   -- mouse wheel scroll amount
}

-------------------------------------------------------------------------------
-- Convenience functions
-------------------------------------------------------------------------------

--- Return spacing value by name, or pass through a raw number.
--- @param size string|number  spacing key ("XS".."XXL") or numeric value
--- @return number
function LDF.Pad(size)
    if type(size) == "number" then return size end
    local value = LDF.spacing[size]
    if not value then
        error("Pad: unknown spacing key '" .. tostring(size) .. "'", 2)
    end
    return value
end

--- Return control height by name, or pass through a raw number.
--- @param size string|number  height key or numeric value
--- @return number
function LDF.ControlHeight(size)
    if type(size) == "number" then return size end
    local value = LDF.heights[size]
    if not value then
        error("ControlHeight: unknown height key '" .. tostring(size) .. "'", 2)
    end
    return value
end
