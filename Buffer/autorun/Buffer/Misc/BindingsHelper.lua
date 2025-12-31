-- BindingsHelper module - extends the Bindings module with additional functionality
local Bindings = require("Buffer.Misc.Bindings")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local file_path = "Buffer/Bindings.json"
local enabled_text
local disabled_text

local modules
local module_lookup = {}
local path_name_cache = {}

-- Create a new table that inherits all of the original bindings functionality
local helper = {}
helper.popup = {} -- Store popup state in helper

setmetatable(helper, {
    __index = Bindings
})

--- Sets a value in a module's data structure using a dot-separated path
--- @param path string The path to the setting (e.g., "character.health")
--- @param value any The value to set
--- @return boolean success Whether the operation was successful
function helper.set_module_value(path, value)
    local path_parts = Utils.split(path, ".")
    local module_name = path_parts[1]

    -- Find the module by title
    local target_module = module_lookup[module_name]
    if not target_module then return false end

    -- Traverse to the target value
    table.remove(path_parts, 1)
    local target = target_module.data
    for i = 1, #path_parts - 1 do
        if not target[path_parts[i]] then
            target[path_parts[i]] = {}
        end
        target = target[path_parts[i]]
    end

    -- Set the value directly
    target[path_parts[#path_parts]] = value
    return true
end

-- Helper function to recursively disable all settings
function helper.disable_all(data_layer)
    for key, value in pairs(data_layer) do
        if type(value) == "boolean" then
            data_layer[key] = false
        elseif type(value) == "number" then
            data_layer[key] = -1
        elseif type(value) == "table" then
            helper.disable_all(value)
        end
    end
end

function helper.convert_old_format()
    local file = json.load_file(file_path)
    if file then
        local controller = file.btns
        local keyboard = file.keys
        if controller then
            for _, data in pairs(controller) do
                local inputs = type(data.input) == "table" and data.input or { data.input }
                local path = string.gsub(data.data.path, "%.data", "")
                helper.add(Bindings.DEVICE_TYPES.CONTROLLER, inputs, path, data.data.on)
            end
        end
        if keyboard then
            for _, data in pairs(keyboard) do
                local inputs = type(data.input) == "table" and data.input or { data.input }
                local path = string.gsub(data.data.path, "%.data", "")
                helper.add(Bindings.DEVICE_TYPES.KEYBOARD, inputs, path, data.data.on)
            end
        end

        if controller or keyboard then return true end
    end
end

-- Loads the bindings and initializes the helper
function helper.load(mods)
    modules = mods
    enabled_text = Language.get("window.bindings.enabled")
    disabled_text = Language.get("window.bindings.disabled")

    -- REMOVE AT A LATER DATE
    module_lookup = {}
    for _, mod in pairs(modules) do
        if mod.title then
            module_lookup[mod.title] = mod
        end
    end

    local hasOldFormat = helper.convert_old_format() -- Convert old bindings format to new one
    if hasOldFormat then
        helper.save()
        log.debug("Converted old bindings format to new one.")
        return
    end

    local file = json.load_file(file_path)
    if file then
        for _, bind in pairs(file) do
            helper.add(bind.device, bind.input, bind.path, bind.value)
        end
    end
end

-- Saves the current bindings to the file
function helper.save()
    local file = {}

    -- Iterate through both devices (1 for controller, 2 for keyboard)
    for i = 1, 2 do
        local bindings_list = Bindings.get_bindings(i)
        for _, bind in pairs(bindings_list) do
            local data = {
                device = i,
                input = bind.input,
                path = bind.path,
                value = bind.value
            }
            table.insert(file, data)
        end
    end

    json.dump_file(file_path, file)
end

-- Override the original add function to include custom functionality
helper.original_add = Bindings.add
function helper.add(device, input, path, value)
    helper.original_add(device, input, function()
        local path_parts = Utils.split(path, ".")
        local module_name = path_parts[1]
        local value = value
        local value_text = enabled_text

        local is_boolean = false
        local is_number = false

        if path == "window.disable_all" then
            -- Special case to disable all settings
            for _, mod in pairs(modules) do
                helper.disable_all(mod.data)
            end
            Utils.send_message(Language.get("window.title") .. " " .. Language.get("window.bindings.disabled"))
            return
        end

        -- Find the module by title
        local target_module = module_lookup[module_name]
        if not target_module then return end

        -- Traverse to the target value
        table.remove(path_parts, 1)
        local target = target_module.data
        for i = 1, #path_parts - 1 do
            target = target[path_parts[i]]
        end

        -- Toggle or set the value
        local target_value = target[path_parts[#path_parts]]
        local setting_path = module_name .. "." .. table.concat(path_parts, ".")

        -- Handle boolean values
        if type(target_value) == "boolean" then
            target_value = not target_value
            helper.set_module_value(path, target_value)
            value_text = target_value and enabled_text or disabled_text

        -- Handle number values
        elseif type(target_value) == "number" then
            target_value = target_value > -1 and -1 or value
            helper.set_module_value(path, target_value)
            value_text = target_value == -1 and disabled_text or
                string.gsub(Language.get("window.bindings.set_to"), "%%d", tostring(target_value))
        end

        Utils.send_message(helper.get_setting_name_from_path(setting_path) .. " " .. value_text)
    end)

    -- Apply additional data to the bindings
    Bindings.apply_data(device, input, {
        path = path,
        value = value
    })
end

-- Override the original remove function to include custom functionality
helper.original_remove = Bindings.remove
function helper.remove(device, number)
    -- Find the binding to remove
    local bindings = Bindings.get_bindings(device)
    local binding = bindings[number]
    helper.original_remove(device, binding.input)
    helper.save()
end

--- Returns the name of the setting based on the provided path.
--- @param path string The path to the setting (e.g., "character.health").
--- @return string The formatted name of the setting.
function helper.get_setting_name_from_path(path)
    if path_name_cache[path] then return path_name_cache[path] end

    local path_parts = Utils.split(path, ".")
    local title_parts = {}
    
    for i, part in ipairs(path_parts) do
        local current_path = table.concat(path_parts, ".", 1, i)
        local key = (i == #path_parts and type(Language.get(current_path)) ~= "table") 
            and current_path 
            or current_path .. ".title"
        table.insert(title_parts, Language.get(key))
    end
    
    local result = table.concat(title_parts, "/")
    path_name_cache[path] = result
    return result
end

-- Draws the popup for adding a new binding
function helper.draw()
    local listener = helper.listener:create("Buffer Popup")
    if helper.popup.open then

        local popup_size = Vector2f.new(350, 145)
        -- If a path has been chosen, make the window taller
        if helper.popup.path ~= nil then
            popup_size.y = 190
        end
        imgui.set_next_window_size(popup_size, 1 + 256)
        imgui.begin_window("buffer_bindings", nil, 1)
        imgui.indent(10)
        imgui.spacing()
        imgui.spacing()

        -- Change title depending on device
        if helper.popup.device == Bindings.DEVICE_TYPES.CONTROLLER then
            imgui.text(Language.get("window.bindings.add_gamepad"))
        else
            imgui.text(Language.get("window.bindings.add_keyboard"))
        end
        imgui.separator()
        imgui.spacing()
        imgui.spacing()

        -- Draw the path menu selector
        local binding_path = Language.get("window.bindings.choose_modification")
        if helper.popup.path ~= nil then
            binding_path = helper.get_setting_name_from_path(helper.popup.path)
        end

        if imgui.begin_menu(binding_path) then
            for module_key, module in pairs(modules) do
            imgui.spacing()
                if imgui.begin_menu(" "..Language.get(module.title .. ".title")) then

                    local function draw_menu(data, path)
                        for key, value in pairs(data) do   
                            imgui.spacing()
                            local current_path = path .. "." .. key
                            if type(value) == "table" then
                                if imgui.begin_menu(" "..Language.get(current_path .. ".title")) then
                                    draw_menu(value, current_path)
                                    imgui.end_menu()
                                end
                            else
                                local label_key = current_path
                                if not string.find(Language.get(current_path .. ".title"), "Invalid Language Key") then
                                    label_key = current_path .. ".title"
                                end
                                if imgui.menu_item(" "..Language.get(label_key)) then
                                    helper.popup.path = current_path
                                    helper.popup.value = value
                                end
                            end
                        end
                        imgui.spacing()
                    end
                    draw_menu(module.data, module.title)
                    imgui.end_menu()
                end
            end
            imgui.spacing()
            imgui.separator()
            imgui.spacing()
            if imgui.menu_item(" "..Language.get("window.disable_all")) then
                helper.popup.path = "window.disable_all"
                helper.popup.value = false
            end
            imgui.spacing()
            imgui.end_menu()
        end

        -- Draw the value input field
        if helper.popup.value ~= nil then
            imgui.text(Language.get("window.bindings.on_value") .. ": ")
            imgui.same_line()
            if type(helper.popup.value) == "boolean" then
                imgui.begin_disabled()
                if helper.popup.path == "window.disable_all" then
                    imgui.input_text("   ", "false")
                else
                    imgui.input_text("   ", "true/false")
                end
                imgui.end_disabled()
            elseif type(helper.popup.value) == "number" then
                imgui.text(Language.get("window.bindings.on_value") .. ": ")
                local changed, on_value = imgui.input_text("     ", helper.popup.value, 1)
                if changed and on_value ~= "" and tonumber(on_value) then
                    helper.popup.value = tonumber(on_value)
                end
            end
        end

        imgui.spacing()

        -- Get the default hotkey text based on the device type
        local binding_hotkey = ""

        -- Popup listening
        if listener:is_listening() then
            helper.popup.device = listener:get_device()

            -- If listener is listening, display the current binding hotkey
            if #listener:get_inputs() ~= 0 then
                binding_hotkey = ""
                local inputs = listener:get_inputs()
                inputs = Bindings.get_names(listener:get_device(), inputs)
                for _, input in ipairs(inputs) do
                    binding_hotkey = binding_hotkey .. input.name .. " + "
                end
            else
                binding_hotkey = Language.get("window.bindings.listening")
            end

            -- If not listening, and inputs are available, display the inputs
        elseif #listener:get_inputs() ~= 0 then
            local inputs = listener:get_inputs()
            inputs = Bindings.get_names(listener:get_device(), inputs)
            for i, input in ipairs(inputs) do
                binding_hotkey = binding_hotkey .. input.name
                if i < #listener:get_inputs() then
                    binding_hotkey = binding_hotkey .. " + "
                end
            end
        else
            binding_hotkey = Language.get("window.bindings.to_listen")
        end

        -- Draw the hotkey button
        if imgui.button(binding_hotkey) then
            listener:start()
        end

        imgui.spacing()
        imgui.spacing()
        imgui.separator()
        imgui.spacing()

        if imgui.button(Language.get("window.bindings.cancel")) then
            helper.popup_close()
        end
        if helper.popup.path and #listener:get_inputs() > 0 then
            imgui.same_line()
            if imgui.button(Language.get("window.bindings.save")) then
                helper.add(helper.popup.device, listener:get_inputs(), helper.popup.path, helper.popup.value)
                helper.save()
                helper.popup_close()
                listener:stop()
                listener:clear()
                helper.popup.open = false
            end
        end
        imgui.unindent(10)
        imgui.end_window()

        -- In case the popup is closed but still listening
    elseif listener:is_listening() then
        helper.popup_close()
        listener:stop()
        listener:clear()
    end
end

-- Opens the popup
function helper.popup_open(device)
    helper.popup.open = true
    helper.popup.device = device
    helper.popup.path = nil
    helper.popup.binding = nil
    helper.popup.value = nil
end

-- Closes the popup
function helper.popup_close()
    helper.popup.open = false
end

return helper
