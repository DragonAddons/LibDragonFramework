-------------------------------------------------------------------------------
-- Quality.lua
-- Item quality color helpers
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local type = type

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local WHITE = { 1, 1, 1, 1, "|cffffffff" }

local QUALITY_NAMES = {
    [0] = "Poor",
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Artifact",
    [7] = "Heirloom",
}

local STRIPE_HEIGHT = 2
local GLOW_ALPHA = 0.1

-------------------------------------------------------------------------------
-- Internal helpers
-------------------------------------------------------------------------------

local function IsValidQuality(quality)
    return type(quality) == "number" and quality >= 0 and quality <= 7
end

local function GetToken(quality)
    if not IsValidQuality(quality) then return nil end
    return LDF.colors["quality" .. quality]
end

-------------------------------------------------------------------------------
-- Color retrieval
-------------------------------------------------------------------------------

function LDF.GetQualityColor(quality)
    local c = GetToken(quality) or WHITE
    return c[1], c[2], c[3], c[4]
end

function LDF.GetQualityColorTable(quality)
    return GetToken(quality) or WHITE
end

function LDF.GetQualityHex(quality)
    local c = GetToken(quality) or WHITE
    return c[5]
end

function LDF.GetQualityName(quality)
    return QUALITY_NAMES[quality] or "Unknown"
end

-------------------------------------------------------------------------------
-- Frame accents
-------------------------------------------------------------------------------

local function EnsureLdf(frame)
    frame._ldf = frame._ldf or {}
    return frame._ldf
end

local function CreateAccentTexture(frame)
    local tex = frame:CreateTexture(nil, "OVERLAY")
    tex:SetTexture(LDF.WHITE8X8)
    return tex
end

function LDF.ApplyQualityBorder(frame, quality)
    frame:SetBackdropBorderColor(LDF.GetQualityColor(quality))
    local ldf = EnsureLdf(frame)
    ldf._qualityBorder = quality
end

function LDF.ApplyQualityAccent(frame, quality, style)
    local ldf = EnsureLdf(frame)

    if quality == nil then
        if ldf._qualityAccent then ldf._qualityAccent:Hide() end
        return
    end

    local r, g, b = LDF.GetQualityColor(quality)

    if style == "border" then
        LDF.ApplyQualityBorder(frame, quality)
        return
    end

    local tex = ldf._qualityAccent or CreateAccentTexture(frame)
    ldf._qualityAccent = tex

    if style == "stripe" then
        tex:ClearAllPoints()
        tex:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        tex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        tex:SetHeight(STRIPE_HEIGHT)
        tex:SetVertexColor(r, g, b, 1)
    elseif style == "glow" then
        tex:ClearAllPoints()
        tex:SetAllPoints(frame)
        tex:SetVertexColor(r, g, b, GLOW_ALPHA)
    end

    tex:Show()
end

function LDF.ClearQualityAccent(frame)
    if not frame._ldf then return end
    local tex = frame._ldf._qualityAccent
    if not tex then return end
    tex:Hide()
    frame._ldf._qualityAccent = nil
end
