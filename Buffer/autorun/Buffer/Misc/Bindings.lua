-- Bindings version 0.0.3

local controller_bindings = {}
local keyboard_bindings = {}
local Bindings = {}

-- The delay to wait before checking the bindings again
Bindings.delay = 0.05


-- Just helper variables to make device numbers easier
local DEVICE_TYPES = {
    NONE = 0,
    CONTROLLER = 1,
    KEYBOARD = 2
}

local CONTROLLER_TYPES = {
    NONE = 0,
    PLAYSTATION = 1,
    XBOX = 2
}

Bindings.DEVICE_TYPES = DEVICE_TYPES
Bindings.CONTROLLER_TYPES = CONTROLLER_TYPES

--- Generate the enums for the bindings
--- @param typename The name of the type to generate the enum for
--- @return A table with the enum values
local function generate_enum(typename)
    local t = sdk.find_type_definition(typename)
    if not t then
        return {}
    end
    local fields = t:get_fields()
    local enum = {}
    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)
            enum[name] = raw_value
        end
    end
    return enum
end

-- Generate the enums for the bindings

-- ======= Listeners ==========
local listeners = {}

-- ========== Example usage ============
-- local listener = Bindings.listener:create("hotkey")

-- listener:on_complete(function()
--     print("Complete")
-- end)

-- if imgui.button("Listen") then
--     listener:start()
-- end

local listener = {}

--- Create a new listener
--- Will return an existing listener if it already exists by id
--- @param id The id of the listener
--- @param [options] The options for the listener
--- timeout_timer: The timeout for the listener in seconds
--- cached_current_timer: How long to keep the current input check cached
--- @return The listener object
function listener:create(id, options)

    if listeners[id] then
        return listeners[id]
    end

    local self = {}
    self.id = id
    self.listening = false
    self.device = 0

    -- Last input tracker
    self.cached_current = nil
    self.cached_current_timer = 0.1
    self.cached_current_time = 0
    
    self.inputs = {}
    self.complete = function() end
    
    self.timeout_timer = nil
    self.timeout_start_time = 0
    self.timeout = function() end

    -- iterate through options and set them
    if options then
        for key, value in pairs(options) do
            self[key] = value
        end
    end

    setmetatable(self, {
        __index = listener
    })
    
    listeners[id] = self
    return self

end

--- Create a new listener with a timeout
--- @param id The id of the listener
--- @param timeout The timeout for the listener in seconds
--- @return The listener object
--- @see listener:create
function listener:create_with_timeout(id, timeout)
    local self = self:create(id)
    self.timeout_timer = timeout
    return self
end

--- Start the listener
--- Sets the listening flag to true, and clears the inputs
function listener:start()
    self.listening = true
    self.inputs = {}
    if self.timeout_timer then
        self.timeout_start_time = os.clock()
    end
end

--- Stop the listener
function listener:stop()
    self.listening = false
end

--- Clear the listener's inputs
function listener:clear()
    self.inputs = {}
end

--- Check if the listener is listening
--- @return true/false if the listener is listening
function listener:is_listening()
    return self.listening
end

--- Call back when listener is complete
--- @param callback The function to call when the listener is complete
function listener:on_complete(callback)
    self.complete = callback
end

--- Call back when listener times out
--- @param callback The function to call when the listener times out
function listener:on_timeout(callback)
    self.timeout = callback
end

--- Get the inputs
--- @return The inputs the listener has received
function listener:get_inputs()
    return self.inputs
end

--- Get the device
--- @return The device the listener is listening to (1 = Controller, 2 = Keyboard)
function listener:get_device()
    return self.device
end

--- Update the listener
--- Called by the bindings update
function listener:update()

    if not self.listening then
        return
    end

    -- Cache the current input for the delay - allows for easier setting/reading of binds
    local current = self.cached_current
    if self.cached_current_time + self.cached_current_timer < os.clock() then
        current = Bindings.get_current()
        self.cached_current = current
        self.cached_current_time = os.clock()
    end

    if not current then
        return
    end

    if #current > 0 then
        self.inputs = current
        if Bindings.get_current_device() ~= DEVICE_TYPES.NONE then
            self.device = Bindings.get_current_device()
        end

    elseif #current == 0 and self.inputs and #self.inputs > 0 then
        self.listening = false
        self.complete()
    end

    -- Check if the timeout time has passed
    if self.timeout_timer and self.timeout_start_time + self.timeout_timer < os.clock() then
        self.listening = false
        self.timeout()
    end
