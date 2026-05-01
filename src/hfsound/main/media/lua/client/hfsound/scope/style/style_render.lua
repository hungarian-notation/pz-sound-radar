local options_lib   = require("hfsound/options/options")
local hfmath        = require('hfsound/math')
local hypermath     = require('hfsound/_math/_hyperbola')

local ilerp_clamped = hfmath.ilerp_clamped
local lerp_clamped  = hfmath.lerp_clamped
local linproj_clamp = hfmath.linear_projection_clamped
local smootherstep  = hfmath.smootherstep
local math_min      = math.min
local math_log      = math.log
local PI            = math.pi
local TAU           = PI * 2
local THETA_MAX     = 19 * TAU / 20


-- #region defines

-- These four control points define three segments of the distance->radius
-- function where each segment covers 1/3 of the total radius range.

local D_RADIUS_MINUMUM = 3
local D_RADIUS_NEAR    = 16
local D_RADIUS_FAR     = 120
local D_RADIUS_DISTANT = 200

-- This is the distance at which we start indicating that sounds are above or
-- below the player.
local D_VERTICALITY    = 8

-- For sounds that are very close to the player, we scale the arclength of
-- the indicator from it's original value at D_ARC_SCALE_BEGIN to a full circle
-- at D_ARC_SCALE_MAXIMUM
local D_GROW_ARC_TO    = 2
local D_GROW_ARC_FROM  = 5


-- #endregion defines

local module = {}

---@param kw hfs.RenderKwargs
local function alpha_multiplier_for(kw)
    local entry          = kw.entry
    local entry_duration = entry.m_duration
    local age_fade       = ilerp_clamped(entry_duration, entry_duration - 0.25, entry.m_age)
    return ilerp_clamped(entry.m_radius, entry.m_radius * 0.75, kw.distance) * (1 - kw.context.scope.overwhelm) * age_fade
end


-- local _opt_radius_min
-- local _opt_radius_max

-- local get_radii_options = function()
--     do
--         _opt_radius_min = options_lib.get_options().controls.slider_radius_min
--         _opt_radius_max = options_lib.get_options().controls.slider_radius_max
--     end
--     get_radii_options = function()
--         return _opt_radius_min.value, _opt_radius_max.value
--     end
--     return get_radii_options()
-- end

local get_radii_options = function() return 1, 8 end

local _opt_dynamic_arcs

local get_dynamic_arcs = function()
    do
        _opt_dynamic_arcs = options_lib.get_options().controls.tickbox_dynamic_arcs
    end

    get_dynamic_arcs = function()
        return _opt_dynamic_arcs.value
    end

    return get_dynamic_arcs()
end

---@param style hfs.BasicStyle
---@param kw hfs.RenderKwargs
function module.render(style, kw)
    local ctx              = kw.context
    local renderer         = ctx.renderer
    local radius_limit     = renderer.m_radiuslimit
    local distance         = kw.distance
    local theta            = kw.theta
    local through_walls    = kw.through_walls
    local alpha_multiplier = alpha_multiplier_for(kw)

    if alpha_multiplier < 0.05 then
        return
    end

    local r1, r2

    local radius_min, radius_max = get_radii_options()
    local radius_range = radius_max - radius_min -- TODO: do not do this here
    local radius_third = radius_range / 3
    local radius_near = radius_min + radius_third
    local radius_far = radius_near + radius_third

    if distance < D_RADIUS_MINUMUM then
        r1 = radius_min
    elseif distance < D_RADIUS_NEAR then
        -- r1 = lerp_clamped(radius_min, radius_near, ilerp_clamped(D_RADIUS_MINUMUM, D_RADIUS_NEAR, distance))
        r1 = linproj_clamp(radius_min, radius_near, D_RADIUS_MINUMUM, D_RADIUS_NEAR, distance)
    elseif distance < D_RADIUS_FAR then
        -- r1 = lerp_clamped(radius_near, radius_far, ilerp_clamped(D_RADIUS_NEAR, D_RADIUS_FAR, distance))
        r1 = linproj_clamp(radius_near, radius_far, D_RADIUS_NEAR, D_RADIUS_FAR, distance)
    else
        -- r1 = lerp_clamped(radius_far, radius_max, ilerp_clamped(D_RADIUS_FAR, D_RADIUS_DISTANT, distance))
        r1 = linproj_clamp(radius_far, radius_max, D_RADIUS_FAR, D_RADIUS_DISTANT, distance)
    end

    r1 = math_min(radius_limit, r1)
    r2 = r1 - 0.3

    local style_arc = style.m_arc

    if style_arc then
        local arclen = style.m_arclen

        if get_dynamic_arcs() and distance <= D_GROW_ARC_FROM then
            arclen = linproj_clamp(arclen, THETA_MAX * radius_min, D_GROW_ARC_FROM, D_GROW_ARC_TO, distance) -- FIXME: inline
        end

        local r, g, b, a

        if through_walls then
            r, g, b, a = style.m_color_desaturated:compute(kw)
        else
            r, g, b, a = style.m_color:compute(kw)
        end

        renderer:renderArc(style_arc, r1, r2, theta, arclen, r, g, b, a * alpha_multiplier)
    end

    local style_icon = style.m_icon
    local zdiff = kw.zdiff

    ---@type Texture?
    local icontexture

    if not not style_icon then
        ---@cast style_icon Texture
        icontexture = style_icon
    end

    if distance < D_VERTICALITY and not through_walls then
        if zdiff > 0.5 then
            if zdiff > 1.5 then
                icontexture = style.m_uicon[3]
            else
                icontexture = style.m_uicon[2]
            end
        elseif zdiff < -0.5 then
            if zdiff < -1.5 then
                icontexture = style.m_dicon[3]
            else
                icontexture = style.m_dicon[2]
            end
        end
    end

    if through_walls then
        icontexture = style.m_question_icon
    end

    if icontexture then
        local iconcolor  = style.m_icon_color
        local r, g, b, a = iconcolor:compute(kw)
        local ricon      = 0.5 * (r1 + r2)

        renderer:renderSprite(
            ricon, theta,
            r, g, b, a * alpha_multiplier,
            icontexture, 0, style.m_icon_scale
        )
    end
end

return module
