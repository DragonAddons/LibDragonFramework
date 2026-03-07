-------------------------------------------------------------------------------
-- Dropdown.lua
-- Custom dropdown selector with scrollable list and singleton list pattern
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local CreateFrame = CreateFrame
local PlaySound = PlaySound
local SOUNDKIT = SOUNDKIT
local table_sort = table.sort
local math_min = math.min
local math_max = math.max
local ipairs = ipairs
local type = type

local FRAME_HEIGHT = 42
local BUTTON_HEIGHT = LDF.heights.CONTROL
local ITEM_HEIGHT = LDF.dims.DROPDOWN_ITEM
local BUTTON_WIDTH = LDF.dims.DROPDOWN_WIDTH
local MAX_LIST_HEIGHT = LDF.dims.DROPDOWN_MAX_HEIGHT
local PREVIEW_WIDTH = 40
local PREVIEW_HEIGHT = 14
local PREVIEW_INSET = 6
local TEXT_OFFSET_WITH_PREVIEW = 52

local activeDropdown = nil
local overlay, listFrame, listScroll, listContent, buttonPool

-------------------------------------------------------------------------------
-- Close / value helpers
-------------------------------------------------------------------------------

local function CloseActiveDropdown()
    if not activeDropdown then return end
    if buttonPool then buttonPool:ReleaseAll() end
    if listFrame then listFrame:Hide() end
    if overlay then overlay:Hide() end
    activeDropdown = nil
end

local function ResolveValues(opts)
    local vals = opts.values
    if type(vals) == "function" then vals = vals() end
    if not vals then return {} end
    if opts.sort then
        table_sort(vals, function(a, b) return (a.text or "") < (b.text or "") end)
    end
    return vals
end

local function FindDisplayText(values, key)
    for _, entry in ipairs(values) do
        if entry.value == key then return entry.text end
    end
    return ""
end

-------------------------------------------------------------------------------
-- LSM preview helpers
-------------------------------------------------------------------------------

local function ApplyTexturePreview(btn, mediaType, value, lsm)
    if not btn._ldfPreview then
        btn._ldfPreview = btn:CreateTexture(nil, "ARTWORK")
        btn._ldfPreview:SetSize(PREVIEW_WIDTH, PREVIEW_HEIGHT)
        btn._ldfPreview:SetPoint("LEFT", btn, "LEFT", PREVIEW_INSET, 0)
        btn._ldfPreview:SetVertexColor(LDF.GetColor("accentGold"))
        LDF.DisablePixelSnap(btn._ldfPreview)
    end
    local texPath = lsm:Fetch(mediaType, value)
    if texPath then btn._ldfPreview:SetTexture(texPath); btn._ldfPreview:Show()
    else btn._ldfPreview:Hide() end
    btn._ldfText:ClearAllPoints()
    btn._ldfText:SetPoint("LEFT", btn, "LEFT", TEXT_OFFSET_WITH_PREVIEW, 0)
    btn._ldfText:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
end

local function ApplyFontPreview(btn, value, lsm)
    local fontPath = lsm:Fetch("font", value)
    if fontPath then btn._ldfText:SetFont(fontPath, 12, "") end
end

local function ResetPreview(btn)
    if btn._ldfPreview then btn._ldfPreview:Hide() end
    btn._ldfText:SetFont(LDF.FONT_PATH, 12, "")
    btn._ldfText:ClearAllPoints()
    btn._ldfText:SetPoint("LEFT", btn, "LEFT", 6, 0)
    btn._ldfText:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
end