end

--- Get the time left in the timeout
--- @param decimals The number of decimals to return
--- @return The time left in the timeout
--- Returns -1 if no timeout is set
function listener:get_timeout_remaining(decimals)
    if self.timeout_timer then
        if not decimals then
            decimals = 2
        end
        local time_left = (self.timeout_start_time + self.timeout_timer) - os.clock()
        if time_left < 0 then
            return 0
        end
        local time_left = math.floor(time_left * 10 ^ decimals) / 10 ^ decimals
        return time_left
    end
    return -1
end


Bindings.listeners = listeners
Bindings.listener = listener



-- ======= Keyboard Manager ==========
local keyboard_enum = generate_enum("via.hid.KeyboardKey")
local native_keyboard = sdk.get_native_singleton("via.hid.Keyboard")
local type_keyboard = sdk.find_type_definition("via.hid.Keyboard")

keyboard_bindings.current = {}
keyboard_bindings.current_last_check = nil
keyboard_bindings.previous = {}

keyboard_bindings.bindings = {}

--- Check if the keyboard is currently in use
--- @return true/false if the keyboard is currently in use
function keyboard_bindings.is_currently_in_use()
    return #keyboard_bindings.get_current() > 0
end

--- Get the previous keys
--- @return An array of the previous keys
function keyboard_bindings.get_previous()
    return keyboard_bindings.previous
end

--- Get the current keys in an array with the codes
--- Will return the current_table table if not enough time has passed since the last check
--- @return An array of the current keys
function keyboard_bindings.get_current()

    local keyboard = sdk.call_native_func(native_keyboard, type_keyboard, "get_Device")

    -- Cache the keys for the delay - allows for easier setting/reading of binds
    if keyboard_bindings.current ~= nil and keyboard_bindings.current_last_check ~= nil and
        keyboard_bindings.current_last_check + Bindings.delay > os.clock() then
        return keyboard_bindings.current
    end

    if not keyboard:get_AnyKeyDown() then
        keyboard_bindings.current = {}
        keyboard_bindings.current_last_check = os.clock()
        return {}
    end

    local current = {}
    for key_name, key_code in pairs(keyboard_enum) do
        if keyboard:isDown(key_code) then
            table.insert(current, key_code)
        end
    end

    keyboard_bindings.current = current
    keyboard_bindings.current_last_check = os.clock()
    return current
end

--- Check if the items in the passed table were just triggered
--- @param data The table of keys to check
--- @return true/false if the keys were just triggered
function keyboard_bindings.is_triggered(data)

    local current = keyboard_bindings.get_current()
    local previous = keyboard_bindings.get_previous()

    -- Check if in current all keys are pressed, and in previous either none or all but one
    local matches = 0
    local previous_matches = 0
    for _, code in pairs(data) do
        for _, current_code in pairs(current) do
            if current_code == code then
                matches = matches + 1
            end
        end
        for _, previous_code in pairs(previous) do
            if previous_code == code then
                previous_matches = previous_matches + 1
            end
        end
    end

    -- If not all current keys match the trigger
    if matches ~= #data then
        return false
    end

    -- If no previous keys were found
    if #keyboard_bindings.previous == 0 then
        return true
    end

    -- Previous has less matches than the current
    return previous_matches < #data
end

--- Check if the items in the passed table are currently pressed
--- @param data The table of keys to check
--- @return true/false if the keys are currently pressed
function keyboard_bindings.is_down(data)
    local current = Bindings.get_current()
    local current_set = {}
    for _, code in pairs(current) do
        current_set[code] = true
    end
    for _, code in pairs(data) do
        if not current_set[code] then
            return false
        end
    end
    return true
end

--- Get the name of the key from the code
--- Returns "Unknown" if not found
--- @param code The code of the key
--- @return The name of the key
function keyboard_bindings.get_name(code)
    for key_name, key_code in pairs(keyboard_enum) do
        if key_code == code then
            return key_name
        end
    end
    return "Unknown"
