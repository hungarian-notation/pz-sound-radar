--[[

    This module tracks the API of exposed globals for changes from expected
    values. 
    
    In situations where we're doing weird things to volatile APIs, we can choose 
    to fall back to more future-proof behavior when we detect changes.

--]]

local module = {
    ---@enum (key) hfs.proprioception.surfaces
    surface = {
        MainOptions =
            "ControllerReload;OnGamepadConnect;OnGamepadDisconnect;" ..
            "addAccessibilityPanel;addButton;addColorButton;addCombo;" ..
            "addControllerPanel;addDescription;addDisplayPanel;addHorizontalLine;" ..
            "addHorizontalLineSmall;addKeybindingPanel;addMegaVolumeControl;" ..
            "addModOptionsPanel;addMultiplayerPanel;addPage;addSlider;" ..
            "addSoundPanel;addTextEntry;addTextPane;addTickBox;addTitle;addUIPanel;" ..
            "addVolumeControl;addVolumeIndicator;addYesNo;apply;centerChildrenX;" ..
            "centerKeybindings;centerTabChildrenX;close;create;doLanguageToolTip;" ..
            "getAvailableLanguage;getGeneralTranslators;getKeyPrefix;initialise;" ..
            "instantiate;joypadSensitivityM;joypadSensitivityP;keyPressHandler;" ..
            "loadKeys;new;onBadHighlightColor;onConfirmModalClick;" ..
            "onConfirmMonitorSettingsClick;onGainJoypadFocus;" ..
            "onGainJoypadFocusCurrentTab;onGameSounds;onGoodHighlightColor;" ..
            "onJoypadBeforeDeactivate;onJoypadBeforeDeactivateCurrentTab;" ..
            "onJoypadDownCurrentTab;onKeyBindingBtnPress;onKeyRelease;" ..
            "onKeybindChanged;onKeyboardLayoutChanged;onLoseJoypadFocusCurrentTab;" ..
            "onMPColor;onModColorPick;onMouseWheel;onMouseWheelCurrentTab;" ..
            "onNoTargetColor;onObjHighlightColor;onOptionMouseDown;" ..
            "onReloadGameSounds;onResolutionChange;onRestartRequiredClick;" ..
            "onTabsActivateView;onTargetColor;onWorldItemHighlightColor;" ..
            "pickedBadHighlightColor;pickedGoodHighlightColor;pickedMPTextColor;" ..
            "pickedModColor;pickedNoTargetColor;pickedObjHighlightColor;" ..
            "pickedTargetColor;pickedWorldItemHighlightColor;prerender;render;" ..
            "saveKeys;setResolutionAndFullScreen;showConfirmDialog;" ..
            "showConfirmMonitorSettingsDialog;showRestartRequiredDialog;sortModes;" ..
            "subPanelPreRender;subPanelRender;tableContains;toUI;upgradeKeysIni;" ..
            "writeKey;",
        ["PZAPI.ModOptions"] = "create;getOptions;load;save;",
        ["PZAPI.ModOptions.Options"] =
            "addButton;addColorPicker;addComboBox;addDescription;addKeyBind;" ..
            "addMultipleTickBox;addSeparator;addSlider;addTextEntry;addTickBox;" ..
            "addTitle;apply;getOption;new;",
    }
}

---@param tbl any
local function getsurfaceimpl(tbl)
    ---@type string[]
    local surface = {}
    for k, v in pairs(tbl) do
        if type(v) == "function" then
            table.insert(surface, string.format("%s;", tostring(k)))
        end
    end
    table.sort(surface)
    return surface
end

---@param tbl any
function module.getsurface(tbl)
    if type(tbl) == "table" then
        return table.concat(getsurfaceimpl(tbl), "")
    else
        return "-"
    end
end

---@param tbl any
function hfsound_dumpsurface(tbl)
    if type(tbl) == "string" then tbl = module.resolve_global(tbl) end

    local surface = getsurfaceimpl(tbl)
    local lines = {}
    local line = {}
    local linelength = 0

    local function endline()
        if #line > 0 then
            local nextline = string.format("\"%s\"", table.concat(line, ""))
            table.insert(lines, nextline)
            line = {}
            linelength = 0
        end
    end

    for _, feature in ipairs(surface) do
        if linelength > 0 and (linelength + #feature) > 70 then
            endline()
        end

        table.insert(line, feature)
        linelength = linelength + #feature
    end

    endline()

    print(table.concat(lines, " ..\n"))
end

function module.resolve_global(which)
    local object = _G
    local path = {}

    for word in string.gmatch(which --[[@as string]], '([^.]+)') do
        object = object[word]
        table.insert(path, word)
        if object == nil then
            return nil
        end
    end

    return object
end

---@param which hfs.proprioception.surfaces
local function checksurface(which)
    local object = module.resolve_global(which)
    local actual = module.getsurface(object)
    local known = module.surface[which]

    if actual ~= known then
        print()
        print("[proprioception]")
        print(which)
        print()
        print("expected:")
        print()
        print(known)
        print()
        print("actual:")
        print()
        hfsound_dumpsurface(object)
        print()
    end

    return known == actual
end

local function init()
    ---@type { [hfs.proprioception.surfaces]: bool }
    local checked = {}

    for k in pairs(module.surface) do
        checked[k] = checksurface(k)
    end

    return checked
end

module.cache = init()

---@param which hfs.proprioception.surfaces
function module.checksurface(which)
    return module.cache[which] == true
end

return module
