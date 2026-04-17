local module          = {}

local taggers         = require('hfsound/worldsound/_impl/_taggers') 
local styles          = require('hfsound/scope/style/style')
local color           = styles.colors.solid
local hsx             = require('hfsound/colors')
local scopeutil       = require('hfsound/scope/util')
local defs            = require('hfsound/worldsound/_impl/_definitions')

---@type { [string]: hfs.WSClassifier? }
local _VCFH_CACHE     = {}
local _VCFH_ARC_COLOR = color("#ccddff80")

---@return hfs.WSClassifier
function module.getclassifier(h, s, v)
    v = 0.5 * v + 0.5

    local hd = 16
    local sd = 16
    local vd = 16

    local hx = math.floor(h * hd)
    local sx = math.floor(s * sd)
    local vx = math.floor(v * vd)
    local id = string.format("%d;%d;%d", hx, sx, vx)

    if _VCFH_CACHE[id] ~= nil then
        return _VCFH_CACHE[id]
    else
        print("new colorway: ", id)
        local r, g, b = hsx.hsv2rgb(hx / hd, sx / sd, vx / vd)
        local colorObject = color(r, g, b, 1.0)

        _VCFH_CACHE[id] = {
            duration = 5,
            discriminator = taggers.uid,
            style = styles.basic {
                arc = math.pi / 2,
                gradient = "electronics-3",
                icon = { which = "vehicle-car", color = colorObject },
                color = _VCFH_ARC_COLOR
            },
            callback_update = scopeutil.callback_followsource
        }

        return _VCFH_CACHE[id]
    end
end

--- how long in world minutes to wait for a car's lights to toggle before
--- deciding an alarm is either done or actually just a honk
local ALARM_WATCHDOG = 0.5

local ALARM_TAGGER = taggers.nsuid("vehicle-alarm")

---@class HeadlightsData
---@field state boolean
---@field time number?

function module.getalarmclassifier()
    local gameTime = getGameTime()
    local deltaMinutes = gameTime:getDeltaMinutesPerDay()
    local dayRealMinutes = gameTime:getMinutesPerDay()
    local alarmHours = 0.66 * deltaMinutes
    local alarmDays = alarmHours / 24
    local alarmRealMinutes = alarmDays * dayRealMinutes
    local alarmRealSeconds = alarmRealMinutes * 60
    local alarmStopWorldAge = gameTime:getWorldAgeHours() + alarmHours

    ---@type hfs.WSClassifier
    local CLASSIFIER_VEHICLE_ALARM = {

        duration = alarmRealSeconds,
        discriminator = ALARM_TAGGER,
        style = defs.styles.VEHICLE_ALARM,

        callback_test = function(entry, _context)
            ---@cast entry.m_source BaseVehicle
            ---@cast entry.m_data { headlights: HeadlightsData? }

            -- In an example of an incredibly disgusting hack, we check to
            -- see if the vehicle sound event is an alarm or just somebody
            -- blowing the car's horn by monitoring the vehicle's headlights
            -- to see if they are blinking.

            -- They both have the same radius, and it seems zombies are only
            -- attracted to the alarm on the frame it actually triggers, but
            -- we want to display the alarm indicator for as long as the alarm
            -- sound is actually playing.

            local source = entry.m_source
            local current_worldtime = gameTime:getWorldAgeHours() * 60
            local headlights = entry.m_data.headlights

            if headlights == nil then
                headlights = {
                    state = source:getHeadlightsOn(),
                    time = current_worldtime
                }
                entry.m_data.headlights = headlights
            end

            if source:getHeadlightsOn() ~= headlights.state then
                headlights.state = source:getHeadlightsOn()
                headlights.time = current_worldtime
            elseif headlights.time
                and ((current_worldtime - headlights.time) > ALARM_WATCHDOG)
            then
                return false
            end

            if source ~= nil and source:getBatteryCharge() <= 0 then
                return false
            end

            if gameTime:getWorldAgeHours() > alarmStopWorldAge then
                return false
            end

            return true
        end,
        callback_update = scopeutil.callback_followsource
    }
    return CLASSIFIER_VEHICLE_ALARM
end

return module
