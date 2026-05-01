require "support/ansi"


local TESTS = {}
local print = ansi_print

function load_tests(filename)
    local testfile = loadfile(filename)
    assert(testfile, "no such test: " .. filename)

    local local_tests = {}

    ---@type metatable
    local testenv_metatable = { __index = _G }
    function testenv_metatable.__newindex(t, k, v)
        if (type(k) == "string" and type(v) == "function") then
            table.insert(local_tests, { id = k, chunk = v, file = filename })
            -- print("defined test: " .. k)
        end
        _G[k] = v
    end

    setfenv(testfile, setmetatable({
        -- print = print
    }, testenv_metatable))

    local ok, err = pcall(testfile)

    if (not ok) then
        print("BUG: error while loading " .. filename .. " (no tests were executed)")
        print()
        print(err)
        os.exit(1)
    end

    table.insert(TESTS, { tests = local_tests, file = filename })
end

function execute_tests()
    print()
    for _, group in ipairs(TESTS) do
        for _, test in ipairs(group.tests) do
            print()
            local result, err = xpcall(test.chunk, debug.traceback)

            if result then
                print(ansi(32), "PASSED", test.id, ansi(0), ansi(2), test.file)
            else
                print(ansi(31), "FAILED", test.id, ansi(0), ansi(2), test.file)
                print("\t", err)
            end
        end
    end
end

function getDebug()
    return true
end

---@param expected any
---@param actual any
---@param assertive? boolean
---@param path? string[]
local function equals(expected, actual, assertive, path)
    if assertive then assert(path ~= nil) end

    ---@param cause string
    ---@param error_path? string[]
    local function validation_error(cause, error_path)
        assert(error_path)
        local message = ""
        if #error_path > 0 then
            message = "at " .. table.concat(error_path, ">") .. ": "
        end
        message = message .. cause
        error(message, 3)
    end

    ---@param ... string
    ---@return string[]
    local function next_path(...)
        if path == nil then return nil --[[@as (string[])]] end

        local next = {}

        for i, v in ipairs(path) do
            next[i] = v
        end

        for i, v in ipairs({ ... }) do
            if type(v) == "string" then
                table.insert(next, v)
            else
                table.insert(next, string.format("[%s]", tostring(v)))
            end
        end

        return next
    end

    if expected == actual then
        return true
    end

    if type(expected) == "table" and type(actual) == "table" then
        if not equals(getmetatable(expected), getmetatable(actual), assertive, next_path("(metatable)")) then
            return false
        end

        local checked = {}

        for k, _ in pairs(expected) do
            if not equals(expected[k], actual[k], assertive, next_path(k)) then
                return false
            end

            checked[k] = true
        end

        for k, _ in pairs(actual) do
            if not checked[k] then
                if assertive then validation_error("different values", next_path(k)) end
                return false
            end
        end

        return true
    else
        if assertive then
            validation_error(
                "different values: expected: '" .. tostring(expected) .. "' vs actual: '" .. tostring(actual) .. "'",
                path)
        end
        return false
    end
end

function assert_equals(expected, actual)
    local ok, err = pcall(function() equals(expected, actual, true, {}) end)

    if not ok then
        print(err); error(err, 2)
    end
end

---@overload fun(expected:number, actual:number, allowable_delta:number): number
---@overload fun(expected:number, actual:number): number
---@param expected number
---@param actual number
---@param allowable_delta? number
function assert_roughly_equal(expected, actual, allowable_delta)
    if allowable_delta == nil then allowable_delta = 0.001 end

    if type(actual) ~= "number" then
        error(string.format("invalid comparison; <actual> value is non numeric: %s %s", type(actual), tostring(actual)))
    elseif math.abs(expected - actual) > allowable_delta then
        error(string.format("excessive delta (greater than %.6f) between expected (%f) and actual (%f)",
            allowable_delta, expected, actual))
    else
        return actual
    end
end
