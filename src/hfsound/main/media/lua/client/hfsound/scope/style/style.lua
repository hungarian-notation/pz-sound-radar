-- local xbezier = require('hfsound/bezier')
-- local Bezier = bezier.Bezier

local simple_color = require('hfsound/scope/_color/simple')
local colorutil = require('hfsound/colors')
local Icons = require('hfsound/icons')
local render = require('hfsound/scope/style/style_render')


---@generic T
---@param v T
---@return hfs.StyleClosure<T>
local function constant(v) return function(...) return v end end

--------------------------------------------------------------------------------

-- #region hfs.BasicStyle


---@class hfs.BasicStyle : hfs.Style
---@field m_arc           false | hfs.Gradient | Texture
---@field m_arclen        number
---@field m_color         hfs.Color
---@field m_icon          false | hfs.Icon | Texture
---@field m_icon_color    hfs.Color
---@field m_icon_scale    number
---@field m_renderer?     hfs.ScopeRenderer
local Basic = { render = render.render }; Basic.__index = Basic

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

    if (type(kw.arc) == "nil") or (type(kw.arc) == "boolean" and kw.arc == true) then
        obj.m_arc = kw.gradient or "normal"
        obj.m_arclen = 2.09433 -- 2 * math.pi / 3
    elseif type(kw.arc) == "number" then
        obj.m_arc = kw.gradient or "normal"
        obj.m_arclen = kw.arc
    else
        if getDebug() then error("illegal state") end
        obj.m_arc = false
        obj.m_arclen = 0.0
    end

    local icon = kw.icon

    if icon == nil then
        obj.m_icon = false
        obj.m_icon_scale = 0.5
        obj.m_icon_color = simple_color.new(1, 1, 1, 1)
    elseif type(icon) == "string" then
        ---@cast icon hfs.Icon
        obj.m_icon = icon
        obj.m_icon_scale = 0.5
        obj.m_icon_color = simple_color.new(1, 1, 1, 1)
    else
        ---@cast icon -hfs.Icon
        if type(icon.which) == "string" then
            ---@cast icon.which hfs.Icon
            obj.m_icon = icon.which
            obj.m_icon_scale = icon.scale or 0.5
            obj.m_icon_color = icon.color or simple_color.new(1, 1, 1, 1)
        elseif instanceof(icon.which, "Texture") then
            ---@cast icon.which Texture
            obj.m_icon = icon.which
            obj.m_icon_scale = icon.scale or 0.5
            obj.m_icon_color = icon.color or simple_color.new(1, 1, 1, 1)
        else
            if getDebug() then error("illegal state") end
            obj.m_icon = false
        end
    end

    obj.m_color_desaturated = obj.m_color:desaturate(0.75)

    return obj
end

---@param other hfs.BasicStyle
function Basic.clone(other)
    local obj = setmetatable({}, Basic)

    obj.m_arc = other.m_arc
    obj.m_arclen = other.m_arclen
    obj.m_color = other.m_color
    obj.m_color_desaturated = other.m_color_desaturated
    obj.m_icon = other.m_icon
    obj.m_icon_color = other.m_icon_color
    obj.m_icon_scale = other.m_icon_scale

    if other.m_renderer then
        obj.m_renderer = other.m_renderer
    end
end

function Basic:with_arclen(arclen)
end

---@param renderer hfs.ScopeRenderer
function Basic:init(renderer)
    self.m_renderer = renderer

    if type(self.m_arc) == "string" then
        ---@cast self.m_arc hfs.Gradient
        self.m_arc = renderer.gradients[self.m_arc]
    end


    if type(self.m_icon) == "string" then
        ---@cast self.m_icon hfs.Icon
        self.m_icon = renderer.icons[self.m_icon]
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

    self.m_question_icon = renderer.icons[Icons.SYMBOL_QUESTION]
end

-- #endregion Scope.Style.Basic

return {
    colors = {
        parse = colorutil.parse_rgba,
        Solid = simple_color,
        solid = simple_color.new,
        WHITE = simple_color.new(1, 1, 1, 1),
    },

    create = Basic.new,
    basic = Basic.new,
    Basic = Basic
}