local function UpdateSelectedPreview(frame, opts, value)
    local mediaType = opts.mediaType
    local selText = frame._ldf.selectedText
    local btn = frame._ldf.button
    if not mediaType then
        if frame._ldf.selPreview then frame._ldf.selPreview:Hide() end
        selText:SetFont(LDF.FONT_PATH, 12, "")
        selText:ClearAllPoints()
        selText:SetPoint("LEFT", btn, "LEFT", 6, 0)
        selText:SetPoint("RIGHT", btn, "RIGHT", -20, 0)
        return
    end
    local lsm = LDF.LSM
    if not lsm then return end
    if mediaType == "font" then
        local fontPath = lsm:Fetch("font", value)
        if fontPath then selText:SetFont(fontPath, 12, "") end
        return
    end
    if not frame._ldf.selPreview then
        frame._ldf.selPreview = btn:CreateTexture(nil, "ARTWORK")
        frame._ldf.selPreview:SetSize(PREVIEW_WIDTH, PREVIEW_HEIGHT)
        frame._ldf.selPreview:SetPoint("LEFT", btn, "LEFT", PREVIEW_INSET, 0)
        frame._ldf.selPreview:SetVertexColor(LDF.GetColor("accentGold"))
        LDF.DisablePixelSnap(frame._ldf.selPreview)
    end
    local texPath = lsm:Fetch(mediaType, value)
    if texPath then frame._ldf.selPreview:SetTexture(texPath); frame._ldf.selPreview:Show()
    else frame._ldf.selPreview:Hide() end
    selText:ClearAllPoints()
    selText:SetPoint("LEFT", btn, "LEFT", TEXT_OFFSET_WITH_PREVIEW, 0)
    selText:SetPoint("RIGHT", btn, "RIGHT", -20, 0)
end

-------------------------------------------------------------------------------
-- Singleton lazy init + ObjectPool
-------------------------------------------------------------------------------

local function CreateItemButton()
    local btn = CreateFrame("Button", nil, listContent)
    btn:SetHeight(ITEM_HEIGHT)
    local text = LDF.CreateFontString(btn, "body")
    text:SetPoint("LEFT", btn, "LEFT", 6, 0)
    text:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    text:SetJustifyH("LEFT")
    btn._ldfText = text
    local sel = btn:CreateTexture(nil, "BACKGROUND")
    sel:SetAllPoints()
    sel:SetColorTexture(LDF.GetColor("accentGold"))
    sel:SetAlpha(0.15)
    sel:Hide()
    btn._ldfSelected = sel
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(LDF.GetColor("highlight"))
    btn._ldfHighlight = hl
    return btn
end

local function ResetItemButton(btn)
    btn:Hide()
    btn:SetScript("OnClick", nil)
    ResetPreview(btn)
    btn._ldfSelected:Hide()
end

local function EnsureSingleton()
    if overlay then return end
    overlay = CreateFrame("Button", nil, UIParent)
    overlay:SetAllPoints(UIParent)
    overlay:SetFrameStrata("FULLSCREEN")
    overlay:SetFrameLevel(199)
    overlay:EnableMouse(true)
    overlay:Hide()
    overlay:SetScript("OnClick", CloseActiveDropdown)
    listFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    listFrame:SetFrameStrata("FULLSCREEN")
    listFrame:SetFrameLevel(200)
    LDF.ApplyBackdrop(listFrame, "dark")
    listFrame:Hide()
    listScroll = LDF.CreateScrollFrame(listFrame)
    listScroll:ClearAllPoints()
    listScroll:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 1, -1)
    listScroll:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -1, 1)
    listContent = listScroll.scrollChild
    buttonPool = LDF.CreateObjectPool(CreateItemButton, ResetItemButton)
end

-------------------------------------------------------------------------------
-- Build list items + toggle
-------------------------------------------------------------------------------

local function BuildListItems(frame, opts)
    buttonPool:ReleaseAll()
    local values = ResolveValues(opts)
    local currentKey = opts.get and opts.get() or nil
    local mediaType = opts.mediaType
    local lsm = mediaType and LDF.LSM or nil
    local yOffset = 0
    for _, entry in ipairs(values) do
        local btn = buttonPool:Acquire()
        btn:SetParent(listContent)
        btn._ldfText:SetText(entry.text or "")
        btn._ldfSelected:SetShown(entry.value == currentKey)
        if lsm and mediaType ~= "font" then
            ApplyTexturePreview(btn, mediaType, entry.value, lsm)
        elseif lsm and mediaType == "font" then
            ApplyFontPreview(btn, entry.value, lsm)
        end
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, -yOffset)
        btn:SetPoint("TOPRIGHT", listContent, "TOPRIGHT", 0, -yOffset)
        btn:Show()
        btn:SetScript("OnClick", function()
            frame:SetValue(entry.value)
            frame:FireValueChanged(entry.value)
            if PlaySound and SOUNDKIT then
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end
            CloseActiveDropdown()
        end)
        yOffset = yOffset + ITEM_HEIGHT
    end
    listContent:SetHeight(math_max(1, yOffset))
