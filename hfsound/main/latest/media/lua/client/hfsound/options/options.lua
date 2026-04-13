local optutil = require('hfsound/options/options_wrapper')
local confirm = require('hfsound/options/confirm')
local color = require('hfsound/scope/color')

-- #region class: HfSoundOptions

---@enum  hfs.config.Group
local Group = {
    Zombie = "Zombie",
    Living = "Living",
    World = "World",
    Vehicle = "Vehicle",
}

---@enum hfs.config.Sound
local Sounds = {
    ZombieIdle = "ZombieIdle",
    ZombieStep = "ZombieStep",
    ZombieClamber = "ZombieClamber",
    ZombieAggression = "ZombieAggression",
    ZombieOther = "ZombieOther",
    LivingPlayer = "LivingPlayer",
    LivingAnimal = "LivingAnimal",
    WorldThump = "WorldThump",
    WorldFire = "WorldFire",
    WorldAlarm = "WorldAlarm",
    WorldThunder = "WorldThunder",
    WorldGunfire = "WorldGunfire",
    WorldHelicopter = "WorldHelicopter",
    WorldElectronics = "WorldElectronics",
    WorldAppliance = "WorldAppliance",
    WorldGenerator = "WorldGenerator",
    VehicleEngine = "VehicleEngine",
    VehicleAlarm = "VehicleAlarm",
    VehicleLightbar = "VehicleLightbar",
}

local function get_soundinfo()
    ---@alias _RawOrder { [hfs.config.Group]: hfs.config.Sound[] }

    ---@type _RawOrder
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

    ---@class hfs.config.Info
    ---@field group hfs.config.Group
    ---@field color hfs.OptionsColor
    ---@field alpha number

    ---@class hfs.config.InfoConfig
    ---@field opt_enable umbrella.ModOptions.TickBox
    ---@field opt_color umbrella.ModOptions.ColorPicker
    ---@field color_configured hfs.ConfiguredColor

    ---@class hfs.config.FullInfo : hfs.config.Info, hfs.config.InfoConfig

    ---@alias _IncompleteInfo hfs.config.Info & Partial<hfs.config.InfoConfig>
    ---@alias _RawInfo { [hfs.config.Sound]: hfs.config.FullInfo | _IncompleteInfo}

    local Z, L, W, V = Group.Zombie, Group.Living, Group.World, Group.Vehicle

    ---@type _RawInfo
    local info = {
        [Sounds.ZombieIdle]       = { group = Z, color = "#CCCC66" },
        [Sounds.ZombieStep]       = { group = Z, color = "#FFFF00" },
        [Sounds.ZombieClamber]    = { group = Z, color = "#FF9900" },
        [Sounds.ZombieAggression] = { group = Z, color = "#FF3300" },
        [Sounds.ZombieOther]      = { group = Z, color = "#ff6633" },
        [Sounds.LivingPlayer]     = { group = L, color = "#33FFCC" },
        [Sounds.LivingAnimal]     = { group = L, color = "#00ff66" },
        [Sounds.WorldThump]       = { group = W, color = "#ff0000" },
        [Sounds.WorldFire]        = { group = W, color = "#ff0000" },
        [Sounds.WorldAlarm]       = { group = W, color = "#ff00ff" },
        [Sounds.WorldThunder]     = { group = W, color = "#ffff99" },
        [Sounds.WorldGunfire]     = { group = W, color = "#ff00ff" },
        [Sounds.WorldHelicopter]  = { group = W, color = "#ff00ff" },
        [Sounds.WorldElectronics] = { group = W, color = "#009999" },
        [Sounds.WorldAppliance]   = { group = W, color = "#cccccc" },
        [Sounds.WorldGenerator]   = { group = W, color = "#cccccc" },
        [Sounds.VehicleEngine]    = { group = V, color = "#cccccc" },
        [Sounds.VehicleAlarm]     = { group = V, color = "#ff00ff" },
        [Sounds.VehicleLightbar]  = { group = V, color = "#cccccc" },
    }

    if getDebug() then
        -- Validate some basic assetions about the data to make sure we haven't
        -- messed up entering it.

        ---@type {[hfs.config.Sound]:bool}
        local found = {}

        for k, o in pairs(order) do
            for _, v in ipairs(o) do
                found[v] = true
                assert(Sounds[v] == v)
                assert(info[v] ~= nil, tostring(v))
                assert(info[v].group == k)
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


---@return hfs.Options
function HfSoundOptions.new()
    local obj = setmetatable({}, HfSoundOptions)

    ---@type { listener:Callback_OnConfigChanged, target: any }[]
    obj.listeners = {}

    obj._onconfigapply = function(...) obj:broadcast(...) end

    local soundinfo = get_soundinfo()
    local _sound_order = soundinfo.order
    local _sound_info = soundinfo.info

    local opt = optutil.options("hfsound")
    local wrapped = opt.opt

    ---@cast wrapped +{ onChange: fun(), onChangeApply:fun() }

    wrapped.onChangeApply = obj._onconfigapply

    local options = {
        sounds = {},
        ---@type hfs.TaggedColorPicker[]
        colors = {}
    }

    opt:addTitle("Display")
    options.quality = opt:addSlider("DisplayQuality", 10, 50, 1, 30)
    options.indicator_limit = opt:addSlider("DisplayLimit", 20, 60, 1, 40)
    opt:addSmallSeparator()

    opt:addTitle("SoundEnable")
    for g, arr in pairs(_sound_order) do
        opt:addTitle(string.format("SoundEnable%s", g))
        for _, s in ipairs(arr) do
            local info = _sound_info[s]
            info.opt_enable = opt:addTickBox(string.format("SoundEnable%s", s), true, false)
            options.sounds[s] = { enable = info.opt_enable }
        end
    end

    opt:addSmallSeparator()
    opt:addTitle("SoundColor")

    for g, arr in pairs(_sound_order) do
        opt:addTitle(string.format("SoundColor%s", g))
        for _, s in ipairs(arr) do
            local info = _sound_info[s]
            info.opt_color = opt:addColorPicker(string.format("SoundColor%s", s), info.color, false)
            options.sounds[s].color = info.opt_color
            table.insert(options.colors, info.opt_color)
            info.color_configured = color.ConfiguredColor.new {
                config = obj,
                sound = s,
                option = info.opt_color,
                alpha = info.alpha or 0.5,
                saturation = 1.0,
            }
        end
    end

    ---@cast _sound_info { [hfs.config.Sound]: hfs.config.FullInfo }
    obj.order = _sound_order
    obj.info = _sound_info

    obj.sounds = _sound_info
    obj.button_resetcolors = opt:addButton("ResetColorsButton", true, obj._promptresetcolors, obj)
    obj.options = options
    obj.opt = opt
    return obj
end

---@param sound hfs.config.Sound
function HfSoundOptions:getconfiguredcolor(sound)
    return self.info[sound].color_configured
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
