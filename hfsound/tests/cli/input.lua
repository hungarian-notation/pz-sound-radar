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
    
local edit = require('cli/edit')

-- #region InputManager

---@class InputManager
local InputManager = {}; InputManager.__index = InputManager

function InputManager.new(callback, defaults)
    local obj = setmetatable({}, InputManager)

    obj.line = edit.EntryLine.new(nil, nil, defaults)

    obj.callback = callback
    obj.font = love.graphics.getFont()

    return obj
end

function InputManager:oninput(t)
    self.line:insert(t)
end

function InputManager:on_up()
    self.line:history_offset(1)
end

function InputManager:on_down()
    self.line:history_offset(-1)
end

function InputManager:on_left()
    self.line:cursor_offset(-1)
end

function InputManager:on_right()
    self.line:cursor_offset(1)
end

function InputManager:on_home()
    self.line:cursor_set(1)
end

function InputManager:on_end()
    self.line:cursor_set(-1)
end

function InputManager:on_tab()
    self:oninput("\t")
end

function InputManager:on_backspace()
    self.line:cursor_backspace()
end

function InputManager:on_delete()
    self.line:cursor_delete()
end

function InputManager:contents()
    return self.line:content()
end

function InputManager.on_escape()
    os.exit(0)
end

function InputManager:on_return(kv)
    if kv.ctrl then
        self:oninput("\n")
    else
        local value = self:contents()
        self.line:clear(true)
        self.callback(value)
    end
end

function InputManager:on_ctrl_v()
    self.line:insert(love.system.getClipboardText())
end

function InputManager:on_ctrl_c()
    love.system.setClipboardText(self.line:content())
end

function InputManager:on_ctrl_x()
    love.system.setClipboardText(self.line:content())
    self.line:clear()
end

local function get_modifiers()
    ---@type ("ctrl"|"alt"|"shift")[]
    local modifiers = {}

    ---@type boolean
    local c = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")

    ---@type boolean
    local a = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")

    ---@type boolean
    local s = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")

    if c then
        modifiers[#modifiers + 1] = "ctrl"
    end

    if a then
        modifiers[#modifiers + 1] = "alt"
    end

    if s then
        modifiers[#modifiers + 1] = "shift"
    end

    return { ctrl = c, alt = a, shift = s, all = modifiers }
end


---@param special string
function InputManager:special(special)
    local mods      = get_modifiers()
    local modprefix = table.concat(mods.all, "_") .. "_"
    local general   = "on_" .. special
    local specific  = "on_" .. modprefix .. special
    local handler   = self[general] or self[specific] or nil
    ---@cast handler +unknown

    if handler then
        --pcall(handler, self)
        handler(self, mods)
    end
end

function InputManager:draw()
    ---@type any
    local font = self.font
    love.graphics.setFont(font)

    local width = love.graphics.getDimensions()

    local left = 32
    local right = width - 32
    local span = right - left
    local y = font:getHeight() * 2
    local x = 0.0
    local i = 1

    while i <= #self.line.buffer + 1 do
        local last = self.line.buffer[i - 1]
        local this = self.line.buffer[i]

        if this == '\n' then
            y = y + font:getLineHeight() * font:getHeight()
            x = 0
            i = i + 1
        else
            local kerning = 0.0

            if last ~= nil and this ~= nil then
                kerning = font:getKerning(last, this)
            end

            local thisx = math.ceil(x + kerning)
            local nextx = x + kerning + ((this == nil) and 0 or font:getWidth(this))

            if this == "\t" then
                local tabwidth = 8 * font:getWidth(" ")
                local laststop = math.floor(nextx / tabwidth) * tabwidth
                local nextstop = laststop + tabwidth
                nextx = nextstop
            end

            if nextx > span then
                if x == 0 then error("infinite loop") end
                y = y + font:getLineHeight() * font:getHeight()
                x = 0
            else
                x = nextx

                if this ~= nil then
                    love.graphics.print(this, left + thisx, y)
                end

                if self.line.cursor == i and ((love.timer.getTime() * 2) % 1) < 0.5 then
                    love.graphics.print("_", left + thisx, y)
                end
                i = i + 1
            end
        end
    end
end

-- #endregion InputManager

return { InputManager = InputManager }
