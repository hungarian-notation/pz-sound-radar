--- @diagnostic disable: invert-if

if love == nil then return end

package.path = package.path .. ";../.dist/Contents/mods/hfsound/42.16/media/lua/client/?.lua"
package.path = package.path .. ";../.dist/Contents/mods/hfsound/42.16/media/lua/shared/?.lua"

HFSOUND = HFSOUND or {}
require('hfsound/tuning')

local mocks = require('polyfill/mocks')
require('polyfill/util')
require('polyfill/renderer')
require('polyfill/player')


utf8                       = require('utf8')
local input                = require('cli/input')

local xtable               = require('hfsound/reflect/tables')
local xgeom                = require('hfsound/geom')
local hf_graphics          = require('hfsound/graphics')
local Scope                = require('hfsound/scope/scope')

local drawTextureIsometric = hf_graphics.drawTextureIsometric

---@type hfs.ScopeRenderer
RENDERER                   = RENDERER

---@type hfs.Scope
SCOPE                      = SCOPE

---@type InputManager
INPUT                      = INPUT

DEFAULT_HISTORY            = {
    "add_zombie()",
    "smoothstep_benchmark()",
    "arcs = {{theta=.785,l=10,rad=1.6}, {theta=.785,l=4*math.pi,r1=8,r2=4}}",
    "arcs = {{theta=.785,l=10,rad=1.6}, {theta=.785,l=4*math.pi,rad=4}}",
    "os.exit()"
}



require('hfsound/debug')

--------------------------------------------------------------------------------

-- #region pcall

local function logged_pcall(...)
    local results = { pcall(...) }

    if not results[1] then
        local err = results[2]

        if type(err) == "table" then
            print()

            if err.message then
                print("error: ", err.message)
            elseif err.type then
                print("error: ", err.type)
            else
                print("error: ", table)
            end

            print()
            xtable.dump(err)
        else
            print()
            print(string.format("error: %s", tostring(err)))
            print()
        end
    else
        return unpack(results, 2)
    end
end


-- #endregion pcall

-- -----------------------------------------------------------------------------

-- #region COMMAND
---@type table?
local WITH_ENV      = nil
local USER_ENV      = {}
local PROTECTED_ENV = {
    _G      = _G,
    _U      = _G._U or USER_ENV,
    locals  = USER_ENV,
    globals = _G,
    dump    = xtable.dump,
}

local function command_index(_t, k)
    if k == "_G" then
        return _G
    end

    if PROTECTED_ENV[k] then
        return PROTECTED_ENV[k]
    elseif WITH_ENV ~= nil and WITH_ENV[k] ~= nil then
        return WITH_ENV[k]
    elseif USER_ENV[k] then
        return USER_ENV[k]
    else
        return _G[k]
    end
end

local function command_newindex(_t, k, v)
    if PROTECTED_ENV[k] ~= nil then print(string.format("`%s` is readonly in this context", k)) end
    if WITH_ENV ~= nil then
        print(string.format("setting %s[\"%s\"] := %s", tostring(WITH_ENV), k, xtable.stringify(v)))
        rawset(WITH_ENV, k, v)
    else
        print(string.format("setting %s := %s", k, xtable.stringify(v)))
        rawset(USER_ENV, k, v)
    end
end

function PROTECTED_ENV.with(scope)
    WITH_ENV = scope
end

local function on_command(command)
    ---@diagnostic disable-next-line: assign-type-mismatch
    ---@type table
    local env = setmetatable({}, {
        __index    = command_index,
        __newindex = command_newindex
    })

    local closure, err = load(command, "command", "t", env)

    if closure ~= nil then
        logged_pcall(closure)
    else
        print(err)
    end
end

-- #endregion

--------------------------------------------------------------------------------

function love.load()
    love.window.setMode(1600, 900, { resizable = true })

    INPUT = input.InputManager.new(on_command, DEFAULT_HISTORY)
    SCOPE = Scope.new(0)
    RENDERER = SCOPE.renderer

    love.keyboard.setKeyRepeat(true)
end

