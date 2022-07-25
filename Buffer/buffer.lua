local isWindowOpen = false

-- Utilities Modules
local utils = require("Buffer Modules.Utils")
local config = require("Buffer Modules.Config")

-- -- Misc Modules
local miscellaneous = require("Buffer Modules.Miscellaneous")
local character = require("Buffer Modules.Character")

-- Weapon Modules
local greatSword = require("Buffer Modules.GreatSword")
local longSword = require("Buffer Modules.LongSword")
local shortSword = require("Buffer Modules.ShortSword")
local dualBlades = require("Buffer Modules.DualBlades")
local hammer = require("Buffer Modules.Hammer")
local lance = require("Buffer Modules.Lance")
local gunlance = require("Buffer Modules.Gunlance")
local huntingHorn = require("Buffer Modules.HuntingHorn")
local switchAxe = require("Buffer Modules.SwitchAxe")
local chargeBlade = require("Buffer Modules.ChargeBlade")
local insectGlaive = require("Buffer Modules.InsectGlaive")
local lightBowgun = require("Buffer Modules.LightBowgun")
local heavyBowgun = require("Buffer Modules.HeavyBowgun")
local bow = require("Buffer Modules.Bow")

local modules = {miscellaneous, character, greatSword, longSword, shortSword, dualBlades, hammer, lance, gunlance,
                 huntingHorn, switchAxe, chargeBlade, insectGlaive, lightBowgun, heavyBowgun, bow}

-- Save the config
-- local function generateSaveData(table, keyPrefix)
--     if not table then table = modules end
--     keyPrefix = keyPrefix or ""
--     for key, value in pairs(table) do
--         if type(value) == "table" then
--             if value.title and value.value ~= nil and not value.dontSave then
--                 saveData[string.sub(keyPrefix .. "." .. value.title, 2)] = value.value
--             elseif value.title then
--                 generateSaveData(value, keyPrefix .. "." .. value.title)
--             else
--                 generateSaveData(value, keyPrefix)
--             end
--         end
--     end
-- end

-- -- Load the config, set module data from key and value
-- local function setConfig(key, value, table)
--     if not table then table = modules end

--     local dotIndex = string.find(key, '.', 1, true)
--     if dotIndex then
--         -- log.debug(". found in "..key)
--         local left = string.sub(key, 1, dotIndex - 1)
--         local notLeft = string.sub(key, dotIndex + 1)

--         for k, v in pairs(table) do
--             if type(v) == "table" and v.title == left then
--                 -- log.debug("Going deeper")
--                 setConfig(notLeft, value, v)
--             end
--         end
--     else
--         -- log.debug("Checking for "..key)
--         for k, v in pairs(table) do 

--             if type(v) ~= "function" and v.title == key then
--                  table[k].value = value 
--                 end 
--             end
--     end
-- end

-- -- Load the config, from the JSON file
-- local function loadConfig()
--     if json ~= nil then
--         local settings = json.load_file(configPath)
--         if settings then
--             for settingsKey, settingsValue in pairs(settings) do setConfig(settingsKey, settingsValue) end
--         end
--     end
-- end

-- -- Save the config, to the JSON file 
-- local function saveConfig()
--     if json ~= nil then
--         generateSaveData()
--         json.dump_file(configPath, saveData)
--         saveData = {}
--     end
-- end
 
-- Init the modules
for i, module in pairs(modules) do 
    if module.init ~= nil then module.init() end 
    if module.load_from_config ~= nil then module.load_from_config(config.get_section(module.title)) end
end

-- Load and Initialize everything that we need
-- loadConfig()

-- Add the menu to the REFramework Script Generated UI
re.on_draw_ui(function()
    if imgui.button("Toggle Buffer GUI") then
        isWindowOpen = not isWindowOpen
    end
    imgui.set_next_window_size(Vector2f.new(520, 450), 4)
    imgui.begin_window("Modifiers & Settings", isWindowOpen, 0)
    imgui.spacing()
    for _, module in pairs(modules) do
        if imgui.collapsing_header(module.title) then
            if module.draw ~= nil then module.draw() end
            imgui.separator()
            imgui.spacing()
        end
    end
    imgui.spacing()
    imgui.end_window()
end)

-- On script reset, reset anything that needs to be reset
re.on_script_reset(function()
    for _, module in pairs(modules) do if module.reset ~= nil then module.reset() end end
end)
