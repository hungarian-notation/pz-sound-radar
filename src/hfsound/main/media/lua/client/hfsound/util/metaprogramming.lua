local module = {}

local DEBUG = type(getDebug) == "function" and getDebug()

-- #region class: Instrumentation ----------------------------------------------

---allows for the detection or redirection of invocation of a named function
---on some target table
---@class hfs.Instrumentation
local Instrumentation = {}; Instrumentation.__index = Instrumentation

---@alias hfs.Instrumentation.Handler<T> fun(context: hfs.Instrumentation<T>, original: any): (fun(...): any)

---@class hfs.Instrumentation.Kwargs<T>
---@field target [ T, string ] # i.e. { obj, "func" } for obj:func(...)
---@field handler hfs.Instrumentation.Handler<T>
---@field recursive? boolean (default: true)
---@field once? boolean (default: false)
---@field mode? "proxy" | "predicate" | "post" (default: "proxy")
---@field immediate? boolean (default: true)

---@generic T
---@param kw hfs.Instrumentation.Kwargs<T>
---@return hfs.Instrumentation
function Instrumentation.new(kw)
    local target          = kw.target[1]
    local target_function = kw.target[2]
    local handler         = kw.handler


    local obj = setmetatable({}, Instrumentation)
    obj.target_table = target
    obj.target_index = target_function
    obj.handler = handler

    ---@type boolean
    obj.m_installed_flag = false

    ---@type function
    obj.m_installed_callback = nil

    ---overridden function
    ---@type function
    obj.m_overrides = nil

    ---@type any
    obj.m_installed_original = nil

    obj.m_once = not not kw.once
    obj.m_recursive = not not kw.recursive
    obj.m_mode = kw.mode or "proxy"



    if kw.immediate ~= false then
        obj:install()
    end

    return obj
end

local function is_callable(value)
    if type(value) == "function" then return true end
    if type(value) ~= "table" then return false end
    local metatable = getmetatable(value)
    if metatable == nil then return false end
    if type(metatable) ~= "table" then return false end
    if metatable.__call == value or metatable.__call == metatable then
        error("recursive __call")
    end
    return is_callable(metatable.__call)
end

---@return boolean
function Instrumentation:install()
    if not self.m_installed_flag then
        local original = rawget(self.target_table, self.target_index)

        if original ~= nil and not is_callable(original) then
            if DEBUG then
                print(("WARNING: can not instrument %s, current has type %s"):format(self.target_index,
                    type(original)))
            end
            return false
        end

        if original == nil then
            self.m_overrides = self.target_table[self.target_index]
        else
            self.m_overrides = original
        end

        rawset(self.target_table, self.target_index, self)
        self.m_installed_original = original
        self.m_installed_callback = self.handler(self, self.m_installed_original)
        self.m_installed_flag = true

        return true
    else
        return true
    end
end

function Instrumentation:uninstall()
    if self.m_installed_flag then
        local actual = rawget(self.target_table, self.target_index)

        if actual ~= self and actual ~= self.m_installed_original then
            if DEBUG then
                print("WARNING: can't uninstall instrumentation, target table has mutated")
            end
        else
            rawset(self.target_table, self.target_index, self.m_installed_original)
        end

        self.m_installed_original = nil
        self.m_installed_callback = nil
        self.m_installed_flag = false
    end

    return self
end

function Instrumentation:_invoke_proxy(...)
    return self.m_installed_callback(...)
end

function Instrumentation:_invoke_predicate(...)
    local before = { self.m_installed_callback(...) }

    if before[1] ~= true then
        return unpack(before, 2)
    else
        return self.m_overrides(...)
    end
end

function Instrumentation:_invoke_post(...)
    return self.m_installed_callback(self.m_overrides(...))
end

function Instrumentation:_setup()
    local target_table = self.target_table
    local target_index = self.target_index

    if not self.m_recursive then
        -- temporarily restore the original state
        assert(rawget(target_table, target_index) == self)
        rawset(target_table, target_index, self.m_installed_original)
    end
end

function Instrumentation:_teardown()
    if not self.m_recursive then
        rawset(self.target_table, self.target_index, self)
    end

    if self.m_once then
        self:uninstall()
    end
end

function Instrumentation:_invoke(...)
    local m_installed_callback = self.m_installed_callback
    local target_table = self.target_table
    local target_index = self.target_index
    local m_recursive = self.m_recursive

    ---@cast m_installed_callback -nil
    ---@type any[]
    local retval

    self:_setup()

    if self.m_mode == "proxy" then
        retval = { self:_invoke_proxy(...) }
    elseif self.m_mode == "predicate" then
        
        retval = { self:_invoke_predicate(...) }
    elseif self.m_mode == "post" then
        retval = { self:_invoke_post(...) }
    else
        error("unknown mode: " .. tostring(self.m_mode))
    end

    self:_teardown()

    return unpack(retval)
end

function Instrumentation:__call(...)
    local m_installed_callback = self.m_installed_callback
    local target_table = self.target_table
    local target_index = self.target_index

    if m_installed_callback then
        return self:_invoke(...)
    else
        local current_value = target_table[target_index]

        if current_value == self then
            error(target_index .. ": m_installed_callback == nil and target_table[target_index] == self")
        else
            if self.m_panic_recursion then
                error(string.format(
                    "instrumentation for %s appears to be uninstalled but has been invoked recursively",
                    target_index
                ))
            else
                if DEBUG then
                    print("warning: instrumentation for " .. target_index .. " invoked when not installed")
                end
                self.m_panic_recursion = true
                local retval = { current_value(...) }
                self.m_panic_recursion = nil
                return unpack(retval)
            end
        end
    end
end

module.Instrumentation = Instrumentation

-- #endregion

return module
