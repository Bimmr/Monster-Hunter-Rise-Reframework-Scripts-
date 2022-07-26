local utils, misc, config
local data = {
    title = "Bow",
    charge_level = -1,
    herculean_draw = false,
    bolt_boost = false
}

function data.init()
    utils = require("Buffer Modules.Utils")
    misc = require("Buffer Modules.Miscellaneous")
    config = require("Buffer Modules.Config")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.Bow"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if data.charge_level > 0 then managed:set_field("<ChargeLv>k__BackingField", data.charge_level) end
        if data.herculean_draw then managed:set_field("_WireBuffAttackUpTimer", 1800) end
        if data.bolt_boost then managed:set_field("_WireBuffArrowUpTimer", 1800) end
    end, utils.nothing())
end

function data.draw()

    local changed, any_changed, misc_changed = false, false, false
    changed, data.charge_level = imgui.slider_int("Charge Level   ", data.charge_level, 0, 4, data.charge_level > -1 and "Level %d" or "Off")
    any_changed = changed or any_changed
    changed, misc.ammo_and_coatings.unlimited_coatings = imgui.checkbox("Unlimited Arrows", misc.ammo_and_coatings.unlimited_coatings)
    misc_changed = changed or misc_changed
    changed, data.herculean_draw = imgui.checkbox("Herculean Draw", data.herculean_draw)
    utils.tooltip("No effect will appear on the weapon")
    any_changed = changed or any_changed
    changed, data.bolt_boost = imgui.checkbox("Bolt Boost", data.bolt_boost)
    any_changed = changed or any_changed

    if any_changed then config.save_section(data.create_config_section()) end
    if misc_changed then config.save_section(misc.create_config_section()) end
end

function data.create_config_section()
    return {
        [data.title] = {
            charge_level = data.charge_level,
            herculean_draw = data.herculean_draw,
            bolt_boost = data.bolt_boost
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.charge_level = config_section.charge_level or data.charge_level
    data.herculean_draw = config_section.herculean_draw or data.herculean_draw
    data.bolt_boost = config_section.bolt_boost or data.bolt_boost
end

return data
