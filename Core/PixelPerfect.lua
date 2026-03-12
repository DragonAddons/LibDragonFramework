-------------------------------------------------------------------------------
-- PixelPerfect.lua
-- Pixel-perfect rendering utilities
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

-- WoW API cache
local GetPhysicalScreenSize = GetPhysicalScreenSize
local CreateFrame = CreateFrame
local math_floor = math.floor
local math_max = math.max
local math_abs = math.abs
local UIParent = UIParent
local C_Timer = C_Timer
local pairs = pairs
local type = type

-------------------------------------------------------------------------------
-- Core math
-------------------------------------------------------------------------------

local function GetPixelFactor()
    return 768.0 / select(2, GetPhysicalScreenSize())
end

local function GetNearestPixelSize(uiUnitSize, layoutScale, minPixels)
    local factor = GetPixelFactor()
    local numPixels = math_floor((uiUnitSize * layoutScale / factor) + 0.5)
    if minPixels then
        numPixels = math_max(numPixels, minPixels)
    end
    return numPixels * factor / layoutScale
end

LDF.GetPixelFactor = GetPixelFactor
LDF.GetNearestPixelSize = GetNearestPixelSize

-------------------------------------------------------------------------------
-- Size helpers
-------------------------------------------------------------------------------

function LDF.SetSize(region, width, height, minWidthPx, minHeightPx)
    if not region then error("SetSize: 'region' must not be nil", 2) end

    region._ldf = region._ldf or {}
    region._ldf._width = width
    region._ldf._height = height
    region._ldf._minWidthPx = minWidthPx
    region._ldf._minHeightPx = minHeightPx

    local scale = region:GetEffectiveScale()
    region:SetSize(
        GetNearestPixelSize(width, scale, minWidthPx),
        GetNearestPixelSize(height, scale, minHeightPx)
    )
end

function LDF.SetWidth(region, width, minPx)
    if not region then error("SetWidth: 'region' must not be nil", 2) end

    region._ldf = region._ldf or {}
    region._ldf._width = width
    region._ldf._minWidthPx = minPx

    local scale = region:GetEffectiveScale()
    region:SetWidth(GetNearestPixelSize(width, scale, minPx))
end

function LDF.SetHeight(region, height, minPx)
    if not region then error("SetHeight: 'region' must not be nil", 2) end

    region._ldf = region._ldf or {}
    region._ldf._height = height
    region._ldf._minHeightPx = minPx

    local scale = region:GetEffectiveScale()
    region:SetHeight(GetNearestPixelSize(height, scale, minPx))
end

-------------------------------------------------------------------------------
-- Point helpers
-------------------------------------------------------------------------------

--- Snap an offset to the nearest pixel while preserving its sign.
local function SnapOffset(offset, scale)
    if offset == 0 then return 0 end
    local sign = offset < 0 and -1 or 1
    return sign * GetNearestPixelSize(math_abs(offset), scale)
end

function LDF.SetPoint(region, point, relativeTo, relativePoint, offsetX, offsetY)
    if not region then error("SetPoint: 'region' must not be nil", 2) end

    offsetX = offsetX or 0
    offsetY = offsetY or 0

    region._ldf = region._ldf or {}
    region._ldf._points = region._ldf._points or {}
    region._ldf._points[point] = { point, relativeTo, relativePoint, offsetX, offsetY }

    local scale = region:GetEffectiveScale()
    region:SetPoint(point, relativeTo, relativePoint,
        SnapOffset(offsetX, scale), SnapOffset(offsetY, scale))
end

-------------------------------------------------------------------------------
-- Re-apply stored values after scale changes
-------------------------------------------------------------------------------

function LDF.ReSize(region)
    if not region then error("ReSize: 'region' must not be nil", 2) end

    local data = region._ldf
    if not data then return end

    local scale = region:GetEffectiveScale()
    if data._width and data._height then
        region:SetSize(
            GetNearestPixelSize(data._width, scale, data._minWidthPx),
            GetNearestPixelSize(data._height, scale, data._minHeightPx)
        )
    elseif data._width then
        region:SetWidth(GetNearestPixelSize(data._width, scale, data._minWidthPx))
    elseif data._height then
        region:SetHeight(GetNearestPixelSize(data._height, scale, data._minHeightPx))
    end
