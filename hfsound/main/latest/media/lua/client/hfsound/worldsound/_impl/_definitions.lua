local taggers = require('hfsound/worldsound/_impl/_taggers')
local styles = require('hfsound/scope/style')
local color = styles.colors.solid
local Icons = require('hfsound/icons')
local basicstyle = require('hfsound/worldsound/_impl/_basicstyle')

---type guarding validator for classifiers
---@param tbl hfs.WSClassifier
local function classifier(tbl)
    assert(type(tbl.discriminator) == "function")
    assert(type(tbl.duration) == "number")
    assert(type(tbl.style) == "table")
    return tbl
end

local module                      = {}
local COLORS                      = {}

COLORS.BROADCAST                  = styles.colors.cyclic {
    rate = 1 / 2,

    colors = {
        "#60C0D040", "#00DDFF60", "#A5A5A540", "#60C0D050",
        "#00DDFF40", "#60C0D060", "#00DDFF40", "#00DDFF50",
        "#00DDFF40", "#00DDFF60", "#00DDFF40", "#60C0D050",
        "#00DDFF40", "#A5A5A560", "#60C0D040", "#A5A5A550",
        "#60C0D040", "#00DDFF60", "#00DDFF40", "#00DDFF50",
    }
}

COLORS.THUMP                      = styles.colors.cyclic {
    colors = { "#Ff800060", "#ff000060" },
    rate = 3
};

COLORS.HOUSE_ALARM                = styles.colors.cyclic {
    colors = {
        "#ccccffff",
        "#ff0000ff",
    },
    rate = 4
}

local WORLDSOUND_STYLE            = {}

WORLDSOUND_STYLE.LIVING           = basicstyle("#FFEE0050")
WORLDSOUND_STYLE.UNKNOWN          = basicstyle("#FFffff80", nil, "edge")
WORLDSOUND_STYLE.HELICOPTER       = basicstyle("#EE00FFAA", Icons.VEHICLE_HELICOPTER, "edge")
WORLDSOUND_STYLE.APPLIANCE        = basicstyle("#ccddff80", Icons.APPLIANCE_GENERATOR, "electronics-4")
WORLDSOUND_STYLE.LAUNDRY          = basicstyle("#ccddff80", Icons.APPLIANCE_LAUNDRY, "electronics-3")
WORLDSOUND_STYLE.VEHICLE_ALARM    = basicstyle("#FF006680", Icons.VEHICLE_CAR_ALERT, "electronics-5")
WORLDSOUND_STYLE.GUNSHOT          = basicstyle("#EE00FFAA", Icons.OBJECT_PISTOL, "edge")
WORLDSOUND_STYLE.THUNDER          = basicstyle("#FFEEAAAA", Icons.SYMBOL_BOLT, "edge")

WORLDSOUND_STYLE.FIRE             = styles.create {
    arc = true,
    color = color("#ff0000aa"),
    icon = { which = "symbol-fire" }
}

WORLDSOUND_STYLE.BROADCAST        = styles.create {
    color = COLORS.BROADCAST,
    arc = math.pi,
    icon = {
        which = Icons.SYMBOL_WAVEFORM,
        color = color("#FFFFFFFF"),
    },
    gradient = "electronics-4"
}

WORLDSOUND_STYLE.HOUSE_ALARM      = styles.basic {
    color = COLORS.HOUSE_ALARM,
    arc = math.pi,
    icon = { which = "alarm-bang" }
}

module.styles                     = WORLDSOUND_STYLE

local WORLDSOUND_CLASSIFIERS      = {}

WORLDSOUND_CLASSIFIERS.UNKNOWN    = classifier {
    discriminator = taggers.positional("unknown"),
    style = WORLDSOUND_STYLE.UNKNOWN,
    duration = 5
}

WORLDSOUND_CLASSIFIERS.HELICOPTER = classifier {
    discriminator = function()
        return "helicopter" --
    end,
    style = WORLDSOUND_STYLE.HELICOPTER,
    duration = 60
}

WORLDSOUND_CLASSIFIERS.THUNDER    = classifier {
    discriminator = function()
        return "thunder" --
    end,
    style = WORLDSOUND_STYLE.THUNDER,
    duration = 10
}

