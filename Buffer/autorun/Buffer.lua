local version = "3.0.0"

local isWindowOpen, wasOpen = false, false

-- Constants
local WINDOW_WIDTH = 520
local WINDOW_HEIGHT = 450
local WINDOW_ROUNDING = 7.5
local FRAME_ROUNDING = 5.0
local WINDOW_ALPHA = 0.9

-- Utilities and Helpers
local Utils = require("Buffer.Misc.Utils")
local Config = require("Buffer.Misc.Config")
local Language = require("Buffer.Misc.Language")
local Bindings = require("Buffer.Misc.BindingsHelper")

-- -- Misc Modules
local character = require("Buffer.Modules.Character")
local miscellaneous = require("Buffer.Modules.Miscellaneous")

-- Weapon Modules
local greatSword = require("Buffer.Modules.GreatSword")
local shortSword = require("Buffer.Modules.ShortSword")
local dualBlades = require("Buffer.Modules.DualBlades")
local longSword = require("Buffer.Modules.LongSword")
local hammer = require("Buffer.Modules.Hammer")
local huntingHorn = require("Buffer.Modules.HuntingHorn")
local lance = require("Buffer.Modules.Lance")
local gunlance = require("Buffer.Modules.Gunlance")
local switchAxe = require("Buffer.Modules.SwitchAxe")
local chargeBlade = require("Buffer.Modules.ChargeBlade")
local insectGlaive = require("Buffer.Modules.InsectGlaive")
local bow = require("Buffer.Modules.Bow")
local lightBowgun = require("Buffer.Modules.LightBowgun")
local heavyBowgun = require("Buffer.Modules.HeavyBowgun")

local modules = {
    character,
    miscellaneous,
    greatSword,
    shortSword,
    dualBlades,
    longSword,
    hammer,
    huntingHorn,
    lance,
    gunlance,
    switchAxe,
    chargeBlade,
    insectGlaive,
    bow,
    lightBowgun,
    heavyBowgun
}

-- Load the languages
Language.init()

-- Load the bindings
Bindings.load(modules)

-- Helper function to draw binding tables
local function draw_binding_table(device, bindings_list, table_id)
    if #bindings_list > 0 then
        imgui.begin_table(table_id, 3, nil, nil, nil)

        for i, bind in pairs(bindings_list) do
            imgui.push_id(i)
            imgui.table_next_row()
            imgui.table_next_column()
            local btns = Bindings.get_names(device, bind.input)

            local title = Bindings.get_setting_name_from_path(bind.path)
            imgui.text("   " .. title)
            imgui.table_next_column()
            local bind_string = ""

            for j, btn in pairs(btns) do
                bind_string = bind_string .. btn.name
                if j < #btns then bind_string = bind_string .. " + " end
            end

            imgui.text("   [ " .. bind_string .. " ]     ")
            imgui.table_next_column()
            if imgui.button(Language.get("window.bindings.remove")) then
                Bindings.remove(device, i)
            end
            imgui.same_line()
            imgui.text("  ")
            imgui.pop_id()
        end

        imgui.end_table()
        imgui.separator()
    end
end

-- Helper function to recursively check for enabled buffs
local function check_for_enabled(data_layer, parent_key, enabled_buffs)
    for key, value in pairs(data_layer) do

        -- Skip internal use keys
        if key:sub(1,1) == "_" then goto continue end

        if type(value) == "boolean" and value == true then
            table.insert(enabled_buffs, {parent_key .. "." .. key, value})
        elseif type(value) == "number" and value ~= -1 then
            table.insert(enabled_buffs, {parent_key .. "." .. key, value})
        elseif type(value) == "table" then
            check_for_enabled(value, parent_key .. "." .. key, enabled_buffs)
        end
        ::continue::
    end
end

-- Init the modules
for _, module in pairs(modules) do
    if module.init then module:init() end
end

-- Check if the window was last open
if Config.get("window.is_window_open") then isWindowOpen = true end

