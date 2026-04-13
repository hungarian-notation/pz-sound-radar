---@meta

---@class hfs.WorldSound<T>
---@field x int
---@field y int
---@field z int
---@field radius int
---@field volume int
---@field source T

---@class hfs.WSClassifier
---@field discriminator     hfs.WSTagger
---@field style             hfs.Style
---@field duration          number
---@field callback_test?    Scope.Entry.TestFunction
---@field callback_update?  Scope.Entry.UpdateFunction


---@alias hfs.WorldSoundClassifierFunction<T> fun(hfs.WorldSound & { player?: IsoPlayer }): hfs.WSClassifier
