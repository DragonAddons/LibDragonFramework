-------------------------------------------------------------------------------
-- ColorPicker.lua
-- Color swatch that opens the WoW ColorPickerFrame (Retail + Classic)
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local ColorPickerFrame = ColorPickerFrame
local ShowUIPanel = ShowUIPanel
local type = type

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local SWATCH_SIZE = LDF.dims.SWATCH_SIZE
local LABEL_OFFSET = LDF.spacing.MD

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function UpdateSwatch(swatch, r, g, b, a)
    swatch:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
end

-------------------------------------------------------------------------------
-- Open ColorPickerFrame - Retail API (10.2.5+)
-------------------------------------------------------------------------------

local function OpenRetailPicker(r, g, b, a, hasAlpha, swatchFunc, cancelFunc, opacityFunc)
    local info = {}
    info.r = r
    info.g = g
    info.b = b
    info.hasOpacity = hasAlpha
    info.opacity = hasAlpha and (1 - (a or 1)) or nil
    info.swatchFunc = swatchFunc
    info.cancelFunc = cancelFunc
    if hasAlpha then
        info.opacityFunc = opacityFunc
    end
    ColorPickerFrame:SetupColorPickerAndShow(info)
end

-------------------------------------------------------------------------------
-- Open ColorPickerFrame - Classic API
-------------------------------------------------------------------------------

local function OpenClassicPicker(r, g, b, a, hasAlpha, swatchFunc, cancelFunc, opacityFunc)
    ColorPickerFrame.hasOpacity = hasAlpha
    ColorPickerFrame.opacity = hasAlpha and (1 - (a or 1)) or nil
    ColorPickerFrame.previousValues = { r, g, b, a }
    ColorPickerFrame.func = swatchFunc
    ColorPickerFrame.cancelFunc = cancelFunc
    if hasAlpha then
        ColorPickerFrame.opacityFunc = opacityFunc
    else
        ColorPickerFrame.opacityFunc = nil
    end
    ColorPickerFrame:SetColorRGB(r, g, b)
    ShowUIPanel(ColorPickerFrame)
end

-------------------------------------------------------------------------------
-- Build callbacks for picker interaction
-------------------------------------------------------------------------------

local function BuildCallbacks(frame, opts, prevColor)
    local swatchFunc = function()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        local newA = 1
        if opts.hasAlpha then
            newA = 1 - (ColorPickerFrame.GetColorAlpha
                and ColorPickerFrame:GetColorAlpha()
                or ColorPickerFrame.opacity or 0)
        end
        UpdateSwatch(frame._ldf.swatch, newR, newG, newB, newA)
        frame:FireValueChanged(newR, newG, newB, newA)
    end

    local cancelFunc = function(prev)
        local pR, pG, pB, pA
        if prev and type(prev) == "table" then
            pR = prev.r or prev[1]
            pG = prev.g or prev[2]
            pB = prev.b or prev[3]
            pA = prev.a or prev[4]
        else
            pR, pG, pB, pA = prevColor[1], prevColor[2], prevColor[3], prevColor[4]
        end
        UpdateSwatch(frame._ldf.swatch, pR, pG, pB, pA or 1)
        frame:FireValueChanged(pR, pG, pB, pA or 1)
    end

    local opacityFunc = function()
        local oR, oG, oB = ColorPickerFrame:GetColorRGB()
        local oA = 1 - (ColorPickerFrame.GetColorAlpha
            and ColorPickerFrame:GetColorAlpha()
            or ColorPickerFrame.opacity or 0)
        UpdateSwatch(frame._ldf.swatch, oR, oG, oB, oA)
        frame:FireValueChanged(oR, oG, oB, oA)
    end

    return swatchFunc, cancelFunc, opacityFunc
end

-------------------------------------------------------------------------------
-- Factory: CreateColorPicker
-------------------------------------------------------------------------------

