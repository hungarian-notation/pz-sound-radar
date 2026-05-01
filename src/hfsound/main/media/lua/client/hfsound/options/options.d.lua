---@meta

-- ---@field group hfs.config.Group

---@class hfs.ConfigSoundInfo.Static
---@field color hfs.OptionsColor
---@field style hfs.ColorStyle
---@field alpha number

---@class hfs.ConfigSoundInfo.Runtime
---@field opt_enable umbrella.ModOptions.TickBox
---@field opt_color umbrella.ModOptions.ColorPicker
---@field colorobject hfs.ConfiguredColor

---@class hfs.ConfigSoundInfo.Complete : hfs.ConfigSoundInfo.Static, hfs.ConfigSoundInfo.Runtime
---@class hfs.ConfigSoundInfo.Partial : hfs.ConfigSoundInfo.Static, Partial<hfs.ConfigSoundInfo.Runtime>

---@alias hfs.ConfigSoundInfo { [hfs.ConfigSound]: hfs.ConfigSoundInfo.Complete | hfs.ConfigSoundInfo.Partial}
---@alias hfs.ConfigSoundOrder { group: hfs.config.Group, sounds: hfs.ConfigSound[] }[]

---@class hfs.ColorPickerWithDefault : umbrella.ModOptions.ColorPicker
---@field defaultcolor umbrella.RGBA
---@

---@class hfs.MappedSlider : umbrella.ModOptions.Slider
---@field mappedValue number
---@field mapping fun(x:number):number

---@alias Callback_OnConfigChanged fun(target: unknown, config: hfs.Options, ...: unknown )