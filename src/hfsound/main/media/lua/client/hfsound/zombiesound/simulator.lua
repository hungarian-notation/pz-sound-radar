-- local style         = require('hfsound/scope/style')
-- local color         = style.colors.solid

local states = require('hfsound/zombiesound/states')

-- #region hfs.ZSimulator
-- @field private m_delta number

---@class hfs.ZombieSoundSimulator
---@field private m_scope hfs.Scope
---@field private m_rate number
---@field private m_global_bounds [number,number,number,number]
---@field private m_category_bounds { [hfs.StateCategory]: [number,number,number,number] }
local ZombieSoundSimulator = {}; ZombieSoundSimulator.__index = ZombieSoundSimulator

---@class hfs.ZombieSoundSimulator.Kwargs
---@field scope hfs.Scope

---@param kw hfs.ZombieSoundSimulator.Kwargs
function ZombieSoundSimulator.new(kw)
    local obj = setmetatable({}, ZombieSoundSimulator)

    -- ---@type unknown[]
    -- obj.m_events = {}
    obj.m_scope = kw.scope

    obj.m_global_bounds = { 0, 0, 0, 0 }
    obj.m_category_bounds = {}
    for k in pairs(states.CATEGORIES) do obj.m_category_bounds[k] = { 0, 0, 0, 0 } end

    obj:update()

    return obj
end

local gameTime = getGameTime()
local GameTime_getRealworldSecondsSinceLastUpdate = gameTime.getRealworldSecondsSinceLastUpdate


function ZombieSoundSimulator:update()
    -- self.m_delta = delta
    -- self.m_rate = 1 / delta

    -- TODO: we could do this less often, but it needs to be an upvalue here
    gameTime = getGameTime()
    GameTime_getRealworldSecondsSinceLastUpdate = gameTime.getRealworldSecondsSinceLastUpdate

    local player = getSpecificPlayer(self.m_scope.m_player_index)
    local px, py = player:getX(), player:getY()
    local simradius = HFSOUND.tuning.simradius
    local category_simradius = HFSOUND.tuning.category_simradius

    local bounds = self.m_global_bounds
    bounds[1] = px - simradius
    bounds[2] = py - simradius
    bounds[3] = px + simradius
    bounds[4] = py + simradius

    for k in pairs(states.CATEGORIES) do
        local category_bounds = self.m_category_bounds[k]
        local category_radius = category_simradius[k]
        category_bounds[1] = px - category_radius
        category_bounds[2] = py - category_radius
        category_bounds[3] = px + category_radius
        category_bounds[4] = py + category_radius
    end
end

local math_exp = math.exp
local ZombRandFloat = ZombRandFloat
local ipairs = ipairs
local unpack = unpack

---@param event_rate number average rate of events per second
function ZombieSoundSimulator:random_event(event_rate)
    local delta = GameTime_getRealworldSecondsSinceLastUpdate(gameTime)
    local chance = 1 - math_exp(-event_rate * delta)
    local roll = ZombRandFloat(0, 1)
    return roll < chance
end

---@param zombie IsoZombie
function ZombieSoundSimulator:simulate(zombie)
    local zombie_x = zombie:getX()
    local zombie_y = zombie:getY()

    -- This changes between zombies updates within a single tick.
    -- MovingObjectUpdateScheduler
    local delta = GameTime_getRealworldSecondsSinceLastUpdate(gameTime)

    local state_category = states.getcategory(zombie)
    local x1, y1, x2, y2 = unpack(self.m_category_bounds[state_category])

    -- ignore zombies outside of the AABB of our maximum hearing radius
    if zombie_x < x1 or zombie_x > x2 or zombie_y < y1 or zombie_y > y2 then
        -- return
    end

    -- FIXME tuning.zombies needs to be an upvalue at release

    local state_sounds = HFSOUND.tuning.zombies[state_category] 

    for _i, sound in ipairs(state_sounds) do
        local chance = 1 - math_exp(-sound.frequency * delta)
        local roll = ZombRandFloat(0, 1)

        if roll < chance then
            self.m_scope:offerzombiesound(zombie:getUID(), sound, zombie)
        end
    end
end

-- #endregion hfs.ZSimulator

---@class hfsound.zombiesound.simulator.module
local module = {
    ZombieSoundSimulator = ZombieSoundSimulator
}



return module
