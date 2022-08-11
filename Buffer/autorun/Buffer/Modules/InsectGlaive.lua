local utils, config, language
local data = {
    title = "insect_glaive",
    red_extract = false,
    white_extract = false,
    orange_extract = false,
    aerials = false,
    kinsect_stamina = false
}
function data.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.InsectGlaive"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if data.red_extract then managed:set_field("_RedExtractiveTime", 8000) end
        if data.white_extract then managed:set_field("_WhiteExtractiveTime", 8000) end
        if data.orange_extract then managed:set_field("_OrangeExtractiveTime", 8000) end
        if data.aerials then managed:set_field("_AerialCount", 2) end
    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.player.IG_Insect"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if data.kinsect_stamina then managed:set_field("<_Stamina>k__BackingField", 100) end -- not working?

    end, utils.nothing())
end

function data.draw()

    local changed, any_changed = false, false
    local languagePrefix = data.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

        changed, data.red_extract = imgui.checkbox(language.get(languagePrefix .. "red_extract"), data.red_extract)
        any_changed = changed or any_changed
        changed, data.white_extract = imgui.checkbox(language.get(languagePrefix .. "white_extract"), data.white_extract)
        any_changed = changed or any_changed
        changed, data.orange_extract = imgui.checkbox(language.get(languagePrefix .. "orange_extract"), data.orange_extract)
        any_changed = changed or any_changed
        changed, data.aerials = imgui.checkbox(language.get(languagePrefix .. "aerials"), data.aerials)
        any_changed = changed or any_changed
        changed, data.kinsect_stamina = imgui.checkbox(language.get(languagePrefix .. "kinsect_stamina"), data.kinsect_stamina)
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
            red_extract = data.red_extract,
            white_extract = data.white_extract,
            orange_extract = data.orange_extract,
            aerials = data.aerials,
            kinsect_stamina = data.kinsect_stamina
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.red_extract = config_section.red_extract or data.red_extract
    data.white_extract = config_section.white_extract or data.white_extract
    data.orange_extract = config_section.orange_extract or data.orange_extract
    data.aerials = config_section.aerials or data.aerials
    data.kinsect_stamina = config_section.kinsect_stamina or data.kinsect_stamina
end

return data
