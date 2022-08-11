local utils, config, language
local data = {
    title = "sword_and_shield",
    destroyer_oil = false
}

function data.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.ShortSword"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if data.destroyer_oil then
            managed:set_field("<IsOilBuffSetting>k__BackingField", true)
            managed:set_field("_OilBuffTimer", 3000)
        end
    end, utils.nothing())
end

function data.draw()

    local changed, any_changed = false, false
    local languagePrefix = data.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

        changed, data.destroyer_oil = imgui.checkbox(language.get(languagePrefix .. "destroyer_oil"), data.destroyer_oil)
        any_changed = changed or any_changed
        
        if any_changed then config.save_section(data.create_config_section()) end
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end
end

function data.create_config_section()
    return {
        [data.title] = {
            destroyer_oil = data.destroyer_oil
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.destroyer_oil = config_section.destroyer_oil or data.destroyer_oil
end

return data
