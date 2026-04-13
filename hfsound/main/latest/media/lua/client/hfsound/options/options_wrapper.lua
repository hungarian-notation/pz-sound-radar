local proprioception   = require('hfsound/reflect/proprioception')

local colors           = require('hfsound/colors')
local hr               = require('hfsound/options/separator')
local OptionsProbe     = require('hfsound/options/trap')

local module           = {}

-- #region class: Options

---@class hfs.OptionsWrapper
local OptionsWrapper   = {}; OptionsWrapper.__index = OptionsWrapper
module.OptionsWrapper  = OptionsWrapper

---@param id string
---@return string
local function text(id)
    return id
end

---@param opt PZAPI.ModOptions.Options
---@param id string
---@return hfs.OptionsWrapper
function OptionsWrapper.new(opt, id)
    local obj = setmetatable({}, OptionsWrapper)
    obj.fancy =
        proprioception.checksurface("MainOptions") and
        proprioception.checksurface("PZAPI.ModOptions") and
        proprioception.checksurface("PZAPI.ModOptions.Options")
    obj.opt = opt
    obj.id = id
    return obj
end

---@param options MainOptions
---@param y number
function OptionsWrapper.addCustomHorizontalLine(options, y)
    local UI_BORDER_SPACING = 10
    local sbarWidth         = 13
    local width             = options.width - (UI_BORDER_SPACING * 2 + 1) * 2 - sbarWidth
    local hrx, hry          = UI_BORDER_SPACING * 2 + 1, options.addY + y
    local hLine             = hr.HorizonalRule:new(hrx, hry, width, 0.666, { 0.5, 0.5, 0.5, 0.333 })
    hLine.anchorRight       = true
    options.mainPanel:addChild(hLine)
    options.addY = options.addY + UI_BORDER_SPACING
end

---Stick a fake control into the options data that detects when the MainOptions
---instance is trying to render it.
---@param onlayout fun()
function OptionsWrapper:addProbe(onlayout)
    if not self.fancy and getDebug() then
        error("addProbe when self.fancy ~= true")
    end

    local probe = OptionsProbe.new(onlayout)
    table.insert(self.opt.data, probe)
end

function OptionsWrapper:useSmallSeparator()
    if not self.fancy then return end

    local addHorizontalLineSmall = MainOptions.addHorizontalLineSmall

    local function interceptor(...)
        OptionsWrapper.addCustomHorizontalLine(...)
        MainOptions.addHorizontalLineSmall = addHorizontalLineSmall
    end

    local function intercept()
        MainOptions.addHorizontalLineSmall = interceptor
    end

    self:addProbe(intercept)
end

function OptionsWrapper:getids(key)
    return key, self:get_translation(key), self:get_tooltip(key)
end

function OptionsWrapper:get_translation(key)
    return string.format("UI_options_%s_%s", self.id, key)
end

function OptionsWrapper:get_tooltip(key)
    return string.format("UI_options_tooltip_%s_%s", self.id, key)
end

---@param name string
function OptionsWrapper:addTitle(name)
    local _, tstr = self:getids(name)
    self.opt:addTitle(tstr)
end

---@param name string
function OptionsWrapper:addDescription(name)
    local _, tstr = self:getids(name)
    self.opt:addDescription(tstr)
end

local function add_padding(pixels)
    local function closure()
        ---@cast MainOptions.instance -?
        MainOptions.instance.addY = MainOptions.instance.addY + pixels
    end
    return closure
end

---@param pixels? int
function OptionsWrapper:addSpacer(pixels)
    if not self.fancy then
        self.opt:addTitle("")
        return
    end
    pixels = pixels or 20
    self:addProbe(add_padding(pixels))
end

function OptionsWrapper:addSmallSeparator()
    if not self.fancy then
        self:addSpacer()
        return
    end

    self:useSmallSeparator()
    self.opt:addSeparator()
end

function OptionsWrapper:addSeparator()
    self.opt:addSeparator()
end

---@param key string
---@param value string
---@param tooltip boolean? Optional tooltip text
function OptionsWrapper:addTextEntry(key, value, tooltip)
    local id, tstr, ttstr = self:getids(key)

    return self.opt:addTextEntry(id, text(tstr),
        value,
        tooltip and text(ttstr) or nil
    )
