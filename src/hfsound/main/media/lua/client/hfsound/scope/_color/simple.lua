local colorutil = require('hfsound/colors')

-- #region hfs.Color

---@class (exact) hfs.SimpleColor : hfs.Color
local SimpleColor = {}; SimpleColor.__index = SimpleColor

---@overload fun(rgba: string): hfs.SimpleColor
---@overload fun(r: number, g: number, b: number, a: number): hfs.SimpleColor
---@return hfs.SimpleColor
function SimpleColor.new(...)
    local obj = setmetatable({}, SimpleColor)
    local r, g, b, a = colorutil.parse_rgba(...)

    obj.r = r
    obj.g = g
    obj.b = b
    obj.a = a or 1.0

    return obj
end

function SimpleColor:desaturate(factor)
    local r, g, b = colorutil.desaturate(self.r, self.g, self.b, factor)
    return SimpleColor.new(r, g, b, self.a)
end

function SimpleColor:compute(_)
    return self.r, self.g, self.b, self.a
end

-- #endregion

return SimpleColor
