local dev = {}


-- #region class: PerfTime

---@class hfs.ReentrantPerfTimer
local ReentrantPerfTimer = {}; ReentrantPerfTimer.__index = ReentrantPerfTimer

---@param name string
---@return hfs.ReentrantPerfTimer
function ReentrantPerfTimer.new(name)
    local obj = setmetatable({}, ReentrantPerfTimer)

    if getDebug() and not isClient() and not GameTime.getServerTimeShiftIsSet() then
        GameTime.setServerTimeShift(0)
    end

    obj._name       = name

    obj._creation   = 0

    ---@type int
    obj._depth      = 0

    ---@type number
    obj._entrytime  = 0

    ---@type number
    obj._total_time = 0

    ---@type number
    obj._events     = 0

    ---@type number
    obj._maxtime    = 0

    return obj
end

function ReentrantPerfTimer:enter()
    if getDebug() then
        self._depth = self._depth + 1
        if self._depth == 1 then
            self._entrytime = GameTime.getServerTime()
        end
    end
end

function ReentrantPerfTimer:exit()
    if getDebug() then
        self._depth = self._depth - 1
        if self._depth == 0 then
            self._entered = true
            local elapsed = GameTime.getServerTime() - self._entrytime
            self._total_time = self._total_time + elapsed
            self._events = self._events + 1
            if elapsed > self._maxtime then self._maxtime = elapsed end
        end
    end
end

---@param reset boolean
function ReentrantPerfTimer:report(reset)
    if getDebug() then
        local average = self._total_time / self._events

        print("----------------------------------------")
        print(string.format("perfcounter: %s", self._name))
        print(string.format("    events     = %d", self._events))

        if self._events > 0 then
            print(string.format("    total_time = %d millis", math.floor(self._total_time / 1000000)))
            print(string.format("    average    = %d millis (%d nanos)", math.floor(average / 1000000), average))
            print(string.format("    max        = %d millis (%d nanos)", math.floor(self._maxtime / 1000000), self._maxtime))
        end

        if reset then
            self._total_time = 0
            self._events     = 0
            self._maxtime    = 0
        end
    end
end

dev.PerfTimer = ReentrantPerfTimer

-- #endregion

return dev
