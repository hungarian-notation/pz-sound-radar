local wsutil                 = require('hfsound/worldsound/util')
local dispatch               = require('hfsound/worldsound/_impl/_dispatch')

-- #region class: WorldSoundClassifier

---@class hfs.WorldSoundClassifier
local WorldSoundClassifier   = {}; WorldSoundClassifier.__index = WorldSoundClassifier

---@class hfs.WorldSoundClassifier.Kwargs
---@field scope hfs.Scope

---@param kw hfs.WorldSoundClassifier.Kwargs
---@return hfs.WorldSoundClassifier
function WorldSoundClassifier.new(kw)
    local obj = setmetatable({}, WorldSoundClassifier)

    --- the arguments table passed to this instance's constructor
    obj.m_kwargs = kw
    obj.m_scope = kw.scope
    obj.m_player_index = obj.m_scope.m_player_index

    ---@type IsoPlayer?
    obj.m_player = nil

    return obj
end

function WorldSoundClassifier:update(_dt)
    self.m_player = getSpecificPlayer(self.m_player_index)
end

---@param x integer
---@param y integer
---@param z integer
---@param radius integer
---@param volume integer
---@param source Object
function WorldSoundClassifier:OnWorldSound(x, y, z, radius, volume, source)
    ---@type hfs.WorldSound & { player: IsoPlayer? }
    local worldsound = { x = x, y = y, z = z, radius = radius, volume = volume, source = source, player = self.m_player }

    local classified = self:classify_world_sound(worldsound)

    if classified then
        local uid = classified.discriminator(worldsound)
        self.m_scope:offerworldsound(uid, classified, worldsound)
    end
end

---@param worldsound hfs.WorldSound
---@return hfs.WSClassifier | nil
function WorldSoundClassifier:classify_world_sound(worldsound)
    if not self.m_player then
        return
    end

    local source = worldsound.source
    local radius = worldsound.radius
    local volume = worldsound.volume

    -- fail fast for some vehicles cases
    if instanceof(source, "BaseVehicle") then
        ---@cast source BaseVehicle

        if radius == 80 and volume < 20 then
            -- Filters out a weird long range sound that all running cars emit
            -- that only animals can hear. This is not a joke.
            return nil
        end

        if self.m_player and wsutil.is_passenger_in(self.m_player, source) then
            -- While this might be useful in cases where the car engine dies,
            -- we really don't want to spam the screen with our own car's
            -- engine noise.
            return nil
        end
    end

    -- if source ~= nil then

    local classifier = dispatch.lookup(source)

    if type(classifier) == "table" then
        return classifier
    end

    return classifier(worldsound)

    -- for _, v in ipairs(dispatch.array) do
    --     if (v.instanceof == name) or instanceof(source, v.instanceof) then
    --         ---@type hfs.WSClassifier | function | nil
    --         local classified = v.classifier

    --         if type(classified) == "function" then
    --             classified = classified(x, y, z, radius, volume, source) --[[@as hfs.WSClassifier | nil]]
    --         end

    --         if type(classified) == "table" then
    --             return classified
    --         end
    --     end
    -- end

    -- return classify.classify_fallback(x, y, z, radius, volume, source)
    -- else
    --     return classify.classify_null(x, y, z, radius, volume, nil)
    -- end
end

-- #endregion

local module = {
    WorldSoundClassifier = WorldSoundClassifier
}

return module
