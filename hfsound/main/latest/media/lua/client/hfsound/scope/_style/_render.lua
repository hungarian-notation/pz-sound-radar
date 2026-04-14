local hfmath         = require('hfsound/math')
local ilerp_clamped  = hfmath.ilerp_clamped
local lerp_clamped   = hfmath.lerp_clamped

local TAU            = math.pi * 2

local CLOSE_DISTANCE = 2.5
local NEAR_DISTANCE  = 8


local module = {}

---@param kw hfs.RenderKwargs
local function alpha_multiplier_for(kw)
    local entry          = kw.entry
    local entry_duration = entry.m_duration
    local age_fade       = ilerp_clamped(entry_duration, entry_duration - 0.25, entry.m_age)
    return ilerp_clamped(entry.m_radius, 0, kw.distance) * (1 - kw.context.scope.overwhelm) * age_fade
end

local near_range      = NEAR_DISTANCE - CLOSE_DISTANCE
local near_slope      = 0.5
local near_offset     = near_range * near_slope
local log_scale       = 4
local log_coefficient = near_slope / log_scale

local function distance_falloff(d)
    if d < CLOSE_DISTANCE then
        return 0
    elseif d < NEAR_DISTANCE then
        return (d - CLOSE_DISTANCE) * near_slope
    else
        return near_offset + math.log(log_coefficient * (d - NEAR_DISTANCE) + 1) * log_scale
    end
end

-- local function RoundFunction(size)
--     local rsize = 1 / size

--     local function closure(value)
--         return math.floor(value * rsize + 0.5) * size
--     end

--     return closure
-- end

-- local SMOOTH         = true
-- local round_distance = RoundFunction(0.666)
-- local round_theta    = RoundFunction(TAU / 32)

---@param style hfs.BasicStyle
---@param kw hfs.RenderKwargs
function module.renderstyle(style, kw)
    local ctx              = kw.context
    local distance         = kw.distance
    local theta            = kw.theta
    local alpha_multiplier = alpha_multiplier_for(kw)

    if alpha_multiplier < 0.05 then
        return
    end

    local r1, r2

    if distance >= CLOSE_DISTANCE then
        local adjusted_distance = distance_falloff(distance)

        -- if not SMOOTH then
        --     adjusted_distance = round_distance(adjusted_distance)
        -- end

        r1 = 1 + adjusted_distance * 0.3
        r2 = r1 - 0.3
    else
        r1 = 1
        r2 = r1 - 0.3
    end

    -- if not SMOOTH then
    --     theta = round_theta(theta)
    -- end

    if style.m_arc then
        local arclen = style.m_arclen(kw)

        if distance <= NEAR_DISTANCE then
            local nearness = (1 - distance / NEAR_DISTANCE)
            arclen = lerp_clamped(arclen, TAU, nearness)

            -- if not SMOOTH then
            --     arclen = round_theta(arclen)
            -- end
        end

        local r, g, b, a

        if kw.transbuilding then
            r, g, b, a = style.m_color_desaturated:compute(kw)
        else
            r, g, b, a = style.m_color:compute(kw)
        end

        local adjusted_arclen = math.min(TAU, arclen)

        ctx.renderer:renderArc(style.m_gradient, r1, r2, theta, adjusted_arclen, r, g, b, a * alpha_multiplier)
    end

    local icon = style.m_icon
    local icontexture = style.m_icontexture
    local zdiff = kw.zdiff

    if distance < NEAR_DISTANCE then
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
