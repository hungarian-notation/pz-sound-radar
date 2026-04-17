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

local module = {}

module.bezier = require('hfsound/_math/_bezier')
module.functors = require('hfsound/_math/_functors')
module.hyperbola = require("hfsound/_math/_hyperbola")

local math_min = math.min
local math_max = math.max

---@param value number
---@param min number
---@param max number
---@return number
local function clamp(min, max, value)
    if min < max then
        return math_min(math_max(value, min), max)
    else
        return math_min(math_max(value, max), min)
    end
end


---@param value number
---@param min number
---@param max number
---@return number
local function lerp(min, max, value)
    return value * (max - min) + min
end


---@param c00 number
---@param c10 number
---@param c01 number
---@param c11 number
---@param x number
---@param y number
---@return number
local function lerp_bilinear(c00, c10, c01, c11, x, y)
    local r1 = lerp(c00, c10, x)
    local r2 = lerp(c01, c11, x)
    return lerp(r1, r2, y)
end

---@param value number
---@param min number
---@param max number
---@return number
local function lerp_clamped(min, max, value)
    if value >= 1 then
        return max
    elseif value <= 0 then
        return min
    else
        return value * (max - min) + min
    end
end

---@param value number The point within the range you want to calculate.
---@param a number The start of the range.
---@param b number The end of the range.
---@return number
local function ilerp(a, b, value)
    return (value - a) / (b - a)
end

---@param value number The point within the range you want to calculate.
---@param a number The start of the range.
---@param b number The end of the range.
---@return number
local function ilerp_clamped(a, b, value)
    if a < b then
        if value >= b then
            return 1
        elseif value <= a then
            return 0
        else
            return (value - a) / (b - a)
        end
    else
        if value >= a then
            return 0
        elseif value <= b then
            return 1
        else
            return (value - a) / (b - a)
        end
    end
end

local function smoothstep(a, b, x)
    if a < b then
        if x < a then return 0 elseif x > b then return 1 end
    else
        if x < b then return 1 elseif x > a then return 0 end
    end

    x = ((x - a) / (b - a))

    return x * x * x * (x * (6.0 * x - 15.0) + 10.0)
end

module.clamp = clamp
module.lerp = lerp
module.lerp_clamped = lerp_clamped
module.ilerp = ilerp
module.ilerp_clamped = ilerp_clamped
module.smootherstep = smoothstep
module.bilinear = { lerp = lerp_bilinear }

---@readonly
local lib = module
return lib
