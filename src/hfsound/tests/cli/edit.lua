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
    
---@class hf.module.edit
local module = {}

local enc = require('cli/encoding')

-- #region hf.EntryLine

--- Implements an editable text buffer with a cursor and history for use as a
--- command line.
---
---
---
---@class (exact) hf.EntryLine
---@field buffer char[]
---@field history string[]
---@field cursor integer
---@field history_selected integer
local EntryLine = {}; EntryLine.__index = EntryLine

local function translate_index(i, len)
    if i < 0 then
        return len + (i + 1)
    else
        return i
    end
end

---@param encoding? hf.Encoding
---@param content? string
---@param history? string[]
function EntryLine.new(encoding, content, history)
    local obj = setmetatable({}, EntryLine)

    obj.encoding = encoding or enc.encodings.default()
    obj.buffer = {}
    obj.cursor = 1
    obj.history = history or {}
    obj.history_selected = 0

    if content ~= nil then
        obj:replace(content, false)
    end

    return obj
end

function EntryLine:history_append(history)
    table.insert(self.history, 1, history)

    local search = 2
    while search <= #self.history do
        while self.history[search] == history do
            table.remove(self.history, search)
        end

        search = search + 1
    end
end

function EntryLine:clear(make_history)
    if #self.buffer > 0 and make_history == true then
        self:history_append(self:content())
    end

    self.cursor = 1
    self.history_selected = 0
    self.buffer = {}
end

function EntryLine:content()
    return table.concat(self.buffer, "")
end

---@param what char|char[]
---@param pos? integer
function EntryLine:insert(what, pos)
    pos = pos or self.cursor --[[@as int]]

    local encoding = self.encoding

    ---@type (fun(): int, char)?
    local iterator = nil

    if type(what) == "string" then
        local length = encoding.len(what)
        if length == 0 then return end -- nothing to insert
        if length > 1 then iterator = enc.chars(what, encoding) end
    elseif type(what) == "table" then
        iterator = ipairs(what)
    end

    if iterator then
        for i, char in iterator do
            self:insert(char, pos + i - 1)
        end
    else
        table.insert(self.buffer, pos, what)

        if self.cursor >= pos then
            self:cursor_offset(1)
        end
    end
end

---@param what char|char[]
function EntryLine:append(what)
    self:insert(what, #self.buffer + 1)
end

---@param a integer
---@param b integer
function EntryLine:remove_range(a, b)
    local len = #self.buffer

    ---@type int
    a = translate_index(a, len)
    ---@type int
    b = translate_index(b, len)

    if (b < a or b < 1 or a > len) then return end -- nothing to remove

    ---@type int
    local amount = b - a + 1
    local next_buffer = {}

    for i = 1, #self.buffer do
        if i < a or i > b then
            table.insert(next_buffer, self.buffer[i])
        end
    end

    self.buffer = next_buffer

    if self.cursor >= a then
        if self.cursor <= b then
            self:cursor_set(a)
        else
            self:cursor_offset(-amount)
        end
    end
end

function EntryLine:remove(index)
    return self:remove_range(index, index)
end

function EntryLine:replace(content, make_history)
    self:clear(make_history)
    for _i, c in enc.chars(content, self.encoding) do
        self:insert(c)
    end
end

-- #region hf.EntryLine#cursor

function EntryLine:cursor_set(index)
    local limit = #self.buffer + 1
    index = translate_index(index, limit)
    if index < 1 then index = 1 end
    if index > limit then index = limit end
    self.cursor = index
end

---@param delta integer
function EntryLine:cursor_offset(delta)
    self:cursor_set(self.cursor + delta)
end

function EntryLine:cursor_delete()
    return self:remove(self.cursor)
end

function EntryLine:cursor_backspace()
    return self:remove(self.cursor - 1)
end

-- #endregion hf.EntryLine#cursor

-- #region hf.EntryLine#history

function EntryLine:history_select(index)
    local sanitized_index = index
    if index < 0 then sanitized_index = 0 end
    if index > #self.history then sanitized_index = #self.history end
    local history = self.history[sanitized_index]
    self:replace(history, false)
    self.history_selected = sanitized_index
end

function EntryLine:history_offset(delta)
    self:history_select(self.history_selected + delta)
end

-- #endregion hf.EntryLine#history

-- #endregion hf.EntryLine

module.encodings = enc.encodings
module.EntryLine = EntryLine

return module
