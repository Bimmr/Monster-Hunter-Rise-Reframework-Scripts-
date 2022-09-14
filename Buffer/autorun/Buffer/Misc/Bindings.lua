local utils = require("Buffer.Misc.Utils")
local input_manager, active_device, input_device

local bindings = {
    btns = {},
    keys = {}
}
local modules = {}

function bindings.init(module_list)
    modules = module_list

    input_manager = sdk.get_managed_singleton("snow.StmInputManager")
    active_device = input_manager:get_field("_ActiveDevice")
    input_device = input_manager:get_field("_InGameInputDevice")

    -- Testing
    bindings.add(1, 8192, "miscellaneous.ammo_and_coatings.unlimited_ammo", true) -- R3
    bindings.add(3, 80, "miscellaneous.ammo_and_coatings.unlimited_ammo", true) -- P
end

function bindings.add(device, keyNum, path, on)
    if device == 1 then
        bindings.btns[keyNum] = {
            path = path,
            modifiers = nil,
            on = on
        }
    elseif device == 3 then
        bindings.keys[keyNum] = {
            path = path,
            modifiers = nil,
            on = on
        }
    end
end

-- 1 = Gamepad | 2 = Mouse | 2 = Keyboard
function bindings.get_device()
    return active_device:get_field("_ActiveDevice")
end

-- ======= Gamepad ==========

-- Get current button push
function bindings.get_current_buttons()
    return {input_device:get_field("_pad_on")}
end
-- Is the button down
function bindings.is_button_down(btn)
    local current = input_device:get_field("_pad_on")
    if current == btn then return true end
    return false
end
-- Was the button pressed
function bindings.is_button_pressed(btn)
    local triggered = input_device:get_field("_pad_trg")
    if triggered == btn then return true end
    return false
end

-- ======= Keyboard ==========

-- Get current key push
function bindings.get_current_keys()
    local current = input_device:get_field("_kbd_on")
    local keys = {}
    for i = 1, #current do
        if current[i] and current[i]["mValue"] and current[i].mValue == true then table.insert(keys, i) end
    end
    return keys
end

-- Is the key down
function bindings.is_key_down(key)
    local current = input_device:get_field("_kbd_on")[key]
    if current[key] and current[key]["mValue"] and current[key].mValue == true then return true end
    return false
end

-- Is the key pressed
function bindings.is_key_pressed(key)
    local triggered = input_device:get_field("_kbd_trg")
    if triggered[key] and triggered[key]["mValue"] and triggered[key].mValue == true then return true end
    return false
end

-- =========================================

-- Checks the bindings
function bindings.update()
    local device = bindings.get_device()
    if device == 1 then
        -- log.debug(json.dump_string(bindings.get_current_buttons()))
        for btn, data in pairs(bindings.btns) do if bindings.is_button_pressed(btn) then bindings.perform(data) end end
    elseif device == 3 then
        -- log.debug(json.dump_string(bindings.get_current_keys()))
        for key, data in pairs(bindings.keys) do if bindings.is_key_pressed(key) then bindings.perform(data) end end
    end
end

-- Perform the changes
function bindings.perform(data)
    local path = utils.split(data.path, ".")
    local on_value = data.on

    -- Find module
    local module_index
    for key, value in pairs(modules) do if modules[key].title == path[1] then module_index = key end end

    -- I have to do it this way because otherwise it changes it by value and not by reference which means the module remains unchanged...
    --     unless Lua has another option I don't know about - I'm open to suggestions
    if #path == 2 then
        if type(on_value) == "boolean" then
            modules[module_index][path[2]] = not modules[module_index][path[2]]
        elseif type(on_value) == "int" then
            if modules[module_index][path[2]] > -1 then
                modules[module_index][path[2]] = on_value
            else
                modules[module_index][path[2]] = -1
            end
        end
    elseif #path == 3 then
        if type(on_value) == "boolean" then
            modules[module_index][path[2]][path[3]] = not modules[module_index][path[2]][path[3]]
            log.debug("Value Changed")
        elseif type(on_value) == "int" then
            if modules[module_index][path[2]][path[3]] > -1 then
                modules[module_index][path[2]][path[3]] = on_value
            else
                modules[module_index][path[2]][path[3]] = -1
            end
        end
    elseif #path == 4 then
        if type(on_value) == "boolean" then
            modules[module_index][path[2]][path[3]][path[4]] = not modules[module_index][path[2]][path[3]][path[4]]
            log.debug("Value Changed")
        elseif type(on_value) == "int" then
            if modules[module_index][path[2]][path[3]][path[4]] > -1 then
                modules[module_index][path[2]][path[3]][path[4]] = on_value
            else
                modules[module_index][path[2]][path[3]][path[4]] = -1
            end
        end
    end
end

return bindings
