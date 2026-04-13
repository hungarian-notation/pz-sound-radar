local module = {}

function module.buildingat(x, y, z)
    local square = getSquare(x, y, z)

    if square ~= nil then
        local building = square:getBuildingDef()

        if building ~= nil then
            return building:getID()
        end
    end

    return nil
end

return module
