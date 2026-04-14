-- local xbezier = require('hfsound/bezier')
-- local Bezier = xbezier.Bezier

local simple_color = require('hfsound/scope/_color/simple')
local cyclic_color = require('hfsound/scope/_color/cyclic')
local colorutil = require('hfsound/colors')
local Icons = require('hfsound/icons')

local impl = require('hfsound/scope/_style/_render')

---@generic T
---@param v T
---@return hfs.StyleClosure<T>
local function constant(v) return function(...) return v end end

--------------------------------------------------------------------------------

-- #region hfs.BasicStyle

---@class (partial) hfs.BasicStyle : hfs.Style
---@field m_icon         boolean
---@field m_arc          boolean
---@field m_iconload?    hfs.Icon
---@field m_icontexture? Texture
---@field m_iconscale    hfs.StyleClosure<number>
---@field m_iconcolor    hfs.Color
---@field m_arclen       hfs.StyleClosure<number>
---@field m_color        hfs.Color
local Basic = { render = impl.renderstyle }; Basic.__index = Basic

---@class hfs.BasicStyle.Kwargs.Icon
---@field which          Texture | hfs.Icon
---@field scale?         number
---@field color?         hfs.Color

---@class hfs.BasicStyle.Kwargs
---@field color?         hfs.Color,
---@field arc?           number | boolean,
---@field gradient?      hfs.Gradient,
---@field icon?          hfs.Icon | hfs.BasicStyle.Kwargs.Icon

---@param kw hfs.BasicStyle.Kwargs
function Basic.new(kw)
    local obj = setmetatable({}, Basic)

    if kw.color then
        obj.m_color = kw.color
    else
        obj.m_color = simple_color.new(1.0, 0.75, 0.0, 1.0)
    end

    obj.m_color_desaturated = obj.m_color:desaturate(0.5)

    if (type(kw.arc) == "nil") or (type(kw.arc) == "boolean" and kw.arc == true) then
        obj.m_arc = true
        obj.m_arclen = constant(2.09433) -- 2 * math.pi / 3
        obj.m_gradient = kw.gradient or "normal"
    elseif type(kw.arc) == "number" then
        obj.m_arc = true
        obj.m_arclen = constant(kw.arc)
        obj.m_gradient = kw.gradient or "normal"
    else
        if getDebug() then error("illegal state") end
        obj.m_arc = false
        obj.m_arclen = constant(0)
    end

    local icon = kw.icon

    if icon == nil then
        obj.m_icontexture = nil
        obj.m_iconload = nil
        obj.m_iconscale = constant(0.5)
        obj.m_iconcolor = simple_color.new(1, 1, 1, 1)
        obj.m_icon = false
    elseif type(icon) == "string" then
        ---@cast icon hfs.Icon
        obj.m_icon = true
        obj.m_icontexture = nil
        obj.m_iconload = icon
        obj.m_iconscale = constant(0.5)
        obj.m_iconcolor = simple_color.new(1, 1, 1, 1)
    else
        ---@cast icon -hfs.Icon
        if type(icon.which) == "string" then
            ---@cast icon.which hfs.Icon
            obj.m_icon = true
            obj.m_icontexture = nil
            obj.m_iconload = icon.which --[[@as hfs.Icon | nil]]
            obj.m_iconscale = constant(icon.scale or 0.5)
            obj.m_iconcolor = icon.color or simple_color.new(1, 1, 1, 1)
        elseif instanceof(icon.which, "Texture") then
            ---@cast icon.which Texture
            obj.m_icon = true
            obj.m_icontexture = icon.which
            obj.m_iconload = nil
            obj.m_iconscale = constant(icon.scale or 0.5)
            obj.m_iconcolor = icon.color or simple_color.new(1, 1, 1, 1)
        else
            if getDebug() then error("illegal state") end
            obj.m_icon = false
        end
    end

    return obj
end

function Basic:init(renderer)
    if self.m_iconload then
        self.m_icontexture = renderer.icons[self.m_iconload]
        assert(self.m_icontexture ~= nil, "no such icon", self.m_iconload)
        self.m_iconload = nil
    end


    self.m_uicon = {
        renderer.icons[Icons.ARROW_UP],
        renderer.icons[Icons.ARROW_UP_2],
        renderer.icons[Icons.ARROW_UP_3]
    }

    self.m_dicon = {
        renderer.icons[Icons.ARROW_DOWN],
        renderer.icons[Icons.ARROW_DOWN_2],
        renderer.icons[Icons.ARROW_DOWN_3]
    }

    if self.m_icon then
        assert(self.m_icontexture ~= nil, "missing texture for icon")
    end
end

-- local STEP_BEZIER = Bezier({ 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 })

-- local function round_bezier(n)
--     return math.floor(n) + STEP_BEZIER(n % 1)
-- end





-- #endregion Scope.Style.Basic

return {
    colors = {
        parse = colorutil.parse_rgba,
        Solid = simple_color,
        solid = simple_color.new,
        Cyclic = cyclic_color,
        cyclic = cyclic_color.new,

        WHITE = simple_color.new(1, 1, 1, 1),
    },

    create = Basic.new,
    basic = Basic.new,
    Basic = Basic
}
