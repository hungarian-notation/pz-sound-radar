local confirm = require('hfsound/options/confirm')
local options_definitions = require("hfsound/options/options_definitions")
local color = require('hfsound/scope/color')

-- #region class: HfSoundOptions

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

---@alias hfs.Options.SoundInfo { [hfs.ConfigSound]: hfs.ConfigSoundInfo.Complete }

local definitions

---@return hfs.Options
function HfSoundOptions.new()
    definitions = definitions or options_definitions.initialize()

    HFSOUND = HFSOUND or {}

    if HFSOUND.options then
        return HFSOUND.options
    end

    local obj = setmetatable({}, HfSoundOptions)

    HFSOUND.options = obj


    -- ---@type { listener:Callback_OnConfigChanged, target: any }[]
    -- obj.listeners         = {}

    -- obj._onconfigapply    = function(...) obj:_broadcast(...) end

    -- local soundinfo    = get_configurable_sounds()
    obj.order     = definitions.Order
    obj.info      = definitions.Info
    local wrapped = PZAPI.ModOptions:create(kt_option "Options")

    -- This isn't injection, umbrella's types are just inaccurate in this corner of the api.
    ---@diagnostic disable-next-line: inject-field
    -- wrapped.onChangeApply = obj._onconfigapply

    local options = {
        ---@type hfs.ColorPickerWithDefault[]
        colors = {}
    }

    wrapped:addTitle(t_option "General")

    options.enable_zombie_sounds = wrapped:addTickBox(option_args("EnableZombieSounds", true))

    wrapped:addTitle(t_option "Display")

    options.quality    = wrapped:addSlider(option_args("DisplayQuality", 10, 50, 1, 30))
    options.radius_min = wrapped:addSlider(option_args("DisplayRadiusMin", 0.2, 4, 0.1, 1))
    options.radius_max = wrapped:addSlider(option_args("DisplayRadiusMax", 2, 10, 0.5, 5))

    wrapped:addTitle(t_option "SoundColor")


    for _, category in pairs(definitions.Order) do
        local sounds_group = category.group
        local sounds       = category.sounds

        wrapped:addTitle(t_option("SoundColor" .. sounds_group))

        for _, soundtype in ipairs(sounds) do
            local info = obj.info[soundtype]
            local r, g, b = color.parse(info.color)
            ---@class hfs.XColorPicker : umbrella.ModOptions.ColorPicker
            info.opt_color = wrapped:addColorPicker(option_args("SoundColor" .. soundtype, r, g, b, 1))
            info.opt_color.defaultcolor = { r = r, g = g, b = b, a = 1 }
            -- options.sounds[soundtype].color = info.opt_color
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

    ---@cast obj.info { [hfs.ConfigSound]: hfs.ConfigSoundInfo.Complete }

    obj.order      = obj.order
    -- obj.sounds     = _sound_info
    obj.info       = obj.info
    obj.options    = options

    return obj
end

---@param sound hfs.ConfigSound
function HfSoundOptions:getconfiguredcolor(sound)
    return self.info[sound].colorobject
end

-- ---@param listener Callback_OnConfigChanged
-- ---@param target unknown
-- function HfSoundOptions:subscribe(listener, target)
--     table.insert(self.listeners, { listener = listener, target = target })
-- end

-- ---invoke all config subscription callbacks
-- function HfSoundOptions:_broadcast(...)
--     print("broadcast:")
--     for k, v in ipairs({ ... }) do
--         print(string.format("%s %s", tostring(k), tostring(v)))
--     end
--     for _, listener in ipairs(self.listeners) do
--         listener.listener(listener.target, self, ...)
--     end
-- end

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
    local options = module.HfSoundOptions.new()
    assert(HFSOUND.options == options)
    return HFSOUND.options
end

return module
