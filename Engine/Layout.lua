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

        local children = self._ldf.children
        local resolvedOrder = order
            or (widget._ldf and widget._ldf.opts and widget._ldf.opts.order)
            or (#children + 1)

        widget._ldf = widget._ldf or {}
        widget._ldf._layoutOrder = resolvedOrder
        widget._ldf._layoutParent = self

        if not widget._ldf._layoutHooked then
            widget:HookScript("OnSizeChanged", function()
                local owner = widget._ldf._layoutParent
                if not owner or not owner._ldf then return end
                if owner._ldf._refreshing then
                    owner._ldf._dirty = true
                    return
                end
                owner:Refresh()
            end)
            widget._ldf._layoutHooked = true
        end

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
        widget._ldf._layoutParent = nil
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
        if self._ldf._refreshing then
            self._ldf._dirty = true
            return
        end
        self._ldf._refreshing = true

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

                if isVertical then
                    child:SetPoint("RIGHT", self, "RIGHT")
                else
                    child:SetPoint("BOTTOM", self, "BOTTOM")
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

        -- Propagate size to scrollChild so ScrollFrame updates scroll range.
        -- Only applies when the stack's parent is a scroll child (its grandparent
        -- is a ScrollFrame).
        local layoutParent = self:GetParent()
        if layoutParent then
            local grandparent = layoutParent:GetParent()
            if grandparent and grandparent:GetObjectType() == "ScrollFrame" then
                if isVertical then
                    layoutParent:SetHeight(totalSize)
                else
                    layoutParent:SetWidth(totalSize)
                end
            end
        end

        LDF.FireCallback("LAYOUT_UPDATED", self)
        self._ldf._refreshing = false
        if self._ldf._dirty then
            self._ldf._dirty = false
            self:Refresh()
        end
    end

    -- Clear - remove all children and reset size
    function stack:Clear()
        local children = self._ldf.children
        for i = #children, 1, -1 do
            children[i]:ClearAllPoints()
            if children[i]._ldf then
                children[i]._ldf._layoutParent = nil
            end
            children[i] = nil
        end

        if self._ldf.direction == "vertical" then
            self:SetHeight(0)
        else
            self:SetWidth(0)
        end
    end

    return stack
end
