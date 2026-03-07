-------------------------------------------------------------------------------
-- Slider.lua
-- Horizontal slider with label, min/max labels, and editable value display
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

-- WoW API cache
local CreateFrame = CreateFrame
local format = string.format

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FRAME_HEIGHT = 55
local SM = LDF.spacing.SM
local MD = LDF.spacing.MD
local EDITBOX_WIDTH = LDF.dims.EDITBOX_WIDTH
local SLIDER_HEIGHT = LDF.heights.SLIDER

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function FormatValue(value, opts)
    if opts.isPercent then
        return format((opts.format or "%.1f"), value * 100) .. "%"
    end
    return format((opts.format or "%.1f"), value)
end

-------------------------------------------------------------------------------
-- Factory: CreateSlider
-------------------------------------------------------------------------------

function LDF.CreateSlider(parent, opts)
    if not parent then error("LDF.CreateSlider: parent required", 2) end

    opts = opts or {}

    local minVal = opts.min or 0
    local maxVal = opts.max or 100
    local step = opts.step or 1

    local frame = LDF.CreateWidgetFrame(parent)
    frame:SetHeight(FRAME_HEIGHT)
    frame._ldf.isInternal = false
    frame._ldf.currentValue = minVal

    ---------------------------------------------------------------------------
    -- Label
    ---------------------------------------------------------------------------

    local label = LDF.CreateFontString(frame, "body", opts.label or "")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    label:SetJustifyH("LEFT")

    ---------------------------------------------------------------------------
    -- Slider
    ---------------------------------------------------------------------------

    local slider = CreateFrame("Slider", nil, frame, "BackdropTemplate")
    slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -SM)
    slider:SetPoint("RIGHT", frame, "RIGHT", -(EDITBOX_WIDTH + MD), 0)
    slider:SetHeight(SLIDER_HEIGHT)
    LDF.ApplyBackdrop(slider, "widget")
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    -- Flat thumb
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(LDF.GetColor("accentGold"))
    thumb:SetSize(12, 18)
    LDF.DisablePixelSnap(thumb)
    slider:SetThumbTexture(thumb)

    ---------------------------------------------------------------------------
    -- Min / Max labels
    ---------------------------------------------------------------------------

    local minLabel = LDF.CreateFontString(frame, "meta", FormatValue(minVal, opts))
    minLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -SM)

    local maxLabel = LDF.CreateFontString(frame, "meta", FormatValue(maxVal, opts))
    maxLabel:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -SM)

    ---------------------------------------------------------------------------
    -- EditBox
    ---------------------------------------------------------------------------

    local editBox = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    editBox:SetSize(EDITBOX_WIDTH, 20)
    editBox:SetPoint("LEFT", slider, "RIGHT", MD, 0)
    LDF.ApplyBackdrop(editBox, "input")
    editBox:SetFont(LDF.FONT_PATH, 11, "")
    editBox:SetTextColor(LDF.GetColor("text"))
    editBox:SetJustifyH("CENTER")
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(10)

    ---------------------------------------------------------------------------
    -- Internal: update editbox text from current value
    ---------------------------------------------------------------------------

    local function UpdateEditBoxText(value)
        editBox:SetText(FormatValue(value, opts))
    end

    ---------------------------------------------------------------------------
    -- Two-phase commit: Slider scripts
    ---------------------------------------------------------------------------

    slider:SetScript("OnValueChanged", function(_self, raw)
        if not frame._ldf.enabled then return end
        local rounded = LDF.Snap(raw, step)
        rounded = LDF.Clamp(rounded, minVal, maxVal)
        frame._ldf.currentValue = rounded
        UpdateEditBoxText(rounded)
        if not frame._ldf.isInternal then
            frame:FireValueChanged(rounded)
        end
    end)

    slider:SetScript("OnMouseUp", function()
        if not frame._ldf.enabled then return end
        frame:FireValueCommitted(frame._ldf.currentValue)
    end)

    ---------------------------------------------------------------------------
    -- Two-phase commit: EditBox scripts
    ---------------------------------------------------------------------------

    editBox:SetScript("OnEnterPressed", function(self)
        local raw = tonumber(self:GetText())
        if not raw then
            UpdateEditBoxText(frame._ldf.currentValue)
            self:ClearFocus()
            return
        end
        if opts.isPercent then raw = raw / 100 end
        local clamped = LDF.Clamp(LDF.Snap(raw, step), minVal, maxVal)
        frame._ldf.currentValue = clamped
        frame._ldf.isInternal = true
        slider:SetValue(clamped)
        frame._ldf.isInternal = false
        UpdateEditBoxText(clamped)
        frame:FireValueChanged(clamped)
        frame:FireValueCommitted(clamped)
        self:ClearFocus()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        UpdateEditBoxText(frame._ldf.currentValue)
        self:ClearFocus()
    end)

    editBox:SetScript("OnTabPressed", function(self)
        self:ClearFocus()
    end)

    ---------------------------------------------------------------------------
    -- Widget protocol
    ---------------------------------------------------------------------------

    LDF.ApplyWidgetProtocol(frame, opts)

    ---------------------------------------------------------------------------
    -- GetValue / SetValue
    ---------------------------------------------------------------------------

    function frame:GetValue()
        return self._ldf.currentValue
    end

    function frame:SetValue(v)
        local clamped = LDF.Clamp(LDF.Snap(v, step), minVal, maxVal)
        self._ldf.currentValue = clamped
        self._ldf.isInternal = true
        slider:SetValue(clamped)
        self._ldf.isInternal = false
        UpdateEditBoxText(clamped)
    end

    ---------------------------------------------------------------------------
    -- Refresh override
    ---------------------------------------------------------------------------

    function frame:Refresh()
        if opts.get then
            local v = opts.get() or minVal
            local clamped = LDF.Clamp(LDF.Snap(v, step), minVal, maxVal)
            self._ldf.currentValue = clamped
            self._ldf.isInternal = true
            slider:SetValue(clamped)
            self._ldf.isInternal = false
            UpdateEditBoxText(clamped)
        end
    end

    ---------------------------------------------------------------------------
    -- SetEnabled override
    ---------------------------------------------------------------------------

    local baseSetEnabled = frame.SetEnabled
    function frame:SetEnabled(state)
        baseSetEnabled(self, state)
        slider:EnableMouse(state)
        editBox:EnableMouse(state)
        if state then
            label:SetTextColor(LDF.GetColor("text"))
            editBox:SetTextColor(LDF.GetColor("text"))
        else
            label:SetTextColor(LDF.GetColor("textDim"))
            editBox:SetTextColor(LDF.GetColor("textDim"))
        end
    end

    ---------------------------------------------------------------------------
    -- Tooltip
    ---------------------------------------------------------------------------

    frame:EnableMouse(true)
    frame:SetScript("OnEnter", frame.ShowTooltip)
    frame:SetScript("OnLeave", frame.HideTooltip)

    ---------------------------------------------------------------------------
    -- Internal state
    ---------------------------------------------------------------------------

    frame._ldf.slider = slider
    frame._ldf.editBox = editBox
    frame._ldf.label = label

    ---------------------------------------------------------------------------
    -- Initialize
    ---------------------------------------------------------------------------

    frame:Refresh()

    return frame
end
