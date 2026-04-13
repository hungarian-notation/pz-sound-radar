--[[

    This source file is released under the MIT/Expat License. Only files 
    in which this header appears are covered by this license.

    Copyright © 2026 Christopher Bode

    Permission is hereby granted, free of charge, to any person obtaining a 
    copy of this software and associated documentation files (the “Software”), 
    to deal in the Software without restriction, including without limitation 
    the rights to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the Software, and to permit persons to whom the 
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included 
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS 
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--]]

local geom = {}

---@param theta number
---@param x number
---@param y number
---@return number
---@return number
function geom.rotate_vector(theta, x, y)
    local xCos = math.cos(theta) * x;
    local xSin = math.sin(theta) * x;
    local yCos = math.cos(theta) * y;
    local ySin = math.sin(theta) * y;
    local x1 = xCos - ySin;
    local y1 = yCos + xSin;
    return x1, y1
end

---compute the vertex coordinates of a rotated rectangle
---@param theta number radians
---@param dX number halfwidth of rectangle
---@param dY number halfwidth of rectangle
---@param offsetX number | nil
---@param offsetY number | nil
---@return number x1
---@return number y1
---@return number x2
---@return number y2
---@return number x3
---@return number y3
---@return number x4
---@return number y3
function geom.rotate_rectangle(theta, dX, dY, offsetX, offsetY)
    if not offsetX then offsetX = 0 end
    if not offsetY then offsetY = 0 end

    local xCos = math.cos(theta) * dX;
    local xSin = math.sin(theta) * dX;
    local yCos = math.cos(theta) * dY;
    local ySin = math.sin(theta) * dY;

    local x1 = xCos - ySin;
    local y1 = yCos + xSin;
    local x2 = -xCos - ySin;
    local y2 = yCos - xSin;
    local x3 = -xCos + ySin;
    local y3 = -yCos - xSin;
    local x4 = xCos + ySin;
    local y4 = -yCos + xSin;

    return x1, y1, x2, y2, x3, y3, x4, y4
end

---@param isoX number
---@param isoY number
---@param isoZ number
---@param cameraZ number
---@return number x
---@return number y
function geom.project_iso(isoX, isoY, isoZ, cameraZ)
    return isoX * 64 - isoY * 64,
        isoY * 32 + isoX * 32 + (cameraZ - isoZ) * 192
end

---@param isoX number
---@param isoY number
---@param isoZ number
---@param cameraZ number
---@param offsetX? number
---@param offsetY? number
---@return number x
---@return number y
function geom.project_isooffset(isoX, isoY, isoZ, cameraZ, offsetX, offsetY)
    return isoX * 64 - isoY * 64 + (offsetX or 0),
        isoY * 32 + isoX * 32 + (cameraZ - isoZ) * 192 + (offsetY or 0)
end

return geom
