if _G.love == nil then return end

local _INJECT = _G --[[@as table]]

_INJECT.PZAPI = _INJECT.PZAPI or {}
_INJECT.PZAPI.ModOptions = {}
_INJECT.PZAPI.ModOptions.Data = {}
_INJECT.PZAPI.ModOptions.Dict = {}
_INJECT.PZAPI.ModOptions.OtherOptions = {}

_INJECT.PZAPI.ModOptions.Options = {}
local Options = _INJECT.PZAPI.ModOptions.Options; Options.__index = Options

function Options:new(_1, _2)
    return setmetatable({}, self)
end

function Options:apply()

end

function Options:getOption(_)
    error("NOT MOCKED")
end

function Options:addTitle(name)
end

function Options:addDescription(text)
end

function Options:addSeparator()
end

function Options:addTextEntry(id, name, value, _tooltip)
end

function Options:addTickBox(id, name, value, _tooltip)
    return { value = value }
end

function Options:addMultipleTickBox(id, name, _tooltip)
    local option = {
        values = setmetatable({}, { __index = function() return true end }),
        addTickBox = function() end
    }

    return option
end

function Options:addComboBox(id, name, _tooltip)
    return {
        values = {},
        selected = 1,
        addItem = function(self, optname, selected)
            table.insert(self.values, name)
            if selected then self.selected = #self.values end
        end
    }
end

function Options:addColorPicker(id, name, r, g, b, a, _tooltip)
    return { color = { r = r, g = g, b = b, a = a } }
end

function Options:addKeyBind(id, name, key, _tooltip)
    return { key = key, defaultkey = key }
end

function Options:addSlider(id, name, min, max, step, value, _tooltip)
    print(id,value)
    return { value = value }
end

function Options:addButton(id, name, tooltip, onclickfunc, target, arg1, arg2, arg3, arg4)
    return {}
end

function _INJECT.PZAPI.ModOptions:create(_1, _2)
    return Options:new(_1, _2)
end

function _INJECT.PZAPI.ModOptions:getOptions(modOptionsID)
    error("NOT MOCKED")
end

function _INJECT.PZAPI.ModOptions:save()

end

function _INJECT.PZAPI.ModOptions:load()

end