local zombie_styles = require('hfsound/zombiesound/styles')
ZOMBIES = {}

function add_zombie(n)
    n = n or 10

    for _i = 1, n do
        ---@diagnostic disable-next-line: assign-type-mismatch
        ---@type IsoZombie
        local zombie = mocks.IsoMovable.new {
            classes = { "IsoZombie", "IsoMovable" },
            x = math.random(-20, 20),
            y = math.random(-20, 20),
            z = math.random(-20, 20)
        }

        ---@cast zombie any

        zombie.goal = { x = math.random(-20, 20), y = math.random(-20, 20) }

        table.insert(ZOMBIES, zombie)
    end
end

function love.update(dt)
    for _i, zombie in ipairs(ZOMBIES) do
        local dx = zombie.goal.x - zombie.x
        local dy = zombie.goal.y - zombie.y

        if (math.abs(dx) < 0.5 and math.abs(dy) < 0.5) then
            zombie.goal = { x = math.random(-10, 10), y = math.random(-10, 10) }
        else
            if dx > 0.5 then
                zombie.x = zombie.x + dt
            elseif dx < -0.5 then
                zombie.x = zombie.x - dt
            end

            if dy > 0.5 then
                zombie.y = zombie.y + dt
            elseif dy < -0.5 then
                zombie.y = zombie.y - dt
            end
        end

        SCOPE:offerzombiesound(zombie:getUID(), {
            duration = 10, frequency = 10, radius = 20, volume = 20, style = zombie_styles.FOOTSTEP_STYLE
        }, zombie)
    end

    RENDERER:update()
    SCOPE:update(dt)
end

function love.keypressed(key, _, _)
    INPUT:special(key)
    -- print("input: " .. key)
end

function love.textinput(t)
    INPUT:oninput(t)
    -- print("text: " .. t)
end

TAU = math.pi * 2

-- Draw a coloured rectangle.
function love.draw()
    local w, h = love.graphics.getDimensions()
    local cx, cy = w / 2, h / 2
    love.graphics.clear()

    drawTextureIsometric(RENDERER.icons[RENDERER.Icons.ARROW_UP], 1 / 64, w / 2, h / 2, 0, 1, 0, 0, 1)

    local arcs = USER_ENV["arcs"] or USER_ENV["ARCS"]

    if type(arcs) == "table" then
        for _k, arc in pairs(arcs) do
            local r1    = (arc.r1 or arc.radius or arc.rad or 1) --[[@as number]]
            local width = (arc.arcwidth or arc.width or arc.w or 0.5) --[[@as number]]
            local r2    = (arc.r2 or (r1 - width)) --[[@as number]]

            local steps = RENDERER:renderArc(
                (arc.gradient or "normal") --[[@as hfs.Gradient]],
                r1, r2,
                (arc.theta or arc.angle or 0) --[[@as number]],
                (arc.arclength or arc.length or arc.arc or arc.l or math.rad(90)) --[[@as number]],
                (arc.red or arc.r or 1) --[[@as number]],
                (arc.green or arc.g or 1) --[[@as number]],
                (arc.blue or arc.b or 1) --[[@as number]],
                (arc.alpha or arc.a or 1) --[[@as number]])

            --- @diagnostic disable-next-line: unnecessary-if
            if arc.print then
                arc.print(steps)
                arc.print = nil
            end
        end
    end

    local points = {
        { -0.5, -0.5 }, { 0.5, -0.5 }, { 0.5, 0.5 }, { -0.5, 0.5 }
    }

    for i = 1, #points do
        local a = points[i]
        local b = points[i % 4 + 1]
        local x1, y1 = unpack(a)
        local x2, y2 = unpack(b)
        x1, y1 = xgeom.project_iso(x1, y1, 0, 0)
        x2, y2 = xgeom.project_iso(x2, y2, 0, 0)
        love.graphics.line(x1 + cx, y1 + cy, x2 + cx, y2 + cy)
    end

    love.graphics.line(cx, cy, cx, cy - 192)

    SCOPE:render()

    INPUT:draw()
end
