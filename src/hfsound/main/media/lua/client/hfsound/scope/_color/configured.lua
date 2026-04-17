local colors = require('hfsound/colors')
local xtabla = require('hfsound/reflect/tables')

-- #region hfs.Color

---@class (exact) hfs.ConfiguredColor : hfs.Color
local ConfiguredColor = {}; ConfiguredColor.__index = ConfiguredColor

---@alias hfs.ColorStyle  "normal" | "breathe" | "flicker" | "flash"

---@class hfs.ConfiguredColor.Kwargs
---@field config        hfs.Options
---@field option        umbrella.ModOptions.ColorPicker
---@field alpha?        number
---@field saturation?   number
---@field style?        hfs.ColorStyle

---ConfiguredColor implements config-aware animated colors. It handles
---computing the per-frame color for various animation types, and it
---subscribes to config update events in real time.
---@param kw hfs.ConfiguredColor.Kwargs
---@return hfs.ConfiguredColor
function ConfiguredColor.new(kw)
    local obj      = setmetatable({}, ConfiguredColor)

    ---@type boolean
    obj.dirty      = true
    obj.style      = kw.style or "normal"

    ---@type fun(self, hfs.RenderKwargs): number, number, number, number
    obj.compute    = ConfiguredColor["compute_" .. obj.style]

    obj.config     = kw.config
    obj.option     = kw.option
    obj.saturation = kw.saturation or 1.0

    obj.r          = 0.0
    obj.g          = 0.0
    obj.b          = 0.0
    obj.a          = kw.alpha or 0.666

    -- optimization for hot path computation
    obj.a_div_2    = obj.a / 2
    obj.a_div_4    = obj.a / 4

    obj.config:subscribe(obj.setdirty, obj)
    obj:setdirty()

    return obj
end

function ConfiguredColor:setdirty()
    self.dirty = true
end

function ConfiguredColor:update()
    print("update ", self.style)
    local color            = self.option.color
    self.r, self.g, self.b = colors.desaturate(color.r, color.g, color.b, 1 - self.saturation)
    self.dirty             = false
end

---@param factor number
function ConfiguredColor:desaturate(factor)
    return ConfiguredColor.new {
        config = self.config,
        option = self.option,
        alpha = self.a,
        saturation = self.saturation * (1 - factor),
        style = self.style,
    }
end

---@param alpha number
function ConfiguredColor:alpha(alpha)
    return ConfiguredColor.new {
        config = self.config,
        option = self.option,
        alpha = alpha,
        saturation = self.saturation,
        style = self.style,
    }
end

-----------------------------------------

local floor  = math.floor
local cosine = math.cos
local PI     = math.pi
local PIDIV2 = PI / 2

-- These functions are in the hot path.

function ConfiguredColor:compute_normal()
    if self.dirty then self:update() end
    return self.r, self.g, self.b, self.a
end

---@param kw hfs.RenderKwargs
function ConfiguredColor:compute_breathe(kw)
    if self.dirty then self:update() end
    local alpha = (cosine(PIDIV2 * kw.entry.m_age) * 0.5 + 0.5) * self.a
    return self.r, self.g, self.b, alpha
end

---@type number[]
local FLICKER_LUT = {
    0.977, 0.680, 0.604, 0.907, 0.839, 0.668, 0.926, 0.511,
    0.614, 0.660, 0.722, 0.799, 0.705, 0.808, 0.934, 0.642,
    0.888, 0.886, 0.635, 0.768, 0.518, 0.939, 0.945, 0.631,
    0.610, 0.699, 0.628, 0.604, 0.658, 0.803, 0.962, 0.861,
    0.781, 0.720, 0.502, 0.936, 0.828, 0.758, 0.881, 0.788,
    0.970, 0.638, 0.975, 0.897, 0.694, 0.955, 0.878, 0.562,
    0.905, 0.883, 0.968, 0.721, 0.862, 0.927, 0.698, 0.928,
    0.747, 0.707, 0.905, 0.696, 0.526, 0.541, 0.542, 0.567
}

local FLICKER_LUT_N = #FLICKER_LUT
local FLICKER_LUT_F = 8

---@param kw hfs.RenderKwargs
function ConfiguredColor:compute_flicker(kw)
    if self.dirty then self:update() end
    ---@diagnostic disable-next-line: need-check-nil
    local alpha = self.a * FLICKER_LUT[1 + floor(FLICKER_LUT_F * kw.entry.m_age) % FLICKER_LUT_N]
    return self.r, self.g, self.b, alpha
end

---@param kw hfs.RenderKwargs
function ConfiguredColor:compute_flash(kw)
    if self.dirty then self:update() end
    local factor = cosine(4 * PI * kw.entry.m_age) * 0.5 + 0.5
    local r, g, b
    r = 1 - (1 - self.r) * factor
    g = 1 - (1 - self.g) * factor
    b = 1 - (1 - self.b) * factor
    return r, g, b, self.a
end

-----------------------------------------

-- Each instance should have its own compute method based on its style
-- If Lua is checking the prototype, it means we're in an illegal state.

function ConfiguredColor:compute() error("virtual function `compute` not set") end

-- #endregion

return ConfiguredColor
