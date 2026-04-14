-- local optutil = require('hfsound/options/options_wrapper')
local confirm = require('hfsound/options/confirm')
local color = require('hfsound/scope/color')

-- #region class: HfSoundOptions

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
    ZombieOther      = "ZombieOther",
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

---@return { info:hfs.ConfigSoundInfo, order:hfs.ConfigSoundOrder }
local function get_configurable_sounds()
    ---@type hfs.ConfigSoundOrder
    local order = {
        [Group.Zombie] = {
            Sounds.ZombieIdle,
            Sounds.ZombieStep,
            Sounds.ZombieClamber,
            Sounds.ZombieAggression,
            Sounds.ZombieOther,
        },
        [Group.Living] = {
            Sounds.LivingPlayer,
            Sounds.LivingAnimal,
        },
        [Group.World] = {
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
        [Group.Vehicle] = {
            Sounds.VehicleEngine,
            Sounds.VehicleAlarm,
            Sounds.VehicleLightbar,
        }
    }

    local Z, L, W, V = Group.Zombie, Group.Living, Group.World, Group.Vehicle

    ---@type hfs.ConfigSoundInfo
    local info = {
        [Sounds.ZombieIdle]       = { group = Z, color = "#CCCC66", style = "breathe" },
        [Sounds.ZombieStep]       = { group = Z, color = "#FFFF00", style = "normal" },
        [Sounds.ZombieClamber]    = { group = Z, color = "#FF9900", style = "normal" },
        [Sounds.ZombieAggression] = { group = Z, color = "#FF3300", style = "normal" },
        [Sounds.ZombieOther]      = { group = Z, color = "#ff6633", style = "normal" },
        [Sounds.LivingPlayer]     = { group = L, color = "#33FFCC", style = "normal" },
        [Sounds.LivingAnimal]     = { group = L, color = "#00ff66", style = "normal" },
        [Sounds.WorldThump]       = { group = W, color = "#ff0000", style = "flash" },
        [Sounds.WorldFire]        = { group = W, color = "#ff0000", style = "normal" },
        [Sounds.WorldAlarm]       = { group = W, color = "#ff00ff", style = "flash" },
        [Sounds.WorldThunder]     = { group = W, color = "#ffff99", style = "normal" },
        [Sounds.WorldGunfire]     = { group = W, color = "#ff00ff", style = "normal" },
        [Sounds.WorldHelicopter]  = { group = W, color = "#ff00ff", style = "normal" },
        [Sounds.WorldElectronics] = { group = W, color = "#009999", style = "flicker" },
        [Sounds.WorldAppliance]   = { group = W, color = "#cccccc", style = "normal" },
        [Sounds.WorldGenerator]   = { group = W, color = "#cccccc", style = "normal" },
        [Sounds.VehicleEngine]    = { group = V, color = "#cccccc", style = "normal" },
        [Sounds.VehicleAlarm]     = { group = V, color = "#ff00ff", style = "flash" },
        [Sounds.VehicleLightbar]  = { group = V, color = "#cccccc", style = "flash" },
    }

    if getDebug() then
        -- Validate some basic assetions about the data to make sure we haven't
        -- messed up entering it, but only if the game is in debug mode.

        ---@type {[hfs.ConfigSound]:bool}
        local found = {}

        for soundgroup, soundgroup_order in pairs(order) do
            for _, sound in ipairs(soundgroup_order) do
                found[sound] = true
                assert(Sounds[sound] == sound, "non-identity: " .. Sounds[sound] .. " vs " .. sound)
                assert(info[sound] ~= nil, "no info: " .. tostring(sound))
                assert(info[sound].group == soundgroup)
                assert(info[sound].style ~= nil)
            end
        end

        for k in pairs(Sounds) do
            assert(info[k] ~= nil)
            assert(found[k] == true)
        end
    end

    return { info = info, order = order }
end

---@alias Callback_OnConfigChanged fun(target: unknown, config: hfs.Options, ...: unknown )

---@class hfs.Options
local HfSoundOptions = {}; HfSoundOptions.__index = HfSoundOptions

---@param name string
---@param ... any
local function t_option(name, ...)
    return string.format("UI_options_%s_%s", "hfsound", string.format(name, ...))
end

---@param name string
local function kt_option(name)
    return name, string.format("UI_options_%s_%s", "hfsound", name)
end

---@overload fun(string:string): string, string
---@overload fun<T1>(string:string, a1: T1): string, string, T1
---@overload fun<T1,T2>(string:string, a1: T1, a2: T2): string, string, T1, T2
---@overload fun<T1,T2,T3>(string:string, a1: T1, a2: T2, a3: T3): string, string, T1, T2, T3
---@overload fun<T1,T2,T3,T4>(string:string, a1: T1, a2: T2, a3: T3, a4: T4): string, string, T1, T2, T3, T4
---@overload fun<T1,T2,T3,T4,T5>(string:string, a1: T1, a2: T2, a3: T3, a4: T4, a4: T5): string, string, T1, T2, T3, T4, T5
---@generic T
---@param name string
---@param ... T
local function option_args(name, ...)
    -- Not sure why, but my LSP needs the overloads to be happy.
    return name, string.format("UI_options_%s_%s", "hfsound", name), ...
end

---@return hfs.Options
function HfSoundOptions.new()
    local obj             = setmetatable({}, HfSoundOptions)

    ---@type { listener:Callback_OnConfigChanged, target: any }[]
    obj.listeners         = {}

    obj._onconfigapply    = function(...) obj:broadcast(...) end

    local soundinfo       = get_configurable_sounds()
    local _sound_order    = soundinfo.order
    local _sound_info     = soundinfo.info
    local wrapped         = PZAPI.ModOptions:create(kt_option "Options")

    -- This isn't injection, umbrella's types are just inacurate in this corner of the api.
    ---@diagnostic disable-next-line: inject-field
    wrapped.onChangeApply = obj._onconfigapply

    local options         = {
        sounds = {},
        ---@type hfs.ColorPickerWithDefault[]
        colors = {}
    }

    wrapped:addTitle(t_option "Display")
    options.quality         = wrapped:addSlider(option_args("DisplayQuality", 10, 50, 1, 30))
    options.indicator_limit = wrapped:addSlider(option_args("DisplayLimit", 20, 60, 1, 40))

    wrapped:addTitle(t_option "SoundEnable")
    for soundgroup, arr in pairs(_sound_order) do
        wrapped:addTitle(t_option("SoundEnable%s", soundgroup))
        for _, sound in ipairs(arr) do
            local info            = _sound_info[sound]
            info.opt_enable       = wrapped:addTickBox(option_args("SoundEnable" .. sound, true))
            options.sounds[sound] = { enable = info.opt_enable }
        end
    end

    wrapped:addTitle(t_option "SoundColor")
    for soundgroup, soundgroup_sounds in pairs(_sound_order) do
        wrapped:addTitle(t_option("SoundColor" .. soundgroup))
        for _, soundtype in ipairs(soundgroup_sounds) do
            local info = _sound_info[soundtype]
            local r, g, b = color.parse(info.color)
            ---@class hfs.XColorPicker : umbrella.ModOptions.ColorPicker
            info.opt_color = wrapped:addColorPicker(option_args("SoundColor" .. soundtype, r, g, b, 1))
            info.opt_color.defaultColor = { r = r, g = g, b = b, a = 1 }
            options.sounds[soundtype].color = info.opt_color
            table.insert(options.colors, info.opt_color)
            info.colorobject = color.ConfiguredColor.new({
                style = info.style,
                config = obj,
                option = info.opt_color,
                alpha = info.alpha or 0.5,
                saturation = 1.0,
            })
        end
    end

    obj._btn_reset = wrapped:addButton(option_args("ResetColorsButton",
        "UI_options_tooltip_hfsound_ResetColorsButton",
        obj._promptresetcolors, obj))

    ---@cast _sound_info { [hfs.ConfigSound]: hfs.ConfigSoundInfo.Complete }

    obj.order      = _sound_order
    obj.info       = _sound_info
    obj.sounds     = _sound_info
    obj.options    = options

    return obj
end

---@param sound hfs.ConfigSound
function HfSoundOptions:getconfiguredcolor(sound)
    return self.info[sound].colorobject
end

function HfSoundOptions:broadcast(...)
    print("broadcast:")
    for k, v in ipairs({ ... }) do
        print(string.format("%s %s", tostring(k), tostring(v)))
    end
    for _, listener in ipairs(self.listeners) do
        listener.listener(listener.target, self, ...)
    end
end

---@param listener Callback_OnConfigChanged
---@param target unknown
function HfSoundOptions:subscribe(listener, target)
    table.insert(self.listeners, { listener = listener, target = target })
end

function HfSoundOptions:_promptresetcolors()
    local function action()
        self:_resetcolors()
    end
    confirm.show_confirm(getText("UI_options_hfsound_ResetColorsConfirm"), action)
end

function HfSoundOptions:_resetcolors()
    for _, option in ipairs(self.options.colors) do
        assert(option.defaultcolor ~= nil)
        option:setValue(option.defaultcolor)
    end

    if type(MainOptions) ~= "table" then return end
    if type(MainOptions.instance) ~= "table" then return end
    if type(MainOptions.instance.gameOptions) ~= "table" then return end
    if type(MainOptions.instance.gameOptions.changed) ~= "boolean" then return end

    MainOptions.instance.gameOptions.changed = true
end

-- #endregion

local module = { HfSoundOptions = HfSoundOptions }



---@class (partial) _HFSOUND
---@field options hfs.Options?
HFSOUND = HFSOUND or {}

function module.get_options()
    if HFSOUND.options == nil then
        HFSOUND.options = module.HfSoundOptions.new()
    end

    return HFSOUND.options
end

return module
