---@param chars string?
---@param out string[]?
local function split(str, chars, out)
    chars = chars or "\r\n"
    chars = "([^" .. chars .. "]+)"
    ---@type string[]
    out = out or {}
    for substring in str:gmatch("([^\r\n]+)") do
        table.insert(out, substring)
    end
    return out
end

local function parse_config()
    ---@type string[]
    local chars = split(package.config, "\r\n")
    return {
        directory_separator = assert(chars[1], "1", chars[1]),
        path_separator = assert(chars[2], "2", chars[2]),
        wildcard = assert(chars[3], "3", chars[3]),
        executable = assert(chars[4], "4", chars[4]),
        ignore = assert(chars[5], "5", chars[5])
    }
end

local function insert_unique(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return
        end
    end
    table.insert(t, value)
end

function normalize_path(...)
    local config = parse_config()

    if config.wildcard ~= "?" then
        error("unexpected wildcard: " .. config.wildcard)
    end

    if config.directory_separator ~= "/" and config.directory_separator ~= "\\" then
        error("unexpected directory separator: " .. config.directory_separator)
    end

    local directory_separators = { "/", "\\" }
    local split_pattern = "([^" .. table.concat(directory_separators, "") .. "]+)"
    local parts = {}
    for i, arg in ipairs({ ... }) do
        for next_subpath in tostring(arg):gmatch(split_pattern) do
            local subpath = next_subpath
            if subpath == ".." then
                if parts[#parts] ~= nil and parts[#parts] ~= ".." then
                    parts[#parts] = nil
                else
                    table.insert(parts, "..")
                end
            elseif subpath ~= "." then
                table.insert(parts, subpath)
            end
        end
    end
    return table.concat(parts, config.directory_separator)
end

function bootstrap_path(basis)
    ---@type string[]
    local expanded = {}

    for path in package.path:gmatch("([^;]+)") do
        table.insert(expanded, path)
    end

    for next in basis:gmatch("([^;]+)") do
        local path = normalize_path(next)
        insert_unique(expanded, path)
    end

    package.path = table.concat(expanded, ";")
end

bootstrap_path(package.path)
