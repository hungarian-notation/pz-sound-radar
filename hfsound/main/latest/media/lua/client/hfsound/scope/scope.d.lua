---@meta

if true then return end -- this source file contains type definitions only

---@alias hfs.StyleInitFn fun(
--- self: self,
--- renderer: hfs.ScopeRenderer
--- ): void

---@class hfs.Style
---@field init? hfs.StyleInitFn
local __Style = {}

---@class hfs.RenderKwargs
---@field context       hfs.ScopeContext
---@field entry         hfs.ScopeEntry
---@field theta         number
---@field distance      number
---@field radius        number effective radius
---@field zdiff         number
---@field transbuilding boolean

---@param kw hfs.RenderKwargs
function __Style:render(kw) end

---@class hfs.ScopeContext
---@field scope hfs.Scope
---@field renderer hfs.ScopeRenderer
---@field player IsoPlayer
---@field hearing number hearing factor to be multiplied against radius
---@field x number playerX
---@field y number playerY
---@field z number playerZ
---@field t number time in seconds from some time before the mod was first loaded
---@field player_building int?