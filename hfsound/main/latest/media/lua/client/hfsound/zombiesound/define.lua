local styles = require('hfsound/zombiesound/styles')

local module = {}

---@param kw hfs.ZSoundKwargs
---@return hfs.ZombieSound
function module.define_sound(kw)
    ---@type number
    local frequency

    if kw.frequency then
        ---@cast kw hfs.ZSoundKwargsFrequency
        frequency = kw.frequency
    else
        ---@cast kw hfs.ZSoundKwargsPeriod
        frequency = 1 / kw.period
    end

    ---@type hfs.ZombieSound
    local record = {
        frequency = kw.frequency or (kw.period and (1 / kw.period)) or 1,
        volume    = kw.volume or kw.radius,
        radius    = kw.radius,
        duration  = kw.duration or 1,
        style     = kw.style or styles.DEFAULT_STYLE
    }

    assert(type(record.frequency) == "number", "logic error in define_sound")

    return record
end

return module
