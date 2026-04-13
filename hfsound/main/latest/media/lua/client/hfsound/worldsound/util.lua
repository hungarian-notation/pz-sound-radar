local util = {}

---@param character IsoGameCharacter
---@param vehicle BaseVehicle
---@return boolean
function util.is_passenger_in(character, vehicle)
    for i = 0, 5 do
        local occupant = vehicle:getCharacter(i)
        if occupant == character then
            return true
        end
    end

    return false
end

return util
