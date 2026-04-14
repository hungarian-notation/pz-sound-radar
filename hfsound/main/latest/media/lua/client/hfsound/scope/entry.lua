local util = require("hfsound/scope/util")

---@type hfs.Style
local NOOP_STYLE = {
    render = function()
        error("render called on extinct scope entry")
    end
}

--- Represents an individual sound indicator to be rendered to the screen.
---
--- Instances of this class are reused to reduce allocations.
---@class hfs.ScopeEntry
---@field m_extinct   boolean
---@field m_age       number
---@field m_duration  number
---@
---@field m_source?   any arbitrary source tag
---@field m_uid?      string
---@field m_radius    number
---@field m_x         number
---@field m_y         number
---@field m_z         number
---@field m_data      table
---@field m_style     hfs.Style
---@field m_building  int?
---@field m_building_attenuated boolean
---@field m_callback_test? Scope.Entry.TestFunction
---@field m_callback_update? Scope.Entry.UpdateFunction
local Entry = {}; Entry.__index = Entry

function Entry.new()
    local obj = setmetatable({}, Entry)
    obj:reset()
    return obj
end

function Entry:reset()
    self.m_extinct = true
    self.m_age = 0.0
    self.m_duration = 0.0

    self.m_callback_test = nil
    self.m_callback_update = nil

    self.m_source = nil
    self.m_uid = nil
    self.m_radius = 0.0
    self.m_x = 0.0
    self.m_y = 0.0
    self.m_z = 0.0

    if self.m_data == nil then
        self.m_data = {}
    else
        table.wipe(self.m_data)
    end

    self.m_building = nil
    self.m_building_attenuated = false

    self.m_style = NOOP_STYLE
end

---@param uid? string
---@param classifier hfs.WSClassifier
---@param worldSound hfs.WorldSound
---@return boolean
function Entry:setworldsound(uid, classifier, worldSound)
    if self.m_extinct then
        self:_applyworldsound(uid, classifier, worldSound)
        self.m_extinct = false
        return true
    else
        assert(self.m_uid == uid, "uid mismatch in entry")

        if self.m_radius > worldSound.radius then
            return false
        else
            self:_applyworldsound(uid, classifier, worldSound)
            return true
        end
    end
end

---@param uid string
---@param sound hfs.ZombieSound
---@param zombie IsoZombie
---@return boolean
function Entry:setzombiesound(uid, sound, zombie)
    if self.m_extinct then
        self:_applyzombiesound(uid, sound, zombie)
        self.m_extinct = false
        return true
    else
        if self.m_radius > sound.radius then
            return false
        else
            self:_applyzombiesound(uid, sound, zombie)
            return true
        end
    end
end

---@param uid? string
---@param classifier hfs.WSClassifier
---@param worldSound hfs.WorldSound
---@private
function Entry:_applyworldsound(uid, classifier, worldSound)
    -- fully apply

    local ttl = math.max(0, self.m_duration - self.m_age)

    if ttl > 0 and ttl <= classifier.duration then
        -- Prefer to preserve the age, extending the duration instead
        -- This lets us defined parametric animations based on the age of
        -- the entry without worrying about constant sounds like the
        -- house alarm getting stuck at the first frame.

        local difference = (classifier.duration or 1.0) - ttl

        self.m_duration = self.m_duration + difference
    else
        self.m_age = 0
        self.m_duration = classifier.duration or 1.0
    end

    self.m_callback_test = classifier.callback_test
    self.m_callback_update = classifier.callback_update

    self.m_source = worldSound.source
    self.m_radius = worldSound.radius
    self.m_uid = uid
    self.m_x = worldSound.x + 0.5
    self.m_y = worldSound.y + 0.5
    self.m_z = worldSound.z

    self.m_building_attenuated = false
    self.m_style = classifier.style
    self:compute()
end

---@param uid string
---@param sound hfs.ZombieSound
---@param zombie IsoZombie
---@private
function Entry:_applyzombiesound(uid, sound, zombie)
    local ttl = math.max(0, self.m_duration - self.m_age)

    if ttl > 0 and ttl <= sound.duration then
        -- Prefer to preserve the age, extending the duration instead
        -- This lets us defined parametric animations based on the age of
        -- the entry without worrying about constant sounds like the
        -- house alarm getting stuck at the first frame.

        local difference = (sound.duration or 1.0) - ttl
        self.m_duration = self.m_duration + difference
    else
        self.m_age = 0
        self.m_duration = sound.duration or 1.0
    end

    self.m_callback_test = nil
    self.m_callback_update = util.callback_followsource

    self.m_source = zombie
    self.m_radius = sound.radius
    self.m_uid = uid
    self.m_x = zombie:getX()
    self.m_y = zombie:getY()
    self.m_z = zombie:getZ()

    self.m_building_attenuated = true
    self.m_style = sound.style
    self:compute()
end

function Entry:compute()
    local square = getSquare(self.m_x, self.m_y, self.m_z)

    if square ~= nil then
        local building = square:getBuildingDef()

        if building ~= nil then
            self.m_building = building:getID()
        else
            self.m_building = nil
        end
    else
        self.m_building = nil
    end
end

return Entry