end

--- Get an array of the keys from the code
--- @param codes The array of codes to get the names for
--- @return An array of the keys in {name, code} format
function keyboard_bindings.get_names(codes)
    local names = {}
    for _, code in pairs(codes) do
        table.insert(names, {
            name = keyboard_bindings.get_name(code),
            code = code
        })
    end
    return names
end

--- Get the code from the name
--- Returns -1 if not found
--- @param name The name of the key
--- @return The code of the key
function keyboard_bindings.get_code_from_name(name)
    for key_name, key_code in pairs(keyboard_enum) do
        if key_name == name then
            return key_code
        end
    end
    return -1
end



-- ======= Controller ==========
local controller_enum = generate_enum("via.hid.GamePadButton")

local controller_types = generate_enum("via.hid.DeviceKindDetails")
local controller_type = 0

local native_controller = sdk.get_native_singleton("via.hid.GamePad")
local type_controller = sdk.find_type_definition("via.hid.GamePad")

controller_bindings.current = {}
controller_bindings.current_last_check = nil
controller_bindings.previous = {}

controller_bindings.bindings = {}

-- Buttons to ignore, can't remove from enum as the code would be wrong then
local ignore_buttons = {"Cancel", "Decide"}

-- Button names to replace [DefaultName] = {"Playstation", "Xbox"}
local to_replace_buttons = {
    ["RRight"] = {"Circle", "B"},
    ["RDown"] = {"X", "A"},
    ["RLeft"] = {"Square", "X"},
    ["RUp"] = {"Triangle", "Y"},
    ["CLeft"] = {"Share", "View"},
    ["CRight"] = {"Start", "Menu"},
    ["CCenter"] = {"Touchpad", "Guide"},
    ["LTrigBottom"] = {"L2", "LT"},
    ["RTrigBottom"] = {"R2", "RT"},
    ["LTrigTop"] = {"L1", "LB"},
    ["RTrigTop"] = {"R1", "RB"},
    ["LStickPush"] = {"L3", "LS"},
    ["RStickPush"] = {"R3", "RS"}
}

--- Get the controller type
--- Caches the controller type for a short time to avoid constant calls to the native function
--- @return The controller type
local function get_controller_type()
    if controller_type ~= 0 and controller_bindings.current_last_check ~= nil and
        controller_bindings.current_last_check + Bindings.delay > os.clock() then
        return controller_type
    end

    local manager = sdk.get_managed_singleton("ace.PadManager")
    if not manager then
        return 0
    end
    local controller = manager:get_MainPad()
    if not controller then
        return 0
    end
    local type_id = controller:get_DeviceKindDetails()
    local type = {}
    for name, id in pairs(controller_types) do
        if id == type_id then
            type = {
                name = name,
                id = type_id
            }
            break
        end
    end

    if string.find(type.name, "Dual") then
        controller_type = CONTROLLER_TYPES.PLAYSTATION
    elseif string.find(type.name, "Xbox") then
        controller_type = CONTROLLER_TYPES.XBOX
    else
        controller_type = CONTROLLER_TYPES.NONE
    end
    return controller_type
end

--- Check if the controller is currently in use
--- @return true/false if the controller is currently in use
function controller_bindings.is_currently_in_use()
    return #controller_bindings.get_current() > 0
end

--- Get the previous buttons
--- @return An array of the previous buttons
function controller_bindings.get_previous()
    return controller_bindings.previous
end

--- Get an array of the buttons
--- @return An array of the buttons in {name, code} format
local function transform_code_into_codes(code)
    local init_code = code

    -- If the code is a single btn
    local btns = {}
    while code > 0 do
        local largest = {
            code = 0
        }

        for btn_name, btn_code in pairs(controller_enum) do
            if btn_code <= code and btn_code > largest.code then
                largest = {
                    name = btn_name,
                    code = btn_code
                }
            end
        end

        -- If we couldn't find a bigger code, then we must have all the possible ones
        if largest.code == 0 then
            break
        end

        -- Remove the largest and add it to the list of btns as long as it's not in the ignore list
        code = code - largest.code
        local ignore = false
        for _, ignore_name in pairs(ignore_buttons) do
            if largest.name == ignore_name then
                ignore = true
            end
        end
        if not ignore then
            table.insert(btns, largest)
        end
    end
    if #btns > 0 then
        return btns
    elseif code ~= 0 and code ~= -1 then
        table.insert(btns, {
            name = "Unknown",
            code = init_code
        })
        return btns
    else
        return btns
    end
