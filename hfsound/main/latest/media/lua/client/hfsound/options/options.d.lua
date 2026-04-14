---@meta


---@class hfs.ConfigSoundInfo.Static
---@field group hfs.config.Group
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
---@alias hfs.ConfigSoundOrder { [hfs.config.Group]: hfs.ConfigSound[] }


---@class hfs.ColorPickerWithDefault : umbrella.ModOptions.ColorPicker
---@field defaultcolor umbrella.RGBA