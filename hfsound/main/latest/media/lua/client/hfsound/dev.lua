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
    self._depth = self._depth + 1
    if self._depth == 1 then
        self._entrytime = GameTime.getServerTime()
    end
end

function ReentrantPerfTimer:exit()
    self._depth = self._depth - 1
    if self._depth == 0 then
        self._entered = true
        local elapsed = GameTime.getServerTime() - self._entrytime
        self._total_time = self._total_time + elapsed
        self._events = self._events + 1
        if elapsed > self._maxtime then self._maxtime = elapsed end
    end
end

---@param reset boolean
function ReentrantPerfTimer:report(reset)
    ---@diagnostic disable-next-line: unnecessary-if
    if HFSOUND and HFSOUND.debug then
        if HFSOUND.debug.reporting == true or type(HFSOUND.debug.reporting) == "string" and string.match(self._name, HFSOUND.debug.reporting) then
            local average = self._total_time / self._events

            if self._events > 0 then
                print(string.format("perf: %32s; average = %.5f ms",
                    self._name,
                    average / 1000000
                ))
            end
        end
    end



    if reset then
        self._total_time = 0
        self._events = 0
        self._maxtime = 0
    end
end

if not getDebug() then
    ReentrantPerfTimer.enter = function() end
    ReentrantPerfTimer.exit = function() end
    ReentrantPerfTimer.report = function() end
end

dev.PerfTimer = ReentrantPerfTimer

-- #endregion

return dev
