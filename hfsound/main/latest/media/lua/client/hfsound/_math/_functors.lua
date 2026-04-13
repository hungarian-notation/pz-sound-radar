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

local xmath_functors = {}

---@param a number
---@param b number
---@return fun(value: number): number
function xmath_functors.Clamp(a, b)
    if b < a then
        a, b = b, a
    end

    return function(value)
        if value < a then
            return a
        elseif value > b then
            return b
        else
            return value
        end
    end
end

---@param a number
---@param b number
---@return fun(value: number): number
function xmath_functors.Lerp(a, b)
    return function(value)
        return value * (b - a) + a
    end
end

---@param a number
---@param b number
---@return fun(value: number): number
function xmath_functors.ClampedLerp(a, b)
    local min, max

    if a < b then
        min, max = a, b
    else
        min, max = b, a
    end

    return function(value)
        local intermediate = value * (b - a) + a

        if intermediate < min then
            return min
        elseif intermediate > max then
            return max
        else
            return intermediate
        end
    end
end

---@param a number
---@param b number
---@return fun(value: number): number
function xmath_functors.InverseLerp(a, b)
    local factor = 1 / (b - a)

    return function(value)
        return (value - a) * factor
    end
end

---@param a number
---@param b number
---@return fun(value: number): number
function xmath_functors.ClampedInverseLerp(a, b)
    local factor = 1 / (b - a)

    return function(value)
        local intermediate = (value - a) * factor

        if intermediate < 0 then
            return 0
        elseif intermediate > 1 then
            return 1
        else
            return intermediate
        end
    end
end

return xmath_functors
