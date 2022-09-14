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

    -- Testing
    bindings.add(1, 8192, "miscellaneous.ammo_and_coatings.unlimited_ammo", true) -- R3
    bindings.add(1, {16}, "miscellaneous.ammo_and_coatings.unlimited_ammo", true) -- Triangle
    bindings.add(3, {8, 80}, "miscellaneous.ammo_and_coatings.unlimited_ammo", true) -- P
end

-- 1 = Gamepad | 2 = Mouse | 2 = Keyboard
function bindings.get_device()
    if not active_device then
        active_device = input_manager:get_field("_ActiveDevice")
        input_device = input_manager:get_field("_InGameInputDevice")
    end
    return active_device:get_field("_ActiveDevice")
end

-- Add a new binding
-- If device is gamepad(1), input is an int
-- If device is mouse(2), do nothing currently
-- If device is a keyboard(3), input is an array of ints
function bindings.add(device, input, path, on)

    -- Gamepad will combine inputs to create a new number depending on the inputs, so we can just use that as a key
    if device == 1 then
        if type(input) == "table" then input = input[1] end
        bindings.btns[input] = {
            path = path,
            modifiers = nil,
            on = on
        }

        -- Keyboard uses an array of possible inputs, so we need to have an array of inputs and we can't use that as a key
    elseif device == 3 then
        table.insert(bindings.keys, {
            keys = input,
            data = {
                path = path,
                modifiers = nil,
                on = on
            }
        })
    end
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
    for i = 1, #current do if current[i] and current[i]["mValue"] and current[i].mValue == true then table.insert(keys, i) end end
    return keys
end

-- Is the key down
function bindings.is_keys_down(arr_keys)
    local current = input_device:get_field("_kbd_on")
    local result = true
    for _, v in pairs(arr_keys) do if current[v] and current[v]["mValue"] and not current[v].mValue == true then result = false end end
    return result
end

-- Is the key pressed
function bindings.is_keys_pressed(arr_keys)
    local current = input_device:get_field("_kbd_on")
    local triggered = input_device:get_field("_kbd_trg")

    -- Keep track of correct inputs
    local total = #arr_keys

    -- Check currently on
    local on = 0
    for _, v in pairs(arr_keys) do if current[v] and current[v]["mValue"] and  current[v].mValue == true then on = on + 1 end end

    -- Check currently triggered
    local trig = 0
    for _, v in pairs(arr_keys) do if triggered[v] and triggered[v]["mValue"] and  triggered[v].mValue == true then trig = trig + 1 end end

    if trig == 0 then return false end
    return on == #arr_keys
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
        for key, input_data in pairs(bindings.keys) do if bindings.is_keys_pressed(input_data.keys) then bindings.perform(input_data.data) end end
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
        elseif type(on_value) == "number" then
            if modules[module_index][path[2]] > -1 then
                modules[module_index][path[2]] = on_value
            else
                modules[module_index][path[2]] = -1
            end
        end
    elseif #path == 3 then
        if type(on_value) == "boolean" then
            modules[module_index][path[2]][path[3]] = not modules[module_index][path[2]][path[3]]
        elseif type(on_value) == "number" then
            if modules[module_index][path[2]][path[3]] > -1 then
                modules[module_index][path[2]][path[3]] = on_value
            else
                modules[module_index][path[2]][path[3]] = -1
            end
        end
    elseif #path == 4 then
        if type(on_value) == "boolean" then
            modules[module_index][path[2]][path[3]][path[4]] = not modules[module_index][path[2]][path[3]][path[4]]
        elseif type(on_value) == "number" then
            if modules[module_index][path[2]][path[3]][path[4]] > -1 then
                modules[module_index][path[2]][path[3]][path[4]] = on_value
            else
                modules[module_index][path[2]][path[3]][path[4]] = -1
            end
        end
    end
end

return bindings
