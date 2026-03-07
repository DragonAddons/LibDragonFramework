-------------------------------------------------------------------------------
-- Button.lua
-- Styled action button with tooltip support
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

-- WoW API cache
local CreateFrame = CreateFrame

-------------------------------------------------------------------------------
-- Factory: CreateButton
-------------------------------------------------------------------------------

function LDF.CreateButton(parent, opts)
    if not parent then error("LDF.CreateButton: parent required", 2) end

    opts = opts or {}
    local width = opts.width or LDF.dims.BUTTON_WIDTH

    ---------------------------------------------------------------------------
    -- Create flat button
    ---------------------------------------------------------------------------

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn._ldf = {}
    LDF.DisablePixelSnap(btn)
    btn:SetSize(width, LDF.heights.CONTROL)

    LDF.ApplyBackdrop(btn, "button")

    -- Label text
    local text = LDF.CreateFontString(btn, "body", "")
    text:SetPoint("CENTER", 0, 0)
    btn._ldf.text = text

    -- Hover highlight
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.08)

    -- Pressed visual offset
    btn:SetScript("OnMouseDown", function(self)
        if not self._ldf.enabled then return end
        self._ldf.text:SetPoint("CENTER", 1, -1)
    end)
    btn:SetScript("OnMouseUp", function(self)
        self._ldf.text:SetPoint("CENTER", 0, 0)
    end)

    ---------------------------------------------------------------------------
    -- SetText
    ---------------------------------------------------------------------------

    function btn:SetText(newText)
        self._ldf.text:SetText(newText)
    end

    btn:SetText(opts.text or "")

    ---------------------------------------------------------------------------
    -- Base mixin (enable/tooltip) - NOT full widget protocol
    ---------------------------------------------------------------------------

    LDF.ApplyBaseMixin(btn)
    btn:InitBase(opts)

    ---------------------------------------------------------------------------
    -- Click handler
    ---------------------------------------------------------------------------

    btn:SetScript("OnClick", function(self)
        if not self:IsEnabled() then return end
        if opts.onClick then opts.onClick() end
    end)

    ---------------------------------------------------------------------------
    -- Tooltip
    ---------------------------------------------------------------------------

    btn:SetScript("OnEnter", btn.ShowTooltip)
    btn:SetScript("OnLeave", btn.HideTooltip)

    return btn
end
