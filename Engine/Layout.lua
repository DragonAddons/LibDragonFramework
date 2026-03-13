-------------------------------------------------------------------------------
-- Layout.lua
-- Auto-flow stack and grid layout containers
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local CreateFrame = CreateFrame
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local table_remove = table.remove
local table_sort = table.sort

local function ClampPositiveInteger(value, fallback)
    local parsedValue = tonumber(value)
    if not parsedValue then return fallback end

    parsedValue = math_floor(parsedValue)
    if parsedValue < 1 then
        return fallback
    end

    return parsedValue
end

local function CopyChildren(children)
    local copy = {}
    for i = 1, #children do
        copy[i] = children[i]
    end
    return copy
end

local function SortChildrenByOrder(children)
    table_sort(children, function(a, b)
        local aOrder = a._ldf and a._ldf._layoutOrder or 0
        local bOrder = b._ldf and b._ldf._layoutOrder or 0
        return aOrder < bOrder
    end)
end

local function ResolveLayoutOrder(children, widget, order)
    if order ~= nil then
        return order
    end

    if widget._ldf and widget._ldf.opts and widget._ldf.opts.order ~= nil then
        return widget._ldf.opts.order
    end

    return #children + 1
end

local function AttachLayoutRefreshHook(widget)
    widget._ldf = widget._ldf or {}
    if widget._ldf._layoutHooked then return end

    widget:HookScript("OnSizeChanged", function()
        local owner = widget._ldf and widget._ldf._layoutParent
        if not owner or not owner._ldf then return end

        if owner._ldf._refreshing then
            owner._ldf._dirty = true
            return
        end

        owner:Refresh()
    end)

    widget._ldf._layoutHooked = true
end

local function AssignLayoutChild(layout, widget, order)
    local children = layout._ldf.children
    widget._ldf = widget._ldf or {}
    widget._ldf._layoutOrder = ResolveLayoutOrder(children, widget, order)
    widget._ldf._layoutParent = layout
    AttachLayoutRefreshHook(widget)
end

local function RemoveLayoutChild(children, widget)
    for i = #children, 1, -1 do
        if children[i] == widget then
            table_remove(children, i)
            return
        end
    end
end

local function DetachLayoutChild(widget)
    widget:ClearAllPoints()
    if not widget._ldf then return end

    widget._ldf._layoutParent = nil
end

local function PropagateScrollChildSize(layout, width, height)
    local layoutParent = layout:GetParent()
    if not layoutParent then return end

    local grandparent = layoutParent:GetParent()
    if not grandparent or grandparent:GetObjectType() ~= "ScrollFrame" then
        return
    end

    if width ~= nil then
        layoutParent:SetWidth(width)
    end

    if height ~= nil then
        layoutParent:SetHeight(height)
    end
end

local function RunLayoutRefresh(layout, refreshFunc)
    local state = layout._ldf
    if state._refreshing then
        state._dirty = true
        return
    end

    state._refreshing = true
    refreshFunc(layout, state)
    LDF.FireCallback("LAYOUT_UPDATED", layout)
    state._refreshing = false

    if state._dirty then
        state._dirty = false
        layout:Refresh()
    end
end

local function GetGridConfig(columnsOrOpts, spacing)
    local defaultSpacing = LDF.spacing.MD
    if type(columnsOrOpts) == "table" then
        local opts = columnsOrOpts
        local columns = ClampPositiveInteger(opts.columns, 2)
        local sharedSpacing = opts.spacing
        local rowSpacing = opts.rowSpacing or sharedSpacing or spacing or defaultSpacing
        local columnSpacing = opts.columnSpacing or sharedSpacing or spacing or defaultSpacing

        return columns, rowSpacing, columnSpacing
    end

    local columns = ClampPositiveInteger(columnsOrOpts, 2)
    local resolvedSpacing = spacing or defaultSpacing
    return columns, resolvedSpacing, resolvedSpacing
end

local function GetAvailableLayoutWidth(layout)
    local availableWidth = layout:GetWidth() or 0
    if availableWidth > 0 then
        return availableWidth
    end

    local parent = layout:GetParent()
    if not parent then
        return 0
    end

    return parent:GetWidth() or 0
end

