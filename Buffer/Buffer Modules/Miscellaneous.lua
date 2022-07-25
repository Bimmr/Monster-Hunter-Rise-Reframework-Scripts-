local utils
local lightBowgun, heavyBowgun, bow
local miscellaneous = {
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


function miscellaneous.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.data.ItemSlider"):get_method("notifyConsumeItem"), function(args)
        if miscellaneous.unlimited_consumables then return sdk.PreHookResult.SKIP_ORIGINAL end
    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local playerBase = utils.getPlayerBase()
        if not playerBase then return end

        if miscellaneous.sharpness_level > -1 then
            if miscellaneous.data.sharpness_level_old == -1 then miscellaneous.data.sharpness_level_old = playerBase:get_field("<SharpnessLv>k__BackingField") end
            -- 0=Red | 1=Orange | 2=Yellow | 3=Green | 4=Blue | 5=White | 6=Purple
            playerBase:set_field("<SharpnessLv>k__BackingField", miscellaneous.sharpness_level) -- Sharpness Level of Purple
            -- playerBase:set_field("<SharpnessGauge>k__BackingField", 400) -- Sharpness Value
            -- playerBase:set_field("<SharpnessGaugeMax>k__BackingField", 400) -- Max Sharpness
        elseif miscellaneous.sharpness_level == -1 and miscellaneous.data.sharpness_level_old > -1 then
            playerBase:set_field("<SharpnessLv>k__BackingField", miscellaneous.data.sharpness_level_old)
            miscellaneous.data.sharpness_level_old = -1
        end

        if miscellaneous.wirebugs.give_3 then
            playerBase:set_field("<HunterWireWildNum>k__BackingField", 1)
            playerBase:set_field("_HunterWireNumAddTime", 7000)
        end

        if miscellaneous.wirebugs.unlimited_powerup then
            local playerData = utils.getPlayerData()
            if not playerData then return end
            playerData:set_field("_WireBugPowerUpTimer", 10700)
        end

    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.data.bulletSlider.BottleSliderFunc"):get_method("notifyConsumeItem"), function(args)
        if miscellaneous.ammo_and_coatings.unlimited_coatings then return sdk.PreHookResult.SKIP_ORIGINAL end
    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.data.bulletSlider.BulletSliderFunc"):get_method("notifyConsumeItem"), function(args)
        if miscellaneous.ammo_and_coatings.unlimited_ammo then return sdk.PreHookResult.SKIP_ORIGINAL end
    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.equip.BulletWeaponBaseUserData.Param"):get_method("get_Fluctuation"), function(args)

        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_type_definition():is_a("snow.equip.BulletWeaponBaseUserData.Param") then return end

        if miscellaneous.ammo_and_coatings.no_deviation then
            miscellaneous.ammo_and_coatings.is_DeviationMethod = true
            return sdk.PreHookResult.SKIP_ORIGINAL
        end

    end, function(retval)
        if miscellaneous.ammo_and_coatings.is_DeviationMethod then
            miscellaneous.ammo_and_coatings.is_DeviationMethod = false
            return 0
        end
    end)

    sdk.hook(sdk.find_type_definition("snow.player.fsm.PlayerFsm2ActionHunterWire"):get_method("start"), utils.nothing(), function(retval)
        if (miscellaneous.wirebugs.unlimited_ooc and not utils.checkIfInBattle()) or miscellaneous.wirebugs.unlimited then
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
    sdk.hook(sdk.find_type_definition("snow.data.DangoData"):get_method("update"), function(args)
        if miscellaneous.canteen.dango_100_no_ticket or miscellaneous.canteen.dango_100_ticket then
            local managed = sdk.to_managed_object(args[2])
            if not managed then return end
            if not managed:get_type_definition():is_a("snow.data.DangoData") then return end

            local isUsingTicket = utils.getMealFunc():call("getMealTicketFlag")

            if isUsingTicket or miscellaneous.canteen.dango_100_no_ticket then
                managed_dango = managed
                managed_dango_chance = managed:get_field("_Param"):get_field("_SkillActiveRate")
                managed:get_field("_Param"):set_field("_SkillActiveRate", 200)
            end
        end
    end, function(retval)
        -- Restore the original value
        if (miscellaneous.canteen.dango_100_no_ticket or miscellaneous.canteen.dango_100_ticket) and managed_dango then
            managed_dango:get_field("_Param"):set_field("_SkillActiveRate", managed_dango_chance)
            managed_dango = nil
            managed_dango_chance = nil
        end
        return retval
    end)

    sdk.hook(sdk.find_type_definition("snow.facility.kitchen.MealFunc"):get_method("updateList"), function(args)
        if miscellaneous.canteen.level_4 and not miscellaneous.data.level_4_wasEnabled then
            miscellaneous.data.level_4_wasEnabled = true
            local dangoLevels = utils.getMealFunc():get_field("SpecialSkewerDangoLv")
            local level4 = sdk.create_instance("System.UInt32")
            level4:set_field("mValue", 4)
            for i = 0, 2 do dangoLevels[i] = level4 end

        elseif not miscellaneous.canteen.level_4 and miscellaneous.data.level_4_wasEnabled then
            miscellaneous.data.level_4_wasEnabled = false
            local dangoLevels = utils.getMealFunc():get_field("SpecialSkewerDangoLv")

            for i = 0, 2 do
                local level = sdk.create_instance("System.UInt32")
                level:set_field("mValue", i == 0 and 4 or i == 1 and 3 or 1) -- lua version of i == 0 ? 4 : i == 1 ? 3 : 1
                dangoLevels[i] = level
            end
        end
    end, utils.nothing())
end

function miscellaneous.init()
    utils = require("Buffer Modules.Utils")
    lightBowgun = require("Buffer Modules.LightBowgun")
    heavyBowgun = require("Buffer Modules.HeavyBowgun")
    bow = require("Buffer Modules.Bow")

    miscellaneous.init_hooks()
end
function miscellaneous.draw()
    local changed
    changed, miscellaneous.unlimited_consumables = imgui.checkbox("Unlimited Consumables", miscellaneous.unlimited_consumables)
    local sharpness_display = {"Off", "Red", "Orange", "Yellow", "Green", "Blue", "White", "Purple"}
    changed, miscellaneous.sharpness_level = imgui.slider_int("Sharpness Level", miscellaneous.sharpness_level, -1, 6, sharpness_display[miscellaneous.sharpness_level + 2])
    utils.tooltip("The sharpness bar will still move, but the sharpness level won't change")
    if imgui.tree_node("Ammo & Coating") then
        changed, miscellaneous.ammo_and_coatings.unlimited_coatings = imgui.checkbox("Unlimited Coatings (Bow)", miscellaneous.ammo_and_coatings.unlimited_coatings)
        changed, miscellaneous.ammo_and_coatings.unlimited_ammo = imgui.checkbox("Unlimited Ammo (Bowguns)", miscellaneous.ammo_and_coatings.unlimited_ammo)
        changed, miscellaneous.ammo_and_coatings.auto_reload = imgui.checkbox("Auto Reload", miscellaneous.ammo_and_coatings.auto_reload)
        changed, miscellaneous.ammo_and_coatings.no_deviation = imgui.checkbox("No Deviation", miscellaneous.ammo_and_coatings.no_deviation)
        imgui.tree_pop()
    end
    if imgui.tree_node("Wirebugs") then
        changed, miscellaneous.wirebugs.unlimited_ooc = imgui.checkbox("Unlimited Wirebugs (Out of Combat)", miscellaneous.wirebugs.unlimited_ooc)
        changed, miscellaneous.wirebugs.unlimited = imgui.checkbox("Unlimited Wirebugs", miscellaneous.wirebugs.unlimited)
        changed, miscellaneous.wirebugs.give_3 = imgui.checkbox("Give 3 Wirebugs", miscellaneous.wirebugs.give_3)
        changed, miscellaneous.wirebugs.unlimited_powerup = imgui.checkbox("Unlimited Powerup", miscellaneous.wirebugs.unlimited_powerup)
        imgui.tree_pop()
    end
    if imgui.tree_node("Canteen") then
        changed, miscellaneous.canteen.dango_100_no_ticket = imgui.checkbox("Dango Skill 100% (No Ticket)", miscellaneous.canteen.dango_100_no_ticket)
        changed, miscellaneous.canteen.dango_100_ticket = imgui.checkbox("Dango Skill 100% (Ticket)", miscellaneous.canteen.dango_100_ticket)
        changed, miscellaneous.canteen.level_4 = imgui.checkbox("Level 4 Dango", miscellaneous.canteen.level_4)
        utils.tooltip("GUI won't show level 4, but it will give you the level 4 skill")
        imgui.tree_pop()
    end
    if changed then utils.saveConfig() end
end

return miscellaneous
