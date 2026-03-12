-------------------------------------------------------------------------------
-- BaseMixin.lua
-- Base mixin applied to all LDF widgets
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local GameTooltip = GameTooltip
local InCombatLockdown = InCombatLockdown
local CreateFrame = CreateFrame

-------------------------------------------------------------------------------
-- Mixin definition
-------------------------------------------------------------------------------

LDF_BaseMixin = {}

function LDF_BaseMixin:InitBase(opts)
    self._ldf = self._ldf or {}
    self._ldf.enabled = true
    self._ldf.labelText = opts and opts.label or ""
    self._ldf.tooltip = opts and opts.tooltip or nil
    self._ldf.opts = opts or {}

    if opts and opts.disabled then
        local isDisabled = type(opts.disabled) == "function" and opts.disabled() or opts.disabled
        if isDisabled then
            self:SetEnabled(false)
        end
    end
end

function LDF_BaseMixin:SetEnabled(enabled)
    self._ldf.enabled = enabled

    local alpha = enabled and 1.0 or 0.5
    if self._ldf.labelFS then
        self._ldf.labelFS:SetAlpha(alpha)
    end
    self:SetAlpha(alpha)

    self:EnableMouse(enabled)
end

function LDF_BaseMixin:IsEnabled()
    return self._ldf.enabled
end

-- DEPRECATED: Remove after full migration to SetEnabled()
--- @deprecated Use SetEnabled() instead. Shim for backward compatibility.
function LDF_BaseMixin:SetDisabled(state)
    self:SetEnabled(not state)
end

function LDF_BaseMixin:SetLabel(text)
    self._ldf.labelText = text
    if self._ldf.labelFS then
        self._ldf.labelFS:SetText(text)
    end
end

function LDF_BaseMixin:GetLabel()
    return self._ldf.labelText
end

function LDF_BaseMixin:SetTooltip(text)
    self._ldf.tooltip = text
end

function LDF_BaseMixin:ShowTooltip()
    if not self._ldf.tooltip then return end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self._ldf.labelText, 1, 0.82, 0)   -- gold
    GameTooltip:AddLine(self._ldf.tooltip, 1, 1, 1, true)  -- white, wrap
    GameTooltip:Show()
end

function LDF_BaseMixin:HideTooltip()
    GameTooltip:Hide()
end

function LDF_BaseMixin:Toggle()
    self:SetEnabled(not self._ldf.enabled)
end

function LDF_BaseMixin:SetOnValueChanged(fn)
    self._ldf.onValueChanged = fn
end

function LDF_BaseMixin:SetOnValueCommitted(fn)
    self._ldf.onValueCommitted = fn
end

function LDF_BaseMixin:FireValueChanged(...)
    if self._ldf.onValueChanged then
        self._ldf.onValueChanged(...)
    end
    if self._ldf.opts and self._ldf.opts.set then
        self._ldf.opts.set(...)
    end
end

function LDF_BaseMixin:FireValueCommitted(...)
    if self._ldf.onValueCommitted then
        self._ldf.onValueCommitted(...)
    end
end

-------------------------------------------------------------------------------
-- Application helper
-------------------------------------------------------------------------------

function LDF.ApplyBaseMixin(widget)
    Mixin(widget, LDF_BaseMixin)
end

-------------------------------------------------------------------------------
-- Combat lockout
-------------------------------------------------------------------------------

function LDF_BaseMixin:SetCombatLockout(enabled)
    self._ldf.combatLockout = enabled
    if enabled and InCombatLockdown() then
        self:SetEnabled(false)
    end
end

local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function(_self, event)
    if not LDF.widgets then return end

    local enteringCombat = (event == "PLAYER_REGEN_DISABLED")
    for _i, widget in pairs(LDF.widgets) do
        if widget._ldf and widget._ldf.combatLockout then
            widget:SetEnabled(not enteringCombat)
        end
    end
end)