local function GetGridSpan(widget, columns)
    local opts = widget._ldf and widget._ldf.opts
    local explicitSpan = widget._ldf and widget._ldf._layoutSpan
    local resolvedSpan = explicitSpan

    if resolvedSpan == nil and opts then
        if opts.fullWidth then
            resolvedSpan = columns
        else
            resolvedSpan = opts.span
        end
    end

    resolvedSpan = ClampPositiveInteger(resolvedSpan, 1)
    return math_min(resolvedSpan, columns)
end

-------------------------------------------------------------------------------
-- CreateStackLayout
--
-- Usage with ScrollFrame: add stack as scrollChild, call
-- scrollFrame:UpdateScrollRange() after stack:Refresh().
--
-- Usage with TabGroup: each tab's createFunc returns a stack layout
-- populated with widgets.
-------------------------------------------------------------------------------

function LDF.CreateStackLayout(parent, direction, spacing)
    local stack = CreateFrame("Frame", nil, parent)
    LDF.DisablePixelSnap(stack)

    if (direction or "vertical") == "vertical" then
        stack:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        stack:SetPoint("RIGHT", parent, "RIGHT")
    else
        stack:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        stack:SetPoint("BOTTOM", parent, "BOTTOM")
    end

    stack._ldf = {
        direction = direction or "vertical",
        spacing = spacing or LDF.spacing.MD,
        children = {},
        _refreshing = false,
        _dirty = false,
    }

    -- AddChild - append a widget to the layout
    function stack:AddChild(widget, order)
        if not widget then return end

        AssignLayoutChild(self, widget, order)
        self._ldf.children[#self._ldf.children + 1] = widget
        self:Refresh()
    end

    -- RemoveChild - detach a widget from the layout
    function stack:RemoveChild(widget)
        if not widget then return end

        RemoveLayoutChild(self._ldf.children, widget)
        DetachLayoutChild(widget)
        self:Refresh()
    end

    -- GetChildren - return a shallow copy of the children array
    function stack:GetChildren()
        return CopyChildren(self._ldf.children)
    end

    -- SetSpacing - update the gap between children
    function stack:SetSpacing(newSpacing)
        self._ldf.spacing = newSpacing
        self:Refresh()
    end

    -- Refresh - sort and re-anchor all visible children
    function stack:Refresh()
        RunLayoutRefresh(self, function(layout, cfg)
            local children = cfg.children
            local gap = cfg.spacing
            local isVertical = (cfg.direction == "vertical")
            local prevVisible = nil
            local totalSize = 0

            SortChildrenByOrder(children)

            for i = 1, #children do
                local child = children[i]
                child:ClearAllPoints()

                if child:IsShown() then
                    if not prevVisible then
                        child:SetPoint("TOPLEFT", layout, "TOPLEFT", 0, 0)
                    elseif isVertical then
                        child:SetPoint("TOPLEFT", prevVisible, "BOTTOMLEFT", 0, -gap)
                    else
                        child:SetPoint("TOPLEFT", prevVisible, "TOPRIGHT", gap, 0)
                    end

                    if isVertical then
                        child:SetPoint("RIGHT", layout, "RIGHT")
                        totalSize = totalSize + (prevVisible and gap or 0) + (child:GetHeight() or 0)
                    else
                        child:SetPoint("BOTTOM", layout, "BOTTOM")
                        totalSize = totalSize + (prevVisible and gap or 0) + (child:GetWidth() or 0)
                    end

                    prevVisible = child
                end
            end

            if isVertical then
                layout:SetHeight(totalSize)
                PropagateScrollChildSize(layout, nil, totalSize)
                return
            end

            layout:SetWidth(totalSize)
            PropagateScrollChildSize(layout, totalSize, nil)
        end)
    end

    -- Clear - remove all children and reset size
    function stack:Clear()
        local children = self._ldf.children
        for i = #children, 1, -1 do
            DetachLayoutChild(children[i])
            children[i] = nil
        end

        if self._ldf.direction == "vertical" then
            self:SetHeight(0)
            PropagateScrollChildSize(self, nil, 0)
        else
            self:SetWidth(0)
            PropagateScrollChildSize(self, 0, nil)
        end
    end

    return stack
end

-------------------------------------------------------------------------------
-- CreateGridLayout
-------------------------------------------------------------------------------

function LDF.CreateGridLayout(parent, columnsOrOpts, spacing)
    local columns, rowSpacing, columnSpacing = GetGridConfig(columnsOrOpts, spacing)
    local grid = CreateFrame("Frame", nil, parent)
    LDF.DisablePixelSnap(grid)
    grid:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    grid:SetPoint("RIGHT", parent, "RIGHT")

    grid._ldf = {
        columns = columns,
        rowSpacing = rowSpacing,
        columnSpacing = columnSpacing,
        children = {},
        _refreshing = false,
        _dirty = false,
        _lastMeasuredWidth = 0,
    }

    grid:SetScript("OnSizeChanged", function(self, width)
        local measuredWidth = width or self:GetWidth() or 0
        if measuredWidth <= 0 or measuredWidth == self._ldf._lastMeasuredWidth then
            return
        end

        self._ldf._lastMeasuredWidth = measuredWidth
        self:Refresh()
    end)

    function grid:AddChild(widget, order, span)
        if not widget then return end

        AssignLayoutChild(self, widget, order)
        widget._ldf._layoutSpan = span
        self._ldf.children[#self._ldf.children + 1] = widget
        self:Refresh()
    end

    function grid:RemoveChild(widget)
        if not widget then return end

        RemoveLayoutChild(self._ldf.children, widget)
        if widget._ldf then
            widget._ldf._layoutSpan = nil
        end
        DetachLayoutChild(widget)
        self:Refresh()
    end

    function grid:GetChildren()
        return CopyChildren(self._ldf.children)
    end

    function grid:SetColumns(newColumns)
        self._ldf.columns = ClampPositiveInteger(newColumns, 1)
        self:Refresh()
    end

    function grid:SetSpacing(newSpacing)
        local resolvedSpacing = newSpacing or LDF.spacing.MD
        self._ldf.rowSpacing = resolvedSpacing
        self._ldf.columnSpacing = resolvedSpacing
        self:Refresh()
    end

    function grid:Refresh()
        RunLayoutRefresh(self, function(layout, cfg)
            local children = cfg.children
            local columnsCount = ClampPositiveInteger(cfg.columns, 1)
            local columnGap = cfg.columnSpacing or 0
            local rowGap = cfg.rowSpacing or 0
            local availableWidth = math_max(GetAvailableLayoutWidth(layout), 0)
            cfg._lastMeasuredWidth = availableWidth
            local totalColumnGap = math_max(columnsCount - 1, 0) * columnGap
            local columnWidth = math_max((availableWidth - totalColumnGap) / columnsCount, 0)
            local currentColumn = 1
            local currentY = 0
            local rowHeight = 0
            local hasRow = false
            local visibleCount = 0

            SortChildrenByOrder(children)

            local function FinishRow()
                if not hasRow then return end

                currentY = currentY + rowHeight + rowGap
                currentColumn = 1
                rowHeight = 0
                hasRow = false
            end

            for i = 1, #children do
                local child = children[i]
                child:ClearAllPoints()

                if child:IsShown() then
                    local span = GetGridSpan(child, columnsCount)
                    if hasRow and (currentColumn + span - 1 > columnsCount) then
                        FinishRow()
                    end

                    local childWidth = math_max(columnWidth * span + columnGap * (span - 1), 0)
                    local xOffset = (currentColumn - 1) * (columnWidth + columnGap)

                    child:SetPoint("TOPLEFT", layout, "TOPLEFT", xOffset, -currentY)
                    child:SetWidth(childWidth)

                    rowHeight = math_max(rowHeight, child:GetHeight() or 0)
                    currentColumn = currentColumn + span
                    hasRow = true
                    visibleCount = visibleCount + 1

                    if currentColumn > columnsCount then
                        FinishRow()
                    end
                end
            end

            local totalHeight = 0
            if visibleCount > 0 then
                if hasRow then
                    totalHeight = currentY + rowHeight
                else
                    totalHeight = math_max(currentY - rowGap, 0)
                end
            end

            layout:SetHeight(totalHeight)
            PropagateScrollChildSize(layout, nil, totalHeight)
        end)
    end

    function grid:Clear()
        local children = self._ldf.children
        for i = #children, 1, -1 do
            if children[i]._ldf then
                children[i]._ldf._layoutSpan = nil
            end
            DetachLayoutChild(children[i])
            children[i] = nil
        end

        self:SetHeight(0)
        PropagateScrollChildSize(self, nil, 0)
    end

    return grid
end
