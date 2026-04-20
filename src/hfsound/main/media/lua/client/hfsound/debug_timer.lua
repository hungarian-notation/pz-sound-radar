local dev = {}

local io = require("hfsound/io")

--[[

    Monitors can be selected for reporting by setting:
        HFSOUND.debug.reporting = true

    Or for an individual monitor:
        HFSOUND.debug.reporting = { <name> = true }

--]]

---@type hfs.PerformanceTimer[]
local monitors = {}


if getDebug() then
    local log_location = "hfsound.performance.csv"
    io.rotatefile(log_location, 8)

    local function reporter()
        local writer = getFileWriter(log_location, true, true)
        assert(writer)
        if HFSOUND.debug.reporting ~= false then
            print("writing to: " .. log_location)
            for _, monitor in ipairs(monitors) do
                monitor:report(true, writer)
            end
        end
        writer:close()
        writer = nil
    end

    local interval = 60

    ---@param tick_number int
    local function tick(tick_number)
        if tick_number % interval == interval - 1 then
            reporter()
        end
    end

    Events.OnTick.Add(tick)
end

-- #region class: PerfTime

---@class hfs.PerformanceTimer
local PerformanceTimer = {}; PerformanceTimer.__index = PerformanceTimer


---@param name string
---@return hfs.PerformanceTimer
function PerformanceTimer.new(name)
    local obj = setmetatable({}, PerformanceTimer)

    if getDebug() and not isClient() and not GameTime.getServerTimeShiftIsSet() then
        GameTime.setServerTimeShift(0)
    end

    -- logged values:

    obj.m_name       = name
    ---@type number
    obj.m_total_time = 0
    ---@type number
    obj.m_events     = 0
    ---@type number
    obj.m_maxtime    = 0

    -- internal state:

    obj.m_start      = 0
    ---@type int
    obj.m_depth      = 0
    ---@type number
    obj.m_entrytime  = 0

    obj:reset()

    table.insert(monitors, obj)

    return obj
end

local now = GameTime.getServerTime

function PerformanceTimer:reset()
    self.m_start = now()
    self.m_total_time = 0
    self.m_events = 0
    self.m_maxtime = 0
end

function PerformanceTimer:enter()
    self.m_depth = self.m_depth + 1
    if self.m_depth == 1 then
        if self.m_events == 0 then
            self.m_start = now()
        end
        self.m_entrytime = now()
    end
end

function PerformanceTimer:exit()
    self.m_depth = self.m_depth - 1
    if self.m_depth == 0 then
        self._entered = true
        local elapsed = now() - self.m_entrytime
        self.m_total_time = self.m_total_time + elapsed
        self.m_events = self.m_events + 1
        if elapsed > self.m_maxtime then self.m_maxtime = elapsed end
    end
end

---@param reset boolean
---@param writer LuaManager.GlobalObject.LuaFileWriter
function PerformanceTimer:report(reset, writer)
    local reporting = HFSOUND and HFSOUND.debug and HFSOUND.debug.reporting -- can't cache above this closure
    local millis = 1e-6

    ---@diagnostic disable-next-line: unnecessary-if
    if reporting then
        local period = now() - self.m_start

        writer:writeln(string.format("%s, %f, %f, %f, %f, %f",
            self.m_name,
            period * millis,
            self.m_events,
            self.m_total_time * millis,
            self.m_total_time * millis / self.m_events,
            self.m_maxtime * millis
        ))
    end

    if reset then
        self:reset()
    end
end

if not getDebug() then
    PerformanceTimer.enter = function() end
    PerformanceTimer.exit = function() end
    PerformanceTimer.report = function() end
end

dev.PerformanceTimer = PerformanceTimer

-- #endregion

return dev
