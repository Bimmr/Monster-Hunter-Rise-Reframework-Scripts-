local version = "2.23"

local isWindowOpen, wasOpen = false, false

-- Utilities and Helpers
local utils = require("Buffer.Misc.Utils")
local config = require("Buffer.Misc.Config")
local language = require("Buffer.Misc.Language")
local bindings = require("Buffer.Misc.Bindings")

-- -- Misc Modules
local miscellaneous = require("Buffer.Modules.Miscellaneous")
local character = require("Buffer.Modules.Character")

-- Weapon Modules
local greatSword = require("Buffer.Modules.GreatSword")
local longSword = require("Buffer.Modules.LongSword")
local shortSword = require("Buffer.Modules.ShortSword")
local dualBlades = require("Buffer.Modules.DualBlades")
local hammer = require("Buffer.Modules.Hammer")
local lance = require("Buffer.Modules.Lance")
local gunlance = require("Buffer.Modules.Gunlance")
local huntingHorn = require("Buffer.Modules.HuntingHorn")
local switchAxe = require("Buffer.Modules.SwitchAxe")
local chargeBlade = require("Buffer.Modules.ChargeBlade")
local insectGlaive = require("Buffer.Modules.InsectGlaive")
local lightBowgun = require("Buffer.Modules.LightBowgun")
local heavyBowgun = require("Buffer.Modules.HeavyBowgun")
local bow = require("Buffer.Modules.Bow")

local modules = {miscellaneous, character, greatSword, longSword, shortSword, dualBlades, hammer, lance, gunlance, huntingHorn, switchAxe, chargeBlade, insectGlaive, lightBowgun,
                 heavyBowgun, bow}

-- Load the languages
language.init()

-- Init the key and button binds
bindings.init(modules)

-- Init the modules, and load their config sections
for i, module in pairs(modules) do
    if module.init ~= nil then module.init() end
    if module.load_from_config ~= nil then module.load_from_config(config.get_section(module.title)) end
end

-- Check if the window was last open
if config.get("window.is_window_open") == true then isWindowOpen = true end

