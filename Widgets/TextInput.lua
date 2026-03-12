-------------------------------------------------------------------------------
-- TextInput.lua
-- Single-line text input with label and bordered edit box
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local FRAME_HEIGHT = 40
local LABEL_GAP = LDF.spacing.SM

-------------------------------------------------------------------------------
-- Factory: CreateTextInput
-------------------------------------------------------------------------------

function LDF.CreateTextInput(parent, opts)
    if not parent then error("LDF.CreateTextInput: parent required", 2) end

    opts = opts or {}

    local frame = LDF.CreateWidgetFrame(parent)
    frame:SetHeight(FRAME_HEIGHT)

    local inputWidth = opts.width or LDF.dims.INPUT_WIDTH

    -- Label at top
    local label = LDF.CreateFontString(frame, "body", opts.label or "")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

    -- EditBox below label
    local editBox = LDF.CreateBackdropFrame(frame, "EditBox")
    editBox:SetSize(inputWidth, LDF.heights.INPUT)
    editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -LABEL_GAP)
    LDF.ApplyBackdrop(editBox, "input")
    editBox:SetFont(LDF.FONT_PATH, 11, "")
    editBox:SetTextColor(LDF.GetColor("text"))
    editBox:SetTextInsets(4, 4, 0, 0)
    editBox:SetAutoFocus(false)

    if opts.maxLength then
        editBox:SetMaxLetters(opts.maxLength)
    end

    ---------------------------------------------------------------------------
    -- EditBox scripts
    ---------------------------------------------------------------------------
    editBox:SetScript("OnEnterPressed", function(self)
        if not frame._ldf.enabled then return end
        frame:FireValueChanged(self:GetText())
        frame:FireValueCommitted(self:GetText())
        self:ClearFocus()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        if opts.get then
            self:SetText(opts.get() or "")
        end
        self:ClearFocus()
    end)

    editBox:SetScript("OnTabPressed", function(self)
        self:ClearFocus()
    end)

    editBox:SetScript("OnEditFocusGained", function(self)
        if not frame._ldf.enabled then self:ClearFocus() end
    end)

    ---------------------------------------------------------------------------
    -- Widget protocol
    ---------------------------------------------------------------------------

    LDF.ApplyWidgetProtocol(frame, opts)

    function frame:GetValue()
        return frame._ldf.editBox:GetText()
    end

    function frame:SetValue(v)
        frame._ldf.editBox:SetText(v or "")
    end

    function frame:Refresh()
        if opts.get then
            frame._ldf.editBox:SetText(opts.get() or "")
        end
    end

    -- Wrap base SetEnabled to update editBox alpha and label color
    local baseSetEnabled = frame.SetEnabled
    function frame:SetEnabled(state)
        baseSetEnabled(self, state)
        editBox:SetAlpha(state and 1 or 0.5)
        if state then
            label:SetTextColor(LDF.GetColor("text"))
        else
            label:SetTextColor(LDF.GetColor("textDim"))
        end
    end

    -- Tooltip
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", frame.ShowTooltip)
    frame:SetScript("OnLeave", frame.HideTooltip)

    -- Store refs and initialize
    frame._ldf.editBox = editBox
    frame._ldf.labelFS = label
    frame:Refresh()

    return frame
end
