-------------------------------------------------------------------------------
-- Glow.lua
-- Soft shadow and glow effects for frame depth
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

-- WoW API cache
local CreateFrame = CreateFrame
local error = error
local math_max = math.max
local BackdropTemplateMixin = BackdropTemplateMixin
local Mixin = Mixin

-------------------------------------------------------------------------------
-- Glow backdrop (uses WHITE8X8 with larger edgeSize for soft shadow)
-------------------------------------------------------------------------------

local GLOW_EDGE_SIZE = 6
local GLOW_INSET = 4

local function CreateGlowBackdrop(edgeSize)
    return {
        edgeFile = LDF.WHITE8X8,
        edgeSize = edgeSize,
        insets = {
            left   = GLOW_INSET,
            right  = GLOW_INSET,
            top    = GLOW_INSET,
            bottom = GLOW_INSET,
        },
    }
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

--- Create a soft shadow glow behind a frame.
--- @param parent table  the frame to wrap with a glow
--- @param colorToken string|nil  color token for the glow (default "shadow")
--- @param size number|nil  glow outset in pixels (default 3)
--- @return table  the glow frame
function LDF.CreateGlow(parent, colorToken, size)
    if not parent then error("CreateGlow: 'parent' must not be nil", 2) end

    colorToken = colorToken or "shadow"
    size = size or 3

    local glow = CreateFrame("Frame", nil, parent)
    if BackdropTemplateMixin then
        Mixin(glow, BackdropTemplateMixin)
    end

    glow:SetFrameLevel(math_max(0, parent:GetFrameLevel() - 1))
    glow:SetPoint("TOPLEFT", parent, "TOPLEFT", -size, size)
    glow:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", size, -size)

    glow:SetBackdrop(CreateGlowBackdrop(GLOW_EDGE_SIZE))
    -- Edge-only backdrop (no bgFile); border color is the glow
    glow:SetBackdropBorderColor(LDF.GetColor(colorToken))

    parent._ldf = parent._ldf or {}
    parent._ldf._glow = glow

    return glow
end

--- Show or create the glow on a frame.
--- @param frame table  target frame
function LDF.ShowGlow(frame)
    if not frame then error("ShowGlow: 'frame' must not be nil", 2) end

    local data = frame._ldf
    if data and data._glow then
        data._glow:Show()
    end
end

--- Hide the glow on a frame.
--- @param frame table  target frame
function LDF.HideGlow(frame)
    if not frame then error("HideGlow: 'frame' must not be nil", 2) end

    local data = frame._ldf
    if data and data._glow then
        data._glow:Hide()
    end
end
