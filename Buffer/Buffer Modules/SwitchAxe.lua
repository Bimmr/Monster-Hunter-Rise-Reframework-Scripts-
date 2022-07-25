local utils, config
local data = {
    title = "Switch Axe",
    max_charge = false,
    max_sword_ammo = false,
    power_axe = false,
    switch_charger = false
}

function data.init()
    utils = require("Buffer Modules.Utils")
    config = require("Buffer Modules.Config")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.SlashAxe"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if data.max_charge then managed:set_field("_BottleGauge", 100) end
        if data.max_sword_ammo then managed:set_field("_BottleAwakeGauge", 150) end
        if data.power_axe then managed:set_field("_BottleAwakeAssistTimer", 3600) end
        if data.switch_charger then managed:set_field("_NoUseSlashGaugeTimer", 400) end
    end, utils.nothing())
end

function data.draw()

    local changed, any_changed = false, false
    changed, data.max_charge = imgui.checkbox("Max Charge", data.max_charge)
    any_changed = changed or any_changed
    changed, data.max_sword_ammo = imgui.checkbox("Max Sword Ammo", data.max_sword_ammo)
    any_changed = changed or any_changed
    changed, data.power_axe = imgui.checkbox("Power Axe", data.power_axe)
    any_changed = changed or any_changed
    changed, data.switch_charger = imgui.checkbox("Switch Charger", data.switch_charger)
    any_changed = changed or any_changed

    if any_changed then config.save_section(data.create_config_section()) end
end

function data.create_config_section()
    return {
        [data.title] = {
            max_charge = data.max_charge,
            max_sword_ammo = data.max_sword_ammo,
            power_axe = data.power_axe,
            switch_charger = data.switch_charger
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.max_charge = config_section.max_charge or data.max_charge
    data.max_sword_ammo = config_section.max_sword_ammo or data.max_sword_ammo
    data.power_axe = config_section.power_axe or data.power_axe
    data.switch_charger = config_section.switch_charger or data.switch_charger
end

return data