end

--- Get a list of button codes from the buttons
--- @param btns The array of buttons to get the codes in {name, code} format
--- @return An array of the codes in {code} format
local function get_codes(btns)
    local codes = {}
    for _, btn in pairs(btns) do
        table.insert(codes, btn.code)
    end
    return codes
end

--- Update the controller type
--- Update the controller_enum if the controller type has changed to not NONE
--- @return The controller type
local function update_controller_type()

    local previous_type = controller_type

    -- Ensure controller type gotten actually matters (not 0)
    controller_type = get_controller_type()
    if previous_type == 0 and controller_type ~= 0 then

        -- Replace controller_enum keys with the first value from to_replace
        for key, values in pairs(to_replace_buttons) do
            if values[controller_type] ~= nil then
                controller_enum[values[controller_type]] = controller_enum[key]
                controller_enum[key] = nil
            end
        end
    end
end

--- Get current buttons pressed as code
--- Returns the current_table table if not enough time has passed since the last check
--- @return An array of the buttons in {name, code} format
function controller_bindings.get_current()

    -- If current controller type hasn't been set, try to get it
    if controller_type == 0 then
        update_controller_type()
    end

    local controller = sdk.call_native_func(native_controller, type_controller, "get_MergedDevice")

    -- Cache the buttons for the delay - allows for easier setting/reading of binds
    if controller_bindings.current ~= nil and controller_bindings.current_last_check ~= nil and
        controller_bindings.current_last_check + Bindings.delay > os.clock() then
        return controller_bindings.current
    end

    local current_code = controller:get_Button()

    if current_code == 0 then
        current_code = -1
    end

    local current = transform_code_into_codes(current_code)
    current = get_codes(current)

    controller_bindings.current = current
    controller_bindings.current_last_check = os.clock()
    return current
end

--- Check if the items in the passed table were just triggered
--- @param data The table of buttons to check
--- @return true/false if the buttons were just triggered
function controller_bindings.is_triggered(data)
    local current = controller_bindings.get_current()
    local previous = controller_bindings.get_previous()

    -- Create lookup tables for O(1) access
    local current_set = {}
    local previous_set = {}
    for _, code in pairs(current) do
        current_set[code] = true
    end
    for _, code in pairs(previous) do
        previous_set[code] = true
    end

    -- Check if all keys are pressed in current, count matches in previous
    local matches = 0
    local previous_matches = 0
    for _, code in pairs(data) do
        if current_set[code] then
            matches = matches + 1
        end
        if previous_set[code] then
            previous_matches = previous_matches + 1
        end
    end

    -- If not all current keys match the trigger
    if matches ~= #data then
        return false
    end

    -- If no previous keys were found
    if #controller_bindings.get_previous() == 0 then
        return true
    end

    -- Previous has less matches than the current
    return previous_matches < #data
end

--- Get the name of the button from the code
--- Returns "Unknown" if not found
--- @param code The code of the button
--- @return The name of the button
function controller_bindings.get_name(code)
    if controller_type == 0 then
        update_controller_type()
    end
    for button_name, button_code in pairs(controller_enum) do
        if button_code == code then
            return button_name
        end
    end
    return "Unknown"
end

--- Get an array of the buttons from the code
--- @param codes The array of codes to get the names for
--- @return An array of the buttons in {name, code} format
function controller_bindings.get_names(codes)

    if controller_type == 0 then
        update_controller_type()
    end

    local names = {}
    for _, code in pairs(codes) do
        table.insert(names, {
            name = controller_bindings.get_name(code),
            code = code
        })
    end
    return names
end

--- Get the code from the name
--- Returns -1 if not found
--- @param name The name of the button
--- @return The code of the button
function controller_bindings.get_code_from_name(name)
    if controller_type == 0 then
        update_controller_type()
    end
    for button_name, button_code in pairs(controller_enum) do
        if button_name == name then
            return button_code
        end
    end
    return -1
