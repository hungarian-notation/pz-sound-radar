

--[[
    This function creates a closure which evaluates an axis-aligned
    rectangular hyperbola with a horizontal asymptote at y=`asymptote` which
    passes through the points {`ax`,`ay`} and {`bx`,`by`}

    https://www.geogebra.org/calculator/t5bw3rxh
--]]
local function TwoPointHorizon(ax, ay, bx, by, asymptote)
    local common_factor = (-ay + by) / (asymptote - by)
    local numer_factor = asymptote - ay
    local denom_addend = bx - ax

    return function(x)
        local common_term = common_factor * (x - ax)
        return ay + (common_term * numer_factor) / (common_term + denom_addend)
    end
end

local function twopointhrz(ax, ay, bx, by, asymptote, x)
    local common_factor = (-ay + by) / (asymptote - by)
    local common_term = common_factor * (x - ax)
    return ay + (common_term * (asymptote - ay)) / (common_term + bx - ax)
end


--[[
    In this version, you specify the intersection between the asymptotes, as 
    well as one point on the hyperbola.
--]]
local function HyperbolaCenterPoint(c, d, a, b)
    return function(x)
        return b + (b * x - b * a - d * x + d * a) / (c - x)
    end
end

local function centerpoint(c, d, a, b, x)
    return b + (b * x - b * a - d * x + d * a) / (c - x)
end

local module = {
    functional_twopointhorizon = TwoPointHorizon,
    functional_centerpoint = HyperbolaCenterPoint,
    twopointhorizon = twopointhrz,
    centerpoint = centerpoint,
}

return module
