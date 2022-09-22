local utils = require("Buffer.Misc.Utils")
local language

local file_path = "Buffer/Bindings.json"

local input_manager, active_device, input_device
local key_bindings, btn_bindings
local modules = {}

local bindings = {
    btns = {},
    keys = {}
}

local popup = {}

-- Init the bindings module
function bindings.init(module_list)
    modules = module_list

    language = require("Buffer.Misc.Language")

    bindings.load_from_file()

    key_bindings = utils.generate_enum("via.hid.KeyboardKey")
    btn_bindings = utils.generate_enum("via.hid.GamePadButton")

    -- Testing
    -- bindings.add(1, {8192, 1024}, "miscellaneous.ammo_and_coatings.unlimited_ammo", true) -- R3 + R1
    -- bindings.add(1, {4096}, "great_sword.charge_level", 3) -- R3

    -- bindings.add(3, {8, 80}, "miscellaneous.ammo_and_coatings.unlimited_ammo", true) -- BACKSPACE + P
end

-- 1 = Gamepad | 2 = Mouse | 3 = Keyboard
function bindings.get_device()
    if not input_manager then input_manager = sdk.get_managed_singleton("snow.StmInputManager") end
    if not input_manager then return 0 end
    if not active_device then active_device = input_manager:get_field("_ActiveDevice") end
    if not active_device then return 0 end
    if not input_device then input_device = input_manager:get_field("_InGameInputDevice") end
    if not input_device then return 0 end
    return active_device:get_field("_ActiveDevice")
end

-- Add a new binding
-- If device is gamepad(1)
-- If device is mouse(2)
-- If device is a keyboard(3)
function bindings.add(device, input, path, on)
    local binding_table = nil
    if device == 1 then
        binding_table = bindings.btns
    elseif device == 3 then
        binding_table = bindings.keys
    end
    if binding_table then
        table.insert(binding_table, {
            ["input"] = input,
            ["data"] = {
                path = path,
                on = on
            }
        })
        bindings.save_to_file()
    end
end
-- Remove a binding from the device's table (Sometimes doesn't work... will need to debug)
function bindings.remove(device, index)
    local binding_table = nil
    if device == 1 then
        binding_table = bindings.btns
    elseif device == 3 then
        binding_table = bindings.keys
    end
    if binding_table then
        table.remove(binding_table, index)
        bindings.save_to_file()
    end
end

-- ======== File Stuff ===========
function bindings.load_from_file()
    local file = json.load_file(file_path)
    if file then
        bindings.btns = file.btns or {}
        bindings.keys = file.keys or {}
    end
end

-- Save the bindings to a file
function bindings.save_to_file()
    json.dump_file(file_path, {
        ['keys'] = bindings.keys,
        ['btns'] = bindings.btns
    })
end

-- ======= Gamepad ==========

-- Because the game combines button inputs into a single number we need to split it back up
function bindings.get_btns_from_code(code, withName)

    -- If the code is a single btn
    local btns = {}
    while code > 0 do
        local largest = {
            code = 0
        }

        for k, v in pairs(btn_bindings) do
            if v <= code and v > largest.code then
                largest = {
                    name = k,
                    code = v
                }
            end
        end

        -- If we couldn't find a bigger code, then we must have all the possible ones
        if largest.code == 0 then break end

        -- Remove the largest and add it to the list of btns
        code = code - largest.code
        if withName then
            btns[largest.name] = largest.code
        else
            table.insert(btns, largest.code)
        end
    end
    if #btns > 0 then return btns end
    return {}
end

-- Get current buttons pressed
function bindings.get_current_buttons()
    local current = input_device:get_field("_pad_on")
    return bindings.get_btns_from_code(current)
end

-- Are the buttons pressed
function bindings.is_buttons_pressed(arr_btns)

    local current = input_device:get_field("_pad_on")
    current = bindings.get_btns_from_code(current)
    local previous = input_device:get_field("_pad_oldon")
    previous = bindings.get_btns_from_code(previous)

    -- if current has all buttons needed, and old has all but one, then return true
    local matches = 0
    for _, required_code in pairs(arr_btns) do
        local found = false
        for _, current_code in pairs(current) do if current_code == required_code then found = true end end
        for _, previous_code in pairs(previous) do
            if previous_code == required_code then
                found = true
                matches = matches + 1
            end
        end
        if not found then return false end
    end

    return matches + 1 == #arr_btns
end

-- Are the buttons down
function bindings.is_buttons_down(arr_btns)
    local current = input_device:get_field("_pad_on")
    current = bindings.get_btns_from_code(current)

    local matches = 0
    for _, required_code in pairs(arr_btns) do
        local found = false
        for _, current_code in pairs(current) do if current_code == required_code then found = true end end
        if not found then return false end
    end
    return true
