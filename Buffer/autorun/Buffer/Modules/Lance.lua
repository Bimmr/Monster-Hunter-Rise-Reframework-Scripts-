local utils, config, language
local data = {
    title = "lance",
    anchor_rage = -1
}

function data.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.Lance"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if data.anchor_rage > -1 then
            managed:set_field("_GuardRageTimer", 3000)
            managed:set_field("_GuardRageBuffType", data.anchor_rage)
        end
    end, utils.nothing())

end

function data.draw()

    local changed, any_changed = false, false
    local languagePrefix = data.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

        changed, data.anchor_rage = imgui.slider_int(language.get(languagePrefix .. "anchor_rage"), data.anchor_rage, -1, 3, data.anchor_rage > -1 and
                                                         language.get(languagePrefix .. "anchor_rage_prefix") .. " %d" or language.get(languagePrefix .. "anchor_rage_disabled"))
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
            anchor_rage = data.anchor_rage
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.anchor_rage = config_section.anchor_rage or data.anchor_rage
end

return data
