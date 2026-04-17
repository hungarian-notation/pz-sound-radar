if love == nil then return end

local inject_scope = _G --[[@as table]]

local mesh_instance

---@alias love.Vertex [number,number,number,number,number,number,number,number]

---@param vertices love.Vertex[]
local function render_vertices(tex, vertices)
    if not mesh_instance then
        mesh_instance = love.graphics.newMesh(vertices, "fan", "dynamic")
        ---@cast mesh_instance -?
    else
        mesh_instance:setVertices(vertices, 1, 4)
    end

    mesh_instance:setTexture(tex)
    mesh_instance:flush()
    love.graphics.draw(mesh_instance)
end


local MockSpriteRenderer = {}

--- @diagnostic disable-next-line: unused
---@param tex any | nil
---@param _ unknown
function MockSpriteRenderer:render(
    tex,
    x1, y1,
    x2, y2,
    x3, y3,
    x4, y4,
    r1, g1, b1, a1,
    r2, g2, b2, a2,
    r3, g3, b3, a3,
    r4, g4, b4, a4, _
)
    ---@type love.Vertex[]
    local vertices

    vertices = {
        { x1, y1, 0.0, 0.0, r1, g1, b1, a1 },
        { x2, y2, 1.0, 0.0, r2, g2, b2, a2 },
        { x3, y3, 1.0, 1.0, r3, g3, b3, a3 },
        { x4, y4, 0.0, 1.0, r4, g4, b4, a4 },
    }

    render_vertices(tex, vertices)
end

--- @diagnostic disable-next-line: unused
function MockSpriteRenderer:renderPoly(
    tex,
    x1, y1,
    x2, y2,
    x3, y3,
    x4, y4,
    r, g, b, a,
    u1, v1,
    u2, v2,
    u3, v3,
    u4, v4
)
    ---@type love.Vertex[]
    local vertices

    vertices = {
        { x1, y1, u1 or 1, v1 or 0, r, g, b, a },
        { x2, y2, u2 or 0, v2 or 0, r, g, b, a },
        { x3, y3, u3 or 0, v3 or 1, r, g, b, a },
        { x4, y4, u4 or 1, v4 or 1, r, g, b, a },
    }

    render_vertices(tex, vertices)
end

---@diagnostic disable-next-line: unused
---@param tex Texture
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param r number
---@param g number
---@param b number
---@param a number
---@param thickness number
---@param thickness2? number
function MockSpriteRenderer:renderlinef(tex, x1, y1, x2, y2, r, g, b, a, thickness, thickness2)
    love.graphics.setColor(r, g, b, a)
    love.graphics.setLineWidth(thickness or 1)
    love.graphics.line(x1, y1, x2, y2)
    love.graphics.setColor(1, 1, 1, 1)
end

inject_scope.getRenderer = inject_scope.getRenderer or function()
    return MockSpriteRenderer
end

inject_scope.getTexture = inject_scope.getTexture or function(path)
    local fullpath = string.format("%s", path)
    local info = love.filesystem.getInfo(fullpath)
    assert(info, "missing image: " .. fullpath)
    return love.graphics.newImage(fullpath)
end