end

-- Get the enum name of the button
function bindings.get_btn_name(code)
    -- If the code is a single btn
    for k, v in pairs(btn_bindings) do if v == code then return k end end
    local btns = bindings.get_btns_from_code(code, true)
    local btn_names = {}
    for name, code in pairs(btns) do table.insert(btn_names, name) end
    if #btns > 0 then return btn_names end
    return "Unknown"
end

-- ======= Keyboard ==========

-- Get current keys down
function bindings.get_current_keys()
    local current = input_device:get_field("_kbd_on")
    local keys = {}
    for i = 1, #current do if current[i] and current[i]["mValue"] and current[i].mValue == true then table.insert(keys, i) end end
    return keys
end

-- Are the keys pressed
function bindings.is_keys_pressed(arr_keys)
    local current = input_device:get_field("_kbd_on")
    local triggered = input_device:get_field("_kbd_trg")

    -- Keep track of correct inputs
    local total = #arr_keys

    -- Check currently on
    local on = 0
    for _, v in pairs(arr_keys) do if current[v] and current[v]["mValue"] and current[v].mValue == true then on = on + 1 end end

    -- Check currently triggered
    local trig = 0
    for _, v in pairs(arr_keys) do if triggered[v] and triggered[v]["mValue"] and triggered[v].mValue == true then trig = trig + 1 end end

    if trig == 0 then return false end
    return on == #arr_keys
end

-- Are the keys currently down
function bindings.is_keys_down(arr_keys)
    local current = input_device:get_field("_kbd_on")
    local on = 0
    for _, v in pairs(arr_keys) do if current[v] and current[v]["mValue"] and current[v].mValue == true then on = on + 1 end end
    return on == #arr_keys
end

-- Get the enum name of the key
function bindings.get_key_name(key)
    for k, v in pairs(key_bindings) do if v == key then return k end end
    return "Unknown"
end

-- =========================================

-- Checks the bindings
function bindings.update()
    local device = bindings.get_device()
    if device == 1 then
        -- log.debug(json.dump_string(bindings.get_current_buttons()))
        for btn, input_data in pairs(bindings.btns) do if bindings.is_buttons_pressed(input_data.input) then bindings.perform(input_data.data) end end
    elseif device == 3 then
        -- log.debug(json.dump_string(bindings.get_current_keys()))
        for key, input_data in pairs(bindings.keys) do if bindings.is_keys_pressed(input_data.input) then bindings.perform(input_data.data) end end
    end
    bindings.popup_update()

end

-- Draw anything the bindings need
function bindings.draw()
    bindings.popup_draw()
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

    if #path == 2 then -- Example: character.sharpness
        if type(on_value) == "boolean" then
            modules[module_index][path[2]] = not modules[module_index][path[2]]
        elseif type(on_value) == "number" then
            if modules[module_index][path[2]] == -1 then
                modules[module_index][path[2]] = on_value
            else
                modules[module_index][path[2]] = -1
            end
        end
    elseif #path == 3 then -- Example: miscellaneous.ammo_and_coatings.unlimited_ammo
        if type(on_value) == "boolean" then
            modules[module_index][path[2]][path[3]] = not modules[module_index][path[2]][path[3]]
        elseif type(on_value) == "number" then
            if modules[module_index][path[2]][path[3]] == -1 then
                modules[module_index][path[2]][path[3]] = on_value
            else
                modules[module_index][path[2]][path[3]] = -1
            end
        end
    elseif #path == 4 then-- Example: character.conditions_and_blights.blights.fire
        if type(on_value) == "boolean" then
            modules[module_index][path[2]][path[3]][path[4]] = not modules[module_index][path[2]][path[3]][path[4]]
        elseif type(on_value) == "number" then
            if modules[module_index][path[2]][path[3]][path[4]] == -1 then
                modules[module_index][path[2]][path[3]][path[4]] = on_value
            else
                modules[module_index][path[2]][path[3]][path[4]] = -1
            end
        end
    end
end
-- ================= Popup =====================

-- Popup updating function
function bindings.popup_update()
    if popup.open then
        if popup.listening then
            local current = popup.device == 1 and bindings.get_current_buttons() or bindings.get_current_keys()
            if #current > 0 then
                if not popup.binding then popup.binding = {} end
                for _, pressed_btn in pairs(current) do
                    local in_list = false
                    for _, binding_btn in pairs(popup.binding) do if binding_btn == pressed_btn then in_list = true end end
                    if not in_list then table.insert(popup.binding, pressed_btn) end
                end
            elseif #current == 0 and popup.binding and #popup.binding > 0 then
                popup.listening = false
            end
        end
    end
end

-- Open the popup for the given device (1 = Gamepad, 3 = Keyboard)
function bindings.popup_open(device)
    bindings.popup_reset()
    popup.open = true
    popup.device = device
