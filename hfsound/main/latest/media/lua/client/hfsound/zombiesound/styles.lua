local styles          = require('hfsound/scope/style')
local options         = require("hfsound/options/options")

local module          = {}

local opts            = options.get_options()

module.DEFAULT_STYLE  = styles.basic {
    color = opts:getconfiguredcolor("ZombieOther"),
    arc   = math.pi * 0.5
}

module.BREATH_STYLE   = styles.basic {
    color = opts:getconfiguredcolor("ZombieIdle"),
    arc   = math.pi * 0.5
}

module.FOOTSTEP_STYLE = styles.basic {
    color = opts:getconfiguredcolor("ZombieStep"),
    arc   = math.pi * 0.5
}

module.CLAMBER_STYLE  = styles.basic {
    color    = opts:getconfiguredcolor("ZombieClamber"),
    arc      = math.pi * 0.5,
    gradient = "edge"
}

module.ATTACK_STYLE   = styles.basic {
    color = opts:getconfiguredcolor("ZombieAggression"),
    arc   = math.pi * 0.5
}

return module
