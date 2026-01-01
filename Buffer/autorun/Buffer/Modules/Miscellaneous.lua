local ModuleBase = require("Buffer.Misc.ModuleBase")
local Utils = require("Buffer.Misc.Utils")
local Config = require("Buffer.Misc.Config")
local Language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("miscellaneous", {
    consumables = {
        items = false,
        endemic_life = false
    },
    wirebugs = {
        unlimited_ooc = false,
        unlimited = false,
        give_3 = false,
        unlimited_powerup = false
    },
    canteen = {
        dango_100_no_ticket = false,
        dango_100_ticket = false,
        level_4 = false,
        all_dangos = false
    },
    unlimited_recon = false,
    hidden = {}
})

local managed_gui_kitchen = nil

function Module.create_hooks()
    sdk.hook(sdk.find_type_definition("snow.data.ItemSlider"):get_method("notifyConsumeItem(snow.data.ContentsIdSystem.ItemId, System.Boolean)"), function(args)
        local item_id = sdk.to_int64(args[3])
        -- Marionette Spider = 69206037
        -- Ec Item = 69206016 - 69206040
        if Module.data.consumables.endemic_life and ((item_id >= 69206016 and item_id <= 69206040) or (item_id == 69206037)) then
            if item_id == 69206037 then -- Needs to be reset otherwise it will be stuck in the "consumed" state
                local creature_manager = sdk.get_managed_singleton("snow.envCreature.EnvironmentCreatureManager")
                local playerBase = Utils.getMasterPlayer()
                creature_manager:call("setEc057UseCount", playerBase:get_field("_PlayerIndex"), 0)
            end
            return sdk.PreHookResult.SKIP_ORIGINAL
        elseif Module.data.consumables.items and not ((item_id >= 69206016 and item_id <= 69206040) or (item_id == 69206037)) then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end

    end)

    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.player.PlayerManager") then return end
        local playerBase = Utils.getMasterPlayer()
        if not playerBase then return end

        if Module.data.wirebugs.give_3 then
            playerBase:set_field("<HunterWireWildNum>k__BackingField", 1)
            playerBase:set_field("_HunterWireNumAddTime", 7000)
        end

        if Module.data.wirebugs.unlimited_powerup then
            local playerData = Utils.getPlayerData()
            if not playerData then return end
            playerData:set_field("_WireBugPowerUpTimer", 10700)
        end

    end)

    sdk.hook(sdk.find_type_definition("snow.player.fsm.PlayerFsm2ActionHunterWire"):get_method("start"), nil, function(retval)
        if (Module.data.wirebugs.unlimited_ooc and not Utils.checkIfInBattle()) or Module.data.wirebugs.unlimited then
            local playerBase = Utils.getMasterPlayer()
            if not playerBase then return end

            local wireGuages = playerBase:get_field("_HunterWireGauge")
            if not wireGuages then return end

            wireGuages = wireGuages:get_elements()
            for i, gauge in ipairs(wireGuages) do
                gauge:set_field("_RecastTimer", 0)
                gauge:set_field("_RecoverWaitTimer", 0)
            end
        end
    end)

    sdk.hook(sdk.find_type_definition("snow.data.DangoData"):get_method("get_SkillActiveRate"), function(args)
        if Module.data.canteen.dango_100_no_ticket or Module.data.canteen.dango_100_ticket then
            local managed = sdk.to_managed_object(args[2])
            if not managed then return end
            if not managed:get_type_definition():is_a("snow.data.DangoData") then return end

            local isUsingTicket = Utils.getMealFunc():call("getMealTicketFlag")

            if isUsingTicket or Module.data.canteen.dango_100_no_ticket then
                thread.get_hook_storage()["dango_managed"] = true
            end
        end
    end, function(retval)
        if thread.get_hook_storage()["dango_managed"] then
            return sdk.to_ptr(200)
        end
        return retval
    end)

    --- Cache and return value helper function
    --- @param cache_key string The key to identify the cached value
    --- @param current_value any The current value to potentially cache
    --- @param target_value any The value to return when enabled is true
    --- @param enabled boolean Whether to return the target value or restore the cached value
    --- @return any The value to use (either target value or cached value)
    --- @return boolean Whether a value was restored from cache
    function Module.cache_and_return_value(cache_key, current_value, target_value, enabled)
        log.debug("Cache check for " .. cache_key .. ": " .. tostring(current_value) .. " (enabled: " .. tostring(enabled) .. ")")
        if enabled then
            if Module.old[cache_key] == nil then
                Module.old[cache_key] = current_value
                log.debug("Caching old value: " .. tostring(current_value))
            end
            log.debug("Returning target value: " .. tostring(target_value))
            return target_value, false
        elseif Module.old[cache_key] ~= nil then
            log.debug("Restoring cached value: " .. tostring(Module.old[cache_key]))
            local cached_value = Module.old[cache_key]
            Module.old[cache_key] = nil
            return cached_value, true
        end
    end

    sdk.hook(sdk.find_type_definition("snow.facility.kitchen.MealFunc"):get_method("updateList"), function(args)
        if Module.data.canteen.level_4 and not Module.data.hidden.level_4_was_enabled then
            Module.data.hidden.level_4_was_enabled = true
            local dangoLevels = Utils.getMealFunc():get_field("SpecialSkewerDangoLv")
            local level4 = sdk.create_uint32(4)
            level4:set_field("mValue", 4)
            for i = 0, 2 do dangoLevels[i] = level4 end

        elseif not Module.data.canteen.level_4 and Module.data.hidden.level_4_was_enabled then
            Module.data.hidden.level_4_was_enabled = false
            local dangoLevels = Utils.getMealFunc():get_field("SpecialSkewerDangoLv")
            for i = 0, 2 do
                dangoLevels[i] = sdk.create_uint32(i == 0 and 4 or i == 1 and 3 or 1)-- lua version of i == 0 ? 4 : i == 1 ? 3 : 1
            end
        end
    end)
    
    sdk.hook(sdk.find_type_definition("snow.gui.fsm.kitchen.GuiKitchen"):get_method("setDangoTabList"), function(args)
        if Module.data.canteen.level_4 and not Module.data.hidden.level_4GUI_was_enabled then
            Module.data.hidden.level_4GUI_was_enabled = true
            local managed = sdk.to_managed_object(args[2])
            managed_gui_kitchen = sdk.to_managed_object(args[2])
            if not managed then return end
            local dangoLevels = managed:get_field("SpecialSkewerDangoLv")
            local level4 = sdk.create_uint32(4)
            level4:set_field("mValue", 4)
            for i = 0, 2 do dangoLevels[i] = level4 end

        elseif not Module.data.canteen.level_4 and Module.data.hidden.level_4GUI_was_enabled then
            Module.data.hidden.level_4GUI_was_enabled = false
            local managed = sdk.to_managed_object(args[2])
            if not managed then return end
            local dangoLevels = managed:get_field("SpecialSkewerDangoLv")
            for i = 0, 2 do
                dangoLevels[i] = sdk.create_uint32(i == 0 and 4 or i == 1 and 3 or 1)-- lua version of i == 0 ? 4 : i == 1 ? 3 : 1
            end
        end
    end)
  
    sdk.hook(sdk.find_type_definition("snow.facility.kitchen.MealFunc"):get_method("updateList"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.facility.kitchen.MealFunc") then return end
        
        local enabled = Module.data.canteen.all_dangos
        local dangoList = managed:get_field("<DangoDataList>k__BackingField"):get_field("mItems")
        
        if dangoList and dangoList.get_elements then
            dangoList = dangoList:get_elements()
        end

        for i, dango in pairs(dangoList) do
            local dangoParam = dango:get_field("_Param")
            
            local unlock_val = Module.cache_and_return_value("dango_unlock_" .. i, dangoParam:get_field("_UnlockFlag"), 5, enabled)
            if unlock_val then dangoParam:set_field("_UnlockFlag", unlock_val) end

            local rate_val = Module.cache_and_return_value("dango_rate_" .. i, dangoParam:get_field("_DailyRate"), 0, enabled)
            if rate_val then dangoParam:set_field("_DailyRate", rate_val) end
        end
    end)

    sdk.hook(sdk.find_type_definition("snow.otomo.OtomoReconCharaManager"):get_method("onCompleteReconOtomoAct"), function(args)
        if Module.data.unlimited_recon then
            local managed = sdk.to_managed_object(args[2])
            if not managed then return end
                thread.get_hook_storage()["recon_managed"] = managed
        end
    end, function(retval)
        if thread.get_hook_storage()["recon_managed"] ~= nil then
            thread.get_hook_storage()["recon_managed"]:set_field("_IsUseOtomoReconFastTravel", false)
        end
    end)
    
end

function Module.add_ui()

    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    
    local row_width = imgui.calc_item_width()
    local max_width, col_width = 0, 0   


    local unlimited_recon_change = false
    unlimited_recon_change, Module.data.unlimited_recon = imgui.checkbox(Language.get(languagePrefix .. "unlimited_recon"), Module.data.unlimited_recon)
    if unlimited_recon_change and Module.data.unlimited_recon then
        sdk.get_managed_singleton("snow.data.OtomoReconManager"):set_field("_IsUseOtomoReconFastTravel", false)
    end
    any_changed = any_changed or unlimited_recon_change

    languagePrefix = Module.title .. ".consumables."
    if imgui.tree_node(Language.get(languagePrefix .. "title")) then
        changed, Module.data.consumables.items = imgui.checkbox(Language.get(languagePrefix .. "items"), Module.data.consumables.items)
        any_changed = any_changed or changed
        changed, Module.data.consumables.endemic_life = imgui.checkbox(Language.get(languagePrefix .. "endemic_life"), Module.data.consumables.endemic_life)
        any_changed = any_changed or changed
        imgui.tree_pop()
    end
    
    languagePrefix = Module.title .. ".wirebugs."
    if imgui.tree_node(Language.get(languagePrefix .. "title")) then

        local WIREBUG_KEYS = {"unlimited_ooc", "unlimited"}
        for _, key in ipairs(WIREBUG_KEYS) do
            local text = Language.get(languagePrefix .. key)
            max_width = math.max(max_width, imgui.calc_text_size(text).x)
        end
        
        col_width = math.max(max_width + 24 + 20, row_width / 2)

        imgui.begin_table(Module.title .. "1", 2, 0)
        imgui.table_setup_column("1", 16 + 4096, col_width)
        imgui.table_setup_column("2", 16 + 4096, col_width)
        imgui.table_next_row()
        imgui.table_next_column()

        changed, Module.data.wirebugs.unlimited_ooc = imgui.checkbox(Language.get(languagePrefix .. "unlimited_ooc"), Module.data.wirebugs.unlimited_ooc)
        any_changed = any_changed or changed

        imgui.table_next_column()

        changed, Module.data.wirebugs.unlimited = imgui.checkbox(Language.get(languagePrefix .. "unlimited"), Module.data.wirebugs.unlimited)
        any_changed = any_changed or changed

        imgui.end_table()

        changed, Module.data.wirebugs.give_3 = imgui.checkbox(Language.get(languagePrefix .. "give_3"), Module.data.wirebugs.give_3)
        any_changed = any_changed or changed
        changed, Module.data.wirebugs.unlimited_powerup = imgui.checkbox(Language.get(languagePrefix .. "unlimited_powerup"), Module.data.wirebugs.unlimited_powerup)
        Utils.tooltip(Language.get(languagePrefix .. "unlimited_powerup_tooltip"))
        any_changed = any_changed or changed
        imgui.tree_pop()
    end

    languagePrefix = Module.title .. ".canteen."
    if imgui.tree_node(Language.get(languagePrefix .. "title")) then

        local CANTEEN_KEYS = {"dango_100_no_ticket", "dango_100_ticket"}
        max_width = 0
        for _, key in ipairs(CANTEEN_KEYS) do
            local text = Language.get(languagePrefix .. key)
            max_width = math.max(max_width, imgui.calc_text_size(text).x)
        end

        col_width = math.max(max_width + 24 + 20, row_width / 2)

        imgui.begin_table(Module.title .. "2", 2, 0)
        imgui.table_setup_column("1", 16 + 4096, col_width)
        imgui.table_setup_column("2", 16 + 4096, col_width)
        imgui.table_next_row()
        imgui.table_next_column()
        
        changed, Module.data.canteen.dango_100_ticket = imgui.checkbox(Language.get(languagePrefix .. "dango_100_ticket"), Module.data.canteen.dango_100_ticket)
        any_changed = any_changed or changed

        imgui.table_next_column()

        changed, Module.data.canteen.dango_100_no_ticket = imgui.checkbox(Language.get(languagePrefix .. "dango_100_no_ticket"), Module.data.canteen.dango_100_no_ticket)
        any_changed = any_changed or changed

        imgui.end_table()

        changed, Module.data.canteen.level_4 = imgui.checkbox(Language.get(languagePrefix .. "level_4"), Module.data.canteen.level_4)
        any_changed = any_changed or changed

        changed, Module.data.canteen.all_dangos = imgui.checkbox(Language.get(languagePrefix .. "all_dangos"), Module.data.canteen.all_dangos)
        any_changed = any_changed or changed

        imgui.tree_pop()
    end

    return any_changed
end


local function reset_dango_list()
    local dangoList = Utils.getMealFunc():get_field("<DangoDataList>k__BackingField"):get_field("mItems")
        
    if dangoList and dangoList.get_elements then
        dangoList = dangoList:get_elements()
    end

    for i, dango in pairs(dangoList) do
        local dangoParam = dango:get_field("_Param")
        
        local unlock_val = Module.cache_and_return_value("dango_unlock_" .. i, nil, 5, false)
        if unlock_val then dangoParam:set_field("_UnlockFlag", unlock_val) end

        local rate_val = Module.cache_and_return_value("dango_rate_" .. i, nil, 0, false)
        if rate_val then dangoParam:set_field("_DailyRate", rate_val) end
    end
end

local function reset_level_4()
    local dangoLevels = Utils.getMealFunc():get_field("SpecialSkewerDangoLv")
    local uiDangoLevels = managed_gui_kitchen:get_field("SpecialSkewerDangoLv")
    for i = 0, 2 do
        dangoLevels[i] = sdk.create_uint32(i == 0 and 4 or i == 1 and 3 or 1)-- lua version of i == 0 ? 4 : i == 1 ? 3 : 1
    end
end

function Module.reset()
    if Module.data.canteen.all_dangos then
        reset_dango_list()
    end
    if Module.data.canteen.level_4 then
        reset_level_4()
    end
end

return Module