end

---@param key string
---@param value bool
---@param tooltip boolean? Optional tooltip text
function OptionsWrapper:addTickBox(key, value, tooltip)
    local id, tstr, ttstr = self:getids(key)

    return self.opt:addTickBox(id, text(tstr),
        value,
        tooltip and text(ttstr) or nil
    )
end

---@param key string
---@param values [string,boolean?][]
---@param tooltip boolean? Optional tooltip text
function OptionsWrapper:addMultipleTickBox(key, values, tooltip)
    local id, tstr, ttstr = self:getids(key)

    local ticks = self.opt:addMultipleTickBox(id, text(tstr),
        tooltip and text(ttstr) or nil
    )

    for _, tuple in ipairs(values) do
        if tuple[1]:sub(1, 1) == "." then
            id, tstr, ttstr = self:getids(key .. tuple[1]:sub(2))
        else
            id, tstr, ttstr = self:getids(key .. "_" .. tuple[1])
        end
        ticks:addTickBox(text(tstr), tuple[2] or false)
    end

    return ticks
end

---@param key string
---@param values [string,boolean?][]
---@param tooltip boolean? Optional tooltip text
function OptionsWrapper:addComboBox(key, values, tooltip)
    local id, tstr, ttstr = self:getids(key)

    local combo = self.opt:addComboBox(id, text(tstr),
        tooltip and text(ttstr) or nil
    )

    for _, tuple in ipairs(values) do
        combo:addItem(text(tuple[1]), tuple[2])
    end
end

---@alias hfs.TaggedColorPicker umbrella.ModOptions.ColorPicker & { defaultcolor: umbrella.RGBA }

---@param key string
---@param color hfs.OptionsColor
---@param tooltip boolean? Optional tooltip text
---@return hfs.TaggedColorPicker
function OptionsWrapper:addColorPicker(key, color, tooltip)
    local id, tstr, ttstr = self:getids(key)
    local r, g, b, _ = colors.parse(color)

    ---@type umbrella.ModOptions.ColorPicker | hfs.TaggedColorPicker
    local result = self.opt:addColorPicker(id, text(tstr),
        r, g, b, 1,
        tooltip and text(ttstr) or nil
    )

    result.defaultcolor = result.color

    return result
end

---@param key string
---@param value integer?
---@param tooltip boolean? Optional tooltip text
function OptionsWrapper:addKeyBind(key, value, tooltip)
    local id, tstr, ttstr = self:getids(key)

    value = value or Keyboard.KEY_NONE

    return self.opt:addKeyBind(id, text(tstr),
        value,
        tooltip and text(ttstr) or nil
    )
end

---@param key string
---@param min number Minimum value
---@param max number Maximum value
---@param step number Step size
---@param value number Initial value
---@param tooltip boolean? Optional tooltip text
function OptionsWrapper:addSlider(key, min, max, step, value, tooltip)
    local id, tstr, ttstr = self:getids(key)

    return self.opt:addSlider(id, text(tstr),
        min, max, step, value,
        tooltip and text(ttstr) or nil
    )
end

---@generic T
---@param key string
---@param tooltip boolean? Optional tooltip text
---@param onclickfunc fun(target: T, button: ISButton, ...: [unknown?,unknown?,unknown?,unknown?])? Function to call when button is clicked
---@param target T? Optional target object for the onclick function
---@param arg1? unknown Optional first argument for the onclick function
---@param arg2? unknown Optional second argument for the onclick function
---@param arg3? unknown Optional third argument for the onclick function
---@param arg4? unknown Optional fourth argument for the onclick function
function OptionsWrapper:addButton(key, tooltip, onclickfunc, target, arg1, arg2, arg3, arg4)
    local id, tstr, ttstr = self:getids(key)

    return self.opt:addButton(id, text(tstr),
        tooltip and text(ttstr) or nil,
        onclickfunc, target, arg1, arg2, arg3, arg4
    )
end

---@param id string
---@return hfs.OptionsWrapper
function module.options(id)
    -- local opt_title = string.format("UI_options_%s_%s", id, "title")
    local opt_title = string.format("UI_options_%s", id)

    local opt = PZAPI.ModOptions:create(id, text(opt_title))
    return module.OptionsWrapper.new(opt, id)
end

-- #endregion

return module
