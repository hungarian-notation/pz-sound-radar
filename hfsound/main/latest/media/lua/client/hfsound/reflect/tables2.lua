local EMPTY_TABLE = setmetatable({},
    {
        __newindex = function()
            error("tried setting index in empty table singleton")
        end,

        __len = function()
            return 0
        end,

        __tostring = function()
            return "<table:special[empty-singleton]>"
        end
    })

---@param value _LuaRecord
local function is_array(value)
    if value.type ~= "table" then
        return false
    end

    if not value.children then
        return false
    end

    if not value.identity then
        return false
    end

    if value.problem then
        return false
    end


    local previous_index = 0

    for i, v in ipairs(value.children) do
        local key, _ = unpack(v)

        if key.type ~= "number" then
            return false
        end

        if key.value ~= previous_index + 1 then
            return false
        end

        previous_index = key.value
    end

    return true
end

---@return int
local function array_index_insert(arr, value)
    for i, v in ipairs(arr) do
        if v == value then return i end
    end
    local index = #arr + 1
    arr[index] = value
    return index
end

---@param complex userdata|function|thread|table
local function repr_complex(complex)
    local str = tostring(complex):gsub("%s+", " ")
    if #str > 32 then str = str:sub(1, 29) .. "..." end
    return string.format("<%s[%s]>", type(complex), str)
end


---@return (table)?
local function pcall_getmetatable(x)
    local ok, result = pcall(getmetatable, x)
    if ok == true and type(result) == "table" then
        return result
    end
end

local function pcall_getpairs(x)

end



-- #region class: IdentitySet

---@class hfs.IdentitySet
local IdentitySet = {}; IdentitySet.__index = IdentitySet

---@return hfs.IdentitySet
function IdentitySet.new()
    local obj = setmetatable({}, IdentitySet)



    return obj
end

-- #endregion


---@class _LuaValueRecord
---@field type          std.type
---@field repr          string
---@field value         any
---@field name?         string
---@field identity?     int
---@field depth?        int
---@field metatable?    _LuaRecord<table> | _LuaProblemRecord
---@field children?     [_LuaRecord,_LuaRecord][]

---@class _LuaProblemRecord
---@field type          nil
---@field repr          nil
---@field value         nil
---@field problem       string
---@field name?         string
---@field identity?     int
---@field depth?        int

---@alias _LuaRecord _LuaValueRecord | _LuaProblemRecord
---@class _LuaRecord.Root: _LuaRecord
---@generic T
---@return _LuaRecord
local function analyze(root_luavalue, maxdepth)
    local index = {}
    local registry = {}

    ---@generic T
    ---@param luavalue T
    ---@param depth int
    ---@param hinting? { contextual_name?: string, metatable?: boolean }
    ---@return _LuaRecord
    local function analyze_inner(luavalue, depth, hinting)
        hinting = hinting or EMPTY_TABLE
        local bonus_depth = 0

        if hinting.metatable then
            -- Don't skip describing a metatable at exactly max depth.
            bonus_depth = 1
        end

        if maxdepth and depth > (maxdepth + bonus_depth) then
            return { problem = "exceeded max depth" }
        end

        ---@return int
        ---@return _LuaRecord?
        local function get_identity(complex)
            local i = array_index_insert(index, complex)
            assert(index[i] == complex)
            return i, registry[i]
        end

        ---@return [_LuaRecord,_LuaRecord][]
        local function getchildren(complex)
            ---@type [_LuaRecord,_LuaRecord][]
            local object_keyed  = {}
            ---@type [_LuaRecord,_LuaRecord][]
            local numeric_keyed = {}

            for k, child in pairs(complex) do
                local key_record = analyze_inner(k, depth + 1)
                local context
                if key_record.type == "string" then
                    context = key_record.value
                end
                local value_record = analyze_inner(child, depth + 1, context)

                table.insert(object_keyed, { key_record, value_record })
            end

            table.sort(numeric_keyed, function(a, b)
                assert(a[1].type == "number")
                assert(type(a[1].value) == "number")
                assert(b[1].type == "number")
                assert(type(b[1].value) == "number")

                return a[1].value < b[1].value
            end)
            table.sort(object_keyed,
                function(a, b)
                    if b[1].problem then return false end
                    if a[1].problem then return true end
                    if a[1].repr == b[1].repr then return false end
                    if a[1].type ~= b[1].type then
                        return a[1].type < b[1].type
                    end

                    if a[1].type == "nil" or type(a[1].repr) ~= "string" then return true end
                    if b[1].type == "nil" or type(b[1].repr) ~= "string" then return false end

                    return a[1].repr < b[1].repr
                end
            )

            local combined = {}
            local numeric_start = #object_keyed + 1

            for i, v in ipairs(object_keyed) do combined[i] = v end
            for i, v in ipairs(numeric_keyed) do combined[i + numeric_start] = v end

            return combined
        end

        -- ---@return [_LuaRecord,_LuaRecord][]
        -- local function pcall_getchildren(complex)
        --     local ok, result = pcall(getchildren, complex)
        --     if ok then
        --         return result or {}
        --     else
        --         return {}
        --     end
        -- end

        if type(luavalue) == "nil" then
            return {
                type = "nil",
                value = luavalue,
                repr = "nil",
                depth = depth,
            }
        elseif type(luavalue) == "boolean" then
            return {
                type = "boolean",
                value = luavalue,
                repr = tostring(luavalue),
                depth = depth,
            }
        elseif type(luavalue) == "number" then
            return {
                type = "number",
                value = luavalue,
                repr = tostring(luavalue),
                depth = depth,
            }
        elseif type(luavalue) == "string" then
            return {
                type = "string",
                value = luavalue,
                repr = tostring(luavalue),
                depth = depth,
            }
        else
            local identity, existing = get_identity(luavalue)

            if existing then
                if existing.depth > depth then
                    existing.depth = depth
                end

                if hinting.contextual_name then
                    if not existing.problem and not existing.name then
                        existing.name = hinting.contextual_name
                    elseif (existing.name) and (existing.depth) and (existing.depth > depth) then
                        existing.name = hinting.contextual_name
                    end
                end

                return existing
            else
                assert(type(identity) == "number")
                assert(registry[identity] == nil)

                -- early registration here so we are available if any of our children refer to us circularly
                ---@type _LuaRecord
                local record = {
                    identity = identity,
                    type     = type(luavalue),
                    name     = hinting.contextual_name,
                    -- value = luavalue,
                    repr     = repr_complex(luavalue),
                    depth    = depth,
                }

                registry[identity] = record

                local metatable = getmetatable(luavalue)

                if metatable ~= nil then
                    record.metatable = analyze_inner(metatable, depth + 1, { metatable = true, })
                end

                if record.type == "table" then
                    record.children = getchildren(luavalue)
                end

                assert(registry[identity] == record)
                return record
            end
        end
    end

    return analyze_inner(root_luavalue, 0)