end

local function ToggleList(frame, opts)
    if activeDropdown == frame then CloseActiveDropdown(); return end
    CloseActiveDropdown()
    EnsureSingleton()
    local button = frame._ldf.button
    listFrame:ClearAllPoints()
    listFrame:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -1)
    listFrame:SetWidth(button:GetWidth())
    BuildListItems(frame, opts)
    listFrame:SetHeight(math_min(listContent:GetHeight(), MAX_LIST_HEIGHT) + 2)
    listScroll:UpdateScrollRange()
    overlay:Show()
    listFrame:Show()
    activeDropdown = frame
end

-------------------------------------------------------------------------------
-- Factory: CreateDropdown
-------------------------------------------------------------------------------

function LDF.CreateDropdown(parent, opts)
    if not parent then error("LDF.CreateDropdown: parent required", 2) end
    opts = opts or {}

    local frame = LDF.CreateWidgetFrame(parent)
    frame:SetHeight(FRAME_HEIGHT)

    local label = LDF.CreateFontString(frame, "small", opts.label or "")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

    local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
    button:SetSize((opts.width or BUTTON_WIDTH), BUTTON_HEIGHT)
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -16)
    LDF.ApplyBackdrop(button, "widget")
    LDF.SetBackdropHighlight(button)

    local selText = LDF.CreateFontString(button, "body")
    selText:SetPoint("LEFT", button, "LEFT", 6, 0)
    selText:SetPoint("RIGHT", button, "RIGHT", -20, 0)
    selText:SetJustifyH("LEFT")

    local arrow = LDF.CreateFontString(button, "body", "v")
    arrow:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    arrow:SetTextColor(LDF.GetColor("textMuted"))

    frame._ldf.button = button
    frame._ldf.selectedText = selText
    frame._ldf.label = label
    frame._ldf.arrow = arrow

    button:SetScript("OnClick", function()
        if not frame:IsEnabled() then return end
        ToggleList(frame, opts)
    end)

    frame:SetScript("OnHide", function(self)
        if activeDropdown == self then
            CloseActiveDropdown()
        elseif listFrame then
            listFrame:Hide()
            if overlay then overlay:Hide() end
        end
    end)

    function frame:GetValue()
        return opts.get and opts.get() or nil
    end

    function frame:SetValue(v)
        if opts.set then opts.set(v) end
        local vals = ResolveValues(opts)
        self._ldf.selectedText:SetText(FindDisplayText(vals, v))
        UpdateSelectedPreview(self, opts, v)
    end

    LDF.ApplyWidgetProtocol(frame, opts)

    function frame:Refresh()
        local vals = ResolveValues(opts)
        local key = opts.get and opts.get() or nil
        self._ldf.selectedText:SetText(FindDisplayText(vals, key))
        UpdateSelectedPreview(self, opts, key)
    end

    local baseSetEnabled = frame.SetEnabled
    function frame:SetEnabled(state)
        baseSetEnabled(self, state)
        if state then
            label:SetTextColor(LDF.GetColor("textMuted"))
            arrow:SetTextColor(LDF.GetColor("textMuted"))
            selText:SetTextColor(LDF.GetColor("text"))
            button:SetAlpha(1)
        else
            label:SetTextColor(LDF.GetColor("textDim"))
            arrow:SetTextColor(LDF.GetColor("textDim"))
            selText:SetTextColor(LDF.GetColor("textDim"))
            button:SetAlpha(0.5)
            if activeDropdown == self then CloseActiveDropdown() end
        end
    end

    frame:SetScript("OnEnter", frame.ShowTooltip)
    frame:SetScript("OnLeave", frame.HideTooltip)
    frame:Refresh()

    return frame
end
