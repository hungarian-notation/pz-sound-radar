local colors = require('hfsound/colors')
local xtabla = require('hfsound/reflect/tables')

-- #region hfs.Color

---@class (exact) hfs.ConfiguredColor : hfs.Color
local ConfiguredColor = {}; ConfiguredColor.__index = ConfiguredColor

---@class hfs.ConfiguredColor.Kwargs
---@field config        hfs.Options
---@field sound         hfs.config.Sound
---@field option        hfs.TaggedColorPicker
---@field alpha?        number
---@field saturation?   number

---@param kw hfs.ConfiguredColor.Kwargs
---@return hfs.ConfiguredColor
function ConfiguredColor.new(kw)
    local obj      = setmetatable({}, ConfiguredColor)

    ---@type boolean
    obj.dirty      = true

    obj.config     = kw.config
    obj.sound      = kw.sound
    obj.option     = kw.option
    obj.saturation = kw.saturation or 1.0

    obj.r          = 0.0
    obj.g          = 0.0
    obj.b          = 0.0
    obj.a          = kw.alpha or 0.5

    obj.config:subscribe(obj.setdirty, obj)
    obj:setdirty()

    return obj
end

function ConfiguredColor:setdirty()
    self.dirty = true
end

function ConfiguredColor:update()
    local color = self.option:getValue()
    self.r, self.g, self.b = colors.desaturate(color.r, color.g, color.b, 1 - self.saturation)
    print("updated to: ", string.format("%f, %f, %f", self.r, self.g, self.b), " from ", self.sound)
    self.dirty = false
end

function ConfiguredColor:desaturate(factor)
    return ConfiguredColor.new {
        config = self.config,
        sound = self.sound,
        option = self.option,
        alpha = self.a,
        saturation = self.saturation * (1 - factor)
    }
end

function ConfiguredColor:compute(_)
    if self.dirty then self:update() end

    return self.r, self.g, self.b, self.a
end

-- #endregion

return ConfiguredColor
