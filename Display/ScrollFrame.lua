-------------------------------------------------------------------------------
-- ScrollFrame.lua
-- Scrollable content container with styled scrollbar
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local CreateFrame = CreateFrame
local math_max = math.max
local math_min = math.min
local pcall = pcall

local SCROLLBAR_WIDTH = LDF.heights.SCROLLBAR
local SCROLL_STEP = LDF.dims.SCROLL_STEP

-------------------------------------------------------------------------------
-- Shared handlers (avoid per-instance closures)
-------------------------------------------------------------------------------

local function OnScrollBarValueChanged(self, value)
    local sf = self._scrollFrame
    if sf then sf:SetVerticalScroll(value) end
end

local function OnMouseWheel(self, delta)
    local bar = self._scrollBar
    if not bar then return end
    local lo, hi = bar:GetMinMaxValues()
    local newValue = math_min(math_max(bar:GetValue() - (delta * SCROLL_STEP), lo), hi)
    bar:SetValue(newValue)
end

local function UpdateScrollRange(wrapper)
    local sf = wrapper._scrollFrame
    local bar = wrapper._scrollBar
    if not sf or not bar then return end

    local contentHeight = wrapper.scrollChild:GetHeight() or 0
    local visibleHeight = sf:GetHeight() or 0
    local maxScroll = math_max(contentHeight - visibleHeight, 0)

    bar:SetMinMaxValues(0, maxScroll)

    if maxScroll == 0 then
        bar:Hide()
        sf:SetVerticalScroll(0)
        sf:ClearAllPoints()
        sf:SetPoint("TOPLEFT", wrapper, "TOPLEFT", 0, 0)
        sf:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", 0, 0)
    else
        bar:Show()
        sf:ClearAllPoints()
        sf:SetPoint("TOPLEFT", wrapper, "TOPLEFT", 0, 0)
        sf:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", -(SCROLLBAR_WIDTH + 2), 0)
        bar:SetValue(math_min(bar:GetValue(), maxScroll))
    end
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function LDF.CreateScrollFrame(parent)
    if not parent then error("CreateScrollFrame: 'parent' must not be nil", 2) end

    local wrapper = LDF.CreateWidgetFrame(parent, "Frame")
    wrapper:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    wrapper:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    wrapper:EnableMouseWheel(true)

    -- ScrollFrame for clipping
    local sf = CreateFrame("ScrollFrame", nil, wrapper)
    sf:SetPoint("TOPLEFT", wrapper, "TOPLEFT", 0, 0)
    sf:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", -(SCROLLBAR_WIDTH + 2), 0)
    LDF.DisablePixelSnap(sf)

    -- Scroll child (content target)
    local scrollChild = CreateFrame("Frame", nil, sf)
    scrollChild:SetHeight(1)
    sf:SetScrollChild(scrollChild)

    sf:SetScript("OnSizeChanged", function(self)
        scrollChild:SetWidth(self:GetWidth())
        UpdateScrollRange(wrapper)
    end)

    -- Scrollbar slider (BackdropTemplate with fallback)
    local ok, scrollbar = pcall(CreateFrame, "Slider", nil, wrapper, "BackdropTemplate")
    if not ok or not scrollbar then
        scrollbar = CreateFrame("Slider", nil, wrapper)
        if BackdropTemplateMixin then Mixin(scrollbar, BackdropTemplateMixin) end
    end

    scrollbar:SetPoint("TOPRIGHT", wrapper, "TOPRIGHT", 0, 0)
    scrollbar:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", 0, 0)
    scrollbar:SetWidth(SCROLLBAR_WIDTH)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetMinMaxValues(0, 0)
    scrollbar:SetValue(0)
    scrollbar:SetValueStep(1)
    LDF.DisablePixelSnap(scrollbar)

    scrollbar:SetBackdrop({ bgFile = LDF.WHITE8X8, edgeFile = LDF.WHITE8X8, edgeSize = 1 })
    scrollbar:SetBackdropColor(LDF.GetColor("bg2"))
    scrollbar:SetBackdropBorderColor(LDF.GetColor("border"))

    -- Thumb texture
    local thumb = scrollbar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(LDF.WHITE8X8)
    thumb:SetVertexColor(LDF.GetColor("borderLight"))
    thumb:SetSize(SCROLLBAR_WIDTH - 2, 30)
    LDF.DisablePixelSnap(thumb)
    scrollbar:SetThumbTexture(thumb)
    scrollbar:Hide()

    -- Cross-references for shared handlers
    scrollbar._scrollFrame = sf
    wrapper._scrollFrame = sf
    wrapper._scrollBar = scrollbar

    -- Wire events
    scrollbar:SetScript("OnValueChanged", OnScrollBarValueChanged)
    wrapper:SetScript("OnMouseWheel", OnMouseWheel)

    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(_, delta) OnMouseWheel(wrapper, delta) end)

    scrollChild:SetScript("OnSizeChanged", function() UpdateScrollRange(wrapper) end)

    function wrapper:UpdateScrollRange()
        UpdateScrollRange(self)
    end

    -- Public references
    wrapper.scrollChild = scrollChild
    wrapper.scrollFrame = sf

    LDF.AddToPixelUpdater(wrapper, "onshow")

    return wrapper
end
