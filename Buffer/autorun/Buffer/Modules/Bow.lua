local utils, config, language
local misc
local data = {
    title = "bow",
    charge_level = -1,
    herculean_draw = false,
    bolt_boost = false
}

function data.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    misc = require("Buffer.Modules.Miscellaneous")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.Bow"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.player.Bow") then return end

        if data.charge_level > 0 then managed:set_field("<ChargeLv>k__BackingField", data.charge_level) end
        if data.herculean_draw then managed:set_field("_WireBuffAttackUpTimer", 1800) end
        if data.bolt_boost then managed:set_field("_WireBuffArrowUpTimer", 1800) end
    end, utils.nothing())
end

function data.draw()
    local changed, any_changed, misc_changed = false, false, false
    local languagePrefix = data.title.."."

    if imgui.collapsing_header(language.get(languagePrefix.."title")) then
        imgui.indent(10)
        changed, data.charge_level = imgui.slider_int(language.get(languagePrefix.."charge_level"), data.charge_level, -1, 3,
                                                      data.charge_level > -1 and language.get(languagePrefix.."charge_level_prefix").." " .. (data.charge_level + 1) or language.get(languagePrefix.."charge_level_disabled"))
        any_changed = changed or any_changed
        changed, misc.ammo_and_coatings.unlimited_coatings = imgui.checkbox(language.get(languagePrefix.."unlimited_arrows"), misc.ammo_and_coatings.unlimited_coatings)
        misc_changed = changed or misc_changed
        changed, data.herculean_draw = imgui.checkbox(language.get(languagePrefix.."herculean_draw"), data.herculean_draw)
        utils.tooltip(language.get(languagePrefix.."herculean_draw_tooltip"))
        any_changed = changed or any_changed
        changed, data.bolt_boost = imgui.checkbox(language.get(languagePrefix.."bolt_boost"), data.bolt_boost)
        any_changed = changed or any_changed

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
