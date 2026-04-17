---@meta

-- naming this hfs.Color caused my LSP to freak out and merge the definition
-- with java.awt.Color

---@interface hfs.Color
---@field desaturate fun(self, number): hfs.Color
---@field compute fun(self, hfs.RenderKwargs): number, number, number, number
