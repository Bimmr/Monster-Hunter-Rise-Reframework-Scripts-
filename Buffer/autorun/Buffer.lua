local isWindowOpen, wasOpen = false, false

-- Utilities and Helpers
local utils = require("Buffer.Misc.Utils")
local config = require("Buffer.Misc.Config")
local language = require("Buffer.Misc.Language")

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
    if imgui.button(language.get(languagePrefix.."toggle_button")) then
        isWindowOpen = not isWindowOpen
        config.set("window.is_window_open", isWindowOpen)
    end

    if isWindowOpen then
        wasOpen = true
        imgui.set_next_window_size(Vector2f.new(520, 450), 4)

        isWindowOpen = imgui.begin_window(language.get(languagePrefix.."title"), isWindowOpen, 1024)
        if imgui.begin_menu_bar() then
            if imgui.begin_menu(language.get(languagePrefix.."settings")) then
                imgui.spacing()
                if imgui.begin_menu(language.get(languagePrefix.."language")) then
                    imgui.spacing()
                    for lang, value in pairs(language.languages) do
                        if imgui.menu_item("   " .. lang .. "   ", "", lang == language.current, lang ~= language.current) then
                           language.change(lang)
                        end
                    end
                    imgui.spacing()
                    imgui.end_menu()
                end
                if imgui.begin_menu(language.get(languagePrefix.."font_size")) then
                    imgui.spacing()
                    language.font.temp_size = language.font.temp_size or language.font.size
                    local changed = false
                    changed, language.font.temp_size = imgui.slider_int(language.get(languagePrefix.."font_size").." ", language.font.temp_size, 8, 24)
                    imgui.same_line()
                    if imgui.button(language.get(languagePrefix.."font_size_apply")) then
                        language.change(language.current, language.font.temp_size)
                        language.font.temp_size = nil
                    end
                    imgui.spacing()
                    imgui.end_menu()
                end
                imgui.spacing()
                imgui.end_menu()
            end

            if imgui.begin_menu(language.get(languagePrefix.."about")) then
                imgui.spacing()
                imgui.text("   "..language.get(languagePrefix.."author")..": Bimmr   ")
                imgui.text("   "..language.get(languagePrefix.."version")..": 2.15   ")
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

        -- If the window is closed, but was just open. 
        -- This is needed because of the close icon on the window not triggering a save to the config
    elseif wasOpen then
        wasOpen = false
        config.set("window.is_window_open", isWindowOpen)
    end

    if language.font.data ~= nil then imgui.pop_font() end
end)

-- On script reset, reset anything that needs to be reset
re.on_script_reset(function()
    for _, module in pairs(modules) do if module.reset ~= nil then module.reset() end end
end)
