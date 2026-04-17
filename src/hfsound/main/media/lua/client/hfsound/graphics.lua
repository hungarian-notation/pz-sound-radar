local xgeom = require('hfsound/geom')

local rotate_rectangle = xgeom.rotate_rectangle
local project_isometric = xgeom.project_iso

---@param texture Texture
---@param textureScale number | [number, number]
---@param cx number
---@param cy number
---@param theta number
---@param r number
---@param g number
---@param b number
---@param a number
local function drawTexture(texture, textureScale, cx, cy, theta, r, g, b, a)
    local xscale, yscale

    if type(textureScale) == "table" then
        xscale = textureScale[1]
        yscale = textureScale[2]
    else
        xscale = textureScale
        yscale = textureScale
    end

    local --[[float]] dx = texture:getWidth() * xscale / 2;
    local --[[float]] dy = texture:getHeight() * yscale / 2;

    local x1, y1, x2, y2, x3, y3, x4, y4 = rotate_rectangle(theta, dx, dy)

    getRenderer():renderPoly(
        texture,
        x1 + cx,
        y1 + cy,
        x2 + cx,
        y2 + cy,
        x3 + cx,
        y3 + cy,
        x4 + cx,
        y4 + cy,
        r, g, b, a
    );
end

---@param texture Texture
---@param textureScale number | [number,number]
---@param cx number
---@param cy number
---@param theta number
---@param r number
---@param g number
---@param b number
---@param a number
local function drawTextureIsometric(texture, textureScale, cx, cy, theta, r, g, b, a)
    local xscale, yscale

    if type(textureScale) == "table" then
        xscale = textureScale[1]
        yscale = textureScale[2]
    else
        xscale = textureScale
        yscale = textureScale
    end

    local --[[float]] dx = texture:getWidth() * xscale / 2;
    local --[[float]] dy = texture:getHeight() * yscale / 2;

    local x1, y1, x2, y2, x3, y3, x4, y4 = rotate_rectangle(theta, dx, dy)

    x1, y1 = project_isometric(x1, y1, 0, 0)
    x2, y2 = project_isometric(x2, y2, 0, 0)
    x3, y3 = project_isometric(x3, y3, 0, 0)
    x4, y4 = project_isometric(x4, y4, 0, 0)

    getRenderer():renderPoly(
        texture,
        x1 + cx,
        y1 + cy,
        x2 + cx,
        y2 + cy,
        x3 + cx,
        y3 + cy,
        x4 + cx,
        y4 + cy,
        r, g, b, a
    );
end

return {
    drawTexture = drawTexture,
    drawTextureIsometric = drawTextureIsometric
}
