local colorutil = require('hfsound/colors')
local xmath     = require('hfsound/math')
local lerp      = xmath.lerp


-- #region Scope.Color.Cyclic

---@class hfs.CyclicColor : hfs.Color
local CyclicColor = {}; CyclicColor.__index = CyclicColor

---@alias hf.vec4 [number, number, number, number]

---@param kwargs ({ colors: ((string|hf.vec4)[]), rate: number })
function CyclicColor.new(kwargs)
    local obj = setmetatable({}, CyclicColor)
    local colors = kwargs.colors

    for i, color in ipairs(colors) do
        if type(color) == "string" then
            colors[i] = { colorutil.parse_rgba(color) } --[[@as hf.vec4]]
        end
    end

    ---@cast colors hf.vec4[]

    obj.colors = colors
    obj.rate = kwargs.rate
    return obj
end

function CyclicColor:desaturate(factor)
    ---@type hf.vec4[]
    local desaturated_colors = {}

    for i, color in ipairs(self.colors) do
        desaturated_colors[i] = { colorutil.desaturate(color[1], color[2], color[3], factor), color[4] }
    end

    return CyclicColor.new { colors = desaturated_colors, rate = self.rate }
end

function CyclicColor:compute(kwargs)
    local colors = self.colors
    local frame = ((kwargs.entry.m_age * self.rate * #colors) % #colors) + 1

    local ia = math.floor(frame)
    local ib = (ia % #colors) + 1
    local a = colors[ia]
    local b = colors[ib]
    local x = frame % 1

    assert(a ~= nil)
    assert(b ~= nil)

    return lerp(a[1], b[1], x), lerp(a[2], b[2], x), lerp(a[3], b[3], x), lerp(a[4], b[4], x)
end

-- #endregion

return CyclicColor
