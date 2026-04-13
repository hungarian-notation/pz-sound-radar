-- local style         = require('hfsound/scope/style')
-- local color         = style.colors.solid

local states = require('hfsound/zombiesound/states')

-- #region hfs.ZSimulator

---@class hfs.ZombieSoundSimulator
---@field private m_scope hfs.Scope
---@field private m_xmin number
---@field private m_xmax number
---@field private m_ymin number
---@field private m_ymax number
---@field private m_delta number
---@field private m_rate number
local ZombieSoundSimulator = {}; ZombieSoundSimulator.__index = ZombieSoundSimulator

---@class hfs.ZombieSoundSimulator.Kwargs
---@field scope hfs.Scope

---@param kw hfs.ZombieSoundSimulator.Kwargs
function ZombieSoundSimulator.new(kw)
    local obj = setmetatable({}, ZombieSoundSimulator)

    -- ---@type unknown[]
    -- obj.m_events = {}
    obj.m_scope = kw.scope

    obj:update(0)

    return obj
end

---@param delta number time in seconds since last update
function ZombieSoundSimulator:update(delta)
    self.m_delta = delta
    self.m_rate = 1 / delta

    local player = getSpecificPlayer(self.m_scope.m_player_index)

    self.m_xmin = player:getX() - HFSOUND.tuning.simradius
    self.m_xmax = player:getX() + HFSOUND.tuning.simradius
    self.m_ymin = player:getY() - HFSOUND.tuning.simradius
    self.m_ymax = player:getY() + HFSOUND.tuning.simradius
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

    local x1, y1, x2, y2 = self.m_xmin, self.m_ymin, self.m_xmax, self.m_ymax

    -- ignore zombies outside of the AABB of our maximum hearing radius
    if zombie_x < x1 or zombie_x > x2 or zombie_y < y1 or zombie_y > y2 then
        return
    end

    if type(self.m_delta) ~= "number" then
        return -- first frame
    end

    local state_category = states.getcategory(zombie)
    local state_sounds = HFSOUND.tuning.zombies[state_category]
    local delta = self.m_delta

    for _i, sound in ipairs(state_sounds) do
        -- FIXME: major optimization: precalculate `chance` for all sounds on
        -- update, rather than computing this math.exp multiple times for
        -- every zombie

        local chance = 1 - math.exp(-sound.frequency * delta)
        local roll = ZombRandFloat(0, 1)

        if roll < chance then
            -- TODO: preliminary filtering to ensure zombie is within range
            --       of the player

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
