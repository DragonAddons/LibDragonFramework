-------------------------------------------------------------------------------
-- Init.lua
-- Library bootstrap and namespace initialization
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LIB_NAME, LDF = ...

-- Version info
LDF.version = "@project-version@"
LDF.major = "LibDragonFramework"
LDF.minor = 1

-- Sub-tables
LDF.callbacks = {} -- internal event bus
LDF.widgets = {}   -- widget registry (for future iteration)
LDF.colors = {}    -- populated by Theme/Tokens.lua
LDF.fonts = {}     -- populated by Theme/Typography.lua
LDF.spacing = {}   -- populated by Theme/Spacing.lua
LDF.heights = {}   -- populated by Theme/Spacing.lua
LDF.dims = {}      -- populated by Theme/Spacing.lua

-------------------------------------------------------------------------------
-- Callback system
-------------------------------------------------------------------------------

--- Register a callback function for a named event.
--- @param event string  event name to listen for
--- @param key string    unique key identifying this registration
--- @param fn function   handler invoked when the event fires
function LDF.RegisterCallback(event, key, fn)
    if type(event) ~= "string" or event == "" then
        error("RegisterCallback: 'event' must be a non-empty string", 2)
    end
    if type(key) ~= "string" or key == "" then
        error("RegisterCallback: 'key' must be a non-empty string", 2)
    end
    if type(fn) ~= "function" then
        error("RegisterCallback: 'fn' must be a function", 2)
    end

    if not LDF.callbacks[event] then
        LDF.callbacks[event] = {}
    end
    LDF.callbacks[event][key] = fn
end

--- Remove a previously registered callback.
--- @param event string  event name the callback was registered under
--- @param key string    unique key used during registration
function LDF.UnregisterCallback(event, key)
    if type(event) ~= "string" or event == "" then
        error("UnregisterCallback: 'event' must be a non-empty string", 2)
    end
    if type(key) ~= "string" or key == "" then
        error("UnregisterCallback: 'key' must be a non-empty string", 2)
    end

    if not LDF.callbacks[event] then
        return
    end
    LDF.callbacks[event][key] = nil
end

--- Fire all registered callbacks for a named event.
--- @param event string  event name to fire
--- @param ... any       arguments forwarded to each callback
function LDF.FireCallback(event, ...)
    if type(event) ~= "string" or event == "" then
        error("FireCallback: 'event' must be a non-empty string", 2)
    end

    local handlers = LDF.callbacks[event]
    if not handlers then
        return
    end

    for _key, fn in pairs(handlers) do
        fn(...)
    end
end

-------------------------------------------------------------------------------
-- Global export
-------------------------------------------------------------------------------

LibDragonFramework = LDF
