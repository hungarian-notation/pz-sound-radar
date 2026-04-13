local styles = require('hfsound/scope/style')
local color = styles.colors.solid

---@overload fun(rgba:string, icon?: hfs.Icon, gradient?: hfs.Gradient): hfs.BasicStyle
---@param ... [string, hfs.Icon?, hfs.Gradient?]
local function basicstyle(...)
    -- TODO: DEPRECATE

    local args = { ... }
    -- if type(args[1]) == "string" then
    local rgb = args[1]
    local icon = args[2] --[[@as hfs.Icon|nil]]
    local gradient = args[3] --[[@as hfs.Gradient|nil]]

    return styles.basic {
        arc = true,
        color = color(rgb),
        icon = icon and { which = icon, color = color(1, 1, 1, 1) } or nil,
        gradient = gradient,
    }
end

return basicstyle
