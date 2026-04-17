local mocks = require('polyfill/mocks')

if love == nil then return end

local inject_scope = _G --[[@as table]]

inject_scope.CharacterTrait = setmetatable({}, { __index = function(_t, k) return k end })

local PLAYERS = {
    mocks.IsoMovable.new {
        classes = { "IsoPlayer", "IsoMovable" },
        x = 0,
        y = 0,
        z = 0,
    }
}

function inject_scope.getSpecificPlayer(_i)
    return PLAYERS[_i + 1]
end

function inject_scope.getPlayer()
    return PLAYERS[1]
end
