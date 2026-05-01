local function create_instance()
    ---@enum  hfs.config.Group
    local Group = {
        Zombie  = "Zombie",
        Living  = "Living",
        World   = "World",
        Vehicle = "Vehicle",
    }

    ---@enum hfs.ConfigSound
    local Sounds = {
        ZombieIdle       = "ZombieIdle",
        ZombieStep       = "ZombieStep",
        ZombieClamber    = "ZombieClamber",
        ZombieAggression = "ZombieAggression",
        -- ZombieOther      = "ZombieOther",
        LivingPlayer     = "LivingPlayer",
        LivingAnimal     = "LivingAnimal",
        WorldThump       = "WorldThump",
        WorldFire        = "WorldFire",
        WorldAlarm       = "WorldAlarm",
        WorldThunder     = "WorldThunder",
        WorldGunfire     = "WorldGunfire",
        WorldHelicopter  = "WorldHelicopter",
        WorldElectronics = "WorldElectronics",
        WorldAppliance   = "WorldAppliance",
        WorldGenerator   = "WorldGenerator",
        VehicleEngine    = "VehicleEngine",
        VehicleAlarm     = "VehicleAlarm",
        VehicleLightbar  = "VehicleLightbar",
    }

    ---@type hfs.ConfigSoundOrder
    local Order = {
        {
            group = Group.Zombie,
            sounds = {
                Sounds.ZombieIdle,
                Sounds.ZombieStep,
                Sounds.ZombieClamber,
                Sounds.ZombieAggression,
                -- Sounds.ZombieOther,
            },
        },
        {
            group = Group.Living,
            sounds = {
                Sounds.LivingPlayer,
                Sounds.LivingAnimal,
            },
        },
        {
            group = Group.World,
            sounds = {
                Sounds.WorldThump,
                Sounds.WorldHelicopter,
                Sounds.WorldAlarm,
                Sounds.WorldAppliance,
                Sounds.WorldGenerator,
                Sounds.WorldElectronics,
                Sounds.WorldFire,
                Sounds.WorldThunder,
                Sounds.WorldGunfire,
            },
        },
        {
            group = Group.Vehicle,
            sounds = {
                Sounds.VehicleEngine,
                Sounds.VehicleAlarm,
                Sounds.VehicleLightbar,
            },
        }
    }

    ---@type hfs.ConfigSoundInfo
    local Info = {
        [Sounds.ZombieIdle]       = { color = "#CCCC66", style = "breathe" },
        [Sounds.ZombieStep]       = { color = "#FFFF00", style = "normal" },
        [Sounds.ZombieClamber]    = { color = "#FF9900", style = "normal" },
        [Sounds.ZombieAggression] = { color = "#FF3300", style = "normal" },
        -- [Sounds.ZombieOther]      = {  color = "#ff6633", style = "normal" },
        [Sounds.LivingPlayer]     = { color = "#33FFCC", style = "normal" },
        [Sounds.LivingAnimal]     = { color = "#00ff66", style = "normal" },
        [Sounds.WorldThump]       = { color = "#ff0000", style = "flash" },
        [Sounds.WorldFire]        = { color = "#ff0000", style = "normal" },
        [Sounds.WorldAlarm]       = { color = "#ff00ff", style = "flash" },
        [Sounds.WorldThunder]     = { color = "#ffff99", style = "normal" },
        [Sounds.WorldGunfire]     = { color = "#ff00ff", style = "normal" },
        [Sounds.WorldHelicopter]  = { color = "#ff00ff", style = "normal" },
        [Sounds.WorldElectronics] = { color = "#009999", style = "flicker" },
        [Sounds.WorldAppliance]   = { color = "#cccccc", style = "normal" },
        [Sounds.WorldGenerator]   = { color = "#cccccc", style = "normal" },
        [Sounds.VehicleEngine]    = { color = "#cccccc", style = "normal" },
        [Sounds.VehicleAlarm]     = { color = "#ff00ff", style = "flash" },
        [Sounds.VehicleLightbar]  = { color = "#cccccc", style = "flash" },
    }

    if getDebug() then
        -- Validate some basic assertions about the data to make sure we haven't
        -- messed up entering it.

        ---@type {[hfs.ConfigSound]:bool}
        local found = {}


        for _, category in pairs(Order) do
            local soundgroup = category.group
            local soundgroup_order = category.sounds

            for _, sound in ipairs(soundgroup_order) do
                found[sound] = true
                assert(Sounds[sound] == sound, "non-identity: " .. Sounds[sound] .. " vs " .. sound)
                assert(Info[sound] ~= nil, "no info: " .. tostring(sound))
                assert(Info[sound].style ~= nil)
            end
        end

        for k in pairs(Sounds) do
            assert(Info[k] ~= nil)
            assert(found[k] == true)
        end
    end

    return {
        Group  = Group,
        Sounds = Sounds,
        Order  = Order,
        Info   = Info
    }
end

return { create_instance = create_instance }
