local utils, misc, config
local bow = {
    title = "Bow",
    charge_level = 0,
    herculean_draw = false,
    bolt_boost = false
}

function bow.init()
    utils = require("Buffer Modules.Utils")
    misc = require("Buffer Modules.Miscellaneous")
    config = require("Buffer Modules.Config")

    bow.init_hooks()
end

function bow.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.Bow"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if bow.charge_level > 0 then managed:set_field("<ChargeLv>k__BackingField", bow[1].value) end
        if bow.herculean_draw then managed:set_field("_WireBuffAttackUpTimer", 1800) end
        if bow.bolt_boost then managed:set_field("_WireBuffArrowUpTimer", 1800) end
    end, utils.nothing())
end

function bow.draw()

    -- I really don't like how this looks, so I'm gonna change it. Plus the saving doesn't work yet

    local changed = false
    changed, bow.charge_level = imgui.slider_int("Charge Level   ", bow.charge_level, 0, 4, bow.charge_level > -1 and "Level %d" or "Off")
    if changed then config.saveSection(bow.create_config_section()) end
    changed, misc.ammo_and_coatings.unlimited_coatings = imgui.checkbox("Unlimited Arrows", misc.ammo_and_coatings.unlimited_coatings)
    if changed then config.saveSection(bow.create_config_section()) end
    changed, bow.herculean_draw = imgui.checkbox("Herculean Draw", bow.herculean_draw)
    utils.tooltip("No effect will appear on the weapon")
    if changed then config.saveSection(bow.create_config_section()) end
    changed, bow.bolt_boost = imgui.checkbox("Bolt Boost", bow.bolt_boost)
    if changed then config.saveSection(bow.create_config_section()) end
end

function bow.create_config_section()
    return {
        [bow.title] = {
            charge_level = bow.charge_level,
            herculean_draw = bow.herculean_draw,
            bolt_boost = bow.bolt_boost
        }
    }
end

function bow.load_from_config(config_section)
    if not config_section then return end
    bow.charge_level = config_section.charge_level or bow.charge_level
    bow.herculean_draw = config_section.herculean_draw or bow.herculean_draw
    bow.bolt_boost = config_section.bolt_boost or bow.bolt_boost
end

return bow
