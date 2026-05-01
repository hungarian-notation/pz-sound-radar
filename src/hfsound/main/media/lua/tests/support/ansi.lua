local COLORS     = os.getenv("LUA_COLORS") == "1"
local TERM       = os.getenv("TERM")
local MAX_CURSOR = 100

if TERM == "xterm-color" or TERM == "xterm-256color" then
    COLORS = true
end

local CONTROL_ESC  = string.char(27)
local ANSI_CSI     = { CONTROL_ESC, "[" }
local ANSI_PATTERN = string.char(27) .. "%[[^@-~]*[^@-~]"

---@return boolean
function is_stdout_tty()
    local function check_unix()
        local is_tty = io.popen("tty > /dev/null 2>&1 && echo yes || echo no"):read("*l")
        if is_tty == "yes" then
            return true
        end
        return false
    end

    local ok, err = check_unix()

    if ok then
        return true
    else
        print(err)
    end

    local f = io.open("/dev/tty", "r")
    if f then
        f:close()
        return true
    else
        return false
    end
end

COLORS = COLORS and is_stdout_tty()

---@param str string
function ansi_strip(str)
    local start, stop
    repeat
        start, stop = str:find(ANSI_PATTERN, 0, true)
        if start ~= nil and stop ~= nil then
            str = str:sub(0, start - 1) .. str:sub(stop + 1)
        end
    until start == nil
    return str
end

local function create_ansi(sequence, inner)
    return setmetatable({ ["$ansi"] = true, value = sequence, inner = inner },
        { __tostring = function(self) return self.value end })
end

function ansi(style)
    if not COLORS then return create_ansi("", "") end

    if style == nil then
        style = "0"
    end

    local text = string.char(27) .. '[' .. style .. 'm'

    return create_ansi(text, style)
end

function is_ansi(value)
    return type(value) == "table" and value["$ansi"] == true
end

---@param color number
---@param mode? "fg" | "bg"
function ansi_color(color, mode)
    local offset = 0

    if mode == "bg" then
        offset = 10
    end

    return ansi(tostring(color))
end

---@param color number
---@param mode? "fg" | "bg"
function xterm256(color, mode)
    local code = "38;5;"
    if mode == "bg" then
        code = "48;5;"
    end

    return ansi(code .. tostring(color))
end

function ansi_print(...)
    local args = { ... }

    io.stdout:write(tostring(ansi()))

    local text_elements = 0
    local need_space = false

    for i, v in ipairs(args) do
        if is_ansi(v) then
            io.stdout:write(tostring(v))
        else
            if need_space then
                io.stdout:write(" ")
            end
            local str = tostring(v)
            io.stdout:write(str)
            local end_char = str:sub(-1)
            need_space = end_char ~= "\n" and end_char ~= " " and end_char ~= "\t"
            text_elements = text_elements + 1
        end
    end

    io.stdout:write("\n")
end
