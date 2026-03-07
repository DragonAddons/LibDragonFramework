-------------------------------------------------------------------------------
-- Description.lua
-- Word-wrapped gray description text block
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local DEFAULT_HEIGHT = 20
local PADDING_BOTTOM = LDF.spacing.SM

-------------------------------------------------------------------------------
-- Helper
-------------------------------------------------------------------------------

local function UpdateHeight(frame)
    local textHeight = frame._ldf.fontString:GetStringHeight() or 11
    frame:SetHeight(textHeight + PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Factory: CreateDescription
-------------------------------------------------------------------------------

--- Create a display-only word-wrapped description text block.
--- This widget does NOT participate in the widget protocol (no get/set/value).
function LDF.CreateDescription(parent, text)
    if not parent then error("CreateDescription: 'parent' must not be nil", 2) end

    local frame = LDF.CreateWidgetFrame(parent)
    frame:SetHeight(DEFAULT_HEIGHT)

    -- Gray body text (FRIZQT 11 via "small" preset)
    local fontString = LDF.CreateFontString(frame, "small", text)
    fontString:SetWordWrap(true)
    fontString:SetNonSpaceWrap(true)
    fontString:SetJustifyH("LEFT")
    fontString:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    fontString:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

    -- Internal state
    frame._ldf.fontString = fontString

    -- Recalculate height when frame resizes or becomes visible
    frame:SetScript("OnSizeChanged", UpdateHeight)
    frame:SetScript("OnShow", UpdateHeight)

    -- Convenience method to update description text
    function frame:SetText(newText)
        self._ldf.fontString:SetText(newText)
        UpdateHeight(self)
    end

    return frame
end
