-------------------------------------------------------------------------------
-- Bindings.lua
-- Unified widget protocol and opts contract wiring
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local CreateFrame = CreateFrame
local pairs = pairs
local type = type

-------------------------------------------------------------------------------
-- Widget Protocol
--
-- Every LDF value widget must implement:
--   widget:SetValue(value)          - set programmatically, update visuals
--   widget:GetValue()               - return current value
--   widget:SetOnValueChanged(fn)    - live/preview callback (from BaseMixin)
--   widget:SetOnValueCommitted(fn)  - final callback (from BaseMixin)
--   widget:SetEnabled(enabled)      - enable/disable (from BaseMixin)
--   widget:SetLabel(text)           - update label (from BaseMixin)
--   widget:Refresh()                - re-read from opts.get() and update visuals
--   widget:UpdatePixels()           - pixel-perfect recalculation (PixelPerfect)
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ApplyWidgetProtocol - wire opts contract into the widget protocol
-------------------------------------------------------------------------------

function LDF.ApplyWidgetProtocol(widget, opts)
    if not widget then error("ApplyWidgetProtocol: 'widget' must not be nil", 2) end

    opts = opts or {}

    LDF.ApplyBaseMixin(widget)
    widget:InitBase(opts)

    -- Wire Refresh from opts.get
    if opts.get then
        widget.Refresh = function(self)
            self:SetValue(self._ldf.opts.get())
        end
    end

    -- Label and tooltip
    if opts.label then widget:SetLabel(opts.label) end
    if opts.tooltip then widget:SetTooltip(opts.tooltip) end

    -- Disabled state (supports both static boolean and function)
    if opts.disabled then
        local isDisabled = type(opts.disabled) == "function" and opts.disabled() or opts.disabled
        if isDisabled then widget:SetEnabled(false) end
    end

    -- Register in the global widget table
    LDF.widgets[widget] = true

    return widget
end

-------------------------------------------------------------------------------
-- RemoveWidget - unregister and clean up a widget
-------------------------------------------------------------------------------

function LDF.RemoveWidget(widget)
    if not widget then return end

    LDF.widgets[widget] = nil
    LDF.RemoveFromPixelUpdater(widget)
end

-------------------------------------------------------------------------------
-- RefreshAll - re-read opts.get() for every registered widget
-------------------------------------------------------------------------------

function LDF.RefreshAll()
    for widget in pairs(LDF.widgets) do
        if widget.Refresh then
            widget:Refresh()
        end
    end
end

-------------------------------------------------------------------------------
-- SetAllEnabled - enable or disable every registered widget
-------------------------------------------------------------------------------

function LDF.SetAllEnabled(enabled)
    for widget in pairs(LDF.widgets) do
        if widget.SetEnabled then
            widget:SetEnabled(enabled)
        end
    end
end

-------------------------------------------------------------------------------
-- CreateWidgetFrame - standard frame factory for all LDF widgets
-------------------------------------------------------------------------------

function LDF.CreateWidgetFrame(parent, frameType, name)
    local frame = CreateFrame(frameType or "Frame", name, parent)
    frame._ldf = {}
    LDF.DisablePixelSnap(frame)
    return frame
end
