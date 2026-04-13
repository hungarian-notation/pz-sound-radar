---@class hfs.HorizonalRule : ISPanel
---@field hr_span number
---@field hr_color [number,number,number,number]
local HorizonalRule = ISPanel:derive("HorizontalLine")

---@param x number
---@param y number
---@param width number
---@param span number
---@param color [number,number,number,number]
function HorizonalRule:new(x, y, width, span, color)
    ---@type hfs.HorizonalRule
    local o = ISPanel.new(self, x, y, width, 2)
    o.hr_span = span
    o.hr_color = color or { 0.5, 0.5, 0.5, 0.5 }
    return o
end

function HorizonalRule.prerender() end

function HorizonalRule:render()
    local outer = (1 - self.hr_span) * self.width
    local left = outer / 2
    local r, g, b, a = unpack(self.hr_color)
    self:drawRect(left, 0, self.width * self.hr_span, 1, a, r, g, b)
end

local module = {
    HorizonalRule = HorizonalRule
}

return module