-- Add the menu to the REFramework Script Generated UI
re.on_draw_ui(function()

    if language.font.data ~= nil then imgui.push_font(language.font.data) end
    local languagePrefix = "window."

    -- Draw button to toggle window state
    if imgui.button(language.get(languagePrefix .. "toggle_button")) then
        isWindowOpen = not isWindowOpen
        config.set("window.is_window_open", isWindowOpen)
    end

    if isWindowOpen then
        wasOpen = true

        imgui.push_style_var(11, 5.0) -- Rounded elements
        imgui.push_style_var(2, 10.0) -- Window Padding

        imgui.set_next_window_size(Vector2f.new(520, 450), 4)

        isWindowOpen = imgui.begin_window(language.get(languagePrefix .. "title"), isWindowOpen, 1024)
        bindings.draw()
        if imgui.begin_menu_bar() then

            languagePrefix = "window.bindings."
            if imgui.begin_menu(language.get(languagePrefix .. "title")) then
                imgui.spacing()
                if imgui.begin_menu("   " .. language.get(languagePrefix .. "keyboard")) then
                    imgui.spacing()
                    if #bindings.keys > 0 then
                        imgui.begin_table("bindings_keyboard", 3, nil, nil, nil)

                        for k, v in pairs(bindings.keys) do
                            imgui.table_next_row()
                            imgui.table_next_column()
                            local keys = v.input
                            local data = v.data
                            local title = bindings.get_formatted_title(data.path)
                            imgui.text("   " .. title)
                            imgui.table_next_column()
                            local key_string = ""
                            for index, key in pairs(keys) do
                                key_string = key_string .. bindings.get_key_name(key)
                                if index < #keys then key_string = key_string .. " + " end
                            end
                            imgui.text("   [ " .. key_string .. " ]     ")
                            imgui.table_next_column()
                            if imgui.button(language.get(languagePrefix .. "remove").. " "..tostring(k)) then 
                                bindings.remove(3, k) end
                            imgui.same_line()
                            imgui.text("  ")
                        end

                        imgui.end_table()
                        imgui.separator()
                    end

                    if imgui.button("   " .. language.get(languagePrefix .. "add_keyboard"), "", false) then bindings.popup_open(3) end
                    imgui.spacing()
                    imgui.end_menu()
                end
                if imgui.begin_menu("   " .. language.get(languagePrefix .. "gamepad")) then
                    imgui.spacing()
                    if #bindings.btns > 0 then
                        imgui.begin_table("bindings_gamepad", 3, nil, nil, nil)

                        for k, v in pairs(bindings.btns) do
                            imgui.table_next_row()
                            imgui.table_next_column()
                            local btns = v.input
                            local data = v.data
                            
                            local title = bindings.get_formatted_title(data.path)
                            imgui.text("   " .. title)
                            imgui.table_next_column()
                            local key_string = ""
                            for index, key in pairs(btns) do
                                key_string = key_string .. bindings.get_btn_name(key)
                                if index < #btns then key_string = key_string .. " + " end
                            end
                            imgui.text("   [ " .. key_string .. " ]     ")
                            imgui.table_next_column()
                            if imgui.button(language.get(languagePrefix .. "remove").. " ".. tostring(k)) then 
                                bindings.remove(1, k) end
                            imgui.same_line()
                            imgui.text("  ")
                        end

                        imgui.end_table()
                        imgui.separator()
                    end
                    if imgui.button("   " .. language.get(languagePrefix .. "add_gamepad")) then bindings.popup_open(1) end
                    imgui.spacing()
                    imgui.end_menu()
                end

                imgui.spacing()
                imgui.end_menu()
            end
            languagePrefix = "window."
            if imgui.begin_menu(language.get(languagePrefix .. "settings")) then
                imgui.spacing()
                if imgui.begin_menu("   " .. language.get(languagePrefix .. "language")) then
                    imgui.spacing()
                    for _, lang in pairs(language.sorted) do
                        if imgui.menu_item("   " .. lang .. "   ", "", lang == language.current, lang ~= language.current) then language.change(lang) end
                    end
                    imgui.spacing()
                    imgui.end_menu()
                end
                if imgui.begin_menu("   " .. language.get(languagePrefix .. "font_size")) then
                    imgui.spacing()
                    language.font.temp_size = language.font.temp_size or language.font.size
                    local changed = false
                    changed, language.font.temp_size = imgui.slider_int(language.get(languagePrefix .. "font_size") .. " ", language.font.temp_size, 8, 24)
                    imgui.same_line()
                    if imgui.button(language.get(languagePrefix .. "font_size_apply")) then
                        language.change(language.current, language.font.temp_size)
                        language.font.temp_size = nil
                    end
                    imgui.spacing()
                    imgui.end_menu()
                end
                imgui.spacing()
                imgui.end_menu()
            end

            if imgui.begin_menu(language.get(languagePrefix .. "about")) then
                imgui.spacing()
                imgui.text("   " .. language.get(languagePrefix .. "author") .. ": Bimmr   ")
                if language.languages[language.current]["_TRANSLATOR"] then
                    imgui.text("   " .. language.get(languagePrefix .. "translator") .. ": " .. language.languages[language.current]["_TRANSLATOR"] .. "   ")
                end
                imgui.text("   " .. language.get(languagePrefix .. "version") .. ": " .. version .. "   ")

                imgui.spacing()
                imgui.end_menu()
            end

            imgui.end_menu_bar()
        end
        imgui.separator()

        imgui.spacing()
        for _, module in pairs(modules) do if module.draw ~= nil then module.draw() end end
        imgui.spacing()

        imgui.spacing()
        imgui.end_window()
        imgui.pop_style_var(2)

        -- If the window is closed, but was just open. 
        -- This is needed because of the close icon on the window not triggering a save to the config
    elseif wasOpen then
        wasOpen = false
        config.set("window.is_window_open", isWindowOpen)
    end

    if language.font.data ~= nil then imgui.pop_font() end
end)

-- Keybinds
re.on_frame(function()
    bindings.update()
end)

-- On script reset, reset anything that needs to be reset
re.on_script_reset(function()
    for _, module in pairs(modules) do if module.reset ~= nil then module.reset() end end
end)

-- On script save
re.on_config_save(function()
    for _, module in pairs(modules) do config.save_section(module.create_config_section()) end
end)
