local hfmath          = require('hfsound/math')
local hypermath       = require('hfsound/_math/_hyperbola')
local options         = require("hfsound/options")

local ilerp_clamped   = hfmath.ilerp_clamped
local lerp_clamped    = hfmath.lerp_clamped
local smootherstep    = hfmath.smootherstep
local math_min        = math.min
local math_log        = math.log
local TAU             = math.pi * 2

local opt_radius_min  = options.options.radius_min
local opt_radius_max  = options.options.radius_max
local opt_radius_bias = options.options.radius_bias

-- #region defines

local DISTANCE_0      = 1.5
local DISTANCE_1      = 5
local DISTANCE_2      = 8
local DISTANCE_3      = 12

-- #endregion defines


local module = {}

---@param kw hfs.RenderKwargs
local function alpha_multiplier_for(kw)
    local entry          = kw.entry
    local entry_duration = entry.m_duration
    local age_fade       = ilerp_clamped(entry_duration, entry_duration - 0.25, entry.m_age)
    return ilerp_clamped(entry.m_radius, 0, kw.distance) * (1 - kw.context.scope.overwhelm) * age_fade
end

---@param style hfs.BasicStyle
---@param kw hfs.RenderKwargs
function module.render(style, kw)
    local ctx              = kw.context
    local distance         = kw.distance
    local theta            = kw.theta
    local through_walls    = kw.through_walls
    local alpha_multiplier = alpha_multiplier_for(kw)

    if alpha_multiplier < 0.05 then
        return
    end

    local r1, r2

    local minimum_radius = opt_radius_min.value
    local maximum_radius = opt_radius_max.value
    local radius_range   = maximum_radius - minimum_radius -- TODO: do not do this here

    if distance < DISTANCE_0 then
        r1 = minimum_radius
    else
        r1 = smootherstep(DISTANCE_0, DISTANCE_3, distance) * (radius_range + minimum_radius) -- FIXME: inline
    end

    r2 = r1 - 0.3

    if style.m_arc then
        local arclen = style.m_arclen(kw)

        if distance <= DISTANCE_1 then
            local ratio = smootherstep(DISTANCE_1, 0, distance)        -- FIXME: inline
            arclen = lerp_clamped(arclen, TAU * minimum_radius, ratio) -- FIXME: inline
        end

        local r, g, b, a

        if through_walls then
            r, g, b, a = style.m_color_desaturated:compute(kw)
        else
            r, g, b, a = style.m_color:compute(kw)
        end

        ctx.renderer:renderArc(style.m_gradient, r1, r2, theta, arclen, r, g, b, a * alpha_multiplier)
    end

    local icon = style.m_icon
    local icontexture = style.m_icontexture
    local zdiff = kw.zdiff

    if distance < DISTANCE_2 and not through_walls then
        if zdiff > 0.5 then
            icon = true

            if zdiff > 1.5 then
                icontexture = style.m_uicon[3]
            else
                icontexture = style.m_uicon[2]
            end
        elseif zdiff < -0.5 then
            icon = true

            if zdiff < -1.5 then
                icontexture = style.m_dicon[3]
            else
                icontexture = style.m_dicon[2]
            end
        end
    end

    if through_walls then
        icon = true
        icontexture = style.m_question_icon
    end

    if icon then
        ---@cast icontexture Texture

        local iconcolor  = style.m_iconcolor
        local r, g, b, a = iconcolor:compute(kw)
        local ricon      = 0.5 * (r1 + r2)

        ctx.renderer:renderSprite(
            ricon, theta,
            r, g, b, a * alpha_multiplier,
            icontexture, 0, style.m_iconscale(kw)
        )
    end
end

return module
