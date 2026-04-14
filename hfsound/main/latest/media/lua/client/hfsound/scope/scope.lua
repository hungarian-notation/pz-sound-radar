local Entry         = require('hfsound/scope/entry')
local ScopeRenderer = require('hfsound/scope/renderer')

local xmath         = require('hfsound/math')
local dev           = require("hfsound/dev")
local ilerp         = xmath.ilerp
local lerp_clamped  = xmath.lerp_clamped

---@class hfs.Scope
---@field overwhelm number
---@field overwhelm_clamped number
local Scope         = {}; Scope.__index = Scope

---@param player integer
function Scope.new(player)
    local obj = setmetatable({}, Scope)

    obj.m_player_index = player
    obj.renderer = ScopeRenderer.ScopeRenderer.new { player = player, }

    --- holds all entry instances for the scope
    ---@type hfs.ScopeEntry[]
    obj.m_entries = table.newarray and table.newarray() or {}

    --- maps uids to indices in _entries
    ---
    ---@type { [string]: integer }
    obj.m_uidmap = {}

    ---@type hfs.ScopeContext | nil
    obj.m_context = nil
    obj.m_drawn_entries = 0
    obj.overwhelm = 0.0 --[[@as number]]
    obj.overwhelm_clamped = 0.0

    obj.m_perf_perframe = dev.PerfTimer.new("Scope:Render")
    obj.m_perf_perentry = dev.PerfTimer.new("Scope:Render:Each")
    obj.m_perf_peractive = dev.PerfTimer.new("Scope:Render:Each(Active)")

    return obj
end

function Scope:player()
    return getSpecificPlayer(self.m_player_index)
end

---@return hfs.ScopeContext
function Scope:create_context()
    local player = self:player()
    local building = player:getCurrentBuildingDef() --[[@as BuildingDef?]]

    local building_id = building and building:getID() or nil

    ---@type hfs.ScopeContext
    local context = {
        scope           = self,
        renderer        = self.renderer,
        player          = player,
        hearing         = 1.0,
        x               = player:getX(),
        y               = player:getY(),
        z               = player:getZ(),
        player_building = building_id,
        t               = os.time()
    }

    if player:hasTrait(CharacterTrait.DEAF) then
        context.hearing = 0.0
    elseif player:hasTrait(CharacterTrait.KEEN_HEARING) then
        context.hearing = HFSOUND.hearing.KEEN_HEARING
    elseif player:hasTrait(CharacterTrait.HARD_OF_HEARING) then
        context.hearing = HFSOUND.hearing.HARD_OF_HEARING
    else
        context.hearing = HFSOUND.hearing.NORMAL
    end

    self.m_context = context

    return context
end

---@param dt number
function Scope:update(dt)
    self:update_entries(dt)
    self:update_overwhelm(dt)
    self.renderer:update()
end

---@param dt number
function Scope:update_entries(dt)
    local context = self:create_context()

    for i = 1, #self.m_entries do
        local entry = self.m_entries[i]

        if not entry.m_extinct then
            entry.m_age = entry.m_age + dt
            -- extinct after duration
            if entry.m_age >= entry.m_duration then
                self:exterminate(i, entry)
            elseif entry.m_callback_test ~= nil and not entry:m_callback_test(context) then
                -- extinct based on lifecycle predicate
                self:exterminate(i, entry)
            elseif entry.m_callback_update ~= nil then
                entry:m_callback_update(context)
            end
        end
    end
end

---@private
---@param i number
---@param entry hfs.ScopeEntry
function Scope:exterminate(i, entry)
    if entry.m_uid ~= nil then
        assert(self.m_uidmap[entry.m_uid] == i, "exhausted entry not at mapped index")
        self.m_uidmap[entry.m_uid] = nil
    end

    entry:reset()
end

---@param dt number
function Scope:update_overwhelm(dt)
    self.overwhelm_goal = math.max(0, ilerp(10, 40, self.m_drawn_entries)) -- only clamped > 0
    local overwhelm     = lerp_clamped(self.overwhelm, self.overwhelm_goal, dt * 2)

    if math.abs(self.overwhelm_goal - self.overwhelm) > 0.01 then
        self.overwhelm = overwhelm
    else
        self.overwhelm = self.overwhelm_goal
    end

    self.overwhelm_clamped = math.min(1, self.overwhelm)

    -- print()
    -- print(self.m_drawn_entries)
    -- print(self.overwhelm_goal)
    -- print(self.overwhelm)
end

