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
if config.get("is_window_open") == true then
    isWindowOpen = true
end

-- Add the menu to the REFramework Script Generated UI
re.on_draw_ui(function()

    -- Draw button to toggle window state
    if imgui.button("Toggle Buffer GUI") then
        isWindowOpen = not isWindowOpen
        config.set("is_window_open", isWindowOpen)
    end

    if isWindowOpen then
        wasOpen = true
        imgui.set_next_window_size(Vector2f.new(520, 450), 4)

        isWindowOpen = imgui.begin_window("Modifiers & Settings", isWindowOpen, 0)
        imgui.spacing()
        for _, module in pairs(modules) do
            if module.draw ~= nil then module.draw() end
        end
        imgui.spacing()
        imgui.end_window()

    -- If the window is closed, but was just open. 
    -- This is needed because of the close icon on the window not triggering a save to the config
    elseif wasOpen then
        wasOpen = false
        config.set("is_window_open", isWindowOpen)
    end
end)

-- On script reset, reset anything that needs to be reset
re.on_script_reset(function()
    for _, module in pairs(modules) do if module.reset ~= nil then module.reset() end end
end)
