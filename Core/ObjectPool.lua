-------------------------------------------------------------------------------
-- ObjectPool.lua
-- Simple object pool for frame reuse
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local LDF = LibDragonFramework

local pairs = pairs
local tremove = table.remove

--- Create a new object pool.
--- @param createFunc function  factory that returns a new object
--- @param resetFunc function?  optional reset handler called on acquire/release
--- @return table pool  pool object with Acquire, Release, ReleaseAll, etc.
function LDF.CreateObjectPool(createFunc, resetFunc)
    if type(createFunc) ~= "function" then
        error("CreateObjectPool: 'createFunc' must be a function", 2)
    end

    local pool = {
        _active = {},
        _inactive = {},
        _createFunc = createFunc,
        _resetFunc = resetFunc,
    }

    function pool:Acquire()
        local obj
        local isNew = false
        local numInactive = #self._inactive

        if numInactive > 0 then
            obj = tremove(self._inactive, numInactive)
            if self._resetFunc then
                self._resetFunc(obj)
            end
        else
            obj = self._createFunc()
            isNew = true
        end

        self._active[obj] = true
        return obj, isNew
    end

    function pool:Release(obj)
        if not obj then return end
        if not self._active[obj] then return end

        self._active[obj] = nil

        if self._resetFunc then
            self._resetFunc(obj)
        elseif obj.Hide then
            obj:Hide()
        end

        self._inactive[#self._inactive + 1] = obj
    end

    function pool:ReleaseAll()
        for obj in pairs(self._active) do
            self:Release(obj)
        end
    end

    function pool:GetNumActive()
        local count = 0
        for _ in pairs(self._active) do
            count = count + 1
        end
        return count
    end

    function pool:GetNumInactive()
        return #self._inactive
    end

    function pool:EnumerateActive()
        return pairs(self._active)
    end

    return pool
end
