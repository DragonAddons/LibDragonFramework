-------------------------------------------------------------------------------
-- ItemList.lua
-- Scrollable grid of item slots with drag-and-drop management
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local CreateFrame = CreateFrame
local GetCursorInfo = GetCursorInfo
local ClearCursor = ClearCursor
local pairs = pairs
local ipairs = ipairs
local math_floor = math.floor
local math_max = math.max
local string_format = string.format
local table_sort = table.sort

local SLOT_SPACING = LDF.spacing.SM
local DEFAULT_SLOT_SIZE = 36
local DEFAULT_SLOTS_PER_ROW = 6
local DEFAULT_MAX_ITEMS = 30
local DEFAULT_EMPTY_TEXT = "Drop items here"
local HEADER_HEIGHT = 18
local ADD_SLOT_BG = { 0.08, 0.08, 0.08, 0.6 }
local DASHED_BORDER_COLOR = { 0.6, 0.6, 0.6, 0.5 }

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function CountItems(items)
    local count = 0
    for _ in pairs(items) do count = count + 1 end
    return count
end

local function CollectSortedIDs(items)
    local ids = {}
    for id in pairs(items) do ids[#ids + 1] = id end
    table_sort(ids)
    return ids
end

local function PositionSlot(slot, index, contentFrame, slotSize)
    local slotsPerRow = contentFrame._ldf.slotsPerRow
    local row = math_floor(index / slotsPerRow)
    local col = index - (row * slotsPerRow)
    local stride = slotSize + SLOT_SPACING
    slot:ClearAllPoints()
    LDF.SetPoint(slot, "TOPLEFT", contentFrame, "TOPLEFT", col * stride, -(row * stride))
end

-------------------------------------------------------------------------------
-- Add-slot (the "+" placeholder)
-------------------------------------------------------------------------------

local function CreateAddSlot(parent, slotSize)
    local slot = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    slot:SetSize(slotSize, slotSize)
    LDF.DisablePixelSnap(slot)
    slot:SetBackdrop({ bgFile = LDF.WHITE8X8, edgeFile = LDF.WHITE8X8, edgeSize = 1 })
    slot:SetBackdropColor(ADD_SLOT_BG[1], ADD_SLOT_BG[2], ADD_SLOT_BG[3], ADD_SLOT_BG[4])
    slot:SetBackdropBorderColor(
        DASHED_BORDER_COLOR[1], DASHED_BORDER_COLOR[2],
        DASHED_BORDER_COLOR[3], DASHED_BORDER_COLOR[4]
    )

    local plusText = LDF.CreateFontString(slot, "body", "+")
    plusText:SetPoint("CENTER", slot, "CENTER", 0, 0)
    plusText:SetTextColor(LDF.GetColor("textMuted"))

    slot:EnableMouse(true)
    return slot
end

-------------------------------------------------------------------------------
-- Drag-and-drop handler
-------------------------------------------------------------------------------

local function HandleItemDrop(list)
    if not list:IsEnabled() then return end

    local infoType, itemID = GetCursorInfo()
    if infoType ~= "item" or not itemID then return end

    local items = list._ldf.opts.get()
    if items[itemID] then return end
    if CountItems(items) >= list._ldf.maxItems then return end

    ClearCursor()
    list:AddItem(itemID)
end

-------------------------------------------------------------------------------
-- Grid rebuild
-------------------------------------------------------------------------------

local function RebuildGrid(list)
    local pool = list._ldf.slotPool
    local opts = list._ldf.opts
    local slotSize = list._ldf.slotSize
    local maxItems = list._ldf.maxItems
    local contentFrame = list._ldf.gridContent

    pool:ReleaseAll()

    local items = opts.get()
    local ids = CollectSortedIDs(items)
    local count = #ids

    for i, itemID in ipairs(ids) do
        local slot = pool:Acquire()
        slot:SetItem(itemID)
        PositionSlot(slot, i - 1, contentFrame, slotSize)
        slot:Show()
    end

    -- Add-slot visibility
    local addSlot = list._ldf.addSlot
    if count < maxItems then
        PositionSlot(addSlot, count, contentFrame, slotSize)
        addSlot:Show()
    else
        addSlot:Hide()
    end

    -- Content height for scroll
    local totalSlots = count < maxItems and count + 1 or count
    local slotsPerRow = list._ldf.slotsPerRow
    local rows = totalSlots > 0 and (math_floor((totalSlots - 1) / slotsPerRow) + 1) or 1
    contentFrame:SetHeight(math_max(1, rows * (slotSize + SLOT_SPACING)))

    -- Count and empty text
    list._ldf.countText:SetText(string_format("%d / %d", count, maxItems))
    list._ldf.emptyText:SetShown(count == 0)

    if list._ldf.scrollWrapper.UpdateScrollRange then
        list._ldf.scrollWrapper:UpdateScrollRange()
    end
end

-------------------------------------------------------------------------------
-- Factory: CreateItemList
-------------------------------------------------------------------------------

function LDF.CreateItemList(parent, opts)
    if not parent then error("LDF.CreateItemList: parent required", 2) end
    if not opts then error("LDF.CreateItemList: opts required", 2) end
    if not opts.get then error("LDF.CreateItemList: opts.get required", 2) end
    if not opts.set then error("LDF.CreateItemList: opts.set required", 2) end

    local slotSize = opts.slotSize or DEFAULT_SLOT_SIZE
    local slotsPerRow = opts.slotsPerRow or DEFAULT_SLOTS_PER_ROW
    local maxItems = opts.maxItems or DEFAULT_MAX_ITEMS
    local totalWidth = slotsPerRow * slotSize + (slotsPerRow - 1) * SLOT_SPACING

    -- Container
    local list = LDF.CreateWidgetFrame(parent, "Frame")
    list:SetWidth(totalWidth)
    list._ldf.slotSize = slotSize
    list._ldf.slotsPerRow = slotsPerRow
    list._ldf.maxItems = maxItems

    -- Label
    local label = LDF.CreateFontString(list, "small", opts.label or "")
    label:SetPoint("TOPLEFT", list, "TOPLEFT", 0, 0)
    list._ldf.label = label

    -- Count display
    local countText = LDF.CreateFontString(list, "small", "")
    countText:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, 0)
    countText:SetTextColor(LDF.GetColor("textMuted"))
    list._ldf.countText = countText

    -- Scroll area
    local scrollArea = CreateFrame("Frame", nil, list)
    scrollArea:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(HEADER_HEIGHT + 2))
    scrollArea:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", 0, 0)

    local scrollWrapper = LDF.CreateScrollFrame(scrollArea)
    list._ldf.scrollWrapper = scrollWrapper
    list._ldf.gridContent = scrollWrapper.scrollChild
    scrollWrapper.scrollChild._ldf = scrollWrapper.scrollChild._ldf or {}
    scrollWrapper.scrollChild._ldf.slotsPerRow = slotsPerRow

    -- Empty text
    local emptyText = LDF.CreateFontString(
        scrollWrapper.scrollChild, "small", opts.emptyText or DEFAULT_EMPTY_TEXT
    )
    emptyText:SetPoint("CENTER", scrollWrapper.scrollChild, "CENTER", 0, 0)
    emptyText:SetTextColor(LDF.GetColor("textMuted"))
    emptyText:Hide()
    list._ldf.emptyText = emptyText

    -- Object pool for ItemSlots
    local slotPool = LDF.CreateObjectPool(
        function()
            return LDF.CreateItemSlot(scrollWrapper.scrollChild, {
                size = slotSize,
                showTooltip = true,
                onAccept = function(itemID) list:AddItem(itemID) end,
                onRemove = function(itemID) list:RemoveItem(itemID) end,
            })
        end,
        function(slot) slot:ClearItem(); slot:Hide() end
    )
    list._ldf.slotPool = slotPool

    -- Add-slot ("+" button)
    local addSlot = CreateAddSlot(scrollWrapper.scrollChild, slotSize)
    addSlot:SetScript("OnReceiveDrag", function() HandleItemDrop(list) end)
    addSlot:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then HandleItemDrop(list) end
    end)
    list._ldf.addSlot = addSlot

    -- Drop zone on the scroll content
    scrollWrapper.scrollChild:EnableMouse(true)
    scrollWrapper.scrollChild:SetScript("OnReceiveDrag", function() HandleItemDrop(list) end)
    scrollWrapper.scrollChild:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then HandleItemDrop(list) end
    end)

    ---------------------------------------------------------------------------
    -- Public API
    ---------------------------------------------------------------------------

    function list:GetValue()
        return self._ldf.opts.get()
    end

    function list:SetValue(items)
        self._ldf.opts.set(items)
        RebuildGrid(self)
    end

    function list:Refresh()
        RebuildGrid(self)
    end

    function list:AddItem(itemID)
        if not itemID then return end
        local currentItems = self._ldf.opts.get()
        if currentItems[itemID] then return end
        if CountItems(currentItems) >= self._ldf.maxItems then return end

        currentItems[itemID] = true
        self._ldf.opts.set(currentItems)
        self:FireValueChanged(currentItems)
        RebuildGrid(self)
    end

    function list:RemoveItem(itemID)
        if not itemID then return end
        local currentItems = self._ldf.opts.get()
        if not currentItems[itemID] then return end

        currentItems[itemID] = nil
        self._ldf.opts.set(currentItems)
        self:FireValueChanged(currentItems)
        RebuildGrid(self)
    end

    function list:GetItemCount()
        return CountItems(self._ldf.opts.get())
    end

    ---------------------------------------------------------------------------
    -- Widget protocol + initial build
    ---------------------------------------------------------------------------

    LDF.ApplyWidgetProtocol(list, opts)

    -- Override Refresh after ApplyWidgetProtocol (which wires its own via opts.get)
    function list:Refresh()
        RebuildGrid(self)
    end

    local baseSetEnabled = list.SetEnabled
    function list:SetEnabled(state)
        baseSetEnabled(self, state)
        addSlot:SetShown(state and CountItems(self._ldf.opts.get()) < self._ldf.maxItems)
    end

    list:Refresh()

    return list
end
