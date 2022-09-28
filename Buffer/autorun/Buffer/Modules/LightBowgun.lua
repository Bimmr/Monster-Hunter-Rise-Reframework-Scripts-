local utils, config, language
local misc
local data = {
    title = "light_bowgun",
    -- unlimited_ammo -- In Misc
    -- auto_reload   -- In Misc
    wyvern_blast = false,
    fanning_maneuver = false
    -- no_deviation  -- In Misc,
}

function data.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    misc = require("Buffer.Modules.Miscellaneous")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.LightBowgun"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.player.LightBowgun") then return end

        if misc.ammo_and_coatings.auto_reload then managed:call("resetBulletNum") end
        if data.fanning_maneuver then managed:set_field("LightBowgunWireBuffTimer", 1200) end
    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.player.PlayerManager") then return end
        local playerData = utils.getPlayerData()
        if not playerData then return end

        if data.wyvern_blast then
            playerData:set_field("_WyvernBlastGauge", 3)
            playerData:set_field("_WyvernBlastReloadTimer", 0)
        end
    end, utils.nothing())
end

function data.draw()

    local changed, any_changed, misc_changed = false, false, false
    local languagePrefix = data.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

        changed, misc.ammo_and_coatings.unlimited_ammo = imgui.checkbox(language.get(languagePrefix .. "unlimited_ammo"), misc.ammo_and_coatings.unlimited_ammo)
        misc_changed = changed or misc_changed
        changed, misc.ammo_and_coatings.auto_reload = imgui.checkbox(language.get(languagePrefix .. "auto_reload"), misc.ammo_and_coatings.auto_reload)
        misc_changed = changed or misc_changed
        changed, data.wyvern_blast = imgui.checkbox(language.get(languagePrefix .. "wyvern_blast"), data.wyvern_blast)
        any_changed = changed or any_changed
        changed, data.fanning_maneuver = imgui.checkbox(language.get(languagePrefix .. "fanning_maneuver"), data.fanning_maneuver)
        any_changed = changed or any_changed
        changed, misc.ammo_and_coatings.no_deviation = imgui.checkbox(language.get(languagePrefix .. "no_deviation"), misc.ammo_and_coatings.no_deviation)
        misc_changed = changed or misc_changed
        changed, misc.ammo_and_coatings.no_recoil = imgui.checkbox(language.get(languagePrefix .. "no_recoil"), misc.ammo_and_coatings.no_recoil)
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
            wyvern_blast = data.wyvern_blast,
            fanning_maneuver = data.fanning_maneuver
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.wyvern_blast = config_section.wyvern_blast or data.wyvern_blast
    data.fanning_maneuver = config_section.fanning_maneuver or data.fanning_maneuver
end

return data
