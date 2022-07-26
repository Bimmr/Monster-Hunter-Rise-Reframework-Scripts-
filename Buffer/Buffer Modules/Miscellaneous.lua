local utils, config
local lightBowgun, heavyBowgun, bow
local data = {
    title = "Miscellaneous",
    unlimited_consumables = false,
    sharpness_level = -1,
    old_sharpness_level = -1,
    ammo_and_coatings = {
        unlimited_ammo = false,
        unlimited_coatings = false,
        auto_reload = false, -- Drawn here, but no hook
        no_deviation = false
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
        managed_dango_100 = nil,
        level_4 = false
    },
    data = {
        sharpness_level_old = -1,
        level_4_was_enabled = false
    }
}

function data.init()
    utils = require("Buffer Modules.Utils")
    config = require("Buffer Modules.Config")
    lightBowgun = require("Buffer Modules.LightBowgun")
    heavyBowgun = require("Buffer Modules.HeavyBowgun")
    bow = require("Buffer Modules.Bow")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.data.ItemSlider"):get_method("notifyConsumeItem"), function(args)
        if data.unlimited_consumables then return sdk.PreHookResult.SKIP_ORIGINAL end
    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local playerBase = utils.getPlayerBase()
        if not playerBase then return end

        if data.sharpness_level > -1 then
            if data.data.sharpness_level_old == -1 then data.data.sharpness_level_old = playerBase:get_field("<SharpnessLv>k__BackingField") end
            -- 0=Red | 1=Orange | 2=Yellow | 3=Green | 4=Blue | 5=White | 6=Purple
            playerBase:set_field("<SharpnessLv>k__BackingField", data.sharpness_level) -- Sharpness Level of Purple
            -- playerBase:set_field("<SharpnessGauge>k__BackingField", 400) -- Sharpness Value
            -- playerBase:set_field("<SharpnessGaugeMax>k__BackingField", 400) -- Max Sharpness
        elseif data.sharpness_level == -1 and data.data.sharpness_level_old > -1 then
            playerBase:set_field("<SharpnessLv>k__BackingField", data.data.sharpness_level_old)
            data.data.sharpness_level_old = -1
        end

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

    sdk.hook(sdk.find_type_definition("snow.data.bulletSlider.BottleSliderFunc"):get_method("consumeItem"), function(args)
        if data.ammo_and_coatings.unlimited_coatings then return sdk.PreHookResult.SKIP_ORIGINAL end
    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.data.bulletSlider.BulletSliderFunc"):get_method("consumeItem"), function(args)
        if data.ammo_and_coatings.unlimited_ammo then return sdk.PreHookResult.SKIP_ORIGINAL end
    end, utils.nothing())

    local managed_fluctuation = nil
    sdk.hook(sdk.find_type_definition("snow.data.BulletWeaponData"):get_method("get_Fluctuation"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_type_definition():is_a("snow.data.BulletWeaponData") then return end
        managed_fluctuation = true
    end, function(retval)
        if managed_fluctuation ~= nil then
            managed_fluctuation = nil
            if data.ammo_and_coatings.no_deviation then return 0 end
        end
        return retval
    end)

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

    local managed_dango, managed_dango_chance = nil, nil
    sdk.hook(sdk.find_type_definition("snow.data.DangoData"):get_method("get_SkillActiveRate"), function(args)
        if data.canteen.dango_100_no_ticket or data.canteen.dango_100_ticket then
            local managed = sdk.to_managed_object(args[2])
            if not managed then return end
            if not managed:get_type_definition():is_a("snow.data.DangoData") then return end

            local isUsingTicket = utils.getMealFunc():call("getMealTicketFlag")

            if isUsingTicket or data.canteen.dango_100_no_ticket then
                managed_dango = managed
                managed_dango_chance = managed:get_field("_Param"):get_field("_SkillActiveRate")
                managed:get_field("_Param"):set_field("_SkillActiveRate", 200)
                return sdk.PreHookResult.SKIP_ORIGINAL
            end
        end
    end, function(retval)
        -- Restore the original value
        if (data.canteen.dango_100_no_ticket or data.canteen.dango_100_ticket) and managed_dango then
            managed_dango:get_field("_Param"):set_field("_SkillActiveRate", managed_dango_chance)
            managed_dango = nil
            managed_dango_chance = nil
        end
        return retval
    end)

    sdk.hook(sdk.find_type_definition("snow.facility.kitchen.MealFunc"):get_method("updateList"), function(args)
        if data.canteen.level_4 and not data.data.level_4_wasEnabled then
            data.data.level_4_wasEnabled = true
            local dangoLevels = utils.getMealFunc():get_field("SpecialSkewerDangoLv")
            local level4 = sdk.create_instance("System.UInt32")
            level4:set_field("mValue", 4)
            for i = 0, 2 do dangoLevels[i] = level4 end

        elseif not data.canteen.level_4 and data.data.level_4_wasEnabled then
            data.data.level_4_wasEnabled = false
            local dangoLevels = utils.getMealFunc():get_field("SpecialSkewerDangoLv")

            for i = 0, 2 do
                local level = sdk.create_instance("System.UInt32")
                level:set_field("mValue", i == 0 and 4 or i == 1 and 3 or 1) -- lua version of i == 0 ? 4 : i == 1 ? 3 : 1
                dangoLevels[i] = level
            end
        end
    end, utils.nothing())
    
end

function data.draw()

    local changed, any_changed = false, false
    changed, data.unlimited_consumables = imgui.checkbox("Unlimited Consumables", data.unlimited_consumables)
    any_changed = any_changed or changed
    local sharpness_display = {"Off", "Red", "Orange", "Yellow", "Green", "Blue", "White", "Purple"}
    changed, data.sharpness_level = imgui.slider_int("Sharpness Level", data.sharpness_level, -1, 6, sharpness_display[data.sharpness_level + 2])
    utils.tooltip("The sharpness bar will still move, but the sharpness level won't change")
    any_changed = any_changed or changed
    if imgui.tree_node("Ammo & Coating") then
        changed, data.ammo_and_coatings.unlimited_coatings = imgui.checkbox("Unlimited Coatings (Bow)", data.ammo_and_coatings.unlimited_coatings)
        any_changed = any_changed or changed
        changed, data.ammo_and_coatings.unlimited_ammo = imgui.checkbox("Unlimited Ammo (Bowguns)", data.ammo_and_coatings.unlimited_ammo)
        any_changed = any_changed or changed
        changed, data.ammo_and_coatings.auto_reload = imgui.checkbox("Auto Reload", data.ammo_and_coatings.auto_reload)
        any_changed = any_changed or changed
        changed, data.ammo_and_coatings.no_deviation = imgui.checkbox("No Deviation", data.ammo_and_coatings.no_deviation)
        any_changed = any_changed or changed
        imgui.tree_pop()
    end
    if imgui.tree_node("Wirebugs") then
        changed, data.wirebugs.unlimited_ooc = imgui.checkbox("Unlimited Wirebugs (Out of Combat)", data.wirebugs.unlimited_ooc)
        any_changed = any_changed or changed
        changed, data.wirebugs.unlimited = imgui.checkbox("Unlimited Wirebugs", data.wirebugs.unlimited)
        any_changed = any_changed or changed
        changed, data.wirebugs.give_3 = imgui.checkbox("Give 3 Wirebugs", data.wirebugs.give_3)
        any_changed = any_changed or changed
        changed, data.wirebugs.unlimited_powerup = imgui.checkbox("Unlimited Powerup", data.wirebugs.unlimited_powerup)
        any_changed = any_changed or changed
        imgui.tree_pop()
    end
    if imgui.tree_node("Canteen") then
        changed, data.canteen.dango_100_no_ticket = imgui.checkbox("Dango Skill 100% (No Ticket)", data.canteen.dango_100_no_ticket)
        any_changed = any_changed or changed
        changed, data.canteen.dango_100_ticket = imgui.checkbox("Dango Skill 100% (Ticket)", data.canteen.dango_100_ticket)
        any_changed = any_changed or changed
        changed, data.canteen.level_4 = imgui.checkbox("Level 4 Dango", data.canteen.level_4)
        utils.tooltip("GUI won't show level 4, but it will give you the level 4 skill")
        any_changed = any_changed or changed
        imgui.tree_pop()
    end

    if any_changed then config.save_section(data.create_config_section()) end
end

function data.create_config_section()
    return {
        [data.title] = {
            unlimited_consumables = data.unlimited_consumables,
            sharpness_level = data.sharpness_level,
            ammo_and_coatings = {
                unlimited_coatings = data.ammo_and_coatings.unlimited_coatings,
                unlimited_ammo = data.ammo_and_coatings.unlimited_ammo,
                auto_reload = data.ammo_and_coatings.auto_reload,
                no_deviation = data.ammo_and_coatings.no_deviation
            },
            wirebugs = {
                unlimited_ooc = data.wirebugs.unlimited_ooc,
                unlimited = data.wirebugs.unlimited,
                give_3 = data.wirebugs.give_3,
                unlimited_powerup = data.wirebugs.unlimited_powerup
            },
            canteen = {
                dango_100_no_ticket = data.canteen.dango_100_no_ticket,
                dango_100_ticket = data.canteen.dango_100_ticket,
                level_4 = data.canteen.level_4
            }
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.unlimited_consumables = config_section.unlimited_consumables or data.unlimited_consumables
    data.sharpness_level = config_section.sharpness_level or data.sharpness_level
    data.ammo_and_coatings = config_section.ammo_and_coatings or data.ammo_and_coatings
    data.wirebugs = config_section.wirebugs or data.wirebugs
    data.canteen = config_section.canteen or data.canteen
end

return data
