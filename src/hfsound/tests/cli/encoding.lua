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
    
--- emulates utf8.offset semantics for single-byte encodings
---@param _s bytes
---@param i integer
---@param j? integer
local function bytes_offset(_s, i, j)
    if j == nil then return i end
    return j + i - 1
end

---@return hf.Encoding
local function bytes_encoding()
    return {
        len = string.len,
        offset = bytes_offset
    }
end

--- @type {
---     default:    hf.Provider<hf.Encoding>,
--- } & { [string]: hf.Provider<hf.Encoding> | nil }
local encodings = {
    default = bytes_encoding,
    bytes   = bytes_encoding
}

--- attempt to use the environment's utf8 support
pcall(function()
    --- @diagnostic disable-next-line: access-invisible
    local utf8 = _G['utf8']

    if utf8 == nil then
        pcall(function()
            utf8 = require('utf8')
        end)
    end

    --- @diagnostic disable-next-line: unnecessary-if
    if utf8 and utf8.len and utf8.offset then
        local function utf8_sub(s, i, j)
            if not s then return "" end
            local len = utf8.len(s) or 0
            i = i or 1
            j = j or len
            if i < 0 then i = len + i + 1 end
            if j < 0 then j = len + j + 1 end
            if i < 1 then i = 1 end
            if j > len then j = len end
            if i > j then return "" end
            local startByte = utf8.offset(s, i) --[[@as integer]]
            local endByte = utf8.offset(s, j + 1) --[[@as integer]]
            return string.sub(s, startByte, endByte and endByte - 1 or -1)
        end

        encodings.UTF8 = function()
            return {
                len = utf8.len,
                sub = utf8_sub,
                offset = utf8.offset
            }
        end

        encodings.DEFAULT = encodings.UTF8
    end
end)

---@param str string
---@param encoding hf.Encoding
local function chars(str, encoding)
    local i = 1
    local offset = 1

    ---@type fun(): int?, char?, int?
    local iterator = function()
        if str == nil then return end

        local this_i = i
        local this_offset = offset

        if offset > #str then return end

        local next_offset = encoding.offset(str, 2, offset)
        local char = str:sub(offset, next_offset - 1)
        i = i + 1
        offset = next_offset
        return this_i, char, this_offset
    end

    return iterator
end

return {
    encodings = encodings,
    chars = chars,
    bytes = { offset = bytes_offset }
}