-- Add the menu to the REFramework Script Generated UI
re.on_draw_ui(function()

    if Language.font.data ~= nil then imgui.push_font(Language.font.data) end
    local languagePrefix = "window."

    -- Draw button to toggle window state
    imgui.indent(2)
    if imgui.button(Language.get(languagePrefix .. "toggle_button")) then
        isWindowOpen = not isWindowOpen
        Config.set("window.is_window_open", isWindowOpen)
    end
    imgui.unindent(2)

    if isWindowOpen then
        wasOpen = true

        imgui.push_style_var(3, WINDOW_ROUNDING) -- Rounded window
        imgui.push_style_var(12, FRAME_ROUNDING) -- Rounded elements
        imgui.push_style_var(0, WINDOW_ALPHA) -- Window transparency

        imgui.set_next_window_size(Vector2f.new(WINDOW_WIDTH, WINDOW_HEIGHT), 4)

        isWindowOpen = imgui.begin_window("[Buffer] "..Language.get(languagePrefix .. "title"), isWindowOpen, 1024)
        Bindings.draw()
        if imgui.begin_menu_bar() then

            languagePrefix = "window.bindings."
            if imgui.begin_menu(Language.get(languagePrefix .. "title")) then
                imgui.spacing()
                if imgui.begin_menu("   " .. Language.get(languagePrefix .. "keyboard")) then
                    imgui.spacing()
                    local device = Bindings.DEVICE_TYPES.KEYBOARD
                    local keyboardBindings = Bindings.get_bindings(device)
                    draw_binding_table(device, keyboardBindings, "bindings_keyboard")
                    if imgui.button("   " .. Language.get(languagePrefix .. "add_keyboard") .. "   ", "", false) then Bindings.popup_open(2) end
                    imgui.spacing()
                    imgui.end_menu()
                end
                if imgui.begin_menu("   " .. Language.get(languagePrefix .. "gamepad")) then
                    imgui.spacing()
                    local device = Bindings.DEVICE_TYPES.CONTROLLER
                    local gamepadBindings = Bindings.get_bindings(device)
                    draw_binding_table(device, gamepadBindings, "bindings_gamepad")
                    if imgui.button("   " .. Language.get(languagePrefix .. "add_gamepad") .. "   ", "", false) then Bindings.popup_open(1) end
                    imgui.spacing()
                    imgui.end_menu()
                end
                
                imgui.spacing()
                imgui.end_menu()
            end
            languagePrefix = "window."
            if imgui.begin_menu(Language.get(languagePrefix .. "settings")) then
                imgui.spacing()
                if imgui.begin_menu("   " .. Language.get(languagePrefix .. "language")) then
                    imgui.spacing()
                    for _, lang in pairs(Language.sorted) do
                        if imgui.menu_item("   " .. Language.getLanguageName(lang) .. "   ", "", lang == Language.current, lang ~= Language.current) then Language.change(lang) end
                    end
                    imgui.spacing()
                    imgui.end_menu()
                end
                if imgui.begin_menu("   " .. Language.get(languagePrefix .. "font_size")) then
                    imgui.spacing()
                    Language.font.temp_size = Language.font.temp_size or Language.font.size
                    local changed = false
                    changed, Language.font.temp_size = imgui.slider_int(Language.get(languagePrefix .. "font_size") .. " ", Language.font.temp_size, 8, 24)
                    imgui.same_line()
                    if imgui.button(Language.get(languagePrefix .. "font_size_apply")) then
                        Language.change(Language.current, Language.font.temp_size)
                        Language.font.temp_size = nil
                    end
                    imgui.spacing()
                    imgui.end_menu()
                end
                imgui.spacing()
                imgui.end_menu()
            end

            if imgui.begin_menu(Language.get(languagePrefix .. "options")) then
                imgui.spacing()
                if imgui.begin_menu("   " .. Language.get(languagePrefix .. "enabled_buffs")) then
                    local enabled_buffs = {}

                    for _, module in pairs(modules) do
                        check_for_enabled(module.data, module.title, enabled_buffs)
                    end

                    if #enabled_buffs > 0 then
                        imgui.spacing()
                        imgui.begin_table("enabled_buffs", 3, nil, nil, nil)
                        for i, buff in pairs(enabled_buffs) do

                            if buff[1]:sub(1,1) == "_" then goto continue end -- Skip private variables
                            if buff[2] == 0 then goto continue end -- Skip zero values
                            
                            imgui.spacing()
                            imgui.push_id(i)
                            imgui.table_next_row()
                            imgui.table_next_column()
                            imgui.text(" " .. Bindings.get_setting_name_from_path(buff[1]))
                            imgui.table_next_column()
                            imgui.text("  " .. tostring(buff[2]) .. "  ")
                            imgui.table_next_column()
                            if imgui.button(Language.get(languagePrefix .. "disable")) then
                                local off_state
                                if type(buff[2]) == "boolean" then
                                    off_state = false
                                else
                                    off_state = -1
                                end
                                Bindings.set_module_value(buff[1], off_state)
                            end
                            imgui.same_line()
                            imgui.text("  ")
                            imgui.pop_id()

                            ::continue::
                        end
                        imgui.spacing()
                        imgui.end_table()
                        imgui.separator()
                        imgui.spacing()
                        if imgui.button("   " .. Language.get(languagePrefix .. "disable_all").. "   ", "", false) then
                            for _, module in pairs(modules) do
                                Bindings.disable_all(module.data)
                                module:save_config()
                            end
                        end
                        imgui.spacing()
                    else
                        imgui.spacing()
                        imgui.text(" " .. Language.get(languagePrefix .. "nothing_enabled").. " ")
                        imgui.spacing()
                    end
                    imgui.end_menu()
                end
               
                imgui.spacing()
                imgui.end_menu()
            end

            if imgui.begin_menu(Language.get(languagePrefix .. "about")) then
                imgui.spacing()
                imgui.text("   " .. Language.get(languagePrefix .. "author") .. ": Bimmr   ")
                if Language.languages[Language.current]["_TRANSLATOR"] then
                    imgui.text("   " .. Language.get(languagePrefix .. "translator") .. ": " .. Language.languages[Language.current]["_TRANSLATOR"] .. "   ")
                end
                imgui.text("   " .. Language.get(languagePrefix .. "version") .. ": " .. version .. "   ")

                imgui.spacing()
                imgui.end_menu()
            end

            imgui.end_menu_bar()
        end
        imgui.separator()

        imgui.spacing()
        for _, module in pairs(modules) do 
            module:draw_module()
        end
        imgui.spacing()

        imgui.end_window()
        imgui.pop_style_var(3)

        -- If the window is closed, but was just open. 
        -- This is needed because of the close icon on the window not triggering a save to the config
    elseif wasOpen then
        wasOpen = false
        Config.set("window.is_window_open", isWindowOpen)
    end

    if Language.font.data ~= nil then imgui.pop_font() end
end)

-- Keybinds
re.on_frame(function()
    Bindings.update()
end)

-- On script reset, reset anything that needs to be reset
re.on_script_reset(function()
    for _, module in pairs(modules) do
        if module.reset then module:reset() end
    end
end)

-- On script save
re.on_config_save(function()
    for _, module in pairs(modules) do
        module:save_config()
    end
end)
