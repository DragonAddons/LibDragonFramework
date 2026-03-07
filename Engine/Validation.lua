-------------------------------------------------------------------------------
-- Validation.lua
-- Value clamping, rounding, and type coercion helpers
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local tonumber = tonumber
local _tostring = tostring
local format = format
local type = type

-------------------------------------------------------------------------------
-- Math helpers
-------------------------------------------------------------------------------

function LDF.Clamp(value, min, max)
    if value == nil then return min end
    return math_min(math_max(value, min), max)
end

function LDF.Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math_floor(value * mult + 0.5) / mult
end

function LDF.Snap(value, step)
    if not step or step == 0 then return value end
    return LDF.Round(value / step) * step
end

-------------------------------------------------------------------------------
-- Type coercion
-------------------------------------------------------------------------------

function LDF.ToNumber(value, fallback)
    return tonumber(value) or fallback or 0
end

function LDF.FormatNumber(value, decimals)
    return format("%." .. (decimals or 0) .. "f", value)
end

function LDF.FormatPercent(value, decimals)
    return LDF.FormatNumber(value * 100, decimals) .. "%"
end

-------------------------------------------------------------------------------
-- Type checks
-------------------------------------------------------------------------------

function LDF.IsNumber(value)
    return type(value) == "number"
end

function LDF.IsString(value)
    return type(value) == "string"
end

function LDF.IsFunction(value)
    return type(value) == "function"
end

function LDF.IsTable(value)
    return type(value) == "table"
end

function LDF.IsBoolean(value)
    return type(value) == "boolean"
end
