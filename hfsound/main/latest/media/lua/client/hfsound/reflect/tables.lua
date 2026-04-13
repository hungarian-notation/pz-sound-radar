--[[

    This source file is released under the MIT/Expat License. Only files 
    in which this header appears are covered by this license.

    Copyright © 2026 Christopher Bode

    Permission is hereby granted, free of charge, to any person obtaining a 
    copy of this software and associated documentation files (the “Software”), 
    to deal in the Software without restriction, including without limitation 
    the rights to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the Software, and to permit persons to whom the 
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included 
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS 
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--]]
    
---@alias xpairs.type "m" | "k"
---@alias xpairs.produces [ xpairs.type, string?, any ]

local KTI = { m = 0, k = 1 }
local VTI = {
    ["number"]   = -5,
    ["string"]   = -5,
    ["boolean"]  = -5,
    ["nil"]      = -4,
    ["table"]    = -1,
    ["function"] = 1
}

local function xpairs(t)
    ---@type xpairs.produces[]
    local map = {}
    local metatable = getmetatable(t)

    if metatable then
        map[#map + 1] = { "m", nil, metatable }
    end

    for k, v in pairs(t) do
        map[#map + 1] = { "k", k, v }
    end

    local i = 1

    table.sort(map, function(a, b)
        if a[1] ~= b[1] then
            return KTI[a[1]] < KTI[b[1]]
        else
            local ati = VTI[type(a[3])] or 0
            local bti = VTI[type(b[3])] or 0

            if ati ~= bti then
                return ati < bti
            else
                return a[2] < b[2]
            end
        end
    end)

    return function()
        if i <= #map then
            local next = map[i]
            assert(next, i)
            local type, name, value = next[1], next[2], next[3]
            i = i + 1
            return type, name, value
        end
    end
end

local function stringify(somevalue, maxdepth)
    local visited = {}
    local parts = {}
    local function printf(...)
        local ok, result = pcall(string.format, ...)
        if ok then
            table.insert(parts, result)
        else
            error({ message = "bad format args", args = { ... } })
        end
    end

    local function print(...)
        local items = { ... }
        for i = 1, #items do items[i] = tostring(items[i]) end
        table.insert(parts, table.concat(items, ""))
    end

    local function visit_table(tid, t, depth)
        if depth - 1 == maxdepth then return end

        for keytype, keyname, keyvalue in xpairs(t) do
            local tabs = {}

            local keyident = keyname

            if keytype == "m" then
                keyident = "(metatable)"
            elseif type(keyname) == "string" then
                keyident = keyname
            else
                keyident = string.format("[%s]", tostring(keyname))
            end

            for _i = 1, depth do
                table.insert(tabs, "  ")
            end

            local indent = table.concat(tabs)

            if (type(keyvalue) == "table") then
                local skip = false

                for i, other in ipairs(visited) do
                    if rawequal(keyvalue, other) then
                        print(indent)

                        if i == tid then
                            printf("%s = (%d) (self)\n", keyident, i)
                        else
                            printf("%s = (%d)\n", keyident, i)
                        end

                        skip = true
                        break
                    end
                end

                if not skip then
                    local id = #visited + 1
                    visited[id] = keyvalue

                    print(indent)
                    printf("%s = (%d)", keyident, id)

                    if depth ~= maxdepth then
                        printf(" {\n")
                        local ok, err = pcall(visit_table, id, keyvalue, depth + 1)
                        if not ok then
                            print(indent)
                            printf("  (ERROR) %s\n", err)
                        end
                        print(indent)
                        printf("}\n")
                    else
                        print(" { … }\n")
                    end
                end
            elseif type(keyvalue) == "string" then
                print(indent)
                printf("%s = \"%s\"\n", keyident, keyvalue)
            else
                print(indent)
                printf("%s = %s\n", keyident, tostring(keyvalue))
            end

            if keytype == "m" then
                print("\n")
            end
        end
    end

    if type(somevalue) == "table" then
        visited[1] = somevalue
        printf("{\n")
        visit_table(1, somevalue, 1)
        printf("}\n")
    elseif type(somevalue) == "string" then
        printf("\"%s\"", type(somevalue), somevalue)
    else
        printf("%s", type(somevalue), somevalue)
    end

    return table.concat(parts, "")
end

local function dump(tbl, maxdepth)
    print(stringify(tbl, maxdepth))
end

return {
    dump = dump, stringify = stringify
}
