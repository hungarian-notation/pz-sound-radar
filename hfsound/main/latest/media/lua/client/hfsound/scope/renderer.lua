local geomlib = require('hfsound/geom')
local rotate_vector = geomlib.rotate_vector
local project_iso = geomlib.project_iso
local project_isooff = geomlib.project_isooffset

local hfgfx = require('hfsound/graphics')
local drawTexture = hfgfx.drawTexture

local Gradients = require('hfsound/gradients')
local Icons = require('hfsound/icons')

local options = require("hfsound/options/options")
local opt = options.get_options()


local PI    = 3.141592653589793
local TAU   = 2 * PI

local cos   = math.cos
local sin   = math.sin
local min   = math.min
local max   = math.max
local rad   = math.rad
local floor = math.floor
local ceil  = math.ceil


---@class (partial) hfs.ScopeRenderer
---@field icons { [hfs.Icon]: Texture }
---@field gradients { [hfs.Gradient]: Texture }
local ScopeRenderer = { Icons = Icons, Gradients = Gradients }; ScopeRenderer.__index = ScopeRenderer

---@class hfs.ScopeRenderer.Kwargs
---@field player? integer

---@param kw hfs.ScopeRenderer.Kwargs
function ScopeRenderer.new(kw)
    ---@class (partial) hfs.ScopeRenderer
    local obj = setmetatable({}, ScopeRenderer)

    ---@type { [hfs.Gradient]: Texture }
    obj.gradients = {}

    for _k, v in pairs(Gradients) do
        obj.gradients[v] = getTexture("media/textures/hfsound/gradient/" .. v .. ".png")
    end

    ---@type { [hfs.Icon]: Texture }
    obj.icons = {}

    for _k, v in pairs(Icons) do
        obj.icons[v] = getTexture("media/textures/hfsound/icon/" .. v .. ".png")
    end

    obj.m_gradient = obj.gradients[Gradients.NORMAL]
    --- the args table used to initialize this instance
    obj.m_kwargs = kw

    ---@type IsoPlayer
    obj.m_player = nil
    obj.m_zoom = 1.0
    obj.m_player_screen_x = 0.0
    obj.m_player_screen_y = 0.0
    obj.m_t = os.time()

    obj.unitAngle = rad(10)

    ---@type integer
    obj.m_quality_limit = 30
    ---@type number
    obj.m_quality = 1 / rad(360 / obj.m_quality_limit)

    obj.m_player_index = kw.player or 0
    obj.m_indicator_height = 0.5

    return obj
end

function ScopeRenderer:update()
    local playerIndex = self.m_player_index
    local p = getSpecificPlayer(playerIndex)

    self.m_zoom = getCore():getZoom(playerIndex)
    self.m_invzoom = 1 / self.m_zoom

    self.m_indicator_height_zoomed = self.m_indicator_height * self.m_invzoom

    self.m_player = p
    self.m_player_screen_x = isoToScreenX(0, p:getX(), p:getY(), p:getZ())
    self.m_player_screen_y = isoToScreenY(0, p:getX(), p:getY(), p:getZ())
    self.m_t = os.time()

    self:update_quality()
end

function ScopeRenderer:update_quality()
    self.m_quality_limit = floor(opt.options.quality.value)
    self.m_quality = 1 / rad(360 / self.m_quality_limit)
end

-- local function segment_corner(_theta, _radius)
--     return _radius * math.cos(_theta), _radius * math.sin(_theta)
-- end

function ScopeRenderer:calculate_steps(radius, length)
    local rawsteps = self.m_quality * length / radius
    local steps    = min(self.m_quality_limit, max(1, ceil(rawsteps)))
    return steps
end

