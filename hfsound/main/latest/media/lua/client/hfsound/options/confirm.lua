local module = {}

---@param text string
---@param onconfirm umbrella.ISButton.OnClick
---@param oncancel? umbrella.ISButton.OnClick
function module.show_confirm(text, onconfirm, oncancel)
    ---@param target unknown
    ---@param button ISButton
    local function onclick_wrapper(target, button, ...)
        if button.internal == "YES" then
            onconfirm(target, button, ...)
        elseif oncancel then
            oncancel(target, button, ...)
        end
    end

    local width, height = 350, 150
    local dialogX = getCore():getScreenWidth() / 2 - (width / 2)
    local dialogY = getCore():getScreenHeight() / 2 - (height / 2)

    local modal = ISModalDialog:new(dialogX, dialogY, width, height,
        text, true, nil,
        onclick_wrapper)

    modal:initialise()
    modal:addToUIManager()
    modal:setAlwaysOnTop(true)
end

return module
