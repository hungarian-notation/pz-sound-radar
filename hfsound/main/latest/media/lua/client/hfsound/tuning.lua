local styles = require('hfsound/zombiesound/styles')
local define = require('hfsound/zombiesound/define')
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

---@class (partial) hfs.globals.Tuning
HFSOUND.tuning = {

    simradius = 0.0,
    zombies = {
        silent  = {},

        idle    = {
            define_sound {
                period = 2,
                radius = 3,
                duration = 4,
                style = styles.BREATH_STYLE,
            },
            define_sound {
                period = 20,
                radius = 6,
                duration = 4,
                style = styles.BREATH_STYLE,
            },
            define_sound {
                period = 200,
                radius = 12,
                duration = 4,
                style = styles.BREATH_STYLE,
            }
        },

        stumble = {
            define_sound {
                frequency = 4,
                radius = 6
            },
            define_sound {
                frequency = 1,
                radius = 8
            }
        },

        walk    = {
            define_sound {
                frequency = 2,
                radius    = 4,
                style     = styles.FOOTSTEP_STYLE
            },
            define_sound {
                period = 2,
                radius = 8,
                style  = styles.FOOTSTEP_STYLE
            },
            define_sound {
                period = 8,
                radius = 12,
                style  = styles.FOOTSTEP_STYLE
            }
        },

        clamber = {
            define_sound {
                frequency = 2,
                radius = 6,
                style = styles.CLAMBER_STYLE,
            },
            define_sound {
                period = 2,
                radius = 12,
                style = styles.CLAMBER_STYLE,
            }
        },

        attack  = {
            define_sound {
                frequency = 20,
                radius = 6,
                style = styles.ATTACK_STYLE,
            },
            define_sound {
                frequency = 1,
                radius = 12,
                style = styles.ATTACK_STYLE,
            }
        },
    } --[[@as { [hfs.StateCategory]: hfs.ZombieSound[] }]]
}


local tuning = HFSOUND.tuning

for _, sounds in pairs(tuning.zombies) do
    for _i, sound in ipairs(sounds) do
        local max_radius = sound.radius * HFSOUND.hearing.KEEN_HEARING
        if max_radius > tuning.simradius then
            tuning.simradius = max_radius
        end
    end
end
