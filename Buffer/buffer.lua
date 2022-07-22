local configPath = "Buffer.json"
local saveData = {}

-- Utilities Modules
local utils = require("Buffer Modules.Utils")

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
local function generateSaveData(table, keyPrefix)
    if not table then table = modules end
    keyPrefix = keyPrefix or ""
    for key, value in pairs(table) do
        if type(value) == "table" then
            if value.title and value.value ~= nil and not value.dontSave then
                saveData[string.sub(keyPrefix .. "." .. value.title, 2)] = value.value
            elseif value.title then
                generateSaveData(value, keyPrefix .. "." .. value.title)
            else
                generateSaveData(value, keyPrefix)
            end
        end
    end
end

-- Load the config, set module data from key and value
local function setConfig(key, value, table)
    if not table then table = modules end

    local dotIndex = string.find(key, '.', 1, true)
    if dotIndex then
        -- log.debug(". found in "..key)
        local left = string.sub(key, 1, dotIndex - 1)
        local notLeft = string.sub(key, dotIndex + 1)

        for k, v in pairs(table) do
            if type(v) == "table" and v.title == left then
                -- log.debug("Going deeper")
                setConfig(notLeft, value, v)
            end
        end
    else
        -- log.debug("Checking for "..key)
        for k, v in pairs(table) do if v.title == key then table[k].value = value end end
    end
end

-- Load the config, from the JSON file
local function loadConfig()
    if json ~= nil then
        local settings = json.load_file(configPath)
        if settings then
            for settingsKey, settingsValue in pairs(settings) do setConfig(settingsKey, settingsValue) end
        end
    end
end

-- Save the config, to the JSON file 
local function saveConfig()
    if json ~= nil then
        generateSaveData()
        json.dump_file(configPath, saveData)
        saveData = {}
    end
end

-- Initialize the hooks
local function initHooks(table)
    table = table or modules
    -- Loop through the table
    for k, v in pairs(table) do

        -- If the value is a table, recursively call initHooks
        if type(v) == "table" then
            -- If the table has a path, then it's a hook
            if v.path then
                log.debug("          " .. v.path)
                sdk.hook(sdk.find_type_definition(v.path):get_method(v.func), v.pre, v.post)

                -- If the table has a title but no path, then you'll have to dig deeper
            elseif v.title then
                log.debug("Checking hooks for " .. v.title)
            end
            -- Check deeper hooks
            initHooks(v)
        end
    end
end

-- Initialize the updates
local function initUpdates(table)
    if not table then table = modules end

    -- Loop through the table
    for k, v in pairs(table) do

        -- If the value is a table, recursively call initHooks
        if type(v) == "table" then

            -- If the table has an update, then it needs to be updated
            if v.update then
                -- log.debug("Initializing updates for " .. v.title)
                re.on_pre_application_entry("UpdateBehavior", v.update)

                -- If there is no update, then dig deeper to see if the next level has one
            else
                initUpdates(v)
            end
        end
    end
end

-- Draw the menu
local function drawMenu(table, level)
    if not table then table = modules end
    if not level then level = 0 end
    -- Loop through the table
    for i, obj in ipairs(table) do
        -- If it's a table with a title, draw the title
        if type(obj) == "table" and obj.title then
            -- If the table has a value or type is text draw the table item
            if obj.value ~= nil or obj.type == "text" then
                local changed = false

                -- If the table has a type of checkbox
                if obj.type == "checkbox" then
                    changed, obj.value = imgui.checkbox(obj.title, obj.value)

                    -- If the table has a type of slider
                elseif obj.type == "slider" then
                    local sliderDisplay = "%d"
                    local sliderValue = obj.value
                    if obj.value == -1 then
                        sliderDisplay = "Off" -- If Off
                    elseif obj.display and obj.value >= 0 and type(obj.display) == "table" then
                        sliderDisplay = obj.display[obj.value + 1] -- If display is a table
                    elseif obj.display and obj.value >= 0 then
                        sliderDisplay = obj.display -- If a display format is passed
                    end

                    -- To allow for steps we need to set these and divide them by the steps
                    local sliderMax = obj.max
                    local sliderVal = obj.value
                    local steppedVal = 0
                    if obj.step then
                        sliderMax = math.ceil(obj.max / obj.step)
                        -- If the slider value is greater than -1 (Off), adjust the value by step as well
                        if (obj.value > -1) then
                            -- Divide the value by the step to get the reduced value
                            sliderVal = math.floor(obj.value / obj.step)
                            sliderDisplay = obj.value
                        end
                    end
                    changed, steppedVal = imgui.slider_int(obj.title, sliderVal, obj.min, sliderMax, sliderDisplay)
                    -- If there is a step and the slider isn't off, then multiply the stepped value by the step to get the real total
                    if obj.step and obj.value > -1 then steppedVal = steppedVal * obj.step end
                    -- Update the table's value with the new value
                    obj.value = steppedVal

                    -- If the table has a type of drag, not yet used for anything
                elseif obj.type == "drag" then
                    local dragValue = "Off"
                    if (obj.value >= 0) then dragValue = obj.value end
                    changed, obj.value = imgui.drag_int(obj.title, obj.value, obj.speed, obj.min, obj.max, dragValue)
                    -- If the table has a type of text, draw the text
                elseif obj.type == "text" then
                    imgui.text(obj.title)
                end

                -- If anything changed, save the config
                if changed then saveConfig() end

                -- If anything changed, and the table has a onChange function, call it
                if changed and obj.onChange then obj.onChange() end

                -- If the table doesn't have a value and isn't text, go deeper and see if the next level table has to be drawn
            else
                if level == 0 and imgui.collapsing_header(obj.title) then
                    drawMenu(obj, level + 1)
                    imgui.separator()
                    imgui.spacing()
                elseif level > 0 and imgui.tree_node(obj.title) then
                    drawMenu(obj, level + 1)
                    imgui.separator()
                    imgui.spacing()
                    imgui.tree_pop()
                end

            end
        end
    end
end

-- Init the modules
for _, module in ipairs(modules) do if module.init then module.init() end end

-- Load and Initialize everything that we need
loadConfig()
initHooks()
initUpdates()

-- Add the menu to the REFramework Script Generated UI
re.on_draw_ui(function()
    imgui.begin_window("Modifiers & Settings", nil, 0)
    imgui.spacing()
    drawMenu()
    imgui.spacing()
    imgui.end_window()
end)

-- On script reset, reset anything that needs to be reset
re.on_script_reset(function()
    for _, module in ipairs(modules) do if module.reset then module.reset() end end
end)
