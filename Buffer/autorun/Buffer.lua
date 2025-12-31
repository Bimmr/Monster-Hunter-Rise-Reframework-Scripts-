local version = "2.26"

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
Language.init()

-- Init the key and button binds
bindings.init(modules)

-- Init the modules, and load their config sections
for i, module in pairs(modules) do
    if module.init ~= nil then 
        module:init() 
    else
        -- Old-style module initialization for Character and Miscellaneous
        if module.load_from_config ~= nil then 
            module.load_from_config(Config.get_section(module.title)) 
        end
    end
end

-- Check if the window was last open
if Config.get("window.is_window_open") == true then isWindowOpen = true end

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

        imgui.push_style_var(imgui.ImGuiStyleVar.WindowRounding, WINDOW_ROUNDING) -- Rounded window
        imgui.push_style_var(imgui.ImGuiStyleVar.FrameRounding, FRAME_ROUNDING) -- Rounded elements
        imgui.push_style_var(imgui.ImGuiStyleVar.Alpha, WINDOW_ALPHA) -- Window transparency

        imgui.set_next_window_size(Vector2f.new(WINDOW_WIDTH, WINDOW_HEIGHT), 4)

        isWindowOpen = imgui.begin_window(Language.get(languagePrefix .. "title"), isWindowOpen, 1024)
        bindings.draw()
        if imgui.begin_menu_bar() then

            languagePrefix = "window.bindings."
            if imgui.begin_menu(Language.get(languagePrefix .. "title")) then
                imgui.spacing()
                if imgui.begin_menu("   " .. Language.get(languagePrefix .. "keyboard")) then
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
                            if imgui.button(Language.get(languagePrefix .. "remove").. " "..tostring(k)) then 
                                bindings.remove(3, k) end
                            imgui.same_line()
                            imgui.text("  ")
                        end

                        imgui.end_table()
                        imgui.separator()
                    end

                    if imgui.button("   " .. Language.get(languagePrefix .. "add_keyboard"), "", false) then bindings.popup_open(3) end
                    imgui.spacing()
                    imgui.end_menu()
                end
                if imgui.begin_menu("   " .. Language.get(languagePrefix .. "gamepad")) then
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
                            if imgui.button(Language.get(languagePrefix .. "remove").. " ".. tostring(k)) then 
                                bindings.remove(1, k) end
                            imgui.same_line()
                            imgui.text("  ")
                        end

                        imgui.end_table()
                        imgui.separator()
                    end
                    if imgui.button("   " .. Language.get(languagePrefix .. "add_gamepad")) then bindings.popup_open(1) end
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
                        if imgui.menu_item("   " .. lang .. "   ", "", lang == Language.current, lang ~= Language.current) then Language.change(lang) end
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
            if module.draw_module ~= nil then 
                module:draw_module() 
            elseif module.draw ~= nil then 
                module.draw() 
            end
        end
        imgui.spacing()

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
    bindings.update()
end)

-- On script reset, reset anything that needs to be reset
re.on_script_reset(function()
    for _, module in pairs(modules) do 
        if module.reset ~= nil then 
            module:reset() 
        end 
    end
end)

-- On script save
re.on_config_save(function()
    for _, module in pairs(modules) do 
        if module.save_config ~= nil then
            module:save_config()
        elseif module.create_config_section ~= nil then
            Config.save_section(module.create_config_section())
        end
    end
end)
