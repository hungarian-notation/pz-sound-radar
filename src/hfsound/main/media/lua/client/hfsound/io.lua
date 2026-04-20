---@param default string?
---@return string?
local function readfile(path, default)
    local function try()
        local reader = getFileReader(path, false)
        if reader then
            local contents = reader:readAllAsString()
            reader:close()
            return contents
        else
            return nil
        end
    end
    local ok, result = pcall(try)
    if ok and type(result) == "string" and #result > 0 then
        return result
    else
        return default
    end
end

---@param path string
---@param str string
---@param append (boolean|"write"|"writeln")?
local function writefile(path, str, append)
    local writer = getFileWriter(path, true, (not not append) or false)
    assert(writer)

    if append == true or append == "writeln" then
        writer:writeln(str)
    else
        writer:write(str)
    end

    writer:close()
    return
end

---@param path string
---@param slots int?
local function rotatefile(path, slots)
    slots = slots or 5

    --[[
        This is not optimal, but I don't think we have visibility on file times
        through the API.
    --]]

    local indexpath = string.format("%s.rotate", path)
    local rotatepath = function(index)
        local basename, ext = path:match("^(.*)(%..+)$")
        return string.format("%s.%02d%s", basename, index, ext)
    end

    local nextindex = (tonumber(readfile(indexpath)) or 0) % slots
    writefile(indexpath, tostring((nextindex + 1) % slots))

    local content = readfile(path)

    if content and content ~= "" then
        writefile(rotatepath(nextindex), content)
    end
end

return { readfile = readfile, writefile = writefile, rotatefile = rotatefile }
