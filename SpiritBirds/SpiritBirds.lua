local is_window_open, was_open = false, false
local config_path = "SpiritBirds.json"

local player_manager, creature_manager, quest_manager
local application, application_type

local spawned_birds = {}
local quest_start_time = nil
local quest_start_delay = 2
local SPIRIT_BIRDS = {
    atk = 11,
    def = 12,
    hp = 13,
    spd = 14,
    all = 15,
    gold = 31
}

local autospawn = {
    enabled = true,
    spawned = false
}

local cached_ec_items = nil

-- Load the config
local function load_config()
    if json ~= nil then
        local file = json.load_file(config_path)
        if file then
            autospawn.enabled = file.autospawn
            is_window_open = file.isWindowOpen
        end
    end
end
load_config()

-- Save the config
local function save_config()
    json.dump_file(config_path, {
        autospawn = autospawn.enabled,
        isWindowOpen = is_window_open
    })
end

-- Get the player
local function get_player()
    if not player_manager then player_manager = sdk.get_managed_singleton("snow.player.PlayerManager") end
    local player = player_manager:call("findMasterPlayer")
    if not player then return end
    player = player:call("get_GameObject")
    return player
end

-- Get the player's location
local function get_player_location()
    local player = get_player()
    if not player then return end
    local location = player:call("get_Transform"):call("get_Position")
    if not location then return end
    return location
end

-- Get Quest State [ 0 = Lobby, 1 = Ready/Loading, 2 = Quest, 3 = End, 5 = Abandoned, 7 = Returned ]
local function get_quest_status()
    if not quest_manager then quest_manager = sdk.get_managed_singleton("snow.QuestManager") end
    if quest_manager then
        return quest_manager:get_field("_QuestStatus")
    else
        return 0
    end
end

-- Get up time in seconds
local function get_time()
    if not application then
        application = sdk.get_native_singleton("via.Application")
        application_type = sdk.find_type_definition("via.Application")
    end
    local time = sdk.call_native_func(application, application_type, "get_UpTimeSecond")
    return time
end

-- Get the ec_items - by MorningBao
local function getECItems()
    local creature_manager = sdk.get_managed_singleton("snow.envCreature.EnvironmentCreatureManager")
    if not creature_manager then return nil end

    local ec_list = creature_manager:get_field("_EcPrefabList")
    if not ec_list then return nil end

    local ec_items = ec_list:get_field("mItems")
    if not ec_items then
        log.debug("Unable to get elements from _EcPrefabList")
        return nil
    elseif type(ec_items.get_elements) ~= "function" then
        log.debug("get_elements isn't a function")
        if cached_ec_items then
            log.debug("Returning cached ec_items") 
            return cached_ec_items end
        return nil
    else 
        ec_items = ec_items:get_elements()
    end
    
    cached_ec_items = ec_items
    return ec_items
end

-- Spawn the bird
local function spawn_bird(type)
    local location = get_player_location()
    if not location then return false end
    
    -- Get the EC_Items
    local ec_items = getECItems()
    if not ec_items then     
        log.debug("EC_Items isn't valid")
        return false
    end

    -- Get the EC Bird
    local ec_bird = ec_items[SPIRIT_BIRDS[type]]
    if not ec_bird then
        log.debug("An invalid bird type was just spawned")
        return true
    end
    if not ec_bird:call("get_Standby") then ec_bird:call("set_Standby", true) end

    -- Set the bird as active
    local bird = ec_bird:call("instantiate(via.vec3)", location)
    if sdk.is_managed_object(bird) then
        table.insert(spawned_birds, bird)
        return true
    end
    return false
end

-- Watch for Auto-Spawn of Prism and clear spawned birds after quest ends
re.on_pre_application_entry("UpdateBehavior", function()
    -- If Auto spawn is enabled and quest status says it's active
    if get_quest_status() == 2 and autospawn.enabled and not autospawn.spawned then
        if not autospawn.spawned then
            if quest_start_time == nil then
                quest_start_time = get_time()
            elseif get_time() - quest_start_time > quest_start_delay then
                quest_start_time = nil

                -- REPLACE START
                if spawn_bird("all") then autospawn.spawned = true else
                -- REPLACE END

                    -- If you want to change the the mod to spawn in 5 birds of a different type, just replace the section above with one of the following
                    -- local spawned = false    for i = 0, 5 do    if spawn_bird("hp")   then    spawned = true    end    end    if spawned then autospawn.spawned = true else
                    -- local spawned = false    for i = 0, 5 do    if spawn_bird("atk")  then    spawned = true    end    end    if spawned then autospawn.spawned = true else
                    -- local spawned = false    for i = 0, 5 do    if spawn_bird("def")  then    spawned = true    end    end    if spawned then autospawn.spawned = true else
                    -- local spawned = false    for i = 0, 5 do    if spawn_bird("spd")  then    spawned = true    end    end    if spawned then autospawn.spawned = true else
                    -- local spawned = false    for i = 0, 5 do    if spawn_bird("gold") then    spawned = true    end    end    if spawned then autospawn.spawned = true else
                    -- I have no plans to add this as a feature so you can change it if you want

                    quest_start_time = get_time()
                end
            end
        end

        -- If the quest status is not active, clear the spawned birds, and set autospawned.spawned to false
    elseif get_quest_status() ~= 2 and #spawned_birds > 0 then
        autospawn.spawned = false
        for i, bird in pairs(spawned_birds) do bird:call("destroy", bird) end
        spawned_birds = {}
    end
end)

-- Remove any spawned birds on on script reset
re.on_script_reset(function()
    for i, bird in pairs(spawned_birds) do bird:call("destroy", bird) end
    spawned_birds = {}
end)

-- Draw a window to the REFramework Script Generated UI
re.on_draw_ui(function()
    

    if imgui.button("Toggle SpiritBird GUI") then
        is_window_open = not is_window_open
        save_config()
    end
    if is_window_open then
        
        imgui.push_style_var(11, 5.0) -- Rounded elements
        imgui.push_style_var(2, 10.0) -- Window Padding

        was_open = true
        is_window_open = imgui.begin_window("Spawn SpiritBirds", is_window_open, 64)
        imgui.spacing()
        if imgui.button("   « Attack »    ") then spawn_bird("atk") end
        imgui.same_line()
        if imgui.button("   « Defense »   ") then spawn_bird("def") end
        if imgui.button("   « Health »    ") then spawn_bird("hp") end
        imgui.same_line()
        if imgui.button("   « Stamina »   ") then spawn_bird("spd") end
        imgui.spacing()
        if imgui.button("                 « Rainbow »                  ") then spawn_bird("all") end
        if imgui.button("                  « Golden »                    ") then spawn_bird("gold") end
        local changed = false
        imgui.indent(25)
        imgui.spacing()
        changed, autospawn.enabled = imgui.checkbox("Auto-Spawn Prism", autospawn.enabled)
        imgui.unindent(25)
        if changed then save_config() end
    
        imgui.spacing()
        imgui.spacing()
        imgui.pop_style_var(2)
        imgui.end_window()
    elseif was_open then
        was_open = false
        save_config()
    end
end)
