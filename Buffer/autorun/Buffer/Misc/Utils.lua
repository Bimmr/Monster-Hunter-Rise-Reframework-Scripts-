local utils = {}

local kitchenFacility, mealFunc
local playerInput

local musicManager, questManager

-- Do nothing
function utils.nothing(retval)
    return retval
end

-- Get Player Base, player input is used to ensure the player is the one making the inputs so things work on when not the master player(host)
function utils.getPlayerBase()
    if not playerInput then
        local inputManager = sdk.get_managed_singleton("snow.StmInputManager")
        local inGameInputDevice = inputManager:get_field("_InGameInputDevice")
        playerInput = inGameInputDevice:get_field("_pl_input")
    end
    return playerInput:get_field("RefPlayer")
end

-- Get Player Data from Player Base
function utils.getPlayerData()
    local playerBase = utils.getPlayerBase()
    if not playerBase then return end
    return playerBase:call("get_PlayerData")
end

-- Get kitchen Facility
function utils.getKitchenFacility()
    if not kitchenFacility then
        local facilityDataManager = sdk.get_managed_singleton("snow.data.FacilityDataManager")
        if not facilityDataManager then return end
        kitchenFacility = facilityDataManager:get_field("_Kitchen")
    end
    return kitchenFacility
end

-- Get MealFunct from Kitchen Facility
function utils.getMealFunc()
    if not mealFunc then
        local kitchenFacility = utils.getKitchenFacility()
        if not kitchenFacility then return end
        mealFunc = kitchenFacility:get_field("_MealFunc")
    end
    return mealFunc
end

-- Function to get length of table
function utils.getLength(obj)
    local count = 0

    -- Count the items in the table
    for _ in pairs(obj) do count = count + 1 end
    return count
end

-- Check if player is in battle, code by raffRun
function utils.checkIfInBattle()

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

-- Custom tooltip, adds a spacing before the end of window by default,
-- but by using an empty text on the top and bottom it makes it even
function utils.tooltip(text)
    imgui.same_line()
    imgui.text("(?)")
    if imgui.is_item_hovered() then imgui.set_tooltip("  "..text.."  ") end
end

-- Split a string into an array
function utils.split(text, delim)
    -- returns an array of fields based on text and delimiter (one character only)
    local result = {}
    local magic = "().%+-*?[]^$"

    if delim == nil then
        delim = "%s"
    elseif string.find(delim, magic, 1, true) then
        delim = "%" .. delim
    end

    local pattern = "[^" .. delim .. "]+"
    for w in string.gmatch(text, pattern) do table.insert(result, w) end
    return result
end


function utils.generate_enum(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end
    local fields = t:get_fields()
    local enum = {}
    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)
            enum[name] = raw_value
        end
    end
    return enum
end


function utils.send_message(text)
    local chatManager = sdk.get_managed_singleton("snow.gui.ChatManager");
    chatManager:call("reqAddChatInfomation", text, 0);
end

return utils
