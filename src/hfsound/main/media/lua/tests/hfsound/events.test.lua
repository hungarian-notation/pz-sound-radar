local events = require("hfsound/util/events")

local create_dispatch = events.EventDispatch.new



function test_resolve()
    local host = {}

    local dipatch = create_dispatch(host)

    local test_closure = (
    ---@param d hfs.EventDispatch
        function(d)
            ---@type any
            local last_event = nil

            dipatch:subscribe(function(e, ...)
                last_event = e
            end)

            return function()
                return last_event
            end
        end
    )(dipatch)

    assert_equals(nil, test_closure())

    dipatch:invoke(1)

    assert_equals(1, test_closure())

    dipatch:invoke({ host = host })

    assert_equals({ host = host }, test_closure())
end

function test_hijack()
    local reference_closure, external_callback = (function()
        local last_event = nil

        local set = function(n, n2, n3)
            last_event = n
        end

        local get = function()
            return last_event
        end

        return get, set
    end)()

    local host = { some_event = external_callback }

    assert_equals(nil, reference_closure())

    host.some_event(1)

    assert_equals(1, reference_closure())

    local test_closure, unsub = (
        function()
            ---@type any
            local last_event = nil

            local subscription = events.subscribe(host, "some_event", function(n) last_event = n end)

            local function callback()
                return last_event
            end

            local function unsub()
                subscription:cancel()
            end

            return callback, unsub
        end
    )()

    assert_equals(nil, test_closure())
    assert_equals(1, reference_closure())

    host.some_event(2)

    assert_equals(2, test_closure())
    assert_equals(2, reference_closure())

    unsub()

    host.some_event(3)

    assert_equals(2, test_closure())
    assert_equals(3, reference_closure())
end
