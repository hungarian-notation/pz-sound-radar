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

---@class hfsound.bezier.module
local module = {}

---@param ... [number,number] coordinates: x1, y1, x2, y2, ..., x_n, y_n
function module.Bezier(...)
    ---@type [number,number][]
    local points = { ... }
    local degree = #points - 1
    local static_arr = table.newarray and table.newarray() or { { 0.0, 0.0 } }

    for i = 1, degree + 1 do static_arr[i] = { 0.0, 0.0 } end

    ---@param t number
    ---@return number
    ---@return number
    return function(t)
        ---@type [number,number][]
        local arr = static_arr

        for i = 1, degree + 1 do
            local arr_i    = arr[i]
            local points_i = points[i]
            ---@cast arr_i -?
            ---@cast points_i -?
            arr_i[1]       = points_i[1]
            arr_i[2]       = points_i[2]
        end

        assert(type(arr) == "table")
        assert(type(arr[1]) == "table")

        for iteration = degree, 1, -1 do
            for i = 1, iteration do
                local p_i0 = arr[i]
                local p_i1 = arr[i + 1]

                ---@cast p_i0 -?
                ---@cast p_i1 -?

                p_i0[1] = t * (p_i1[1] - p_i0[1]) + p_i0[1]
                p_i0[2] = t * (p_i1[2] - p_i0[2]) + p_i0[2]
            end
        end

        assert(type(arr) == "table")
        assert(type(arr[1]) == "table")

        return arr[1][1], arr[1][2]
    end
end

---@param ... number
function module.BezierInterpolation(...)
    ---@type number[]
    local points = { ... }
    local degree = #points - 1
    local static_arr = table.newarray and table.newarray() or { 0.0 }

    ---@param t number
    ---@return number
    return function(t)
        ---@type number[]
        local arr = static_arr

        for i = 1, degree + 1 do
            arr[i] = points[i]
        end

        for iteration = degree, 1, -1 do
            for i = 1, iteration do
                local p_i0 = arr[i]
                local p_i1 = arr[i + 1]

                ---@cast p_i0 -?
                ---@cast p_i1 -?

                arr[i] = t * (p_i1 - p_i0) + p_i0
            end
        end

        return arr[1] --[[@as number]]
    end
end

return module
