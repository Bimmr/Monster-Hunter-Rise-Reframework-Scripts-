local utils, config, language
local misc
local data = {
    title = "heavy_bowgun",
    charge_level = -1,
    -- unlimited_ammo - In Misc
    -- auto_reload  - In Misc
    wyvern_sniper = false,
    wyvern_machine_gun = false
    -- no_deviation  - In Misc
}

function data.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    misc = require("Buffer.Modules.Miscellaneous")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.HeavyBowgun"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if data.charge_level > -1 then
            managed:set_field("_ShotChargeLv", data.charge_level)
            managed:set_field("_ShotChargeFrame", 30 * data.charge_level)
        end
        if misc.ammo_and_coatings.auto_reload then managed:call("resetBulletNum") end
    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local playerData = utils.getPlayerData()
        if not playerData then return end

        if data.wyvern_sniper then
            playerData:set_field("_HeavyBowgunWyvernSnipeBullet", 1)
            playerData:set_field("_HeavyBowgunWyvernSnipeTimer", 0)
        end
        if data.wyvern_machine_gun then
            playerData:set_field("_HeavyBowgunWyvernMachineGunBullet", 50)
            playerData:set_field("_HeavyBowgunWyvernMachineGunTimer", 0)
        end
        if data.overheat then playerData:set_field("_HeavyBowgunHeatGauge", 0) end
    end, utils.nothing())
end

function data.draw()

    local changed, any_changed, misc_changed = false, false, false
    local languagePrefix = data.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

        changed, data.charge_level = imgui.slider_int(language.get(languagePrefix .. "charge_level"), data.charge_level, -1, 3, data.charge_level > -1 and
                                                          language.get(languagePrefix .. "charge_level_prefix") .. " %d" or language.get(languagePrefix .. "charge_level_disabled"))
        any_changed = changed or any_changed
        changed, misc.ammo_and_coatings.unlimited_ammo = imgui.checkbox(language.get(languagePrefix .. "unlimited_ammo"), misc.ammo_and_coatings.unlimited_ammo)
        misc_changed = changed or misc_changed
        changed, misc.ammo_and_coatings.auto_reload = imgui.checkbox(language.get(languagePrefix .. "auto_reload"), misc.ammo_and_coatings.auto_reload)
        misc_changed = changed or misc_changed
        changed, data.wyvern_sniper = imgui.checkbox(language.get(languagePrefix .. "wyvern_sniper"), data.wyvern_sniper)
        any_changed = changed or any_changed
        changed, data.wyvern_machine_gun = imgui.checkbox(language.get(languagePrefix .. "wyvern_machine_gun"), data.wyvern_machine_gun)
        any_changed = changed or any_changed
        changed, data.overheat = imgui.checkbox(language.get(languagePrefix .. "overheat"), data.overheat)
        any_changed = changed or any_changed
        changed, misc.ammo_and_coatings.no_deviation = imgui.checkbox(language.get(languagePrefix .. "no_deviation"), misc.ammo_and_coatings.no_deviation)
        misc_changed = changed or misc_changed

        if any_changed then config.save_section(data.create_config_section()) end
        if misc_changed then config.save_section(misc.create_config_section()) end
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end

end

function data.create_config_section()
    return {
        [data.title] = {
            charge_level = data.charge_level,
            wyvern_sniper = data.wyvern_sniper,
            wyvern_machine_gun = data.wyvern_machine_gun,
            overheat = data.overheat
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end

    data.charge_level = config_section.charge_level or data.charge_level
    data.wyvern_sniper = config_section.wyvern_sniper or data.wyvern_sniper
    data.wyvern_machine_gun = config_section.wyvern_machine_gun or data.wyvern_machine_gun
    data.overheat = config_section.overheat or data.overheat
end

return data