end

function LDF.RePoint(region)
    if not region then error("RePoint: 'region' must not be nil", 2) end

    local data = region._ldf
    if not data or not data._points then return end

    local scale = region:GetEffectiveScale()
    for _, pt in pairs(data._points) do
        region:SetPoint(pt[1], pt[2], pt[3],
            SnapOffset(pt[4], scale), SnapOffset(pt[5], scale))
    end
end

function LDF.SetBorderWidth(region, width)
    if not region then error("SetBorderWidth: 'region' must not be nil", 2) end

    region._ldf = region._ldf or {}
    region._ldf._borderWidth = width

    local scale = region:GetEffectiveScale()
    local snapped = GetNearestPixelSize(width, scale, 1)
    local backdrop = region:GetBackdrop()
    if backdrop then
        backdrop.edgeSize = snapped
        backdrop.insets = { left = snapped, right = snapped, top = snapped, bottom = snapped }
        region:SetBackdrop(backdrop)

        -- Re-apply colors since SetBackdrop() resets them to white
        local data = region._ldf
        if data and data._backdropStyle then
            region:SetBackdropColor(LDF.GetColor(data._backdropStyle.bg))
            region:SetBackdropBorderColor(LDF.GetColor(data._backdropStyle.border))
        end
    end
end

function LDF.ReBorder(region)
    if not region then error("ReBorder: 'region' must not be nil", 2) end

    local data = region._ldf
    if not data or not data._borderWidth then return end

    LDF.SetBorderWidth(region, data._borderWidth)
end

function LDF.UpdatePixels(region)
    if not region then return end
    LDF.ReSize(region)
    LDF.RePoint(region)
    LDF.ReBorder(region)
end

-------------------------------------------------------------------------------
-- Pixel updater groups
-------------------------------------------------------------------------------

local autoUpdaters = {}
local onShowUpdaters = {}

local function RunPixelUpdate(region)
    if not region then return end

    if type(region.UpdatePixels) == "function" then
        region:UpdatePixels()
        return
    end

    LDF.UpdatePixels(region)
end

function LDF.AddToPixelUpdater(region, group)
    if not region then error("AddToPixelUpdater: 'region' must not be nil", 2) end

    if group == "auto" then
        autoUpdaters[region] = true
    elseif group == "onshow" then
        onShowUpdaters[region] = true
        region:HookScript("OnShow", function(self)
            RunPixelUpdate(self)
        end)
    else
        error("AddToPixelUpdater: 'group' must be \"auto\" or \"onshow\"", 2)
    end
end

function LDF.RemoveFromPixelUpdater(region)
    if not region then return end
    autoUpdaters[region] = nil
    onShowUpdaters[region] = nil
end

-------------------------------------------------------------------------------
-- Scale change handler (debounced)
-------------------------------------------------------------------------------

local pendingTimer = nil

local function OnScaleChanged()
    for region in pairs(autoUpdaters) do
        RunPixelUpdate(region)
    end
    for region in pairs(onShowUpdaters) do
        if region:IsShown() then
            RunPixelUpdate(region)
        end
    end
    pendingTimer = nil
end

local eventFrame = CreateFrame("Frame", nil, UIParent)
eventFrame:RegisterEvent("UI_SCALE_CHANGED")
eventFrame:SetScript("OnEvent", function()
    if pendingTimer then
        pendingTimer:Cancel()
    end
    pendingTimer = C_Timer.NewTimer(1, OnScaleChanged)
end)

-------------------------------------------------------------------------------
-- Pixel snap disabling (scoped to individual regions)
-------------------------------------------------------------------------------

function LDF.DisablePixelSnap(region)
    if not region then error("DisablePixelSnap: 'region' must not be nil", 2) end

    if region.SetSnapToPixelGrid then
        region:SetSnapToPixelGrid(false)
    end
    if region.SetTexelSnappingBias then
        region:SetTexelSnappingBias(0)
    end
end
