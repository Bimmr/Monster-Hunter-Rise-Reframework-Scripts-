local version = "1.9"

local config_path = "SpiritBirds.json"
local is_window_open = false

-------------------------------- Constants & Variables --------------------------------
local SPIRIT_BIRDS = {
    atk = 10,
    def = 11,
    hp = 12,
    spd = 13,
    all = 14,
    gold = 30
}
local QUEST_START_DELAY = 2

local spawned_birds = {}
local quest_start_time = nil

-- Cached singletons
local player_manager
local quest_manager
local creature_manager

-------------------------------- Config Management --------------------------------

local autospawn = { enabled = true, spawned = false }

-- Load the config file   
local file = json.load_file(config_path)
if file then
    autospawn.enabled = file.autospawn
    is_window_open = file.isWindowOpen
end

--- Save the config file
local function saveConfig()
    json.dump_file(config_path, {
        autospawn = autospawn.enabled,
        isWindowOpen = is_window_open,
    })
end

-------------------------------- Utility Functions --------------------------------

--- Get Player Location
--- @return via.vec3 | nil
local function getPlayerLocation()
    local player_manager = player_manager or sdk.get_managed_singleton("snow.player.PlayerManager")
    if not player_manager then return nil end

    local player = player_manager:call("findMasterPlayer")
    if not player then return nil end
    
    local player_object = player:call("get_GameObject")
    if not player_object then return nil end
    
    return player_object:call("get_Transform"):call("get_Position")
end

--- Get Quest State
--- @return number [ 0 = Lobby, 1 = Ready/Loading, 2 = Quest, 3 = End, 5 = Abandoned, 7 = Returned ]
local function getQuestStatus()
    local quest_manager = quest_manager or sdk.get_managed_singleton("snow.QuestManager")
    if not quest_manager then return 0 end

    return quest_manager:get_field("_QuestStatus")
end

--- Get Environment Creature Items
--- @return table | nil
local function getECItems()
    local creature_manager = creature_manager or sdk.get_managed_singleton("snow.envCreature.EnvironmentCreatureManager")
    if not creature_manager then return nil end

    local ec_list = creature_manager:get_field("_EcPrefabList")
    if not ec_list then return nil end

    local ec_items = ec_list:get_field("mItems")
    if not ec_items then return nil end
    
    return ec_items
end

--- Spawn a Spirit Bird of the specified type at the player's location
--- @param type string One of "atk", "def", "hp", "spd", "all", "gold"
--- @return boolean True if spawned successfully, false otherwise
local function spawnBird(type)
    local ec_items = getECItems()
    if not ec_items then return false end

    local ec_bird = ec_items[SPIRIT_BIRDS[type]]
    if not ec_bird then return true end
    
    if not ec_bird:call("get_Standby") then
        ec_bird:call("set_Standby", true) 
    end
    local bird = ec_bird:call("instantiate(via.vec3)", getPlayerLocation())


    if sdk.is_managed_object(bird) then  -- Rainbow isn't always ready to spawn, so we need to check if it did
        table.insert(spawned_birds, bird)
        return true
    end
    return false
end

--- Reset the autospawn state and destroy all spawned birds
local function reset()
    autospawn.spawned = false
    quest_start_time = nil
    for _, bird in ipairs(spawned_birds) do 
        bird:call("destroy", bird) 
    end
    spawned_birds = {}
end

-------------------------------- Hooks --------------------------------

