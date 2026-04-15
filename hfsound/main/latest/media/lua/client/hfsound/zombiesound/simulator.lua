-- local style         = require('hfsound/scope/style')
-- local color         = style.colors.solid

local states = require('hfsound/zombiesound/states')

-- #region hfs.ZSimulator

---@class hfs.ZombieSoundSimulator
---@field private m_scope hfs.Scope
---@field private m_delta number
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

    obj:update(0)

    return obj
end

---@param delta number time in seconds since last update
function ZombieSoundSimulator:update(delta)
    self.m_delta = delta
    self.m_rate = 1 / delta

    local player = getSpecificPlayer(self.m_scope.m_player_index)
    self.m_global_bounds[1] = player:getX() - HFSOUND.tuning.simradius
    self.m_global_bounds[2] = player:getY() - HFSOUND.tuning.simradius
    self.m_global_bounds[3] = player:getX() + HFSOUND.tuning.simradius
    self.m_global_bounds[4] = player:getY() + HFSOUND.tuning.simradius

    for k in pairs(states.CATEGORIES) do
        local category_bounds = self.m_category_bounds[k]
        category_bounds[1] = player:getX() - HFSOUND.tuning.category_simradius[k]
        category_bounds[2] = player:getY() - HFSOUND.tuning.category_simradius[k]
        category_bounds[3] = player:getX() + HFSOUND.tuning.category_simradius[k]
        category_bounds[4] = player:getY() + HFSOUND.tuning.category_simradius[k]
    end
end

-- ---@param scope hfs.Scope
-- function Simulator:drain_events(scope)
--     local events = self.m_events

--     for i = 1, #events - 1, 2 do
--         local zombie = events[i] --[[@as IsoZombie]]
--         local sound  = events[i + 1] --[[@as hfs.ZombieSound]]
--         scope:offerzombiesound(zombie:getUID(), sound, zombie)
--     end

--     table.wipe(events)
-- end

---@param event_rate number average rate of events per second
function ZombieSoundSimulator:random_event(event_rate)
    assert(type(self.m_delta) == "number")
    local chance = 1 - math.exp(-event_rate * self.m_delta)
    local roll = ZombRandFloat(0, 1)
    return roll < chance
end

---@param zombie IsoZombie
function ZombieSoundSimulator:simulate(zombie)
    local zombie_x = zombie:getX()
    local zombie_y = zombie:getY()

    local state_category = states.getcategory(zombie)
    local x1, y1, x2, y2 = unpack(self.m_category_bounds[state_category])

    -- ignore zombies outside of the AABB of our maximum hearing radius
    if zombie_x < x1 or zombie_x > x2 or zombie_y < y1 or zombie_y > y2 then
        return
    end

    local state_sounds = HFSOUND.tuning.zombies[state_category]
    local delta = self.m_delta

    if type(self.m_delta) ~= "number" then
        return -- first frame
    end

    for _i, sound in ipairs(state_sounds) do
        -- FIXME: major optimization: precalculate `chance` for all sounds on
        -- update, rather than computing this math.exp multiple times for
        -- every zombie

        local chance = 1 - math.exp(-sound.frequency * delta)
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