---retrieves the active entry for the given uid if such an entry exists
---@param uid string
---@return hfs.ScopeEntry | nil
function Scope:retrieve(uid)
    local index = self.m_uidmap[uid]
    if index ~= nil then
        -- if the uid is in the indices map, we should have guarantees that the
        -- entry still exists and is not exhausted
        local indexed = self.m_entries[index]
        assert(indexed ~= nil)
        assert(not indexed.m_extinct)
        return indexed
    else
        return nil
    end
end

---@param uid? string
---@param classifier hfs.WSClassifier
---@param worldSound hfs.WorldSound
function Scope:offerworldsound(uid, classifier, worldSound)
    if
        worldSound.source ~= nil
        and instanceof(worldSound.source, "IsoPlayer")
        and worldSound.source:equals(self:player())
    then
        return
    end

    return self:offer(Entry.setworldsound, uid, classifier, worldSound)
end

---@param uid? string
---@param classifier hfs.ZombieSound
---@param zombie IsoZombie
function Scope:offerzombiesound(uid, classifier, zombie)
    return self:offer(Entry.setzombiesound, uid, classifier, zombie)
end

---@alias hfs.ScopeOfferHandler fun(entry: hfs.ScopeEntry, uid:string|nil, ...):boolean

---@private
---@param tryInit hfs.ScopeOfferHandler
---@param uid string?
function Scope:offer(tryInit, uid, ...)
    if uid ~= nil then
        local existing = self:retrieve(uid)
        if existing ~= nil then
            local success = tryInit(existing, uid, ...)
            if success and existing.m_style.init ~= nil then
                existing.m_style:init(self.renderer)
            end
            return existing
        end
    end

    -- either uid is nil or its not currently represented by this scope
    local i, entry = self:free_entry()
    local success = tryInit(entry, uid, ...)
    assert(success, "tryInit should not fail on novel/refurbished Entry")

    if entry.m_style.init ~= nil then
        entry.m_style:init(self.renderer)
    end

    if uid ~= nil then
        self.m_uidmap[uid] = i
    end
    return entry
end

---@private
function Scope:free_entry()
    for i, entry in ipairs(self.m_entries) do
        if entry.m_extinct then
            return i, entry
        end
    end
    local entry = Entry.new()
    local i = #self.m_entries + 1
    self.m_entries[i] = entry
    return i, entry
end

function Scope:everyoneminute()
    if getDebug() then
        self.m_perf_perframe:report(true)
        self.m_perf_perentry:report(true)
        self.m_perf_peractive:report(true)
    end
end

function Scope:render()
    self.m_perf_perframe:enter()
    local hearing_transbuilding = HFSOUND.hearing.THROUGH_EXTERIOR_WALL
    local context = self:create_context()
    local hearing = context.hearing

    if hearing <= 0.0 then
        return -- why are you even running this mod if you're taking the deaf perk
    end

    local px = context.x
    local py = context.y
    local pz = context.z
    local player_building = context.player_building
    local kw = { context = context }
    local count = 0

    for _i, entry in ipairs(self.m_entries) do
        self.m_perf_perentry:enter()
        if not entry.m_extinct then
            kw.zdiff              = entry.m_z - pz

            local distance_xy     = IsoUtils.DistanceTo(px, py, entry.m_x, entry.m_y)
            local distance_z      = math.abs(kw.zdiff)
            local distance        = distance_xy + distance_z * 2
            local effectiveRadius = entry.m_radius * hearing


            if distance < effectiveRadius then
                self.m_perf_peractive:enter()

                if entry.m_building_attenuated then
                    local building = entry.m_building
                    if (building ~= player_building) then
                        effectiveRadius = effectiveRadius * hearing_transbuilding
                        kw.transbuilding = true
                    else
                        kw.transbuilding = false
                    end
                else
                    kw.transbuilding = false
                end

                -- TODO atan2 is expensive

                -- Theoretically, we could refactor this to only pass a
                -- normalized vector around. The problem is that
                local theta = math.atan2(entry.m_y - py, entry.m_x - px)

                kw.entry = entry
                kw.distance = distance
                kw.radius = effectiveRadius
                kw.theta = theta

                entry.m_style.render(entry.m_style, kw)
                count = count + 1

                self.m_perf_peractive:exit()
            end
        end

        -- XXX: Should we do something about old entries?
        --[[
            If the player goes into louisville and then leaves, the scope will
            forever be looping over a tail end of tons of deactivated entries.
        --]]
        self.m_perf_perentry:exit()
    end

    self.m_drawn_entries = count
    self.m_perf_perframe:exit()
end

return Scope
