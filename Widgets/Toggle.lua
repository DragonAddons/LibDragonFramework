-------------------------------------------------------------------------------
-- Toggle.lua
-- Checkbox toggle with label and optional tooltip
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

-- WoW API cache
local CreateFrame = CreateFrame

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local BOX_SIZE = LDF.heights.CONTROL_SM
local LABEL_OFFSET = LDF.spacing.MD

-------------------------------------------------------------------------------
-- Factory: CreateToggle
-------------------------------------------------------------------------------

function LDF.CreateToggle(parent, opts)
    if not parent then error("LDF.CreateToggle: parent required", 2) end

    opts = opts or {}

    local frame = LDF.CreateWidgetFrame(parent)
    frame:SetHeight(LDF.heights.CONTROL)

    ---------------------------------------------------------------------------
    -- Checkbox box
    ---------------------------------------------------------------------------

    local box = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    box:SetSize(BOX_SIZE, BOX_SIZE)
    box:SetPoint("LEFT", frame, "LEFT", 0, 0)
    LDF.ApplyBackdrop(box, "widget")

    -- Check fill (flat gold indicator)
    local checkFill = box:CreateTexture(nil, "OVERLAY")
    checkFill:SetPoint("TOPLEFT", box, "TOPLEFT", 3, -3)
    checkFill:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
    checkFill:SetColorTexture(LDF.GetColor("accentGold"))
    LDF.DisablePixelSnap(checkFill)
    checkFill:Hide()

    -- Highlight on hover
    local highlight = box:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.08)

    ---------------------------------------------------------------------------
    -- Label
    ---------------------------------------------------------------------------

    local label = LDF.CreateFontString(frame, "body", opts.label or "")
    label:SetPoint("LEFT", box, "RIGHT", LABEL_OFFSET, 0)

    ---------------------------------------------------------------------------
    -- Internal state
    ---------------------------------------------------------------------------

    frame._ldf.checked = false
    frame._ldf.box = box
    frame._ldf.checkFill = checkFill
    frame._ldf.label = label

    ---------------------------------------------------------------------------
    -- GetValue / SetValue
    ---------------------------------------------------------------------------

    function frame:GetValue()
        return self._ldf.checked
    end

    function frame:SetValue(v)
        self._ldf.checked = not not v
        checkFill:SetShown(self._ldf.checked)
    end

    ---------------------------------------------------------------------------
    -- Widget protocol
    ---------------------------------------------------------------------------

    LDF.ApplyWidgetProtocol(frame, opts)

    -- Override Refresh to update visual from opts.get
    function frame:Refresh()
        if opts.get then
            self._ldf.checked = not not opts.get()
            checkFill:SetShown(self._ldf.checked)
        end
    end

    -- Wrap SetEnabled to update label color
    local baseSetEnabled = frame.SetEnabled
    function frame:SetEnabled(state)
        baseSetEnabled(self, state)
        if state then
            label:SetTextColor(LDF.GetColor("text"))
        else
            label:SetTextColor(LDF.GetColor("textDim"))
        end
    end

    ---------------------------------------------------------------------------
    -- Click handler
    ---------------------------------------------------------------------------

    frame:EnableMouse(true)
    frame:SetScript("OnMouseUp", function(self)
        if not self:IsEnabled() then return end
        self._ldf.checked = not self._ldf.checked
        checkFill:SetShown(self._ldf.checked)
        self:FireValueChanged(self._ldf.checked)
    end)

    ---------------------------------------------------------------------------
    -- Tooltip
    ---------------------------------------------------------------------------

    frame:SetScript("OnEnter", frame.ShowTooltip)
    frame:SetScript("OnLeave", frame.HideTooltip)

    ---------------------------------------------------------------------------
    -- Initialize
    ---------------------------------------------------------------------------

    frame:Refresh()

    return frame
end
