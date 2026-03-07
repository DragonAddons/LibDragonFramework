-------------------------------------------------------------------------------
-- Layout.lua
-- Auto-flow stack layout container
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local CreateFrame = CreateFrame
local table_sort = table.sort

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

    stack._ldf = {
        direction = direction or "vertical",
        spacing = spacing or LDF.spacing.MD,
        children = {},
    }

    -- AddChild - append a widget to the layout
    function stack:AddChild(widget, order)
        if not widget then return end

        local children = self._ldf.children
        local resolvedOrder = order
            or (widget._ldf and widget._ldf.opts and widget._ldf.opts.order)
            or (#children + 1)

        widget._ldf = widget._ldf or {}
        widget._ldf._layoutOrder = resolvedOrder

        children[#children + 1] = widget
        self:Refresh()
    end

    -- RemoveChild - detach a widget from the layout
    function stack:RemoveChild(widget)
        if not widget then return end

        local children = self._ldf.children
        for i = #children, 1, -1 do
            if children[i] == widget then
                table.remove(children, i)
                break
            end
        end

        widget:ClearAllPoints()
        self:Refresh()
    end

    -- GetChildren - return a shallow copy of the children array
    function stack:GetChildren()
        local children = self._ldf.children
        local copy = {}
        for i = 1, #children do
            copy[i] = children[i]
        end
        return copy
    end

    -- SetSpacing - update the gap between children
    function stack:SetSpacing(newSpacing)
        self._ldf.spacing = newSpacing
        self:Refresh()
    end

    -- Refresh - sort and re-anchor all visible children
    function stack:Refresh()
        local cfg = self._ldf
        local children = cfg.children
        local gap = cfg.spacing
        local isVertical = (cfg.direction == "vertical")

        table_sort(children, function(a, b)
            return (a._ldf._layoutOrder or 0) < (b._ldf._layoutOrder or 0)
        end)

        local prevVisible = nil
        local totalSize = 0
        local maxCross = 0

        for i = 1, #children do
            local child = children[i]
            child:ClearAllPoints()

            if child:IsShown() then
                if not prevVisible then
                    child:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
                elseif isVertical then
                    child:SetPoint("TOPLEFT", prevVisible, "BOTTOMLEFT", 0, -gap)
                else
                    child:SetPoint("TOPLEFT", prevVisible, "TOPRIGHT", gap, 0)
                end

                local childW = child:GetWidth() or 0
                local childH = child:GetHeight() or 0

                if prevVisible then
                    totalSize = totalSize + gap
                end

                if isVertical then
                    totalSize = totalSize + childH
                    if childW > maxCross then maxCross = childW end
                else
                    totalSize = totalSize + childW
                    if childH > maxCross then maxCross = childH end
                end

                prevVisible = child
            end
        end

        if isVertical then
            self:SetHeight(totalSize)
        else
            self:SetWidth(totalSize)
        end

        LDF.FireCallback("LAYOUT_UPDATED", self)
    end

    -- Clear - remove all children and reset size
    function stack:Clear()
        local children = self._ldf.children
        for i = #children, 1, -1 do
            children[i]:ClearAllPoints()
            children[i] = nil
        end

        self:SetHeight(0)
        self:SetWidth(0)
    end

    return stack
end
