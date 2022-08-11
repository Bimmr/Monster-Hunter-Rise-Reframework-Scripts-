local utils, config, language
local data = {
    title = "dual_blades",
    archdemon_mode = false,
    ironshine_silk = false
}

function data.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.DualBlades"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if data.archdemon_mode then managed:set_field("<KijinKyoukaGuage>k__BackingField", 100) end
        if data.ironshine_silk then managed:set_field("SharpnessRecoveryBuffValidTimer", 3000) end
    end, utils.nothing())
end

function data.draw()
    
    local changed, any_changed = false, false
    local languagePrefix = data.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

        changed, data.archdemon_mode = imgui.checkbox(language.get(languagePrefix .. "archdemon_mode"), data.archdemon_mode)
        any_changed = changed or any_changed
        changed, data.ironshine_silk = imgui.checkbox(language.get(languagePrefix .. "ironshine_silk"), data.ironshine_silk)
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
            archdemon_mode = data.archdemon_mode,
            ironshine_silk = data.ironshine_silk
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.archdemon_mode = config_section.archdemon_mode or data.archdemon_mode
    data.ironshine_silk = config_section.ironshine_silk or data.ironshine_silk
end


return data
