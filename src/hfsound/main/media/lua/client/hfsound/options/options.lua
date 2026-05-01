local confirm = require('hfsound/options/confirm')
local options_definitions = require("hfsound/options/options_definitions")
local color = require('hfsound/scope/color')

-- #region class: HfSoundOptions

---holds references to the ModOptions API instances
---@class (exact) hfs.Options.Controls
---@field tickbox_enable_zombie_sounds umbrella.ModOptions.TickBox
---@field slider_quality umbrella.ModOptions.Slider
---@field tickbox_dynamic_arcs umbrella.ModOptions.TickBox
---@field button_resetcolors umbrella.ModOptions.Button
-- ---@field slider_radius_min umbrella.ModOptions.Slider
-- ---@field slider_radius_max umbrella.ModOptions.Slider

---@class hfs.Options
---@field controls hfs.Options.Controls
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


local definitions = options_definitions.create_instance()
local singleton_guard = false

---@return hfs.Options
function HfSoundOptions.new()
    if singleton_guard then error("multiple invocations of HfSoundOptions.new()") else singleton_guard = true end
    local obj       = setmetatable({}, HfSoundOptions)
    HFSOUND         = HFSOUND or {}
    HFSOUND.options = obj
    obj.info        = (definitions.Info --[[@as { [hfs.ConfigSound]: hfs.ConfigSoundInfo.Complete }]])
    obj.controls    = HfSoundOptions._build_controls(obj)
    return obj
end

---@return hfs.Options.Controls
function HfSoundOptions:_build_controls()
    local mod_options = PZAPI.ModOptions:create(kt_option "Options")
    local controls    = {}
    mod_options:addTitle(t_option "General")
    controls.tickbox_enable_zombie_sounds = mod_options:addTickBox(option_args("EnableZombieSounds", true))
    mod_options:addTitle(t_option "Display")
    controls.slider_quality = mod_options:addSlider(option_args("DisplayQuality", 10, 50, 1, 30))
    controls.tickbox_dynamic_arcs = mod_options:addTickBox(option_args("DisplayDynamicArcs", true))
    
    -- controls.slider_radius_min = mod_options:addSlider(option_args("DisplayRadiusMin", 0.2, 4, 0.1, 1))
    -- controls.slider_radius_max = mod_options:addSlider(option_args("DisplayRadiusMax", 2, 12, 0.2, 8))
    mod_options:addTitle(t_option "SoundColor")
    for _, category in pairs(definitions.Order) do
        mod_options:addTitle(t_option("SoundColor" .. category.group))
        for _, soundtype in ipairs(category.sounds) do
            self:_build_colorpicker(mod_options, soundtype)
        end
    end
    controls.button_resetcolors = mod_options:addButton(option_args("ResetColorsButton",
        "UI_options_tooltip_hfsound_ResetColorsButton",
        self._promptresetcolors, self))
    return controls
end

---@param mod_options PZAPI.ModOptions.Options
---@param soundtype hfs.ConfigSound
function HfSoundOptions:_build_colorpicker(mod_options, soundtype)
    self._resetcolors_targets = self._resetcolors_targets or {}

    local info = self.info[soundtype]
    local r, g, b = color.parse(info.color)
    ---@class hfs.XColorPicker : umbrella.ModOptions.ColorPicker
    info.opt_color = mod_options:addColorPicker(option_args("SoundColor" .. soundtype, r, g, b, 1))
    info.opt_color.defaultcolor = { r = r, g = g, b = b, a = 1 }
    -- options.sounds[soundtype].color = info.opt_color
    table.insert(self._resetcolors_targets, info.opt_color)


    info.colorobject = color.ConfiguredColor.new({
        style = info.style,
        config = self,
        option = info.opt_color,
        alpha = info.alpha or 0.5,
        saturation = 1.0,
    })
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
    for _, option in ipairs(self._resetcolors_targets) do
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

HFSOUND.options = HFSOUND.options or module.HfSoundOptions.new()

---@return hfs.Options
function module.get_options()
    return HFSOUND.options
end

return module