end

-- =========================================

--- Add the keyboard bindings
--- @param keys The keys to bind
--- @param callback The function to call when the keys are pressed
function Bindings.add_keyboard(keys, callback)
    local data = {
        input = keys,
        callback = callback
    }
    table.insert(keyboard_bindings.bindings, data)
end

--- Add the controller bindings
--- @param buttons The buttons to bind
--- @param callback The function to call when the buttons are pressed
function Bindings.add_controller(buttons, callback)
    local data = {
        input = buttons,
        callback = callback
    }
    table.insert(controller_bindings.bindings, data)
end

--- Add the bindings depending on the device
--- @param device The device to bind to (1 = Controller, 2 = Keyboard)
--- @param input The input to bind
--- @param callback The function to call when the input is pressed
function Bindings.add(device, input, callback)
    if device == DEVICE_TYPES.CONTROLLER then
        return Bindings.add_controller(input, callback)
    elseif device == DEVICE_TYPES.KEYBOARD then
        return Bindings.add_keyboard(input, callback)
    end
    return false
end

--- Get the bindings for the keyboard
--- @return An array of the keyboard bindings in {input, callback} format
function Bindings.get_keyboard_bindings()
    return keyboard_bindings.bindings
end

--- Get the bindings for the controller
--- @return An array of the controller bindings in {input, callback} format
function Bindings.get_controller_bindings()
    return controller_bindings.bindings
end

--- Get the bindings depending on the device
--- @param device The device to get the bindings for (1 = Controller, 2 = Keyboard)
--- @return An array of the bindings in {input, callback} format
function Bindings.get_bindings(device)
    if device == DEVICE_TYPES.CONTROLLER then
        return Bindings.get_controller_bindings()
    elseif device == DEVICE_TYPES.KEYBOARD then
        return Bindings.get_keyboard_bindings()
    end
    return {}
end

--- Get the binding depending on the device
--- @param device The device to get the binding for (1 = Controller, 2 = Keyboard)
--- @param input The input to get the binding for
--- @return The binding in {input, callback} format
function Bindings.get_binding(device, input)
    local bindings_list = Bindings.get_bindings(device)
    for _, binding in pairs(bindings_list) do
        if binding.input == input then
            return binding
        end
    end
    return nil
end

--- Apply data to the binding
--- @param device The device to apply the data to (1 = Controller, 2 = Keyboard)
--- @param input The input to apply the data to
--- @param data The data to apply to the binding
--- @return true if the binding was found and data was applied, false otherwise
function Bindings.apply_data(device, input, data)
   local binding = Bindings.get_binding(device, input)
    
   if binding then
        for k, v in pairs(data) do
            binding[k] = v
        end
        return true
    end
    return false
end


--- Remove the keyboard binding
--- @param keys The keys to unbind
function Bindings.remove_keyboard(keys)
    for i, data in pairs(keyboard_bindings.bindings) do
        if data.input == keys then
            table.remove(keyboard_bindings.bindings, i)
        end
    end
end

--- Remove the controller binding
--- @param buttons The buttons to unbind
function Bindings.remove_controller(buttons)
    for i, data in pairs(controller_bindings.bindings) do
        if data.input == buttons then
            table.remove(controller_bindings.bindings, i)
        end
    end
end

--- Remove the bindings depending on the device
--- @param device The device to unbind from (1 = Controller, 2 = Keyboard)
--- @param input The input to unbind
function Bindings.remove(device, input)
    if device == DEVICE_TYPES.CONTROLLER then
        Bindings.remove_controller(input)
    elseif device == DEVICE_TYPES.KEYBOARD then
        Bindings.remove_keyboard(input)
    end
end

--- Check if the device is a keyboard
--- @return true/false if the keyboard is currently in use
function Bindings.is_keyboard()
    return keyboard_bindings.is_currently_in_use()
end

--- Check if the device is a controller
--- @return true/false if the controller is currently in use
function Bindings.is_controller()
    return controller_bindings.is_currently_in_use()
end

