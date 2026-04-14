if not getDebug() then return end

hftable = require('hfsound/reflect/tables')
dump    = dump or hftable.dump

---@class (partial) _HFSOUND
HFSOUND = HFSOUND or {}

function HFSOUND.reload()
    local function reload_client(rpath)
        reloadLuaFile(string.format("media/lua/client/%s.lua", rpath))
    end

    local function reload_shared(rpath)
        reloadLuaFile(string.format("media/lua/shared/%s.lua", rpath))
    end

    reload_shared("generated/hfsound_gradients")
    reload_shared("generated/hfsound_icons")
    reload_client("hfsound/tuning")
    reload_client("hfsound/runtime")
end

function hfsound_dogunevent()
    getAmbientStreamManager():doGunEvent()
end

function smoothstep_benchmark(N)
    N                          = N or 1e3

    local pow                  = math.pow
    local sin                  = math.sin
    local TAU                  = 2 * math.pi
    local TAU_RECIP            = 1 / TAU
    local bezier               = require('hfsound/math')
    local timerfunc            = love and love.timer.getTime or os.time

    local smoothstep           = function(x) return 6 * pow(x, 5) - 15 * pow(x, 4) + 10 * pow(x, 3) end
    local smoothstep_optimized = function(x)
        local x3 = x * x * x
        local x4 = x3 * x
        local x5 = x4 * x
        return 6 * x5 - 15 * x4 + 10 * x3
    end
    local smoothstep_bezier    = bezier.BezierInterpolation(0, 0, 0, 1, 1, 1)
    local smoothsin            = function(x) return x - sin(TAU * x) * TAU_RECIP end



    ---@param name string
    ---@param fn fun(number):number
    ---@param n int
    ---@param results_array? number[]
    ---@param canonical_array? number[]
    local function measure(name, fn, n, results_array, canonical_array)
        results_array = results_array or (table.newarray and table.newarray() or {})

        for i = 0, n do
            results_array[i] = 0
        end

        local start = timerfunc()

        for i = 0, n do
            local t = i / n
            local result = fn(t)
            if i % 1000 == 0 then
                results_array[math.floor(i / 1000)] = result
            end
        end

        local stop = timerfunc()


        local maxerr = 1.0 / 0.0

        if canonical_array then
            maxerr = 0

            for i = 0, #canonical_array do
                --- @diagnostic disable-next-line: need-check-nil
                local err = math.abs(canonical_array[i] - results_array[i])
                if err > maxerr then maxerr = err end
            end
        end

        print(string.format("%32s: %f (err=%f)", name, stop - start, maxerr))
    end

    local results_canonical = {}

    print("--------")
    measure("smoothstep", smoothstep, N, results_canonical)
    measure("smoothstep_optimized", smoothstep_optimized, N, {}, results_canonical)
    measure("smoothstep_bezier", smoothstep_bezier, N, {}, results_canonical)
    measure("smoothsin", smoothsin, N, {}, results_canonical)
end
