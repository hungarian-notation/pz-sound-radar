---@meta

-- Internal Types

---@class hfs.ZSKwargsBase
---@field radius number
---@field category hfs.StateCategory
---@field volume? number
---@field duration? number
---@field style? hfs.Style

---@class hfs.ZSoundKwargsFrequency : hfs.ZSKwargsBase
---@field frequency number

---@class hfs.ZSoundKwargsPeriod : hfs.ZSKwargsBase
---@field period number

---@alias hfs.ZSoundKwargs hfs.ZSoundKwargsFrequency | hfs.ZSoundKwargsPeriod
