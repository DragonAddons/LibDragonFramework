-------------------------------------------------------------------------------
-- TabGroup.lua
-- Tab bar with lazy content creation
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local CreateFrame = CreateFrame
local ipairs = ipairs
local math_max = math.max

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local TAB_HEIGHT = LDF.heights.TAB
local TAB_MIN_WIDTH = 60
local TAB_PADDING = LDF.spacing.XL

-------------------------------------------------------------------------------
-- Tab button helper
-------------------------------------------------------------------------------

local function CreateTabButton(tabBar, tabDef, index)
    local button = CreateFrame("Button", nil, tabBar)
    button:SetHeight(TAB_HEIGHT)
    LDF.DisablePixelSnap(button)

    -- Background
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(LDF.WHITE8X8)
    bg:SetVertexColor(LDF.GetColor("bg0"))

    -- Text label
    local label = LDF.CreateFontString(button, "body", tabDef.label)
    label:SetPoint("CENTER")
    label:SetTextColor(LDF.GetColor("textMuted"))

    -- Auto-width from text content
    local textWidth = label:GetStringWidth() or 40
    local width = math_max(TAB_MIN_WIDTH, textWidth + TAB_PADDING * 2)
    button:SetWidth(width)

    -- Bottom border (visible when inactive)
    local bottomBorder = button:CreateTexture(nil, "ARTWORK")
    bottomBorder:SetHeight(1)
    bottomBorder:SetPoint("BOTTOMLEFT")
    bottomBorder:SetPoint("BOTTOMRIGHT")
    bottomBorder:SetTexture(LDF.WHITE8X8)
    bottomBorder:SetVertexColor(LDF.GetColor("border"))

    -- Hover highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture(LDF.WHITE8X8)
    highlight:SetVertexColor(LDF.GetColor("highlight"))

    -- Internal state
    button._ldf = { tabDef = tabDef, index = index, active = false }

    -- Active/inactive toggle
    function button:SetActive(active)
        self._ldf.active = active
        if active then
            bg:SetVertexColor(LDF.GetColor("bg2"))
            label:SetTextColor(LDF.GetColor("accentGold"))
            bottomBorder:Hide()
        else
            bg:SetVertexColor(LDF.GetColor("bg0"))
            label:SetTextColor(LDF.GetColor("textMuted"))
            bottomBorder:Show()
        end
    end

    return button
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function LDF.CreateTabGroup(parent, tabs)
    if not parent then error("CreateTabGroup: 'parent' must not be nil", 2) end
    if not tabs or #tabs == 0 then error("CreateTabGroup: 'tabs' must be a non-empty array", 2) end

    local tabGroup = LDF.CreateWidgetFrame(parent, "Frame")
    tabGroup:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    tabGroup:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    -- Tab bar across top
    local tabBar = CreateFrame("Frame", nil, tabGroup)
    tabBar:SetHeight(TAB_HEIGHT)
    tabBar:SetPoint("TOPLEFT", tabGroup, "TOPLEFT")
    tabBar:SetPoint("TOPRIGHT", tabGroup, "TOPRIGHT")
    LDF.DisablePixelSnap(tabBar)

    -- Create tab buttons, laid out horizontally
    local buttons = {}
    local tabDefById = {}
    local xOffset = 0

    for i, tabDef in ipairs(tabs) do
        local button = CreateTabButton(tabBar, tabDef, i)
        button:SetPoint("TOPLEFT", tabBar, "TOPLEFT", xOffset, 0)
        xOffset = xOffset + button:GetWidth() + 1

        button:SetScript("OnClick", function()
            tabGroup:SelectTab(tabDef.id)
        end)

        buttons[tabDef.id] = button
        tabDefById[tabDef.id] = tabDef
    end

    -- Separator line below tab bar
    local separator = tabBar:CreateTexture(nil, "ARTWORK", nil, 0)
    separator:SetHeight(1)
    separator:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT")
    separator:SetPoint("TOPRIGHT", tabBar, "BOTTOMRIGHT")
    separator:SetTexture(LDF.WHITE8X8)
    separator:SetVertexColor(LDF.GetColor("border"))

    -- Shadow line below separator for depth
    local shadowLine = tabBar:CreateTexture(nil, "ARTWORK", nil, 1)
    shadowLine:SetHeight(1)
    shadowLine:SetPoint("TOPLEFT", separator, "BOTTOMLEFT")
    shadowLine:SetPoint("TOPRIGHT", separator, "BOTTOMRIGHT")
    shadowLine:SetTexture(LDF.WHITE8X8)
    shadowLine:SetVertexColor(LDF.GetColor("shadow"))

    -- Content area below separator
    local contentArea = CreateFrame("Frame", nil, tabGroup)
    contentArea:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -(2 + LDF.spacing.SM))
    contentArea:SetPoint("BOTTOMRIGHT", tabGroup, "BOTTOMRIGHT", 0, 0)
    LDF.DisablePixelSnap(contentArea)

    -- Lazy content cache
    local contentFrames = {}

    -- State
    tabGroup._ldf = { tabs = tabs, buttons = buttons, _selectedTab = nil }
    tabGroup.contentArea = contentArea

    -- SelectTab: switch active tab with lazy content creation
    function tabGroup:SelectTab(id)
        local currentTab = self._ldf._selectedTab
        if currentTab == id then return end

        -- Deactivate previous
        if currentTab and buttons[currentTab] then
            buttons[currentTab]:SetActive(false)
            if contentFrames[currentTab] then
                contentFrames[currentTab]:Hide()
            end
        end

        -- Activate new button
        if buttons[id] then
            buttons[id]:SetActive(true)
        end

        -- Lazy-create scroll content on first visit
        if not contentFrames[id] then
            local scrollWrapper = LDF.CreateScrollFrame(contentArea)
            scrollWrapper:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 0, 0)
            scrollWrapper:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)

            local tabDef = tabDefById[id]
            if tabDef and tabDef.createFunc then
                tabDef.createFunc(scrollWrapper.scrollChild)
            end

            contentFrames[id] = scrollWrapper
        end

        contentFrames[id]:Show()

        -- Refresh callback
        local tabDef = tabDefById[id]
        if tabDef and tabDef.refreshFunc then
            tabDef.refreshFunc()
        end

        self._ldf._selectedTab = id
    end

    function tabGroup:GetSelectedTab()
        return self._ldf._selectedTab
    end

    function tabGroup:RefreshTab(id)
        local tabDef = tabDefById[id]
        if not tabDef or not tabDef.refreshFunc then return end
        if not contentFrames[id] then return end

        tabDef.refreshFunc()

        if id == self._ldf._selectedTab then
            contentFrames[id]:UpdateScrollRange()
        end
    end

    -- Auto-select first tab
    tabGroup:SelectTab(tabs[1].id)

    return tabGroup
end