function LDF.CreateColorPicker(parent, opts)
    if not parent then error("LDF.CreateColorPicker: parent required", 2) end

    opts = opts or {}

    local frame = LDF.CreateWidgetFrame(parent)
    frame:SetHeight(LDF.heights.CONTROL)

    ---------------------------------------------------------------------------
    -- Label
    ---------------------------------------------------------------------------

    local label = LDF.CreateFontString(frame, "body", opts.label or "")
    label:SetPoint("LEFT", frame, "LEFT", 0, 0)

    ---------------------------------------------------------------------------
    -- Border frame around swatch
    ---------------------------------------------------------------------------

    local border = LDF.CreateBackdropFrame(frame, "Frame")
    border:SetSize(SWATCH_SIZE + 2, SWATCH_SIZE + 2)
    border:SetPoint("LEFT", label, "RIGHT", LABEL_OFFSET, 0)
    LDF.ApplyBackdrop(border, "widget")
    border:SetBackdropColor(0, 0, 0, 0)

    ---------------------------------------------------------------------------
    -- Swatch texture
    ---------------------------------------------------------------------------

    local swatch = border:CreateTexture(nil, "ARTWORK")
    swatch:SetPoint("TOPLEFT", border, "TOPLEFT", 1, -1)
    swatch:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, 1)
    LDF.DisablePixelSnap(swatch)

    local initR, initG, initB, initA = 1, 1, 1, 1
    if opts.get then
        initR, initG, initB, initA = opts.get()
        initA = initA or 1
    end
    UpdateSwatch(swatch, initR, initG, initB, initA)

    ---------------------------------------------------------------------------
    -- Internal state
    ---------------------------------------------------------------------------

    frame._ldf.swatch = swatch
    frame._ldf.border = border
    frame._ldf.labelFS = label

    ---------------------------------------------------------------------------
    -- Click handler
    ---------------------------------------------------------------------------

    border:EnableMouse(true)
    border:SetScript("OnMouseUp", function()
        if not frame:IsEnabled() then return end

        local r, g, b, a = 1, 1, 1, 1
        if opts.get then
            r, g, b, a = opts.get()
            a = a or 1
        end

        local prevColor = { r, g, b, a }
        local swatchFunc, cancelFunc, opacityFunc = BuildCallbacks(frame, opts, prevColor)

        if ColorPickerFrame.SetupColorPickerAndShow then
            OpenRetailPicker(r, g, b, a, opts.hasAlpha, swatchFunc, cancelFunc, opacityFunc)
        else
            OpenClassicPicker(r, g, b, a, opts.hasAlpha, swatchFunc, cancelFunc, opacityFunc)
        end
    end)

    ---------------------------------------------------------------------------
    -- Widget protocol
    ---------------------------------------------------------------------------

    LDF.ApplyWidgetProtocol(frame, opts)

    ---------------------------------------------------------------------------
    -- GetValue / SetValue (multi-return)
    ---------------------------------------------------------------------------

    function frame:GetValue()
        if opts.get then return opts.get() end
        return 1, 1, 1, 1
    end

    function frame:SetValue(r, g, b, a)
        a = a or 1
        UpdateSwatch(self._ldf.swatch, r, g, b, a)
    end

    ---------------------------------------------------------------------------
    -- Refresh override (multi-return aware)
    ---------------------------------------------------------------------------

    function frame:Refresh()
        if not opts.get then return end
        local r, g, b, a = opts.get()
        UpdateSwatch(self._ldf.swatch, r, g, b, a or 1)
    end

    ---------------------------------------------------------------------------
    -- SetEnabled override
    ---------------------------------------------------------------------------

    local baseSetEnabled = frame.SetEnabled
    function frame:SetEnabled(state)
        baseSetEnabled(self, state)
        if state then
            label:SetTextColor(LDF.GetColor("text"))
        else
            label:SetTextColor(LDF.GetColor("textDim"))
        end
        border:SetAlpha(state and 1 or 0.5)
    end

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
