local musicManager, questManager

-- Settings for text
local settings = {
    -- Settings for icons
    iconSettings = {
        enabled = true,
        shape = 1, -- {circle, square}
        colour = "0x80313131",
        size = 6,
        spacing = 4,
        offset = 0
    }
}
-- Variables
local configure = false;
local level = 0;
local screenSize = {
    width = 0,
    height = 0
}
local configPath = "BowLevelIndicator.json"

-- Load the config
local function loadConfig()
    if json ~= nil then
        local file = json.load_file(configPath)
        if file then settings = file end
    end
end
loadConfig()

-- Save the config
local function saveConfig()
    json.dump_file(configPath, settings)
end

-- Function to get the window size
local function getWindowSize()
    local sceneManager = sdk.get_native_singleton("via.SceneManager");
    if not sceneManager then return end
    local sceneView = sdk.call_native_func(sceneManager, sdk.find_type_definition("via.SceneManager"), "get_MainView");
    if not sceneView then return end
    local sceneSize = sceneView:call("get_Size");
    if not sceneSize then return end
    local lwidth = sceneSize:get_field("w");
    if not lwidth then return end
    local lheight = sceneSize:get_field("h");
    if not lheight then return end
    screenSize = {
        width = lwidth,
        height = lheight
    }
end
-- Check if player is in battle, code by raffRun
local function checkIfInBattle()

    if not musicManager then musicManager = sdk.get_managed_singleton("snow.wwise.WwiseMusicManager") end
    if not questManager then questManager = sdk.get_managed_singleton("snow.QuestManager") end

    local currentBattleState = musicManager:get_field("_CurrentEnemyAction")
    local currentMixUsed = musicManager:get_field("_Current")

    local currentQuestType = questManager:get_field("_QuestType")
    local currentQuestStatus = questManager:get_field("_QuestStatus")

    local inBattle = currentBattleState == 3 -- Fighting a monster
    or currentMixUsed == 37 -- Fighting a wave of monsters
    or currentMixUsed == 10 -- Stronger battle music mix is being used
    or currentMixUsed == 31 -- Used in some arena battles
    or currentQuestType == 64 -- Fighting in the arena (Utsushi)

    local isQuestComplete = currentQuestStatus == 3 -- Completed the quest
    or currentQuestStatus == 0 -- Not in a quest

    return inBattle and not isQuestComplete
end

local function getPlayer()
    return sdk.get_managed_singleton("snow.player.PlayerManager"):call("findMasterPlayer")
end

local function isWeaponSheathed()
    local player = getPlayer()
    local playerAction = sdk.find_type_definition("snow.player.PlayerBase"):get_field("<RefPlayerAction>k__BackingField"):get_data(player)
    return sdk.find_type_definition("snow.player.PlayerAction"):get_field("_weaponFlag"):get_data(playerAction) == 0
end

local function isBow()
    local player = getPlayer()
    return player:get_field("_playerWeaponType") == 13
end
local function isAiming()
    local player = getPlayer()
    return player:get_field("<IsAimMode>k__BackingField")
end

-- Hook to get the Bow Level
sdk.hook(sdk.find_type_definition("snow.player.Bow"):get_method("update"), function(args)
    local bow = sdk.to_managed_object(args[2])
    if not bow then return end
    level = bow:get_field("<ChargeLv>k__BackingField") + 1
end, function(retval)
end)

re.on_frame(function()
    if screenSize.width == 0 then getWindowSize() end

    -- TODO: Find a way to check if the player is aiming, and use that instead, could also check what weapon type is being held
    if isBow() and isAiming() then

            local lastX = screenSize.width / 2 - settings.iconSettings.size / 2 - (settings.iconSettings.size * (level + 1) / 2) - (settings.iconSettings.spacing * (level + 1) / 2)
            for i = 1, level do
                local x = lastX + settings.iconSettings.size + settings.iconSettings.spacing
                lastX = x

                -- Draw a square
                if settings.iconSettings.shape == 2 then
                    draw.filled_rect(x, screenSize.height / 2 - settings.iconSettings.size / 2, settings.iconSettings.size, settings.iconSettings.size, settings.iconSettings.colour)
                    draw.outline_rect(x, screenSize.height / 2 - settings.iconSettings.size / 2, settings.iconSettings.size, settings.iconSettings.size,
                                      settings.iconSettings.colour)

                    -- Draw a circle
                elseif settings.iconSettings.shape == 1 then
                    x = x + settings.iconSettings.size / 2
                    local y = screenSize.height / 2
                    local radius = settings.iconSettings.size / 2
                    local angle = 0
                    local step = math.pi * 2 / settings.iconSettings.size
                    for i = 0, settings.iconSettings.size do
                        local x1 = x + radius * math.cos(angle)
                        local y1 = y + radius * math.sin(angle)
                        local x2 = x + radius * math.cos(angle + step)
                        local y2 = y + radius * math.sin(angle + step)
                        draw.line(x1, y1, x2, y2, settings.iconSettings.colour)
                        angle = angle + step
                    end
                end
        end
    end
end)

re.on_draw_ui(function()
    local changed = false

    if (imgui.button("Bow Level Indicator")) then configure = true end
    if configure and imgui.begin_window("Bow Level Indicator Config", true, 0) then
       
            changed, settings.iconSettings.enabled = imgui.checkbox("Enabled", settings.iconSettings.enabled)
            if changed then saveConfig() end
            local possibleShapes = {"Circle", "Square"}
            changed, settings.iconSettings.shape = imgui.combo("Shape", settings.iconSettings.shape, possibleShapes)
            if changed then saveConfig() end

            if imgui.tree_node("Colour") then
                changed, settings.iconSettings.colour = imgui.color_picker("Colour", settings.iconSettings.colour)
                if changed then saveConfig() end
                imgui.tree_pop()
            end
            changed, settings.iconSettings.size = imgui.drag_int("Size", settings.iconSettings.size, 1, 0, 50)
            if changed then saveConfig() end
            changed, settings.iconSettings.spacing = imgui.drag_int("Spacing", settings.iconSettings.spacing, 1, 0, 20)
            if changed then saveConfig() end
            


        imgui.end_window()
    end
end)
