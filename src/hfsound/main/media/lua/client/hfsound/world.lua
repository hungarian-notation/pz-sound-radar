local module             = {}

local META_CELL_CHUNKS   = 32
local META_CHUNK_SQUARES = 8
local META_CELL_SQUARES  = 256

local fast_floor         = PZMath.fastfloor

local function tile_to_chunk(x, y)
    return fast_floor(x / META_CHUNK_SQUARES), fast_floor(y / META_CHUNK_SQUARES)
end

local function tile_to_cell(x, y)
    return fast_floor(x / META_CELL_SQUARES), fast_floor(y / META_CELL_SQUARES)
end

module.tile_to_chunk = tile_to_chunk
module.tile_to_cell = tile_to_cell

return module
