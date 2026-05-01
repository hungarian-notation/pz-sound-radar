local options_lib = require("hfsound/options/options")
local styles      = require('hfsound/scope/style/style')

local module      = {}
local math_pi     = math.pi


local options = options_lib:get_options()


module.BREATH_STYLE   = styles.basic {
    color = options:getconfiguredcolor("ZombieIdle"),
    arc   = math_pi * 0.5
}

module.FOOTSTEP_STYLE = styles.basic {
    color = options:getconfiguredcolor("ZombieStep"),
    arc   = math_pi * 0.8
}


module.CLAMBER_STYLE = styles.basic {
    color    = options:getconfiguredcolor("ZombieClamber"),
    arc      = math_pi * 1,
    gradient = "edge"
}

module.ATTACK_STYLE  = styles.basic {
    color = options:getconfiguredcolor("ZombieAggression"),
    arc   = math_pi * 1.5
}

return module
