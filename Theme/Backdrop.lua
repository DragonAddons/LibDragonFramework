-------------------------------------------------------------------------------
-- Backdrop.lua
-- Shared backdrop recipes for consistent styling
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

-- WoW API cache
local BackdropTemplateMixin = BackdropTemplateMixin
local Mixin = Mixin
local type = type
local error = error
local tostring = tostring

-------------------------------------------------------------------------------
-- Backdrop mixin support (Retail 9.0+)
-------------------------------------------------------------------------------

local function EnsureBackdrop(frame)
    if BackdropTemplateMixin then
        Mixin(frame, BackdropTemplateMixin)
    end
end

-------------------------------------------------------------------------------
-- Named recipes
-------------------------------------------------------------------------------

local RECIPES = {
    panel  = { bg = "bg1",  border = "border",      edgeSize = 1 },
    widget = { bg = "bg2",  border = "border",      edgeSize = 1 },
    input  = { bg = "bg2",  border = "borderLight",  edgeSize = 1 },
    button = { bg = "bg2",  border = "border",      edgeSize = 1 },
    dark   = { bg = "bg0",  border = "border",      edgeSize = 1 },
}

-------------------------------------------------------------------------------
-- Internal helpers
-------------------------------------------------------------------------------

local function ResolveRecipe(style)
    if type(style) == "table" then return style end
    local recipe = RECIPES[style]
    if not recipe then
        error("ApplyBackdrop: unknown style '" .. tostring(style) .. "'", 3)
    end
    return recipe
end

local function ApplyBackdropToFrame(frame, recipe, insets)
    EnsureBackdrop(frame)

    local backdrop = {
        bgFile   = LDF.WHITE8X8,
        edgeFile = LDF.WHITE8X8,
        edgeSize = recipe.edgeSize,
    }
    if insets then
        backdrop.insets = {
            left   = insets.left   or insets[1] or 0,
            right  = insets.right  or insets[2] or 0,
            top    = insets.top    or insets[3] or 0,
            bottom = insets.bottom or insets[4] or 0,
        }
    end

    frame:SetBackdrop(backdrop)
    frame:SetBackdropColor(LDF.GetColor(recipe.bg))
    frame:SetBackdropBorderColor(LDF.GetColor(recipe.border))

    frame._ldf = frame._ldf or {}
    frame._ldf._backdropStyle = recipe

    LDF.SetBorderWidth(frame, recipe.edgeSize)
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

--- Apply a named backdrop recipe (or custom table) to a frame.
--- @param frame table  frame to style
--- @param style string|table  recipe name or { bg, border, edgeSize }
function LDF.ApplyBackdrop(frame, style)
    if not frame then error("ApplyBackdrop: 'frame' must not be nil", 2) end
    if not style then error("ApplyBackdrop: 'style' must not be nil", 2) end

    local recipe = ResolveRecipe(style)
    ApplyBackdropToFrame(frame, recipe)
end

--- Apply a named backdrop recipe with custom insets.
--- @param frame table   frame to style
--- @param style string|table  recipe name or { bg, border, edgeSize }
--- @param insets table  { left, right, top, bottom } padding
function LDF.ApplyBackdropInsets(frame, style, insets)
    if not frame then error("ApplyBackdropInsets: 'frame' must not be nil", 2) end
    if not style then error("ApplyBackdropInsets: 'style' must not be nil", 2) end
    if not insets then error("ApplyBackdropInsets: 'insets' must not be nil", 2) end

    local recipe = ResolveRecipe(style)
    ApplyBackdropToFrame(frame, recipe, insets)
end

--- Re-apply the stored backdrop recipe after theme changes.
--- @param frame table  frame whose backdrop should be refreshed
function LDF.RefreshBackdrop(frame)
    if not frame then error("RefreshBackdrop: 'frame' must not be nil", 2) end

    local data = frame._ldf
    if not data or not data._backdropStyle then return end

    ApplyBackdropToFrame(frame, data._backdropStyle)
end

--- Add hover color effects to a frame with an existing backdrop.
--- @param frame table             frame to enhance
--- @param hoverBorderColor string|nil  color token for hover border
--- @param hoverBgColor string|nil      color token for hover background
function LDF.SetBackdropHighlight(frame, hoverBorderColor, hoverBgColor)
    if not frame then error("SetBackdropHighlight: 'frame' must not be nil", 2) end

    frame._ldf = frame._ldf or {}
    frame._ldf._hoverBorder = hoverBorderColor
    frame._ldf._hoverBg = hoverBgColor

    frame:HookScript("OnEnter", function(self)
        if hoverBorderColor then
            self:SetBackdropBorderColor(LDF.GetColor(hoverBorderColor))
        end
        if hoverBgColor then
            self:SetBackdropColor(LDF.GetColor(hoverBgColor))
        end
    end)

    frame:HookScript("OnLeave", function(self)
        local data = self._ldf
        if not data or not data._backdropStyle then return end
        local recipe = data._backdropStyle
        self:SetBackdropBorderColor(LDF.GetColor(recipe.border))
        self:SetBackdropColor(LDF.GetColor(recipe.bg))
    end)
end
