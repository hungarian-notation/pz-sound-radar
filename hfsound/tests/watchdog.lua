package.path = package.path .. ";../.dist/Contents/mods/hfsound/42.16/media/lua/client/?.lua"
package.path = package.path .. ";../.dist/Contents/mods/hfsound/42.16/media/lua/shared/?.lua"

libtable = require "hfsound/reflect/tables"
---@diagnostic disable-next-line: unresolved-require
libtimer = require "love.timer"

-- print("started watchdog")

function now()
    return libtimer.getTime()
end

_livetime = 0

function keepalive()
    local _elapsed = now() - _livetime
    if _elapsed > 8e-3 then
        -- print(_elapsed)
    end
    _livetime = now()
end

keepalive()

function timeout()
    return (now() - _livetime) > 1
end

local last_message = nil

while true do
    local msg = love.thread.getChannel('watchdog'):pop()

    if msg ~= nil then
        if msg.heartbeat ~= nil then
            keepalive()
        end

        last_message = msg
    end

    if timeout() then
        print("!!! timeout !!!")
        print("dumping last message...")
        libtable.dump(last_message, 2)
        print()

        os.exit()
        return
    end
end
