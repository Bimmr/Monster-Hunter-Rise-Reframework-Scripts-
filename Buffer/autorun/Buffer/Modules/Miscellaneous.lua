local utils, config, language
local lightBowgun, heavyBowgun, bow
local data = {
    title = "miscellaneous",
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
        -- all_dangos = false
    },
    unlimited_recon = false,
    hidden = {
        level_4_was_enabled = false,
        dango_list = false
    }
}

function data.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")
    lightBowgun = require("Buffer.Modules.LightBowgun")
    heavyBowgun = require("Buffer.Modules.HeavyBowgun")
    bow = require("Buffer.Modules.Bow")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.data.ItemSlider"):get_method("notifyConsumeItem(snow.data.ContentsIdSystem.ItemId, System.Boolean)"), function(args)
        local item_id = sdk.to_int64(args[3])
        -- Marionette Spider = 69206037
        -- Ec Item = 69206016 - 69206040
        if data.consumables.endemic_life and ((item_id >= 69206016 and item_id <= 69206040) or (item_id == 69206037)) then
            if item_id == 69206037 then -- Needs to be reset otherwise it will be stuck in the "consumed" state
                local creature_manager = sdk.get_managed_singleton("snow.envCreature.EnvironmentCreatureManager")
                local playerBase = utils.getPlayerBase()
                creature_manager:call("setEc057UseCount", playerBase:get_field("_PlayerIndex"), 0)
            end
            return sdk.PreHookResult.SKIP_ORIGINAL
        elseif data.consumables.items and not ((item_id >= 69206016 and item_id <= 69206040) or (item_id == 69206037)) then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end

    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.player.PlayerManager") then return end
        local playerBase = utils.getPlayerBase()
        if not playerBase then return end

        if data.wirebugs.give_3 then
            playerBase:set_field("<HunterWireWildNum>k__BackingField", 1)
            playerBase:set_field("_HunterWireNumAddTime", 7000)
        end

        if data.wirebugs.unlimited_powerup then
            local playerData = utils.getPlayerData()
            if not playerData then return end
            playerData:set_field("_WireBugPowerUpTimer", 10700)
        end

    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.player.fsm.PlayerFsm2ActionHunterWire"):get_method("start"), utils.nothing(), function(retval)
        if (data.wirebugs.unlimited_ooc and not utils.checkIfInBattle()) or data.wirebugs.unlimited then
            local playerBase = utils.getPlayerBase()
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

    local managed_dango = nil
    sdk.hook(sdk.find_type_definition("snow.data.DangoData"):get_method("get_SkillActiveRate"), function(args)
        if data.canteen.dango_100_no_ticket or data.canteen.dango_100_ticket then
            local managed = sdk.to_managed_object(args[2])
            if not managed then return end
            if not managed:get_type_definition():is_a("snow.data.DangoData") then return end

            local isUsingTicket = utils.getMealFunc():call("getMealTicketFlag")

            if isUsingTicket or data.canteen.dango_100_no_ticket then
                managed_dango = managed
            end
        end
    end, function(retval)
        if managed_dango then
            managed_dango = nil
            return sdk.to_ptr(200)
        end
        return retval
    end)

    sdk.hook(sdk.find_type_definition("snow.facility.kitchen.MealFunc"):get_method("updateList"), function(args)
        if data.canteen.level_4 and not data.hidden.level_4_was_enabled then
            data.hidden.level_4_was_enabled = true
            local dangoLevels = utils.getMealFunc():get_field("SpecialSkewerDangoLv")
            local level4 = sdk.create_uint32(4)
            level4:set_field("mValue", 4)
            for i = 0, 2 do dangoLevels[i] = level4 end

        elseif not data.canteen.level_4 and data.hidden.level_4_was_enabled then
            data.hidden.level_4_was_enabled = false
            local dangoLevels = utils.getMealFunc():get_field("SpecialSkewerDangoLv")
            for i = 0, 2 do
                dangoLevels[i] = sdk.create_uint32(i == 0 and 4 or i == 1 and 3 or 1)-- lua version of i == 0 ? 4 : i == 1 ? 3 : 1
            end
        end
    end, utils.nothing())
    
    sdk.hook(sdk.find_type_definition("snow.gui.fsm.kitchen.GuiKitchen"):get_method("setDangoTabList"), function(args)
        if data.canteen.level_4 and not data.hidden.level_4GUI_was_enabled then
            data.hidden.level_4GUI_was_enabled = true
            local managed = sdk.to_managed_object(args[2])
            if not managed then return end
            local dangoLevels = managed:get_field("SpecialSkewerDangoLv")
            local level4 = sdk.create_uint32(4)
            level4:set_field("mValue", 4)
            for i = 0, 2 do dangoLevels[i] = level4 end

        elseif not data.canteen.level_4 and data.hidden.level_4GUI_was_enabled then
            data.hidden.level_4GUI_was_enabled = false
            local managed = sdk.to_managed_object(args[2])
            if not managed then return end
            local dangoLevels = managed:get_field("SpecialSkewerDangoLv")
            for i = 0, 2 do
                dangoLevels[i] = sdk.create_uint32(i == 0 and 4 or i == 1 and 3 or 1)-- lua version of i == 0 ? 4 : i == 1 ? 3 : 1
            end
        end
    end, utils.nothing())
  
    -- sdk.hook(sdk.find_type_definition("snow.facility.kitchen.MealFunc"):get_method("updateList"), function(args)
    --   local managed = sdk.to_managed_object(args[2])
    --   if not managed then return end
    --   local dangoList = managed:get_field("<DangoDataList>k__BackingField"):get_field("mItems")
    --   for i, dango in pairs(dangoList) do
    --       local dangoParam = dango:get_field("_Param")
    --       -- Set unlock Flag to Village_1 and Dailyrate to 0
    --       dangoParam:set_field("_UnlockFlag", 5)
    --       dangoParam:set_field("_DailyRate", 0)
    --   end
    --   managed:set_field("<AvailableDangoList>k__BackingField", managed:get_field("<DangoDataList>k__BackingField"))
    -- end, utils.nothing())

    local recon_managed = nil
    sdk.hook(sdk.find_type_definition("snow.otomo.OtomoReconCharaManager"):get_method("onCompleteReconOtomoAct"), function(args)
        recon_managed = nil
        if data.unlimited_recon then
            local managed = sdk.to_managed_object(args[2])
            if not managed then return end
            recon_managed = managed
        end
    end, function(retval)
        if recon_managed then
            recon_managed:set_field("_IsUseOtomoReconFastTravel", false)
        end
    end)
    