---@param gradient hfs.Gradient | Texture
---@param r1 number
---@param r2 number
---@param theta number
---@param length number
---@param r number
---@param g number
---@param b number
---@param a number
function ScopeRenderer:renderArc(gradient, r1, r2, theta, length, r, g, b, a)
    ---@type Texture
    local gradient_texture

    if type(gradient) == "string" then
        ---@cast gradient hfs.Gradient
        gradient_texture = self.gradients[gradient] --[[@as Texture]]
    else
        ---@cast gradient Texture
        gradient_texture = gradient
    end

    local inner_angle = min(TAU, length / r1)
    if inner_angle < 0.1 then return end

    local sx      = self.m_player_screen_x
    local sy      = self.m_player_screen_y
    local invzoom = self.m_invzoom
    local height  = self.m_indicator_height_zoomed


    local inner_radius     = r2 * invzoom
    local outer_radius     = r1 * invzoom
    local half_inner_angle = inner_angle * 0.5
    local from             = theta - half_inner_angle
    local to               = theta + half_inner_angle

    local steps            = self:calculate_steps(r1, length)

    local steps_reciprocal = 1 / steps
    local sweep            = to - from
    local delta            = sweep / steps
    local vary_alpha       = inner_angle < TAU


    -- the texture's `u` coordinates
    local tex_u_1 = 0.5
    local tex_u_2 = 0.5

    local renderer = getRenderer()
    local renderPoly = renderer.renderPoly
    ---@cast renderPoly hfs.Function_RenderPolyQuadUV

    local theta_2 = from
    local sin_theta_2 = sin(from)
    local cos_theta_2 = cos(from)

    for i = 0, steps - 1 do
        local theta_1 = theta_2 -- or from + i * delta
        theta_2 = theta_1 + delta

        if vary_alpha then
            -- sweep the u-coordinate across the texture
            -- tex_u_1 = i * steps_reciprocal
            -- tex_u_2 = tex_u_1 + steps_reciprocal

            if i == 0 then
                tex_u_1 = 0
                tex_u_2 = tex_u_1 + steps_reciprocal
            else
                tex_u_1 = tex_u_2
                tex_u_2 = tex_u_1 + steps_reciprocal
            end
        end

        -- local x1, y1 = segment_corner(theta_1, inner_radius)
        -- local x2, y2 = segment_corner(theta_1, outer_radius)
        -- local x3, y3 = segment_corner(theta_2, outer_radius)
        -- local x4, y4 = segment_corner(theta_2, inner_radius)

        -- x1, y1 = project_isometricoff(x1, y1, height, 0, playerX, playerY)
        -- x2, y2 = project_isometricoff(x2, y2, height, 0, playerX, playerY)
        -- x3, y3 = project_isometricoff(x3, y3, height, 0, playerX, playerY)
        -- x4, y4 = project_isometricoff(x4, y4, height, 0, playerX, playerY)

        local sin_theta_1 = sin_theta_2
        sin_theta_2 = sin(theta_2)
        local cos_theta_1 = cos_theta_2
        cos_theta_2 = cos(theta_2)

        -- local sin_theta_1 = sin(theta_1)
        -- sin_theta_2 = sin(theta_2)
        -- local cos_theta_1 = cos(theta_1)
        -- cos_theta_2 = cos(theta_2)

        local x1, y1 = project_isooff(
            inner_radius * cos_theta_1, inner_radius * sin_theta_1,
            height,
            sx, sy
        )

        local x2, y2 = project_isooff(
            outer_radius * cos_theta_1, outer_radius * sin_theta_1,
            height,
            sx, sy
        )

        local x3, y3 = project_isooff(
            outer_radius * cos_theta_2, outer_radius * sin_theta_2,
            height,
            sx, sy
        )

        local x4, y4 = project_isooff(
            inner_radius * cos_theta_2, inner_radius * sin_theta_2,
            height,
            sx, sy
        )

        -- alternate pseudoquad orientation to reduce the impact of uv
        -- distortion
        --
        -- The issue here is that we are doing a perspective projection of our
        -- sprite quads, but the renderer only interpolates the uv coordinates
        -- of the rendered triangles in affine space. There may be a way to
        -- mitigate this by manipulating the transformation matrix.
        if i % 2 == 0 then
            renderPoly(renderer, gradient_texture,
                x2, y2,
                x3, y3,
                x4, y4,
                x1, y1,
                r, g, b, a,
                tex_u_1, 0,
                tex_u_2, 0,
                tex_u_2, 1,
                tex_u_1, 1
            )
        else
            renderPoly(renderer, gradient_texture,
                x1, y1,
                x2, y2,
                x3, y3,
                x4, y4,
                r, g, b, a,
                tex_u_1, 1,
                tex_u_1, 0,
                tex_u_2, 0,
                tex_u_2, 1
            )
        end
    end

    return steps
end

---@param radius number
---@param theta number radians (in isometric coordinate system)
---@param r number red
---@param g number green
---@param b number blue
---@param a number alpha
---@param texture Texture
---@param spriteTheta number radians
---@param scale number
function ScopeRenderer:renderSprite(radius, theta, r, g, b, a, texture, spriteTheta, scale)
    local playerX = self.m_player_screen_x
    local playerY = self.m_player_screen_y
    local zoom = self.m_zoom

    local rx, ry = rotate_vector(theta, radius / zoom, 0)
    local cx, cy = project_iso(rx, ry, self.m_indicator_height / zoom, 0)

    drawTexture(texture, scale, cx + playerX, cy + playerY, spriteTheta + math.pi, r, g, b, a)
end

return { ScopeRenderer = ScopeRenderer, Gradients = Gradients }
