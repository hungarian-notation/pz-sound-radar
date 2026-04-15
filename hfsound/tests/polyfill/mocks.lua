if love == nil then return end

local function __isinstance(obj, name)
    return (obj.classes) and (obj.classes[name] == true)
end

---@class hf.MockMovable
local MockIsoMovable = { __isinstance = __isinstance }; MockIsoMovable.__index = MockIsoMovable

---@class hf.MockMovable.Kwargs
---@field classes string[]
---@field x number
---@field y number
---@field z number

local nextid = 0

---@param kw hf.MockMovable.Kwargs
---@return hf.MockMovable
function MockIsoMovable.new(kw)
    local obj = setmetatable({}, MockIsoMovable)

    --- the arguments table passed to this instance's constructor
    obj.kwargs = kw

    obj.uid = kw.classes[1] .. "-" .. nextid; nextid = nextid + 1
    obj.x = kw.x
    obj.y = kw.y
    obj.z = kw.z

    obj.classes = { IsoObject = true }

    for _, c in ipairs(kw.classes) do
        obj.classes[c] = true
    end

    return obj
end

function MockIsoMovable.getCurrentBuildingDef(...)
    return nil
end

function MockIsoMovable:getX()
    return self.x
end

function MockIsoMovable:getY()
    return self.y
end

function MockIsoMovable:getZ()
    return self.z
end

function MockIsoMovable:getUID()
    return self.uid
end

function MockIsoMovable.hasTrait()
    return false
end

local injectscope = _G --[[@as table]]

function injectscope.instanceof(obj, name)
    if obj["__isinstance"] then
        return obj.__isinstance(obj, name)
    else
        return false
    end
end

return {
    IsoMovable = MockIsoMovable
}
