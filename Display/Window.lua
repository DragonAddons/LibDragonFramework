-------------------------------------------------------------------------------
-- Window.lua
-- Main options window container
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local CreateFrame = CreateFrame
local UIParent = UIParent
local pcall = pcall
local tinsert = table.insert

-------------------------------------------------------------------------------
-- Defaults
-------------------------------------------------------------------------------

local DEFAULT_WIDTH  = 600
local DEFAULT_HEIGHT = 500
local DEFAULT_TITLE  = "Options"

-------------------------------------------------------------------------------
-- Close button helpers
-------------------------------------------------------------------------------

local function CreateRetailCloseButton(window)
    local ok, btn = pcall(CreateFrame, "Button", nil, window, "UIPanelCloseButton")
    if not ok or not btn then return nil end

    btn:SetPoint("TOPRIGHT", window, "TOPRIGHT", -2, -2)
    btn:SetScript("OnClick", function() window:Hide() end)
    return btn
end

local function CreateFallbackCloseButton(window)
    local btn = CreateFrame("Button", nil, window)
    LDF.SetSize(btn, 24, 24)
    LDF.SetPoint(btn, "TOPRIGHT", window, "TOPRIGHT", -4, -4)
    LDF.ApplyBackdrop(btn, "button")

    local label = LDF.CreateFontString(btn, "body", "X")
    label:SetTextColor(LDF.GetColor("danger"))
    label:SetPoint("CENTER")

    btn:SetScript("OnClick", function() window:Hide() end)

    LDF.SetBackdropHighlight(btn, "borderLight", "highlight")

    return btn
end

local function AttachCloseButton(window)
    return CreateRetailCloseButton(window) or CreateFallbackCloseButton(window)
end

-------------------------------------------------------------------------------
-- Title bar
-------------------------------------------------------------------------------

local function CreateTitleBar(window, titleText)
    local titleBar = CreateFrame("Frame", nil, window)
    LDF.DisablePixelSnap(titleBar)

    local titleHeight = LDF.heights.TITLE
    titleBar:SetPoint("TOPLEFT", window, "TOPLEFT")
    titleBar:SetPoint("TOPRIGHT", window, "TOPRIGHT")
    titleBar:SetHeight(titleHeight)

    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() window:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() window:StopMovingOrSizing() end)

    local titleFs = LDF.CreateFontString(titleBar, "title", titleText)
    titleFs:SetPoint("LEFT", titleBar, "LEFT", LDF.spacing.LG, 0)
    titleFs:SetPoint("TOP", titleBar, "TOP")
    titleFs:SetPoint("BOTTOM", titleBar, "BOTTOM")

    return titleBar, titleFs
end

-------------------------------------------------------------------------------
-- Content area
-------------------------------------------------------------------------------

local function CreateContentArea(window)
    local content = CreateFrame("Frame", nil, window)
    LDF.DisablePixelSnap(content)

    local pad = LDF.spacing.MD
    local titleHeight = LDF.heights.TITLE
    local gap = LDF.spacing.SM

    content:SetPoint("TOPLEFT", window, "TOPLEFT", pad, -(titleHeight + gap))
    content:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -pad, pad)

    return content
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function LDF.CreateWindow(opts)
    if not opts then error("CreateWindow: 'opts' must not be nil", 2) end
    if not opts.name then error("CreateWindow: 'opts.name' is required", 2) end

    local name   = opts.name
    local title  = opts.title or DEFAULT_TITLE
    local width  = opts.width or DEFAULT_WIDTH
    local height = opts.height or DEFAULT_HEIGHT

    -- Create frame with BackdropTemplate when available
    local ok, window = pcall(CreateFrame, "Frame", name, UIParent, "BackdropTemplate")
    if not ok or not window then
        window = CreateFrame("Frame", name, UIParent)
    end

    LDF.ApplyBackdrop(window, "panel")
    LDF.SetSize(window, width, height)
    window:SetPoint("CENTER")
    window:SetFrameStrata("HIGH")
    window:SetFrameLevel(100)
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:Hide()

    LDF.DisablePixelSnap(window)

    -- Title bar
    local titleBar, titleFs = CreateTitleBar(window, title)
    window._titleBar = titleBar
    window._titleFs = titleFs

    -- Close button
    AttachCloseButton(window)

    -- Content area
    window.content = CreateContentArea(window)

    -- ESC to close
    tinsert(UISpecialFrames, name)

    -- Instance methods
    function window:SetTitle(text)
        self._titleFs:SetText(text)
    end

    function window:Toggle()
        if self:IsShown() then
            self:Hide()
        else
            self:Show()
        end
    end

    -- Pixel updater
    function window:UpdatePixels()
        local data = self._ldf
        if not data then return end
        LDF.UpdatePixels(self)
    end

    window._ldf = window._ldf or {}
    window._ldf._width = width
    window._ldf._height = height

    LDF.AddToPixelUpdater(window, "auto")

    return window
end
