local impl = require('hfsound/worldsound/_impl/_impl')
local defs = require('hfsound/worldsound/_impl/_definitions')

local module = {}

---@type ({ instanceof:string, classifier:(hfs.WSClassifier | hfs.WorldSoundClassifierFunction) })[]
module.array = {
    {
        instanceof = "IsoFire",
        classifier = defs.classifier.ISOFIRE,
    },
    {
        instanceof = "IsoZombie",
        classifier = impl.classify_zombie,
    },
    {
        instanceof = "BaseVehicle",
        classifier = impl.classify_vehicle,
    },
    {
        instanceof = "IsoAnimal",
        classifier = defs.classifier.ISOANIMAL,
    },
    {
        instanceof = "IsoPlayer",
        classifier = defs.classifier.ISOPLAYER,
    },
    {
        instanceof = "IsoSurvivor",
        classifier = defs.classifier.ISOSURVIVOR,
    },
    {
        instanceof = "Alarm",
        classifier = defs.classifier.ALARM,
    },
    {
        instanceof = "IsoTelevision",
        classifier = defs.classifier.ISOTELEVISION,
    },
    {
        instanceof = "IsoRadio",
        classifier = defs.classifier.ISORADIO,
    },
    {
        instanceof = "IsoObject",
        classifier = defs.classifier.ISOOBJECT,
    },
    {
        instanceof = "ClothingDryerLogic",
        classifier = defs.classifier.CLOTHINGDRYERLOGIC,
    },
    {
        instanceof = "ClothingWasherLogic",
        classifier = defs.classifier.CLOTHINGWASHERLOGIC,
    },
}

---@type { [string]: (hfs.WSClassifier | hfs.WorldSoundClassifierFunction) }
module.map = {}

---@param object any
---@return hfs.WSClassifier | hfs.WorldSoundClassifierFunction
function module.lookup(object)
    if object == nil then
        return impl.classify_null
    end

    ---@type { [string]: (hfs.WSClassifier | hfs.WorldSoundClassifierFunction)? }
    local map = module.map
    local typename = getClassSimpleName(object)

    if map[typename] then 
        return map[typename]
    else
        for _, v in ipairs(module.array) do
            if (v.instanceof == typename) or instanceof(object, v.instanceof) then
                print("novel world sound source: ", typename)
                map[typename] = v.classifier
                return v.classifier
            end
        end

        map[typename] = impl.classify_fallback --[[@as hfs.WorldSoundClassifierFunction]]
    end
end

---@class (partial) _HFSOUND
---@field worldsounds { [string]: (hfs.WSClassifier | hfs.WorldSoundClassifierFunction) }
HFSOUND = HFSOUND or {}
HFSOUND.worldsounds = module.map

return module
