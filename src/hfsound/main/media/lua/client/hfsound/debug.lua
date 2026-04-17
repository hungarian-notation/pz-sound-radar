if not getDebug() then return end

hftable = require('hfsound/reflect/tables')

if dump == nil or dump == hfdump then
    dump = hftable.dump
end


hfdump = hftable.dump


---@class (partial) _HFSOUND
---@field debug _HFSOUND_DEBUG
---@field reload fun()
HFSOUND          = HFSOUND or {}

---x, y, z, radius
---@alias CircleRequest [number, number, number, number, number, number, number, number, number]

---@class _HFSOUND_DEBUG
HFSOUND.debug    = HFSOUND.debug or {
    ---@type {
    ---arr?:     CircleRequest[],
    ---next?:   number
    ---}
    circles = {},

    ---@type number?
    radius = nil,
    ---@type string|boolean
    reporting = false,

    ---@type hfs.Instrumentation[]
    _instrumentations = {}
}

local debug      = HFSOUND.debug

---@class hfs.InstrumentationArgs
---@field owner table
---@field name string
---@field pre?  fun( self:hfs.Instrumentation, ...): bool, table?
---@field post? fun( self:hfs.Instrumentation, ...)
---@field [string] any

---@class hfs.Instrumentation : hfs.InstrumentationArgs
---@field cancel boolean
---@field target function
---@field pre  fun( self:hfs.Instrumentation, ...): bool, table?
---@field post fun( self:hfs.Instrumentation, ...)
---@field clear fun( self:hfs.Instrumentation)
---@field [string] any

---@param instrumentation hfs.InstrumentationArgs
debug.instrument = function(instrumentation)
    instrumentation.cancel = false

    if instrumentation.owner == nil then
        print(string.format("owner for field %s was nil", instrumentation.owner, instrumentation.name))
        return
    end

    ---@cast instrumentation hfs.Instrumentation
    instrumentation.target = rawget(instrumentation.owner, instrumentation.name)

    if instrumentation.target == nil then
        print(string.format("no such field %s on %s", instrumentation.name, tostring(instrumentation.owner)))

        for k, v in instrumentation.target do
            if rawget(instrumentation.target, k) == v and type(v) == "function" then
                print(string.format("  has: %s", k))
            end
        end

        return
    elseif not type(instrumentation.target) == "function" then
        print(string.format("field %s on %s was a %s", instrumentation.name, tostring(instrumentation.owner),
            type(instrumentation.target)))
        return
    end

    instrumentation.target = instrumentation.target
    instrumentation.pre = instrumentation.pre or function() return true end
    instrumentation.post = instrumentation.post or function(...) return ... end

    assert(type(instrumentation.target) == "function")

    local closure = function(...)
        if instrumentation == nil then
            print("warning: instrumentation was nil")
            return nil
        end

        if instrumentation.target == nil then
            print("warning: instrumentation.target was nil")
            return nil
        end

        if instrumentation.cancel then
            return instrumentation.target(...)
        end

        local continue, result = instrumentation:pre(...)
        if not continue then
            return unpack(result)
        else
            return instrumentation:post(instrumentation.target(...))
        end
    end

    instrumentation.owner[instrumentation.name] = closure
    print(string.format("instrumented %s on %s", instrumentation.name, tostring(instrumentation.owner)))

    instrumentation.clear = function()
        if instrumentation.cancel ~= true then
            if instrumentation.target ~= nil and instrumentation.owner[instrumentation.name] ~= instrumentation.target then
                instrumentation.owner[instrumentation.name] = instrumentation.target
            end

            instrumentation.cancel = true
        end
    end

    table.insert(debug._instrumentations, instrumentation)
    return instrumentation
end

function debug.clear_instrumentations()
    for _, v in ipairs(debug._instrumentations) do pcall(v.clear, v) end
end

debug.clear_instrumentation = debug.clear_instrumentations

function debug.ilog(table, name)
    if type(table) == "string" then
        error("not implemented")
    end

    assert(type(table) == "table", "expected table for arg #1")
    assert(type(name) == "string", "expected string for arg #2")
    return debug.instrument {
        owner = table,
        name = name,
        pre = function(self, ...)
            local args = { ... }
            print(string.format("invoked %s on %s", self.name, tostring(self.target)))
            for i, arg in ipairs(args) do print("  ", i, ": ", tostring(arg)) end
            return true
        end
    }
end

