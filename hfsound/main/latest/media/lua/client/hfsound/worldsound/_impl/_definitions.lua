local taggers = require('hfsound/worldsound/_impl/_taggers')
local styles = require('hfsound/scope/style')
local color = styles.colors.solid
local Icons = require('hfsound/icons')

local options = require("hfsound/options/options")
local opts = options.get_options()

---type guarding validator for classifiers
---@param tbl hfs.WSClassifier
local function classifier(tbl)
    assert(type(tbl.discriminator) == "function")
    assert(type(tbl.duration) == "number")
    assert(type(tbl.style) == "table")
    return tbl
end

local module = { styles = {}, classifier = {} }

module.styles.LIVING = styles.create {
    color = opts:getconfiguredcolor("LivingPlayer")
}

module.styles.ANIMAL = styles.create {
    color = opts:getconfiguredcolor("LivingAnimal")
}

module.styles.UNKNOWN = styles.create {

    color = color("#ffffff80"), gradient = "edge"
}

module.styles.HELICOPTER = styles.create {
    color = opts:getconfiguredcolor("WorldHelicopter"),
    icon = Icons.VEHICLE_HELICOPTER,
    gradient = "edge"
}

module.styles.APPLIANCE = styles.create {
    color = opts:getconfiguredcolor("WorldAppliance"),
    icon = Icons.APPLIANCE_GENERATOR,
    gradient = "electronics-4"
}


module.styles.LAUNDRY = styles.create {
    color = opts:getconfiguredcolor("WorldAppliance"),
    icon = Icons.APPLIANCE_LAUNDRY,
    gradient = "electronics-3"
}

module.styles.VEHICLE_ALARM = styles.create {
    color = opts:getconfiguredcolor("VehicleAlarm"),
    icon = Icons.VEHICLE_CAR_ALERT,
    gradient = "electronics-5"
}

module.styles.GUNSHOT = styles.create {
    color = opts:getconfiguredcolor("WorldGunfire"),
    icon = Icons.OBJECT_PISTOL,
    gradient = "edge"
}

module.styles.THUNDER = styles.create {
    color = opts:getconfiguredcolor("WorldThunder"),
    icon = Icons.SYMBOL_BOLT,
    gradient = "edge"
}

module.styles.FIRE = styles.create {
    color = opts:getconfiguredcolor("WorldFire"),
    icon = { which = "symbol-fire" }
}

module.styles.BROADCAST = styles.create {
    color = opts:getconfiguredcolor("WorldElectronics"),
    arc = math.pi,
    icon = Icons.SYMBOL_WAVEFORM,
    gradient = "electronics-4"
}

module.styles.HOUSE_ALARM = styles.basic {
    color = opts:getconfiguredcolor("WorldAlarm"),
    arc = math.pi,
    icon = "alarm-bang"
}

module.classifier.UNKNOWN = classifier {
    discriminator = taggers.positional("unknown"),
    style = module.styles.UNKNOWN,
    duration = 5
}

module.classifier.ISOOBJECT = module.classifier.UNKNOWN

module.classifier.HELICOPTER = classifier {
    discriminator = function() return "helicopter" end,
    style = module.styles.HELICOPTER,
    duration = 60
}

module.classifier.THUNDER = classifier {
    discriminator = function() return "thunder" end,
    style = module.styles.THUNDER,
    duration = 10
}

module.classifier.GUNSHOT = classifier {
    discriminator = function() return "gunshot" end,
    style = module.styles.GUNSHOT,
    duration = 10
}

module.classifier.ISOFIRE = classifier {
    discriminator = taggers.positional("fire"),
    style = module.styles.FIRE,
    duration = 10
}

module.classifier.ZOMBIE = classifier {
    discriminator = taggers.uid,
    style = module.styles.LIVING,
    duration = 1
}

module.classifier.WINDOW_SMASHED = classifier {
    discriminator = taggers.uid,
    style = styles.basic {
        arc = 1,
        color = color(1.0, 0.25, 0.1),
        icon = "symbol-glass-break"
    },
    duration = 5
}

module.classifier.THUMP = classifier {
    discriminator = taggers.nsuid("thump"),
    duration = 1,
    style = styles.basic {
        arc = 2,
        color = opts:getconfiguredcolor("WorldThump"),
        icon = "object-fence",
    }
}

module.classifier.THUMP_DOOR = classifier {
    discriminator = taggers.nsuid("thump"),
    duration = 1,
    style = styles.basic {
        arc = 2,
        color = opts:getconfiguredcolor("WorldThump"),
        icon = "object-door",
    }
}

module.classifier.THUMP_GARAGE = classifier {
    discriminator = taggers.nsuid("thump"),
    duration = 1,
    style = styles.basic {
        arc = 2,
        color = opts:getconfiguredcolor("WorldThump"),
        icon = "object-door-garage",
    }
}

module.classifier.THUMP_WINDOW = classifier {
    discriminator = taggers.nsuid("thump"),
    duration = 1,
    style = styles.basic {
        arc = 2,
        color = opts:getconfiguredcolor("WorldThump"),
        icon = "object-window",
    }
}

module.classifier.THUMP_FENCE = classifier {
    discriminator = taggers.nsuid("thump"),
    duration = 1,
    style = styles.basic {
        arc = 2,
        color = opts:getconfiguredcolor("WorldThump"),
        icon = "object-fence",
    }
}

module.classifier.ISOANIMAL = classifier {
    duration = 1,
    discriminator = taggers.uid,
    style = module.styles.LIVING
}

module.classifier.ISOPLAYER = classifier {
    duration = 1,
    discriminator = taggers.uid,
    style = module.styles.LIVING
}

module.classifier.ISOSURVIVOR = classifier {
    duration = 1,
    discriminator = taggers.uid,
    style = module.styles.LIVING
}

module.classifier.ALARM = classifier {
    duration = 5,
    discriminator = taggers.positional("alarm"),
    style = module.styles.HOUSE_ALARM
}

module.classifier.ISOTELEVISION = classifier {
    duration = 10,
    discriminator = taggers.positional("broadcast"),
    style = module.styles.BROADCAST
}

module.classifier.ISORADIO = classifier {
    duration = 10,
    discriminator = taggers.positional("broadcast"),
    style = module.styles.BROADCAST
}

module.classifier.CLOTHINGDRYERLOGIC = classifier {
    duration = 10,
    discriminator = taggers.positional("appliance"),
    style = module.styles.LAUNDRY
}

module.classifier.CLOTHINGWASHERLOGIC = classifier {
    duration = 10,
    discriminator = taggers.positional("appliance"),
    style = module.styles.LAUNDRY
}

return module
