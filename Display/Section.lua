-------------------------------------------------------------------------------
-- Section.lua
-- Titled content group with separator
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local CreateFrame = CreateFrame

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function LDF.CreateSection(parent, title, opts)
    if not parent then error("CreateSection: 'parent' must not be nil", 2) end
    if not title then error("CreateSection: 'title' must not be nil", 2) end

    opts = opts or {}

    local section = LDF.CreateWidgetFrame(parent, "Frame")
    section:SetPoint("TOPLEFT", parent, "TOPLEFT")
    section:SetPoint("RIGHT", parent, "RIGHT")

    section._ldf = section._ldf or {}
    section._ldf.collapsible = opts.collapsible or false
    section._ldf.collapsed = false
    section._ldf.usesGrid = false

    -- Header text (gold title preset)
    local header = LDF.CreateFontString(section, "title", title)
    header:SetPoint("TOPLEFT", section, "TOPLEFT", 0, 0)
    section._header = header

    -- Separator line below header
    local separator = section:CreateTexture(nil, "ARTWORK", nil, 0)
    separator:SetHeight(LDF.heights.SEPARATOR)
    local ar, ag, ab = LDF.GetColor("accentGold")
    separator:SetColorTexture(ar, ag, ab, 0.8)
    separator:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -LDF.spacing.XS)
    separator:SetPoint("RIGHT", section, "RIGHT")
    LDF.DisablePixelSnap(separator)
    section._separator = separator

    -- Shadow line below separator for depth
    local shadowLine = section:CreateTexture(nil, "ARTWORK", nil, 1)
    shadowLine:SetTexture(LDF.WHITE8X8)
    shadowLine:SetHeight(LDF.heights.SEPARATOR)
    shadowLine:SetVertexColor(LDF.GetColor("shadow"))
    shadowLine:SetPoint("TOPLEFT", separator, "BOTTOMLEFT")
    shadowLine:SetPoint("RIGHT", section, "RIGHT")
    LDF.DisablePixelSnap(shadowLine)
    section._ldf._shadowLine = shadowLine

    -- Content area below separator (anchored to shadow line, not separator)
    local content = CreateFrame("Frame", nil, section)
    content:SetPoint("TOPLEFT", shadowLine, "BOTTOMLEFT", 0, -LDF.spacing.SM)
    content:SetPoint("RIGHT", section, "RIGHT")
    section.content = content

    -- `section.content` remains the raw content frame for backward compatibility.
    -- The internal grid only takes ownership of content height after callers opt
    -- in through the section layout helpers. Once opted in, grid management stays
    -- enabled even if the grid later becomes empty so behavior remains predictable.
    local contentLayout = LDF.CreateGridLayout(content, {
        columns = opts.columns or 2,
        spacing = opts.spacing or LDF.spacing.MD,
        rowSpacing = opts.rowSpacing,
        columnSpacing = opts.columnSpacing,
    })
    section._ldf.layout = contentLayout

    content:SetScript("OnSizeChanged", function()
        if not section.UpdateHeight then return end
        section:UpdateHeight()
    end)

    local function MarkSectionUsesGrid()
        section._ldf.usesGrid = true
    end

    local function SyncGridContentHeight()
        if not section._ldf.usesGrid then return end

        local layoutHeight = contentLayout:GetHeight() or 0
        content:SetHeight(layoutHeight)
    end

    contentLayout:HookScript("OnSizeChanged", SyncGridContentHeight)

    local function UpdateCollapseButtonHeight()
        if not section._ldf._collapseBtn then return end
        local height = header:GetStringHeight() + LDF.spacing.XS + LDF.heights.SEPARATOR * 2
        section._ldf._collapseBtn:SetHeight(height)
    end

    -- Collapsible header controls
    if section._ldf.collapsible then
        local chevron = LDF.CreateFontString(section, "title", "v")
        LDF.SetPoint(chevron, "TOPLEFT", section, "TOPLEFT", 0, 0)
        section._ldf._chevron = chevron

        -- Shift header right to make room for chevron
        header:ClearAllPoints()
        LDF.SetPoint(header, "TOPLEFT", section, "TOPLEFT", LDF.spacing.LG, 0)

        -- Clickable overlay on header region
        local collapseBtn = CreateFrame("Button", nil, section)
        collapseBtn:SetPoint("TOPLEFT", section, "TOPLEFT")
        collapseBtn:SetPoint("RIGHT", section, "RIGHT")
        collapseBtn:SetScript("OnClick", function()
            section:ToggleCollapsed()
        end)
        collapseBtn:SetScript("OnEnter", function()
            header:SetAlpha(0.7)
            if section._ldf._chevron then
                section._ldf._chevron:SetAlpha(0.7)
            end
        end)
        collapseBtn:SetScript("OnLeave", function()
            header:SetAlpha(1.0)
            if section._ldf._chevron then
                section._ldf._chevron:SetAlpha(1.0)
            end
        end)
        section._ldf._collapseBtn = collapseBtn
        UpdateCollapseButtonHeight()
    end

    -- Height calculation
    function section:UpdateHeight()
        local headerHeight = self._header:GetStringHeight()
        local separatorHeight = LDF.heights.SEPARATOR
        local shadowHeight = LDF.heights.SEPARATOR
        if self._ldf.collapsed then
            local total = headerHeight + LDF.spacing.XS + separatorHeight + shadowHeight
            self:SetHeight(total)
            return
        end
        local contentHeight = self.content:GetHeight() or 0
        local total = headerHeight + LDF.spacing.XS + separatorHeight + shadowHeight + LDF.spacing.SM + contentHeight
        self:SetHeight(total)
    end

    function section:SetTitle(text)
        self._header:SetText(text)
        UpdateCollapseButtonHeight()
        self:UpdateHeight()
    end

    function section:GetContent()
        return self.content
    end

    function section:SetCollapsed(collapsed)
        self._ldf.collapsed = collapsed
        if collapsed then
            self.content:Hide()
        else
            self.content:Show()
        end
        if self._ldf._chevron then
            self._ldf._chevron:SetText(collapsed and ">" or "v")
        end
        self:UpdateHeight()
        LDF.FireCallback("SECTION_TOGGLED", self, collapsed)
    end

    function section:ToggleCollapsed()
        self:SetCollapsed(not self._ldf.collapsed)
    end

    function section:IsCollapsed()
        return self._ldf.collapsed
    end

    -- Apply initial collapsed state from opts
    if opts.collapsed then
        section:SetCollapsed(true)
    end

    function section:AddChild(widget, order, span)
        MarkSectionUsesGrid()
        self._ldf.layout:AddChild(widget, order, span)
    end

    function section:RemoveChild(widget)
        MarkSectionUsesGrid()
        self._ldf.layout:RemoveChild(widget)
    end

    function section:GetChildren()
        return self._ldf.layout:GetChildren()
    end

    function section:SetColumns(columns)
        MarkSectionUsesGrid()
        self._ldf.layout:SetColumns(columns)
    end

    function section:SetSpacing(spacing)
        MarkSectionUsesGrid()
        self._ldf.layout:SetSpacing(spacing)
    end

    function section:RefreshLayout()
        MarkSectionUsesGrid()
        self._ldf.layout:Refresh()
    end

    function section:GetLayout()
        return self._ldf.layout
    end

    -- Initial height calculation (deferred - header needs a frame to measure)
    section:SetScript("OnShow", function(self)
        if self._ldf.usesGrid then
            self._ldf.layout:Refresh()
            SyncGridContentHeight()
        end
        self:UpdateHeight()
        UpdateCollapseButtonHeight()
    end)

    SyncGridContentHeight()

    return section
end
