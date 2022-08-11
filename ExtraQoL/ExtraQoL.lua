local isWindowOpen, wasOpen = false, false
local lastQuestState = 0
local config = require("ExtraQoL Modules.Config")
local useDrugs = false
local playerInput = nil

-- Get Quest State [ 0 = Lobby, 1 = Ready/Loading, 2 = Quest, 3 = End, 5 = Abandoned, 7 = Returned ]
local function getQuestStatus()
    local questManager = sdk.get_managed_singleton("snow.QuestManager")
    if not questManager then return end
    return questManager:get_field("_QuestStatus")
end

-- Get Player Base, player input is used to ensure the player is the one making the inputs so things work on when not the master player(host)
local function getPlayerBase()
    if not playerInput then
        local inputManager = sdk.get_managed_singleton("snow.StmInputManager")
        local inGameInputDevice = inputManager:get_field("_InGameInputDevice")
        playerInput = inGameInputDevice:get_field("_pl_input")
    end
    return playerInput:get_field("RefPlayer")
end

-- Get Player Data from Player Base
local function getPlayerData()
    local playerBase = utils.getPlayerBase()
    if not playerBase then return end
    return playerBase:call("get_PlayerData")
end

-- Check if the window was last open
if config.get("is_window_open") == true then
    isWindowOpen = true
end

-- Add the menu to the REFramework Script Generated UI
re.on_draw_ui(function()

    -- Draw button to toggle window state
    if imgui.button("Toggle ExtraQoL GUI") then
        isWindowOpen = not isWindowOpen
        config.set("is_window_open", isWindowOpen)
    end

    if isWindowOpen then
        wasOpen = true

        isWindowOpen = imgui.begin_window("Extra QoL", isWindowOpen, 0)
        imgui.spacing()
        local changed = false
        changed, useDrugs = imgui.checkbox("Enable Drugs", useDrugs)
        imgui.spacing()
        imgui.end_window()

    -- If the window is closed, but was just open. 
    -- This is needed because of the close icon on the window not triggering a save to the config
    elseif wasOpen then
        wasOpen = false
        config.set("is_window_open", isWindowOpen)
    end
end)

-- Need to find a better way to check when a quest starts
re.on_pre_application_entry("UpdateBehavior", function()
    if getQuestStatus() == 2 and lastQuestState ~= 2 then
        log.debug("Quest Started")
        local demon = {atk = 68157918, def = 68157923}
        local misc = {dash = 68157913}
        getPlayerBase():call("useItem(snow.data.ContentsIdSystem.ItemId, System.Boolean)", demon.atk, true)
        getPlayerBase():call("useItem(snow.data.ContentsIdSystem.ItemId, System.Boolean)", demon.def, true)
        getPlayerBase():call("useItem(snow.data.ContentsIdSystem.ItemId, System.Boolean)", misc.dash, true)
    end
    lastQuestState = getQuestStatus()
end)


sdk.hook(sdk.find_type_definition("snow.data.ItemSlider"):get_method("notifyConsumeItem(snow.data.ContentsIdSystem.ItemId, System.Boolean)"), function(args)
   
    local item_id = sdk.to_int64(args[3])
    log.debug(item_id)

end, function(retval)end)