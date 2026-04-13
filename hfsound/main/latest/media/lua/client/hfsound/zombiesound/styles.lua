local styles       = require('hfsound/scope/style')

local lib          = {}

lib.DEFAULT_STYLE  = styles.basic {
    color = styles.colors.solid("#ff800060"),
    arc   = math.pi * 2 / 3
}

lib.BREATH_STYLE   = styles.basic {
    color = styles.colors.cyclic {
        colors = {
            "#D3FF8200", "#E4FFB360", "#A6FF0060", "#E4FFB360",
        },
        rate = 0.5,
    },
    arc   = math.pi * 0.5
}

lib.FOOTSTEP_STYLE = styles.basic {
    color = styles.colors.solid("#FFEE0080"),
    arc   = math.pi * 2 / 3
}

lib.CLAMBER_STYLE  = styles.basic {
    color    = styles.colors.solid("#ff800080"),
    arc      = math.pi * 2 / 3,
    gradient = "edge"
}

lib.ATTACK_STYLE   = styles.basic {
    color = styles.colors.solid("#FF000060"),
    arc   = math.pi * 2 / 3
}

return lib