function debug.instrument_worldsounds()
    if HFSOUND.runtime == nil then return nil end

    if HFSOUND.debug._iws ~= nil then
        HFSOUND.debug._iws:clear()
    end

    HFSOUND.debug._iws = debug.instrument {
        owner = HFSOUND.runtime,
        name = "OnWorldSound",
        pre = function(self, runtime, x, y, z, radius, ...)
            if type(x) ~= "number" then
                print(x, " ", type(x))
                print(y, " ", type(y))
                print(z, " ", type(z))
                print(radius, " ", type(radius))
                return true
            end
            HFSOUND.debug.requestCircle(x, y, z, radius, 1, 1, 1, 0.25)
            return true
        end
    }

    return HFSOUND.debug._iws
end

--[[
---@param uid? string
---@param classifier hfs.ZombieSound
---@param zombie IsoZombie
function Scope:offerzombiesound(uid, classifier, zombie)
    return self:offer(Entry.setzombiesound, uid, classifier, zombie)
end

]]

local zscolor_dispatch = {

    silent  = { 0.0, 1.0, 1.0, 0.125 },
    idle    = { 0.5, 1.0, 0.0, 0.125 },
    stumble = { 1.0, 0.5, 0.0, 0.125 },
    walk    = { 1.0, 1.0, 0.0, 0.125 },
    clamber = { 1.0, 0.5, 0.2, 0.125 },
    attack  = { 1.0, 0.0, 0.0, 0.125 },
}

function debug.instrument_zombiesounds()
    if HFSOUND.runtime == nil then return nil end

    if HFSOUND.debug._izs ~= nil then
        HFSOUND.debug._izs:clear()
    end

    HFSOUND.debug._izs = debug.instrument {
        owner = HFSOUND.runtime.scope,
        name = "offerzombiesound",
        ---@param uid? string
        ---@param classifier hfs.ZombieSound
        ---@param zombie IsoZombie
        pre = function(self, scope, uid, classifier, zombie)
            local x = zombie:getX()
            local y = zombie:getY()
            local z = zombie:getZ()
            local radius = classifier.radius

            if type(x) ~= "number" then
                print(x, " ", type(x))
                print(y, " ", type(y))
                print(z, " ", type(z))
                print(radius, " ", type(radius))
                return true
            end

            HFSOUND.debug.requestCircle(x, y, z, radius, unpack(zscolor_dispatch[classifier.category]))

            return true
        end
    }

    return HFSOUND.debug._izs
end

function debug.instrument_sounds()
    debug.instrument_worldsounds()
    debug.instrument_zombiesounds()
end

debug.iws = debug.instrument_worldsounds
debug.izs = debug.instrument_zombiesounds
debug.ias = debug.instrument_sounds

local added = false

---@param x number
---@param y number
---@param z number
---@param radius number
---@param r number
---@param g number
---@param b number
---@param a number
function debug.requestCircle(x, y, z, radius, r, g, b, a)
    local circles = debug.circles

    circles.next = circles.next or 1
    circles.arr = circles.arr or {}

    if circles.next > 32 then circles.next = 1 end

    if not added then
        print("ADDED EVENT HOOK")
        Events.OnPreUIDraw.Add(HFSOUND.debug.render)
        added = true
    end

    assert(type(x) == "number")
    assert(type(y) == "number")
    assert(type(z) == "number" or type(z) == "nil")
    assert(type(radius) == "number" or type(radius) == "nil")
    z = z or 0
    radius = radius or 8
    assert(type(z) == "number")
    assert(type(radius) == "number")

    local old = circles.arr[circles.next]

    if old == nil then
        print("adding new circle: " .. circles.next)
        circles.arr[circles.next] = { x, y, z, radius, 0, r or 1, g or 1, b or 1, a or 1 }
    else
        old[1] = x
        old[2] = y
        old[3] = z
        old[4] = radius
        old[5] = 0
        old[6] = r or 1
        old[7] = g or 1
        old[8] = b or 1
        old[9] = a or 1
    end

    circles.next = circles.next + 1
end

