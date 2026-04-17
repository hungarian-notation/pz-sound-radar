---defines a mapping of `hfs.WorldSound` instances to uids
---@alias hfs.WSTagger fun(struct:hfs.WorldSound): string | nil


---higher order function that applies a prefix to a uid produced by a secondary
---tagger
---@param ns string
---@param tagger hfs.WSTagger
---@return hfs.WSTagger
local function ns_tagger(ns, tagger)
    return function(s)
        return string.format("%s:%s", ns, tagger(s)) --[[@as string]]
    end
end

-- ---@type hfs.WSTagger
-- local TAGGER_NOP = function(_) return nil end

---@type hfs.WSTagger
local TAGGER_UID = function(s)
    assert(instanceof(s.source, "IsoMovingObject"))
    return s.source:getUID() --[[@as string]]
end

---@param prefix string
---@return hfs.WSTagger
local function nsuid_tagger(prefix) return ns_tagger(prefix, TAGGER_UID) end

---
---@type fun(type:string): hfs.WSTagger
local positional_tagger = function(prefix)
    ---@param s hfs.WorldSound
    return function(s)
        return string.format("%s-%d-%d-%d", prefix, s.x, s.y, s.z)
    end
end

local lib = {
    -- noop       = TAGGER_NOP,
    uid        = TAGGER_UID,
    ns         = ns_tagger,
    nsuid      = nsuid_tagger,
    positional = positional_tagger,
}

return lib