--- Get the current device type
--- @return The device type (0 = None, 1 = Controller, 2 = Keyboard)
function Bindings.get_current_device()
    if Bindings.is_keyboard() then
        return DEVICE_TYPES.KEYBOARD
    end
    if Bindings.is_controller() then
        return DEVICE_TYPES.CONTROLLER
    end
    return DEVICE_TYPES.NONE
end

--- Get the current bindings
--- @return The current bindings in an array of {name, code} depending on the current device
--- Returns an empty array if no bindings are found
function Bindings.get_current()
    if Bindings.is_keyboard() then
        return keyboard_bindings.get_current()
    end
    if Bindings.is_controller() then
        return controller_bindings.get_current()
    end
    return {}
end

--- Get the controller type
--- @return The controller type (0 = None, 1 = Playstation, 2 = Xbox)
function Bindings.get_controller_type()
    return controller_type
end

--- Get the name of the key or button from the codes
--- @param device The device type (1 = Controller, 2 = Keyboard)
--- @param code The code of the key or button
--- @return The name of the key or button in {name, code} format
--- Returns "Unknown" if not found
function Bindings.get_name(device, code)
    if device == DEVICE_TYPES.CONTROLLER then
        return controller_bindings.get_name(code)
    elseif device == DEVICE_TYPES.KEYBOARD then
        return keyboard_bindings.get_name(code)
    end
end

--- Get the names of the keys or buttons from the codes in an array of {name, code}
-- @param device The device type (1 = Controller, 2 = Keyboard)
--- @param codes The array of codes to get the names for
--- @return An array of the keys or buttons in {name, code} format
--- Returns "Unknown" if not found
function Bindings.get_names(device, codes)
    if device == DEVICE_TYPES.CONTROLLER then
        return controller_bindings.get_names(codes)
    elseif device == DEVICE_TYPES.KEYBOARD then
        return keyboard_bindings.get_names(codes)
    end
end

--- Get the code from the name
--- @param device The device type (1 = Controller, 2 = Keyboard)
--- @param name The name of the key or button
--- @return The code of the key or button
--- Returns -1 if not found
function Bindings.get_code_from_name(device, name)
    if device == DEVICE_TYPES.CONTROLLER then
        return controller_bindings.get_code_from_name(name)
    elseif device == DEVICE_TYPES.KEYBOARD then
        return keyboard_bindings.get_code_from_name(name)
    end
end

--- Get the callback for the keyboard input
--- @param input The input to get the callback for
--- @return The callback function for the input
--- Returns nil if not found
function Bindings.get_keyboard_callback(input)
    for _, data in pairs(keyboard_bindings.bindings) do
        if data.input == input then
            return data.data
        end
    end
    return nil
end

--- Get the callback for the controller input
--- @param input The input to get the callback for
--- @return The callback function for the input
--- Returns nil if not found
function Bindings.get_controller_callback(input)
    for _, data in pairs(controller_bindings.bindings) do
        if data.input == input then
            return data.data
        end
    end
    return nil
end

--- Get the callback for the input
--- @param device The device type (1 = Controller, 2 = Keyboard)
--- @param input The input to get the callback for
--- @return The callback function for the input
--- Returns nil if not found
function Bindings.get_callback(device, input)
    if device == DEVICE_TYPES.CONTROLLER then
        return Bindings.get_controller_callback(input)
    elseif device == DEVICE_TYPES.KEYBOARD then
        return Bindings.get_keyboard_callback(input)
    else
        return nil
    end
end

--- Update the bindings and run the callback if the input is triggered
--- Run this function in re.on_frame
function Bindings.update()
    if Bindings.is_keyboard() then
        for _, data in pairs(keyboard_bindings.bindings) do
            if keyboard_bindings.is_triggered(data.input) then
                data.callback()
            end
        end
    end

    if Bindings.is_controller() then
        for _, data in pairs(controller_bindings.bindings) do
            if controller_bindings.is_triggered(data.input) then
                data.callback()
            end
        end
    end

    for _, listener in pairs(Bindings.listeners) do
        listener:update()
    end

    -- Update previous data
    controller_bindings.previous = controller_bindings.get_current()
    keyboard_bindings.previous = keyboard_bindings.get_current()
end

return Bindings
