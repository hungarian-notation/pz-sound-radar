local colorcars = require('hfsound/worldsound/_impl/_automotive')
local defs = require('hfsound/worldsound/_impl/_definitions')

local module = {}


---@param ws hfs.WorldSound<IsoZombie>
---@return hfs.WSClassifier
function module.classify_zombie(ws)
    local source = ws.source

    if (source:getCurrentStateName() == "ThumpState") then
        local target = source:getThumpTarget()

        if instanceof(target, "IsoDoor") then
            ---@cast target IsoDoor
            local sound = target:getThumpSound()

            if sound == "ZombieThumpGarageDoor" then
                return defs.classifier.THUMP_GARAGE
            end

            return defs.classifier.THUMP_DOOR
        end

        if instanceof(target, "IsoWindow")
            or instanceof(target, "IsoWindowFrame")
        then
            return defs.classifier.THUMP_WINDOW
        end

        if instanceof(target, "IsoThumpable") then
            -- FIXME: fence icon
        end

        return defs.classifier.THUMP
    else
        return defs.classifier.ZOMBIE
    end
end


---@param ws hfs.WorldSound<nil> | hfs.WorldSound<nil> & { player: IsoPlayer }
function module.classify_null(ws)
    local radius = ws.radius
    local volume = ws.volume
    local x, y, z = ws.x, ws.y, ws.z

    print(string.format("null world sound: %f, %f, %f; radius=%f; volume=%f", x, y, z, radius, volume))

    if ws.player then
        local player = ws.player
        local px = player:getX()
        local py = player:getY()
        local distance = IsoUtils.DistanceTo(x, y, px, py)
        print(string.format("    player at: %f", distance))
    end

    if radius == 500 and volume == 500 then
        print("    returning HELICOPTER")
        return defs.classifier.HELICOPTER
    end

    if radius == 600 and volume == 600 then
        print("    returning GUNSHOT")
        return defs.classifier.GUNSHOT
    end

    if radius == 5000 and volume == 5000 then
        print("    returning THUNDER")
        return defs.classifier.THUNDER
    end

    local square = getWorld():getCell():getGridSquare(x, y, z)

    if square ~= nil then
        local specials = square:getSpecialObjects()
        local items = square:getWorldObjects()
        local window = square:getWindow()

        if window ~= nil and items:size() == 0 and specials:size() == 0 then
            print("    returning WINDOW_SMASHED")
            return defs.classifier.WINDOW_SMASHED
        end
    end

    return defs.classifier.UNKNOWN
end

---@param _ws hfs.WorldSound<unknown>
---@return hfs.WSClassifier
function module.classify_fallback(_ws)
    return defs.classifier.UNKNOWN
end

---@param ws hfs.WorldSound<BaseVehicle>
---@return hfs.WSClassifier
function module.classify_vehicle(ws)
    --0.66 * GameTime.getInstance().getDeltaMinutesPerDay()
    -- print(radius, " ", volume, " ", source)

    if ws.radius == 150 and ws.volume == 150 then
        return colorcars.getalarmclassifier()
    else
        return colorcars.getclassifier(ws.source:getColorHue(), ws.source:getColorSaturation(), ws.source:getColorValue())
    end
end

return module
