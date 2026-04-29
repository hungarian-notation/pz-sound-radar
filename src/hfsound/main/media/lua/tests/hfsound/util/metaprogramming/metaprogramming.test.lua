local m = require("hfsound/util/metaprogramming")


local function predicate(str, ...)
end

local function post(...)
    return "post", ...
end

local function init()
    local function target(...) return "target", ... end
    return { target = target }
end

function test_proxy()
    local target = init()

    assert_equals({ "target", 1 }, { target.target(1) })

    local instrument = m.Instrumentation.new {
        target = { target, "target" },
        handler = function()
            return function(...)
                return "proxy", ...
            end
        end,
        mode = "proxy"
    }

    assert_equals({ "proxy", 1 }, { target.target(1) })
end

function test_predicate()
    local target = init()

    assert_equals({ "target", 1 }, { target.target(1) })

    local instrument = m.Instrumentation.new {
        target = { target, "target" },
        handler = function()
            return function(str, ...)
                if type(str) ~= "string" then
                    return false, "predicate", str, ...
                else
                    return true
                end
            end
        end,
        mode = "predicate"
    }
    assert_equals({ "predicate", 1 }, { target.target(1) })
    assert_equals({ "target", "1" }, { target.target("1") })
end

function test_proxy()
    local target = init()

    assert_equals({ "target", 1 }, { target.target(1) })

    local instrument = m.Instrumentation.new {
        target = { target, "target" },
        handler = function()
            return function(...)
                return "post", ...
            end
        end,
        mode = "post"
    }

    assert_equals({ "post", "target", 1 }, { target.target(1) })
end
