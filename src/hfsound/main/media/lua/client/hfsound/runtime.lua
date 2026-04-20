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
---@field delta         number the time elapsed since the previous tick
---@field world_delta   number the simulated world time elapsed since the previous tick
local Runtime      = {}; Runtime.__index = Runtime

---@param runtime hfs.Runtime
local function hook(runtime)
    local function OnTick(...) runtime:OnTick(...) end
    local function OnWorldSound(...) runtime:OnWorldSound(...) end
    local function OnPreUIDraw(...) runtime:OnPreUIDraw(...) end
    local function OnGameBoot(...) runtime:OnGameBoot(...) end
    -- local function EveryOneMinute(...) runtime:EveryOneMinute(...) end

    -- This one gets unrolled to upvalues because it gets called per-zombie
    -- per-tick.
    local runtime_zombiesounds = runtime.zombiesounds
    local zombiesound_simulate = runtime_zombiesounds.simulate
    local function OnZombieUpdate(zombie)
        zombiesound_simulate(runtime_zombiesounds, zombie)
    end

    Events.OnTick.Add(OnTick)
    Events.OnZombieUpdate.Add(OnZombieUpdate)
    Events.OnWorldSound.Add(OnWorldSound)
    Events.OnPreUIDraw.Add(OnPreUIDraw)
    Events.OnGameBoot.Add(OnGameBoot)
    -- Events.EveryOneMinute.Add(EveryOneMinute)

    local function unhook()
        Events.OnTick.Remove(OnTick)
        Events.OnZombieUpdate.Remove(OnZombieUpdate)
        Events.OnWorldSound.Remove(OnWorldSound)
        Events.OnPreUIDraw.Remove(OnPreUIDraw)
        Events.OnGameBoot.Remove(OnGameBoot)
        -- Events.EveryOneMinute.Remove(EveryOneMinute)
    end

    local hooked_simulator = true

    local function set_hookzombies(enable)
        if enable then
            if not hooked_simulator then
                Events.OnZombieUpdate.Add(OnZombieUpdate)
                hooked_simulator = true
            end
        else
            if hooked_simulator then
                Events.OnZombieUpdate.Remove(OnZombieUpdate)
                hooked_simulator = false
            end
        end
    end

    local function get_hookzombies()
        return hooked_simulator
    end

    return { unhook = unhook, set_hookzombies = set_hookzombies, get_hookzombies = get_hookzombies }
end

function Runtime.new()
    local obj        = setmetatable({}, Runtime);
    obj.scope        = Scope.new(0)
    obj.zombiesounds = zombiesounds.ZombieSoundSimulator.new { scope = obj.scope }
    obj.worldsounds  = worldsounds.WorldSoundClassifier.new { scope = obj.scope }
    obj.finalizers   = {}
    obj.simulate     = true
    obj.hooks        = hook(obj)
    return obj
end

function Runtime:terminate()
    if self.hooks then
        self.hooks.unhook()
        self.hooks = nil
    end

    if HFSOUND.runtime == self then
        HFSOUND.runtime = nil
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
    -- if we're alive to see this, its time to die.
    self:terminate()
end

function Runtime:OnTick()
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
    self.worldsounds:update()
    self.zombiesounds:update()
    self.scope:update(multiplied_delta)
end

function Runtime:OnPreUIDraw()
    self.scope:render()
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
    HFSOUND.runtime = Runtime.new()
end

local function OnGameStart()
    HFSOUND.reset()
end

Events.OnGameStart.Add(OnGameStart)
