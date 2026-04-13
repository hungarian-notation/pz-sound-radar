if love == nil then return end

local inject_scope = _G --[[@as table]]

inject_scope.Core = inject_scope.Core or {}
inject_scope.Core.tileScale = 2
inject_scope.IsoUtils = inject_scope.IsoUtils or {}

function inject_scope.IsoUtils.XToScreen(objectX, objectY, _objectZ, _screenZ)
    local w, _h = love.graphics.getDimensions()
    local sx = 0.0
    sx = sx + objectX * (32 * Core.tileScale);
    return sx - objectY * (32 * Core.tileScale) + w / 2;
end

function inject_scope.IsoUtils.YToScreen(objectX, objectY, objectZ, screenZ)
    local _w, h = love.graphics.getDimensions()
    local sy = 0.0;
    sy = sy + objectY * (16 * Core.tileScale);
    sy = sy + objectX * (16 * Core.tileScale);
    return sy + (screenZ - objectZ) * (96 * Core.tileScale) + h / 2;
end

function inject_scope.getSquare(...) return nil end

function inject_scope.IsoUtils.DistanceTo(x1, y1, x2, y2)
    return math.sqrt(math.pow(math.abs(x2 - x1), 2) + math.pow(math.abs(y2 - y1), 2))
end

function inject_scope.isoToScreenX(_player, x, y, z)
    return IsoUtils.XToScreen(x, y, z, 0) - 0 --camera.getOffX()
end

function inject_scope.isoToScreenY(_player, x, y, z)
    return IsoUtils.YToScreen(x, y, z, 0) - 0 --camera.getOffY()
end

function inject_scope.Core.getZoom(...)
    return 1
end

function inject_scope.getCore() return inject_scope.Core end

function inject_scope.getDebug() return true end 

local inject_table = table --[[@as table]]

function inject_table.wipe(tbl)
    for k, _v in pairs(tbl) do
        tbl[k] = nil
    end
end

-- function inject_scope.instanceof(_obj, _type)

-- end