WORLDSOUND_CLASSIFIERS.GUNSHOT    = classifier {
    discriminator = function()
        return "gunshot" --
    end,
    style = WORLDSOUND_STYLE.GUNSHOT,
    duration = 10
}

WORLDSOUND_CLASSIFIERS.ISOFIRE    = classifier {
    discriminator = taggers.positional("fire"),
    style = WORLDSOUND_STYLE.FIRE,
    duration = 10
}


WORLDSOUND_CLASSIFIERS.ZOMBIE = classifier {
    discriminator = taggers.uid,
    style = WORLDSOUND_STYLE.LIVING,
    duration = 1
}

WORLDSOUND_CLASSIFIERS.WINDOW_SMASHED = classifier {
    discriminator = taggers.uid,
    style = styles.basic {
        arc = true,
        color = color(1.0, 0.25, 0.1),
        icon = { which = "symbol-glass-break" }
    },
    duration = 5
}

WORLDSOUND_CLASSIFIERS.THUMP = classifier {
    discriminator = taggers.nsuid("thump"),
    duration = 1,
    style = styles.basic {
        color = COLORS.THUMP,
        arc = true,
        icon = { which = "object-fence" }
    }
}

WORLDSOUND_CLASSIFIERS.THUMP_DOOR = classifier {
    discriminator = taggers.nsuid("thump"),
    duration = 1,
    style = styles.basic {
        color = COLORS.THUMP,
        arc = true,
        icon = { which = "object-door" }
    }
}

WORLDSOUND_CLASSIFIERS.THUMP_GARAGE = classifier {
    discriminator = taggers.nsuid("thump"),
    duration = 1,
    style = styles.basic {
        color = COLORS.THUMP,
        arc = true,
        icon = { which = "object-door-garage" }
    }
}

WORLDSOUND_CLASSIFIERS.THUMP_WINDOW = classifier {
    discriminator = taggers.nsuid("thump"),
    duration = 1,
    style = styles.basic {
        color = COLORS.THUMP,
        arc = true,
        icon = { which = "object-window" }
    }
}

WORLDSOUND_CLASSIFIERS.ISOANIMAL = classifier {
    duration = 1,
    discriminator = taggers.uid,
    style = WORLDSOUND_STYLE.LIVING
}

WORLDSOUND_CLASSIFIERS.ISOPLAYER = classifier {
    duration = 1,
    discriminator = taggers.uid,
    style = WORLDSOUND_STYLE.LIVING
}

WORLDSOUND_CLASSIFIERS.ISOSURVIVOR = classifier {
    duration = 1,
    discriminator = taggers.uid,
    style = WORLDSOUND_STYLE.LIVING
}

WORLDSOUND_CLASSIFIERS.ALARM = classifier {
    duration = 5,
    discriminator = taggers.positional("alarm"),
    style = WORLDSOUND_STYLE.HOUSE_ALARM
}

WORLDSOUND_CLASSIFIERS.ISOTELEVISION = classifier {
    duration = 10,
    discriminator = taggers.positional("broadcast"),
    style = WORLDSOUND_STYLE.BROADCAST
}

WORLDSOUND_CLASSIFIERS.ISORADIO = classifier {
    duration = 10,
    discriminator = taggers.positional("broadcast"),
    style = WORLDSOUND_STYLE.BROADCAST
}

WORLDSOUND_CLASSIFIERS.ISOOBJECT = WORLDSOUND_CLASSIFIERS.UNKNOWN

-- classifier {
--     duration = 10,
--     discriminator = taggers.positional("appliance"),
--     style = WORLDSOUND_STYLE.
-- }

WORLDSOUND_CLASSIFIERS.CLOTHINGDRYERLOGIC = classifier {
    duration = 10,
    discriminator = taggers.positional("appliance"),
    style = WORLDSOUND_STYLE.LAUNDRY
}

WORLDSOUND_CLASSIFIERS.CLOTHINGWASHERLOGIC = classifier {
    duration = 10,
    discriminator = taggers.positional("appliance"),
    style = WORLDSOUND_STYLE.LAUNDRY
}

module.classifier = WORLDSOUND_CLASSIFIERS



return module