-- Auto-spawn birds on quest start and cleanup on quest end
re.on_pre_application_entry("UpdateBehavior", function()
    local quest_status = getQuestStatus()
    
    -- If in quest and autospawn enabled, try to spawn bird after delay
    if quest_status == 2 and autospawn.enabled and not autospawn.spawned then

        -- Start the delay timer
        if not quest_start_time then
            quest_start_time = os.clock()

        -- After delay, attempt to spawn bird
        elseif os.clock() - quest_start_time > QUEST_START_DELAY then

                -- REPLACE START
                if spawnBird("all") then autospawn.spawned = true
                -- REPLACE END

                    -- If you want to change the the mod to spawn in 5 birds of a different type, just replace the section above with one of the following
                    -- local spawned = false    for i = 0, 5 do    if spawn_bird("hp")   then    spawned = true    end    end    if spawned then autospawn.spawned = true else
                    -- local spawned = false    for i = 0, 5 do    if spawn_bird("atk")  then    spawned = true    end    end    if spawned then autospawn.spawned = true else
                    -- local spawned = false    for i = 0, 5 do    if spawn_bird("def")  then    spawned = true    end    end    if spawned then autospawn.spawned = true else
                    -- local spawned = false    for i = 0, 5 do    if spawn_bird("spd")  then    spawned = true    end    end    if spawned then autospawn.spawned = true else
                    -- local spawned = false    for i = 0, 5 do    if spawn_bird("gold") then    spawned = true    end    end    if spawned then autospawn.spawned = true else
                    
                    -- If you want to spawn multiple then you have to do something like this - just change hp and spd to the ones you want
                    -- local spawned = false for i = 0, 5 do if spawn_bird("hp") and spawn_bird("spd")then spawned = true end end if spawned then autospawn.spawned = true else
                    
                else
                    -- Wait the delay and try again
                    quest_start_time = os.clock()
            end
        end
    end
    
    -- Cleanup spawned birds when quest ends
    if quest_status ~= 2 and #spawned_birds > 0 then
       reset()
    end
end)

-- Cleanup on script reset
re.on_script_reset(function()
    reset()
end)


-------------------------------- ImGui User Interface --------------------------------
re.on_draw_ui(function()
    
    -- Main Window Toggle
    imgui.indent(2)
    if imgui.button("Toggle SpiritBird GUI") then
        is_window_open = not is_window_open
        saveConfig()
    end
    imgui.unindent(2)
    
    if not is_window_open then return end
    
    imgui.push_style_var(3, 7.5) -- Rounded window
    is_window_open = imgui.begin_window("Spawn SpiritBirds", is_window_open, 64)
    imgui.spacing()

    -- Get size of row and column widths
    local row_width = 200
    local col_width = row_width / 2
    local text_height = imgui.calc_text_size("SpiritBirds").y+10
    -- Define button sizes
    local small_btn_size = Vector2f.new(col_width, text_height)
    local large_btn_size = Vector2f.new(row_width + 8, text_height)

    -- Create table for buttons
    imgui.begin_table("SpiritBirds", 2, 0)
    imgui.table_setup_column("1", 0, col_width)
    imgui.table_setup_column("2", 0, col_width)
    imgui.table_next_row()
    imgui.table_next_column()

    if imgui.button("« Attack »", small_btn_size) then spawnBird("atk") end
    imgui.table_next_column()
    if imgui.button("« Defense »", small_btn_size) then spawnBird("def") end 

    imgui.table_next_row()
    imgui.table_next_column()
    
    if imgui.button("« Health »", small_btn_size) then spawnBird("hp") end
    imgui.table_next_column()
    if imgui.button("« Stamina »", small_btn_size) then spawnBird("spd") end

    imgui.end_table()

    if imgui.button("« Rainbow »", large_btn_size) then spawnBird("all") end
    if imgui.button("« Golden »", large_btn_size) then spawnBird("gold") end

    imgui.spacing()

    -- Auto-Spawn Checkbox, centered
    local text_width = imgui.calc_text_size("Auto-Spawn Prism").x
    local cursor_pos = imgui.get_cursor_pos()
    cursor_pos.x = (row_width - text_width - 10) / 2
    imgui.set_cursor_pos(cursor_pos)
    local changed
    changed, autospawn.enabled = imgui.checkbox("Auto-Spawn Prism", autospawn.enabled)
    if changed then saveConfig() end
    
    imgui.spacing()
    imgui.spacing()
    imgui.pop_style_var(1)
    imgui.end_window()
end)