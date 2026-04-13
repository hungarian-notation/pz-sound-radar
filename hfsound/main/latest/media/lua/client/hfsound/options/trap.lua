local proprioception = require('hfsound/reflect/proprioception')
-- #region class: OptionsProbe


---@class hfs.OptionsProbe.Type
---@field onlayout fun()
---@field enabled boolean
local OptionsTrap = {

    ---@class hfs.OptionsProbe : hfs.OptionsProbe.Type
    ---@field onlayout fun()
    ---@field enabled boolean
    prototype = {},

    ---@type metatable
    meta = {},

    ---@type hfs.OptionsProbe[]
    instances = {},

    ---@type boolean
    installed = false,

    ---@type boolean
    installable = proprioception.checksurface("MainOptions") and
        proprioception.checksurface("PZAPI.ModOptions") and
        proprioception.checksurface("PZAPI.ModOptions.Options"),

    ---@type (fun(MainOptions): nil)?
    _wrapped = nil

}

---@param tbl hfs.OptionsProbe
---@param key unknown
function OptionsTrap.meta.__index(tbl, key)
    if key == "type" then
        if tbl.enabled then
            tbl:trigger()
        end
    else
        local resolved
        resolved = rawget(OptionsTrap.prototype, key)
        if resolved ~= nil then return resolved end
        resolved = rawget(OptionsTrap, key)
        if resolved ~= nil then return resolved end
        return nil
    end
end

function OptionsTrap.prototype:trigger()
    self.onlayout()
    self.enabled = false
end

function OptionsTrap.wrapper(...)
    for _, probe in ipairs(OptionsTrap.instances) do
        probe.enabled = true
    end

    ---@cast OptionsTrap._wrapped -?
    OptionsTrap._wrapped(...)

    for _, probe in ipairs(OptionsTrap.instances) do
        probe.enabled = false
    end
end

---@param onlayout fun()
---@return hfs.OptionsProbe
function OptionsTrap.new(onlayout)
    if OptionsTrap.installable and not OptionsTrap.installed then
        OptionsTrap._wrapped = MainOptions.addModOptionsPanel
        MainOptions.addModOptionsPanel = OptionsTrap.wrapper
        OptionsTrap.installed = true
    end

    ---@type hfs.OptionsProbe
    local obj = setmetatable({}, OptionsTrap.meta)
    obj.onlayout = onlayout
    obj.enabled = false
    table.insert(OptionsTrap.instances, obj)
    return obj
end

-- #endregion

return OptionsTrap