function debug.renderIsoCircle(x, y, z, radius, r, g, b, a, thickness, player)
    assert(type(x) == "number")
    assert(type(y) == "number")

    z = z or 0
    radius = radius or 8
    r = r or 1
    g = g or 1
    b = b or 1
    a = a or 1
    thickness = thickness or 1
    player = player or 0

    -- dump({ x, y, z, "radius:" .. radius, r, g, b, a, thickness, player })

    assert(type(z) == "number")
    assert(type(radius) == "number")
    assert(type(r) == "number")
    assert(type(g) == "number")
    assert(type(b) == "number")
    assert(type(a) == "number")
    assert(type(thickness) == "number")

    local renderer = getRenderer()
    local step = math.pi / 9;
    local x0, y0, x1, y1, sx0, sy0, sx1, sy1
    local theta = 0.0

    while theta <= math.pi * 2 do
        x0 = x + radius * math.cos(theta)
        y0 = y + radius * math.sin(theta)
        x1 = x + radius * math.cos(theta + (math.pi / 9))
        y1 = y + radius * math.sin(theta + (math.pi / 9))
        sx0 = isoToScreenX(player or 0, x0, y0, z)
        sy0 = isoToScreenY(player or 0, x0, y0, z)
        sx1 = isoToScreenX(player or 0, x1, y1, z)
        sy1 = isoToScreenY(player or 0, x1, y1, z)

        renderer:renderlinef(nil --[[@as Texture]], sx0, sy0, sx1, sy1, r, g, b, a, thickness)
        theta = theta + step
    end
end

if HFSOUND.debug.render ~= nil then
    Events.OnPostUIDraw.Remove(HFSOUND.debug.render)
    Events.OnPreUIDraw.Remove(HFSOUND.debug.render)
end

function debug.render()
    if debug.radius then
        local p = getSpecificPlayer(0)
        local x, y, z = p:getX(), p:getY(), p:getZ()
        debug.renderIsoCircle(x, y, z, debug.radius, 1, 1, 0, 1, 1)
    end

    local circles = debug.circles
    circles.arr = circles.arr or {}
    local arr = circles.arr

    for i = 1, 256 do
        local circle = arr[i]
        if circle ~= nil and circle[5] < 512 then
            local x, y, z, radius, age, r, g, b, a = unpack(circle)
            age = age or 0
            a = a - age * 0.002
            if a > 0 then
                circle[5] = age + 1
                assert(type(x) == "number")
                assert(type(y) == "number")
                assert(type(z) == "number")
                assert(type(r) == "number")
                assert(type(g) == "number")
                assert(type(b) == "number")
                assert(type(radius) == "number")
                debug.renderIsoCircle(x, y, z, radius, r, g, b, a, 1)
            end
        end
    end
end

---@param mod "hfsound" | string
---@param path string
function debug.readfile(mod, path)
    ---@type BufferedReader?
    local reader
    ---@type string?
    local contents

    local function try()
        reader = getModFileReader("hfsound", path, false)
        ---@cast reader -?
        contents = reader:readAllAsString()
    end

    local function finally()
        if reader ~= nil then
            reader:close()
        end
    end

    local status, err = pcall(try)
    pcall(finally)

    if status == false or contents == nil then
        error("error reading from path: " .. tostring(path) .. ": " .. tostring(err))
    else
        return contents
    end
end

---@param mod "hfsound" | string
---@param path string
---@param contents string|string[]
---@param create? boolean
---@param append? boolean
function debug.writefile(mod, path, contents, create, append)
    if create == nil then create = false end
    if append == nil then append = false end

    ---@type LuaManager.GlobalObject.LuaFileWriter?
    local writer

    local function try()
        writer = getModFileWriter("hfsound", path, create, append)
        ---@cast writer -?
        if type(contents) == "string" then
            writer:write(contents)
        else
            for _, line in ipairs(contents) do
                writer:writeln(line)
            end
        end
    end

    local function finally()
        if writer ~= nil then
            writer:close()
        end
    end

    local status, err = pcall(try)
    pcall(finally)

    if status == false then
        error("error writing to path: " .. tostring(path) .. ": " .. tostring(err))
    else
        return true
    end
end

---@param path string
function debug.reload(path)
    if path:sub(1, 7) == "hfsound" then
        path = string.format("media/lua/client/%s.lua", path)
    end

    reloadLuaFile(path)
end

function debug.retune()
    -- TODO?
end

function debug.trigger_gun()
    getAmbientStreamManager():doGunEvent()
end

function debug.trigger_alarm()
    local p        = getSpecificPlayer(0)
    local room     = p:getSquare():getRoomDef()
    local building = room:getBuilding()
    building:setAlarmed(true)
    print("alarmed? ", building:isAlarmed())
    getAmbientStreamManager():doAlarm(room)
end

if _G.hfsd == nil then hfsd = HFSOUND.debug end
if _G.hf == nil then hf = HFSOUND.debug end