end

function data.draw()

    local changed, any_changed = false, false
    local languagePrefix = data.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

        local unlimited_recon_change = false
        unlimited_recon_change, data.unlimited_recon = imgui.checkbox(language.get(languagePrefix .. "unlimited_recon"), data.unlimited_recon)
        if unlimited_recon_change and data.unlimited_recon then
            sdk.get_managed_singleton("snow.data.OtomoReconManager"):set_field("_IsUseOtomoReconFastTravel", false)
        end
        any_changed = any_changed or unlimited_recon_change

        languagePrefix = data.title .. ".consumables."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then
            changed, data.consumables.items = imgui.checkbox(language.get(languagePrefix .. "items"), data.consumables.items)
            any_changed = any_changed or changed
            changed, data.consumables.endemic_life = imgui.checkbox(language.get(languagePrefix .. "endemic_life"), data.consumables.endemic_life)
            any_changed = any_changed or changed
            imgui.tree_pop()
        end
       
        languagePrefix = data.title .. ".wirebugs."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then
            changed, data.wirebugs.unlimited_ooc = imgui.checkbox(language.get(languagePrefix .. "unlimited_ooc"), data.wirebugs.unlimited_ooc)
            any_changed = any_changed or changed
            changed, data.wirebugs.unlimited = imgui.checkbox(language.get(languagePrefix .. "unlimited"), data.wirebugs.unlimited)
            any_changed = any_changed or changed
            changed, data.wirebugs.give_3 = imgui.checkbox(language.get(languagePrefix .. "give_3"), data.wirebugs.give_3)
            any_changed = any_changed or changed
            changed, data.wirebugs.unlimited_powerup = imgui.checkbox(language.get(languagePrefix .. "unlimited_powerup"), data.wirebugs.unlimited_powerup)
            utils.tooltip(language.get(languagePrefix .. "unlimited_powerup_tooltip"))
            any_changed = any_changed or changed
            imgui.tree_pop()
        end

        languagePrefix = data.title .. ".canteen."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then
            changed, data.canteen.dango_100_no_ticket = imgui.checkbox(language.get(languagePrefix .. "dango_100_no_ticket"), data.canteen.dango_100_no_ticket)
            any_changed = any_changed or changed
            changed, data.canteen.dango_100_ticket = imgui.checkbox(language.get(languagePrefix .. "dango_100_ticket"), data.canteen.dango_100_ticket)
            any_changed = any_changed or changed
            changed, data.canteen.level_4 = imgui.checkbox(language.get(languagePrefix .. "level_4"), data.canteen.level_4)
            any_changed = any_changed or changed
            -- changed, data.canteen.all_dangos = imgui.checkbox(language.get(languagePrefix .. "all_dangos"), data.canteen.all_dangos)
            -- utils.tooltip(language.get(languagePrefix.."all_dangos_tooltip"))
            any_changed = any_changed or changed
            imgui.tree_pop()
        end

        if any_changed then config.save_section(data.create_config_section()) end
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end
end

function data.create_config_section()
    return {
        [data.title] = {
            unlimited_recon = data.unlimited_recon,
            consumables = data.consumables,
            wirebugs = data.wirebugs,
            canteen = data.canteen
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.unlimited_recon = config_section.unlimited_recon or data.unlimited_recon
    data.consumables = config_section.consumables or data.consumables
    data.wirebugs = config_section.wirebugs or data.wirebugs
    data.canteen = config_section.canteen or data.canteen

end

return data
