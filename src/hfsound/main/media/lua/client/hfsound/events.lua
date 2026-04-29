--[[

    This source file is released under the MIT/Expat License:

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

local module = {}

--[[
    This module provides support for event listeners, including the
    enhancement of listeners that are implemented as a flat callback function
    stored in a table, such as the callbacks in PZAPI/ModOptions.

    It replaces existing callbacks with a callable EventDispatch. The event
    dispatch can then be subscribed to, and when its __call metamethod is
    invoked it will invoke all its subscribers.

    NOTE This module does not interface with the primary Java->Lua events
    managed by the `Events` table. Those are already competently dispatched.
--]]

-- #region class: EventDispatch

---@class hfs.EventDispatch
local EventDispatch = {}; EventDispatch.__index = EventDispatch

---A subscription instance returned from `EventDispatch:subscribe` is the
---structure used by the dispatch to hold a reference to a callback.
---
---Mutating the `callback` field can redirect the events to a different
---function.
---@class hfs.EventDispatch.Subscription
---@field callback              fun(...):unknown subscription callback
---@field dispatch              hfs.EventDispatch
---@field context               any
---@field cancel                fun(self: hfs.EventDispatch.Subscription):void

---@param context? any
---@param primordial? function
---@return hfs.EventDispatch
function EventDispatch.new(context, primordial)
    local obj = setmetatable({}, EventDispatch)

    obj.context = context
    obj._primordial = primordial
    ---@type hfs.EventDispatch.Subscription[]
    obj._subscribers = {}
    obj._nascent = true

    return obj
end

function EventDispatch:__call(...)
    local subscribers = self._subscribers
    for _, subscriber in ipairs(subscribers) do
        subscriber.callback(...)
    end
end

---Adds the callback function to this dispatch's subscribers, returning a
---reference to the created subscription record.
---@param callback function
---@return hfs.EventDispatch.Subscription
function EventDispatch:subscribe(callback)
    if getDebug() then
        for _, existing in ipairs(self._subscribers) do
            if existing.callback == callback then
                error("attempted to subscribe to the same dispatch twice")
            end
        end
    end

    local dispatch = self

    local subscription = {
        cancel = function(self) dispatch:unsubscribe(self.callback) end,
        callback = callback,
        dispatch = dispatch,
        context = self.context
    }

    table.insert(self._subscribers, subscription)

    return subscription
end

---Removes a callback from the subscriptions
---@return boolean # indicates if the callback was present
function EventDispatch:unsubscribe(callback)
    local subs = self._subscribers

    for i = 1, #subs do
        if subs[i].callback == callback then
            table.remove(subs, i)
            return true
        end
    end

    return false
end

module.EventDispatch = EventDispatch

-- #endregion

---Check if the value is an EventDispatch instance
---@param context? table If specified, this function tests if the value is
---the dispatch for a specific context object.
local function is_dispatch(value, context)
    if type(value) ~= "table" then return false end
    if getmetatable(value) ~= EventDispatch then return false end
    ---@cast value hfs.EventDispatch
    return context == nil or value.context == context
end

module.is_dispatch = is_dispatch


---Subscribes to a lua event with `callback`
---
---If the values of `context[event_name]` is nil, creates a new dispatch
---and assigns it to `context[event_name]`
---
---If `context[event_name]` is a function, creates a new dispatch that wraps
---that function and replaces it.
---@param context table the table that holds events
---@param event_name string the name of the event handler in the table
---@param callback function the callback function to subscribe with
---@return hfs.EventDispatch.Subscription
function module.subscribe(context, event_name, callback)
    local existing_value = context[event_name]

    if is_dispatch(existing_value) then
        ---@cast existing_value hfs.EventDispatch
        return existing_value:subscribe(callback)
    else
        if existing_value == nil or type(existing_value) == "function" then
            local dispatch = EventDispatch.new(context, existing_value)
            context[event_name] = dispatch
            return dispatch:subscribe(callback)
        else
            error("the value indexecd by " .. event_name .. " is neither a function nor an event dispatch")
        end
    end
end

function module.unsubscribe(context, event_name, callback)
    local dispatch = context[event_name]
    assert(is_dispatch(dispatch))
    ---@cast dispatch hfs.EventDispatch
    dispatch:unsubscribe(callback)
end

return module
