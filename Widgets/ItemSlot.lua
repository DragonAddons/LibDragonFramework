-------------------------------------------------------------------------------
-- ItemSlot.lua
-- Single item display slot with icon, quality border, and drag-and-drop
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

-- WoW API cache
local GetItemInfo = GetItemInfo
local GetCursorInfo = GetCursorInfo
local ClearCursor = ClearCursor
local GameTooltip = GameTooltip
local C_Timer = C_Timer

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local DEFAULT_SIZE = 36
local EMPTY_ICON = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
local EMPTY_ALPHA = 0.3
local MAX_RETRIES = 3
local RETRY_DELAY = 0.5

-------------------------------------------------------------------------------
-- Query item info with retry on nil
-------------------------------------------------------------------------------

local function QueryItemInfo(slot, itemID, attempt)
    attempt = attempt or 1

    local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
    if itemName and itemTexture then
        slot._ldf.icon:SetTexture(itemTexture)
        slot._ldf.icon:SetAlpha(1)
        LDF.ApplyQualityBorder(slot, itemQuality)
        return
    end

    if attempt < MAX_RETRIES then
        C_Timer.After(RETRY_DELAY, function()
            if slot._ldf.itemID == itemID then
                QueryItemInfo(slot, itemID, attempt + 1)
            end
        end)
    end
end

-------------------------------------------------------------------------------
-- Handle cursor drop onto the slot
-------------------------------------------------------------------------------

local function HandleDrop(slot)
    local infoType, itemID = GetCursorInfo()
    if infoType ~= "item" or not itemID then return end

    ClearCursor()
    slot:SetItem(itemID)

    local onAccept = slot._ldf.opts.onAccept
    if onAccept then onAccept(itemID) end
end

-------------------------------------------------------------------------------
-- Tooltip handlers
-------------------------------------------------------------------------------

local function OnEnterSlot(slot)
    if not slot._ldf.itemID then return end
    if slot._ldf.opts.showTooltip == false then return end

    GameTooltip:SetOwner(slot, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(slot._ldf.itemID)
    GameTooltip:Show()
end

local function OnLeaveSlot()
    GameTooltip:Hide()
end

-------------------------------------------------------------------------------
-- Click handler (left = drop, right = remove)
-------------------------------------------------------------------------------

local function OnClickSlot(slot, button)
    if not slot:IsEnabled() then return end

    if button == "RightButton" and slot._ldf.itemID then
        local removedID = slot._ldf.itemID
        slot:ClearItem()
        local onRemove = slot._ldf.opts.onRemove
        if onRemove then onRemove(removedID) end
        return
    end

    if button == "LeftButton" then
        HandleDrop(slot)
    end
end

-------------------------------------------------------------------------------
-- Apply empty state visuals
-------------------------------------------------------------------------------

local function ApplyEmptyState(slot)
    slot._ldf.icon:SetTexture(EMPTY_ICON)
    slot._ldf.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    slot._ldf.icon:SetAlpha(EMPTY_ALPHA)
    LDF.ApplyBackdrop(slot, "widget")
end

-------------------------------------------------------------------------------
-- Factory: CreateItemSlot
-------------------------------------------------------------------------------

function LDF.CreateItemSlot(parent, opts)
    if not parent then error("LDF.CreateItemSlot: parent required", 2) end

    opts = opts or {}
    local size = opts.size or DEFAULT_SIZE
    if opts.showTooltip == nil then opts.showTooltip = true end

    ---------------------------------------------------------------------------
    -- Frame setup
    ---------------------------------------------------------------------------

    local slot = LDF.CreateWidgetFrame(parent, "Button")
    slot._ldf.itemID = nil
    slot._ldf.opts = opts

    LDF.ApplyBaseMixin(slot)
    slot:InitBase(opts)

    LDF.SetSize(slot, size, size)
    LDF.ApplyBackdrop(slot, "widget")

    ---------------------------------------------------------------------------
    -- Icon texture (inset 1px for border)
    ---------------------------------------------------------------------------

    local icon = slot:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1, 1)
    slot._ldf.icon = icon

    ApplyEmptyState(slot)

    ---------------------------------------------------------------------------
    -- Event scripts
    ---------------------------------------------------------------------------

    slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    slot:SetScript("OnClick", OnClickSlot)
    slot:SetScript("OnReceiveDrag", function(self) HandleDrop(self) end)
    slot:SetScript("OnEnter", OnEnterSlot)
    slot:SetScript("OnLeave", OnLeaveSlot)

    ---------------------------------------------------------------------------
    -- Public API
    ---------------------------------------------------------------------------

    function slot:SetItem(itemID)
        if not itemID then
            self:ClearItem()
            return
        end
        self._ldf.itemID = itemID
        QueryItemInfo(self, itemID)
    end

    function slot:GetItem()
        return self._ldf.itemID
    end

    function slot:ClearItem()
        self._ldf.itemID = nil
        ApplyEmptyState(self)
    end

    ---------------------------------------------------------------------------
    -- Pixel updater
    ---------------------------------------------------------------------------

    LDF.AddToPixelUpdater(slot, "onshow")

    return slot
end