end

---@param root _LuaRecord
local function stringify_records(root, collector)
    local registry   = {}

    local need_comma = true
    local line_start = true
    local level      = 0

    local function wrapped_collector(str)
        if #str > 0 then
            collector(str)

            if string.sub(str, -1) == "\n" then
                line_start = true
            else
                line_start = false
            end
        end
    end

    local function _write(s)
        wrapped_collector(s)
    end

    local function write(s)
        s = tostring(s)
        if #s > 0 then
            if line_start then
                for i = 1, level do _write("  ") end
                line_start = false
            end
            _write(s)
        end
    end

    local function writeln()
        wrapped_collector("\n")
    end


    local function start_item()
        if need_comma then
            write(",")
            writeln()
            need_comma = false
        end
    end

    local function close_object()
        need_comma = false
        writeln()
        level = level - 1
        write("}")
        need_comma = true
    end

    local function open_object(name)
        start_item()
        write("{")

        if name ~= nil then
            write(" \"")
            write(name)
            write("\"")
        end

        level = level + 1
        writeln()
        need_comma = false
    end

    local function close_array()
        need_comma = false
        writeln()
        level = level - 1
        write("]")
        need_comma = true
    end

    local function open_array()
        start_item()
        write("[")
        level = level + 1
        writeln()
        need_comma = false
    end

    local function write_key(key, quoted)
        start_item()
        if quoted then write("\"") end
        write(key)
        if quoted then write("\"") end
        write(": ")
        need_comma = false
    end

    local function write_value(value)
        start_item()
        write(value)
        need_comma = true
    end


    ---@param value _LuaRecord
    local function is_obvious_type(value)
        if value.type == "nil" then return true end
        if value.type == "boolean" then return true end
        if value.type == "number" then return true end
        if value.type == "string" then return true end
        if value.type == "table" then return true end
    end

    ---@param value _LuaRecord
    ---@param depth int
    local function inner(value, depth, hinting)
        hinting = hinting or EMPTY_TABLE

        ---@cast value _LuaRecord
        if depth > 20 then error() end
        local backref = false

        if value.identity and registry[value.identity] then
            backref = true
        else
            if value.identity then
                registry[value.identity] = true
            end
        end

        if value.problem then
            ---@cast value _LuaProblemRecord
            open_object()
            if value.name then
                write_key("@name")
                write_value(value.name)
            end
            write_key("$problem")
            write_value(value.problem)
            close_object()
            return
        end

        ---@cast value _LuaValueRecord

        if backref then
            open_object(value.name)
            write_key("&")
            write_value(value.identity)
            close_object()
        else
            if not value.metatable and is_array(value) then
                ---@cast value.children -?
                open_array()
                for i, v in ipairs(value.children) do
                    inner(v[2], depth + 1, { array_element = true, array_index = i })
                    if v[2].problem then break end
                end
                close_array()
            elseif value.metatable or value.children then
                local use_typename = nil
                local use_name = nil

                if not is_obvious_type(value) then
                    use_typename = value.type
                end

                open_object { typename = value.type }

                if value.name then
                    write_key("@name")
                    write_value(value.name)
                end

                assert(value.identity ~= nil)
                -- writeln(" {")

                if value.metatable then
                    write_key("@metatable")
                    inner(value.metatable, depth + 1, { metatable = true })
                end

                if value.children then
                    for i, v in ipairs(value.children) do
                        local keyname = v[1].repr or v[1].value
                        write_key(keyname)
                        inner(v[2], depth + 1, { contextual_name = keyname })
                        if v[2].problem then break end
                    end
                end

                close_object()
            else
                write_value(value.value)
            end
        end
    end

    return inner(root, 0)
end

local function stringify(value, maxdepth)
    local arr = {}

    local function collect(str)
        table.insert(arr, str)
    end

    stringify_records(analyze(value, maxdepth), collect)

    return table.concat(arr, "")
end

local function dump(value, maxdepth) print(stringify(value, maxdepth)) end

local module = {
    analyze = analyze, stringify = stringify, dump = dump
}

xt2 = module

return module
