local styles = require('hfsound/zombiesound/styles')
local define = require('hfsound/zombiesound/define')
local states = require("hfsound/zombiesound/states")
local define_sound = define.define_sound

---@class (partial) _HFSOUND
---@field tuning hfs.globals.Tuning
---@field hearing hfs.globals.Hearing
HFSOUND = HFSOUND or {}

---@class hfs.globals.Hearing
HFSOUND.hearing = {
    NORMAL                = 1,
    KEEN_HEARING          = 1.2,
    HARD_OF_HEARING       = 0.8,
    THROUGH_EXTERIOR_WALL = 0.5,
}

HFSOUND.tuning = (function()
    ---@class (partial) hfs.globals.Tuning
    local tbl = {
        simradius = 0.0,

        ---@type { [hfs.StateCategory]: number }
        category_simradius = {},

        zombies = {
            silent  = {},

            idle    = {
                define_sound {
                    category = "idle",
                    period = 1,
                    radius = 3,
                    duration = 4,
                    style = styles.BREATH_STYLE,
                },
                define_sound {
                    category = "idle",
                    period = 10,
                    radius = 6,
                    duration = 4,
                    style = styles.BREATH_STYLE,
                },
            },

            stumble = {
                define_sound {
                    category = "stumble",
                    frequency = 4,
                    radius = 6
                },
                define_sound {
                    category = "stumble",
                    frequency = 1,
                    radius = 8
                }
            },

            walk    = {
                define_sound {
                    category = "walk",
                    period   = 0.5,
                    radius   = 3,
                    style    = styles.FOOTSTEP_STYLE
                },
                define_sound {
                    category = "walk",
                    period   = 4,
                    radius   = 8,
                    style    = styles.FOOTSTEP_STYLE
                }
            },

            clamber = {
                define_sound {
                    category = "clamber",
                    period = 7,
                    radius = 8,
                    style = styles.CLAMBER_STYLE,
                },
                define_sound {
                    category = "clamber",
                    period = 8,
                    radius = 12,
                    style = styles.CLAMBER_STYLE,
                }
            },

            attack  = {
                define_sound {
                    category = "attack",
                    frequency = 1,
                    radius = 12,
                    style = styles.ATTACK_STYLE,
                },
                define_sound {
                    category = "attack",
                    period = 5,
                    radius = 16,
                    style = styles.ATTACK_STYLE,
                }
            },
        } --[[@as { [hfs.StateCategory]: hfs.ZombieSound[] }]]
    }

    for k in pairs(states.CATEGORIES) do
        tbl.category_simradius[k] = 0
    end

    return tbl
end
)()

local tuning = HFSOUND.tuning

for category, sounds in pairs(tuning.zombies) do
    for _, sound in ipairs(sounds) do
        local sound_radius = sound.radius * HFSOUND.hearing.KEEN_HEARING

        if sound_radius > tuning.simradius then
            tuning.simradius = sound_radius
        end

        if sound_radius > tuning.category_simradius[category] then
            tuning.category_simradius[category] = sound_radius
        end
    end
end
