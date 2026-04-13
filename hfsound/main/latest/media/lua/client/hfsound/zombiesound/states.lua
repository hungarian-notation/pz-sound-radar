local module = {}

-- https://docs.google.com/spreadsheets/d/1by0DMd_VuVC3HBs-CaJ1f3UOfa9GDt-ttDgvJz65eO0/view?gid=1008512841

---@type { [string]: hfs.StateCategory }
module.ZOMBIE_STATES = {
    FakeDeadAttackState               = "silent",
    FakeDeadZombieState               = "silent",
    ZombieFallingState                = "silent",
    ZombieSittingState                = "silent",
    ZombieTurnAlerted                 = "silent",
    ThumpState                        = "silent", -- thumps are world sounds
    IdleState                         = "idle",
    ZombieEatBodyState                = "idle",
    ZombieFaceTargetState             = "idle",
    ZombieGenericState                = "idle",
    ZombieIdleState                   = "idle",
    ZombieOnGroundState               = "idle",
    ZombieRagdollOnGroundState        = "idle",
    ZombieReanimateState              = "idle",
    BumpedState                       = "stumble",
    GrappledThrownIntoContainerState  = "stumble",
    GrappledThrownOutWindowState      = "stumble",
    GrappledThrownOverFenceState      = "stumble",
    StaggerBackState                  = "stumble",
    VehicleCollisionMinorStaggerState = "stumble",
    VehicleCollisionOnGroundState     = "stumble",
    VehicleCollisionState             = "stumble",
    ZombieFallDownState               = "stumble",
    ZombieGetDownState                = "stumble",
    ZombieGetUpFromCrawlState         = "stumble",
    ZombieGetUpState                  = "stumble",
    ZombieHitReactionState            = "stumble",
    CrawlingZombieTurnState           = "walk",
    PathFindState                     = "walk",
    WalkTowardNetworkState            = "walk",
    WalkTowardState                   = "walk",
    ClimbOverFenceState               = "clamber",
    ClimbThroughWindowState           = "clamber",
    AttackNetworkState                = "attack",
    AttackState                       = "attack",
    AttackVehicleState                = "attack",
    LungeNetworkState                 = "attack",
    LungeState                        = "attack",
}

---@param state IsoZombie | string
---@return hfs.StateCategory
function module.getcategory(state)
    if state == nil then
        return "silent"
    elseif type(state) == "string" then
        local found = module.ZOMBIE_STATES[state]
        if found ~= nil then
            return found
        else
            return "idle"
        end
    else
        return module.getcategory(state:getCurrentStateName())
    end
end

return module
