-- local ArcRenderer = require('hfsound/arcrenderer')
-- local xmath       = require('hfsound/xmath')

require('hfsound/tuning')

local worldsounds  = require('hfsound/worldsound/classifier')
local zombiesounds = require('hfsound/zombiesound/simulator')
local Scope        = require('hfsound/scope/scope')

---@class (partial) _HFSOUND
---@field runtime   hfs.Runtime?
---@field kill fun()
---@field reset fun()
HFSOUND            = HFSOUND or {}

---@class (exact) hfs.Runtime
---@field events        hfs.RuntimeEvents
---@field finalizers    (fun(): nil)[]
---@field delta         number the time elapsed since the previous tick
---@field world_delta   number the simulated world time elapsed since the previous tick
local Runtime      = {}; Runtime.__index = Runtime

function Runtime.new()
    local obj        = setmetatable({}, Runtime);
    obj.scope        = Scope.new(0)
    obj.zombiesounds = zombiesounds.ZombieSoundSimulator.new { scope = obj.scope }
    obj.worldsounds  = worldsounds.WorldSoundClassifier.new { scope = obj.scope }

    -- https://docs.google.com/spreadsheets/d/1by0DMd_VuVC3HBs-CaJ1f3UOfa9GDt-ttDgvJz65eO0/view?gid=173015384

    local function _EventClosure_OnTick(...) if obj ~= nil then obj:OnTick(...) end end
    local function _EventClosure_OnZombieUpdate(...) if obj ~= nil then obj:OnZombieUpdate(...) end end
    local function _EventClosure_OnWorldSound(...) if obj ~= nil then obj:OnWorldSound(...) end end
    local function _EventClosure_OnPreUIDraw(...) if obj ~= nil then obj:OnPreUIDraw(...) end end
    local function _EventClosure_EveryOneMinute(...) if obj ~= nil then obj:EveryOneMinute(...) end end
    local function _EventClosure_OnGameBoot(...) if obj ~= nil then obj:OnGameBoot(...) end end

    ---@class hfs.RuntimeEvents
    local events          = {}
    events.OnTick         = _EventClosure_OnTick --[[@as Callback_OnTick]]
    events.OnZombieUpdate = _EventClosure_OnZombieUpdate --[[@as Callback_OnZombieUpdate]]
    events.OnWorldSound   = _EventClosure_OnWorldSound --[[@as Callback_OnWorldSound]]
    events.OnPreUIDraw    = _EventClosure_OnPreUIDraw --[[@as Callback_OnPreUIDraw]]
    events.EveryOneMinute = _EventClosure_EveryOneMinute --[[@as Callback_EveryOneMinute]]
    events.OnGameBoot     = _EventClosure_OnGameBoot --[[@as Callback_OnGameBoot]]
    obj.events            = events
    obj.finalizers        = {}

    obj.lastminute        = nil
    obj.lastminuteticks   = 0
    obj.lastminute_mdelta = 0.0
    obj.lastminute_delta  = 0.0

    return obj
end

---@param arr (fun())[]
local function execute_finalizers(arr)
    while #arr > 0 do
        local ok, err = pcall(table.remove(arr, #arr))

        if not ok then
            print(string.format("warning: error in finalizer: %s", tostring(err)))
        end
    end
end



function Runtime:start()
    if HFSOUND.runtime then
        if HFSOUND.runtime == self then
            return
        else
            HFSOUND.runtime:terminate()
            assert(HFSOUND.runtime == nil)
        end
    end

    local function install()
        for k, v in pairs(self.events) do
            Events[k].Add(v)

            local finalizer = function()
                print("detaching from event: " .. k)
                Events[k].Remove(v)
            end

            table.insert(self.finalizers, finalizer)
        end
    end

    local ok, err = pcall(install)

    if ok then
        HFSOUND.runtime = self
    else
        local nerr = string.format("error attaching event listeners: %s", tostring(err))
        print(nerr)
        execute_finalizers(self.finalizers)
        error(nerr)
    end
end

function Runtime:terminate()
    if #self.finalizers > 0 then
        execute_finalizers(self.finalizers)
        if HFSOUND.runtime == self then
            HFSOUND.runtime = nil
        end
    else
        assert(HFSOUND.runtime ~= self)
    end
end

---@param x integer
---@param y integer
---@param z integer
---@param radius integer
---@param volume integer
---@param source Object
function Runtime:OnWorldSound(x, y, z, radius, volume, source)
    self.worldsounds:OnWorldSound(x, y, z, radius, volume, source)
end

function Runtime:OnGameBoot()
    self:terminate()
end

---@param _n number
function Runtime:OnTick(_n)
    local gt = getGameTime()
    local speedindex = getGameSpeed()

    local delta, multiplied_delta

    if speedindex == 0 then
        delta = 0
        multiplied_delta = 0
    else
        delta = gt:getRealworldSecondsSinceLastUpdate()
        multiplied_delta = gt:getMultipliedSecondsSinceLastUpdate()
    end

    self.delta = delta
    self.world_delta = multiplied_delta

    self.worldsounds:update(delta)

    -- sound simulation models a player's perception of audio cues, and as such
    -- is not affected by the speed multiplier
    self.zombiesounds:update(delta)
    -- self.zombiesounds:drain_events(self.scope)

    -- sound decay is accelerated by game speed multiplier
    self.scope:update(multiplied_delta)
end

function Runtime:EveryOneMinute()
    self.scope:everyoneminute()
end

function Runtime:OnPreUIDraw()
    self.scope:render()
end

---@param zombie IsoZombie
function Runtime:OnZombieUpdate(zombie)
    self.zombiesounds:simulate(zombie)
end

--------------------------------------------------------------------------------

function HFSOUND.kill()
    if HFSOUND.runtime then
        HFSOUND.runtime:terminate()
        assert(HFSOUND.runtime == nil)
    end
end

function HFSOUND.reset()
    HFSOUND.kill()
    Runtime.new():start()
end

local function OnGameStart()
    HFSOUND.reset()
end

Events.OnGameStart.Add(OnGameStart)