end

-- Close the popup and reset fields
function bindings.popup_close()
    imgui.close_current_popup()
    bindings.popup_reset()
end

-- Reset the popup fields
function bindings.popup_reset()
    popup = {
        open = false,
        device = 0,
        listening = false,
        path = nil,
        on = true,
        binding = {}
    }
end

-- Draw the popup
function bindings.popup_draw()
    if popup.open then
        local popup_size = Vector2f.new(350, 135)
        -- If a path has been chosen, make the window taller
        if popup.path ~= nil then popup_size.y = 175 end
        imgui.set_next_window_size(popup_size, 1 + 256)
        imgui.begin_window("buffer_bindings", nil, 1)
        imgui.indent(10)
        imgui.spacing()
        imgui.spacing()

        -- Change title depending on device
        if popup.device == 1 then
            imgui.text(language.get("window.bindings.add_gamepad"))
        else
            imgui.text(language.get("window.bindings.add_keyboard"))
        end
        imgui.separator()
        imgui.spacing()
        imgui.spacing()

        -- If no path has been chosen use the default text from the language file, otherwise display the path selected
        local bindings_text = language.get("window.bindings.choose_modification")
        if popup.path ~= nil then bindings_text = popup.path end
        if imgui.begin_menu(bindings_text) then
            for _, module in pairs(modules) do
                if imgui.begin_menu(language.get(module.title .. ".title")) then
                    bindings.popup_draw_menu(module, module.title)
                    imgui.end_menu()
                end
            end
            imgui.end_menu()
        end
        imgui.same_line()
        imgui.text("          ")
        imgui.spacing()

        -- If a path has been chosen show the option for the on value
        if popup.path ~= nil then
            imgui.spacing()

            -- On value for numbers - only allow numbers
            if type(popup.on) == "number" then
                imgui.text(language.get("window.bindings.on_value") .. ": ")
                imgui.same_line()
                local changed, on_value = imgui.input_text("     ", popup.on)
                if changed and on_value ~= "" and tonumber(on_value) then popup.on = tonumber(on_value) end

                -- On value for booleans, read only
            elseif type(popup.on) == "boolean" then
                imgui.text(language.get("window.bindings.on_value") .. ": ")
                imgui.same_line()
                imgui.input_text("   ", "true", 16384)
            end
            imgui.spacing()
            imgui.separator()
        end
        imgui.spacing()

        -- If not listening for inputs display default to listen from language file
        local listening_button_text = language.get("window.bindings.to_listen")

        -- If some inputs have been pressed, display them in a readable format
        if popup.binding and #popup.binding > 0 then
            listening_button_text = ""
            if popup.device == 1 then
                listening_button_text = bindings.get_btn_name(popup.binding[1])
                for i = 2, #popup.binding do listening_button_text = listening_button_text .. " + " .. bindings.get_btn_name(popup.binding[i]) end
            else
                listening_button_text = bindings.get_key_name(popup.binding[1])
                for i = 2, #popup.binding do listening_button_text = listening_button_text .. " + " .. bindings.get_key_name(popup.binding[i]) end
            end
            if popup.listening then listening_button_text = listening_button_text .. " + ..." end

        -- If no inputs pressed use default listening from language file
        elseif popup.listening then
            listening_button_text = language.get("window.bindings.listening")
        end

        if imgui.button(listening_button_text) then
            popup.listening = true
            popup.binding = nil
        end
        imgui.separator()
        imgui.spacing()
        imgui.spacing()

        if imgui.button(language.get("window.bindings.cancel")) then bindings.popup_close() end
        if popup.path and popup.binding then
            imgui.same_line()
            if imgui.button(language.get("window.bindings.save")) then
                bindings.add(popup.device, popup.binding, popup.path, popup.on)
                bindings.popup_close()
            end
        end
        imgui.unindent(10)
        imgui.end_window()
    end
end

function bindings.popup_draw_menu(menu, language_path)
    menu = menu or modules
    language_path = language_path or ""

    for key, value in pairs(menu) do
        -- If value is a table, then go deeper in the menu
        if type(value) == "table" then
            if key ~= "hidden" then
                if imgui.begin_menu(language.get(language_path .. "." .. key .. ".title")) then
                    bindings.popup_draw_menu(value, language_path .. "." .. key)
                    imgui.end_menu()
                end
            end

            -- If the value is a boolean or number, display the key
        elseif type(value) == "boolean" or type(value) == "number" then
            if imgui.menu_item(language.get(language_path .. "." .. key), nil, false, true) then
                popup.path = language_path .. "." .. key
                if type(value) == "number" then popup.on = tonumber(1) end
                if type(value) == "boolean" then popup.on = true end
            end
        end
    end
end

return bindings
