-------------------------------------------------------------------------------
-- Header.lua
-- Section header with bold gold text and horizontal separator
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

-------------------------------------------------------------------------------
-- Factory: CreateHeader
-------------------------------------------------------------------------------

--- Create a display-only section header with title text and separator line.
--- This widget does NOT participate in the widget protocol (no get/set/value).
function LDF.CreateHeader(parent, text)
    if not parent then error("CreateHeader: 'parent' must not be nil", 2) end

    local frame = LDF.CreateWidgetFrame(parent)
    frame:SetHeight(LDF.heights.TITLE)

    -- Gold title text (FRIZQT 14 OUTLINE via "title" preset)
    local fontString = LDF.CreateFontString(frame, "title", text)
    fontString:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    fontString:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    fontString:SetJustifyH("LEFT")

    -- Horizontal separator at bottom edge
    local separator = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    separator:SetHeight(LDF.heights.SEPARATOR)
    separator:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    separator:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    local ar, ag, ab = LDF.GetColor("accentGold")
    separator:SetColorTexture(ar, ag, ab, 0.8)
    LDF.DisablePixelSnap(separator)

    -- Shadow line below separator for depth
    local shadowLine = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    shadowLine:SetTexture(LDF.WHITE8X8)
    shadowLine:SetHeight(LDF.heights.SEPARATOR)
    shadowLine:SetVertexColor(LDF.GetColor("shadow"))
    shadowLine:SetPoint("TOPLEFT", separator, "BOTTOMLEFT")
    shadowLine:SetPoint("BOTTOMRIGHT", separator, "BOTTOMRIGHT", 0, -LDF.heights.SEPARATOR)
    LDF.DisablePixelSnap(shadowLine)

    -- Internal state
    frame._ldf.fontString = fontString
    frame._ldf.separator = separator

    -- Convenience method to update the header text
    function frame:SetText(newText)
        self._ldf.fontString:SetText(newText)
    end

    return frame
end
