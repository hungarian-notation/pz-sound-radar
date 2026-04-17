local scopeutil = {}

--- An entry update function that sticks the sound event to a moving object,
--- rather than the position the object was in when the sound was triggered.
---@param entry hfs.ScopeEntry
---@param _context hfs.ScopeContext
function scopeutil.callback_followsource(entry, _context)
    local source = entry.m_source

    if not instanceof(source, "IsoObject") then
        print("warning: updateMoving called on non-IsoObject: ", entry.m_uid)
        entry.m_callback_update = nil
        return
    end

    ---@cast source IsoObject
    entry.m_x = source:getX()
    entry.m_y = source:getY()
    entry.m_z = source:getZ()
end

return scopeutil
