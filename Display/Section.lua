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

    local section = LDF.CreateWidgetFrame(parent, "Frame")
    section:SetPoint("TOPLEFT", parent, "TOPLEFT")
    section:SetPoint("RIGHT", parent, "RIGHT")

    section._ldf = section._ldf or {}
    section._ldf.collapsible = opts and opts.collapsible or false
    section._ldf.collapsed = false

    -- Header text (gold title preset)
    local header = LDF.CreateFontString(section, "title", title)
    header:SetPoint("TOPLEFT", section, "TOPLEFT", 0, 0)
    section._header = header

    -- Separator line below header
    local separator = section:CreateTexture(nil, "ARTWORK")
    separator:SetTexture(LDF.WHITE8X8)
    separator:SetHeight(LDF.heights.SEPARATOR)
    separator:SetColorTexture(LDF.GetColor("border"))
    separator:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -LDF.spacing.XS)
    separator:SetPoint("RIGHT", section, "RIGHT")
    LDF.DisablePixelSnap(separator)
    section._separator = separator

    -- Content area below separator
    local content = CreateFrame("Frame", nil, section)
    content:SetPoint("TOPLEFT", separator, "BOTTOMLEFT", 0, -LDF.spacing.SM)
    content:SetPoint("RIGHT", section, "RIGHT")
    section.content = content

    -- Collapsible header controls
    if section._ldf.collapsible then
        local chevron = LDF.CreateFontString(section, "title", "v")
        LDF.SetPoint(chevron, "RIGHT", header, "LEFT", -LDF.spacing.XS, 0)
        section._ldf._chevron = chevron

        -- Shift header right to make room for chevron
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", section, "TOPLEFT", LDF.spacing.MD, 0)

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
    end

    -- Height calculation
    function section:UpdateHeight()
        local headerHeight = self._header:GetStringHeight()
        local separatorHeight = LDF.heights.SEPARATOR
        if self._ldf.collapsed then
            local total = headerHeight + LDF.spacing.XS + separatorHeight
            self:SetHeight(total)
            return
        end
        local contentHeight = self.content:GetHeight() or 0
        local total = headerHeight + LDF.spacing.XS + separatorHeight + LDF.spacing.SM + contentHeight
        self:SetHeight(total)
    end

    function section:SetTitle(text)
        self._header:SetText(text)
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
    if opts and opts.collapsed then
        section:SetCollapsed(true)
    end

    -- Auto-update height when content resizes
    content:SetScript("OnSizeChanged", function()
        section:UpdateHeight()
    end)

    -- Initial height calculation (deferred - header needs a frame to measure)
    section:SetScript("OnShow", function(self)
        self:UpdateHeight()
        if self._ldf._collapseBtn then
            local h = self._header:GetStringHeight() + LDF.spacing.XS + LDF.heights.SEPARATOR
            self._ldf._collapseBtn:SetHeight(h)
        end
        self:SetScript("OnShow", nil)
    end)

    return section
end
