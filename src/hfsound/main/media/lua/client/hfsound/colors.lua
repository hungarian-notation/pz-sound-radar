--[[

    This source file is released under the MIT/Expat License:

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

-- HSX included here is under its own license. See its source file for details.

local hsx = require('hfsound/_colorutils/hsx')
local xmath = require('hfsound/math')
local lerp = xmath.lerp_clamped


---@param r number
---@param g number
---@param b number
---@return number luminosity
local function luminosity(r, g, b)
    return (0.3 * r) + (0.4 * g) + (0.3 * b)
end


---@param r number
---@param g number
---@param b number
---@param factor number
---@return number r
---@return number g
---@return number b
local function desaturate(r, g, b, factor)
    local l = luminosity(r, g, b)
    return
        lerp(r, l, factor),
        lerp(g, l, factor),
        lerp(b, l, factor)
end


---@overload fun(rgba: [number,number,number,number]): number, number, number, number
---@overload fun(rgba: string): number, number, number, number
---@overload fun(r: number, g: number, b: number, a: number): number, number, number, number
---@param arg1 string | number | ([number,number,number,number])
---@param arg2? number
---@param arg3? number
---@param arg4? number
---@return number red
---@return number green
---@return number blue
---@return number alpha
local function parse_rgba(arg1, arg2, arg3, arg4)
    if type(arg1) == "table" then
        arg1, arg2, arg3, arg4 = unpack(arg1)
    end

    if type(arg1) == "string" then
        assert(#arg1 >= 4)
        assert(arg1:sub(1, 1) == "#")

        ---@cast arg1 string
        if #arg1 == 4 then
            --i.e. #FFF for white
            local r, g, b =
                tonumber(arg1:sub(2, 2), 16),
                tonumber(arg1:sub(3, 3), 16),
                tonumber(arg1:sub(4, 4), 16)
            assert(r)
            assert(g)
            assert(b)
            return r / 0xf, g / 0xf, b / 0xf, 1.0
        elseif #arg1 == 5 then
            --i.e. #FFFF for opaque white, #FFF8 for half transparent white
            local r, g, b, a =
                tonumber(arg1:sub(2, 2), 16),
                tonumber(arg1:sub(3, 3), 16),
                tonumber(arg1:sub(4, 4), 16),
                tonumber(arg1:sub(5, 5), 16)
            assert(r)
            assert(g)
            assert(b)
            assert(a)
            return r / 0xf, g / 0xf, b / 0xf, a / 0xf
        elseif #arg1 == 7 then
            -- standard HTML/CSS hex color code
            local r, g, b =
                tonumber(arg1:sub(2, 3), 16),
                tonumber(arg1:sub(4, 5), 16),
                tonumber(arg1:sub(6, 7), 16)
            assert(r)
            assert(g)
            assert(b)
            return r / 0xff, g / 0xff, b / 0xff, 1.0
        elseif #arg1 == 9 then
            -- standard HTML/CSS hex color code with alpha byte
            local r, g, b, a =
                tonumber(arg1:sub(2, 3), 16),
                tonumber(arg1:sub(4, 5), 16),
                tonumber(arg1:sub(6, 7), 16),
                tonumber(arg1:sub(8, 9), 16)
            assert(r)
            assert(g)
            assert(b)
            assert(a)
            return r / 0xff, g / 0xff, b / 0xff, a / 0xff
        else
            error("illegal color code: " .. arg1)
            return 0.0, 0.0, 0.0, 1.0
        end
    else
        assert(type(arg1) == "number", "illegal argument #1")
        assert(type(arg2) == "number", "illegal argument #2")
        assert(type(arg3) == "number", "illegal argument #3")
        assert(arg4 == nil or type(arg4) == "number", "illegal argument #4")
        return arg1, arg2, arg3, arg4 or 1.0
    end
end


return {
    parse      = parse_rgba,
    parse_rgba = parse_rgba,
    luminosity = luminosity,
    desaturate = desaturate,
    rgb2hsv    = hsx.rgb2hsv,
    hsv2rgb    = hsx.hsv2rgb,
    rgb2hsl    = hsx.rgb2hsl,
    hsl2rgb    = hsx.hsl2rgb,
    rgb2hsi    = hsx.rgb2hsi,
    hsi2rgb    = hsx.hsi2rgb,
}
