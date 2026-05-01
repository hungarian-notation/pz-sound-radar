local options         = require("hfsound/options")
local styles          = require('hfsound/scope/style/style')

local module          = {}
local math_pi         = math.pi

-- module.DEFAULT_STYLE  = styles.basic {
--     color = opts:getconfiguredcolor("ZombieOther"),
--     arc   = math_pi * 1
-- }

module.BREATH_STYLE   = styles.basic {
    color = options:getconfiguredcolor("ZombieIdle"),
    arc   = math_pi * 2 / 3
}

module.FOOTSTEP_STYLE = styles.basic {
    color = options:getconfiguredcolor("ZombieStep"),
    arc   = math_pi * 1
}

module.CLAMBER_STYLE  = styles.basic {
    color    = options:getconfiguredcolor("ZombieClamber"),
    arc      = math_pi * 1,
    gradient = "edge"
}

module.ATTACK_STYLE   = styles.basic {
    color = options:getconfiguredcolor("ZombieAggression"),
    arc   = math_pi * 1
}

return module
