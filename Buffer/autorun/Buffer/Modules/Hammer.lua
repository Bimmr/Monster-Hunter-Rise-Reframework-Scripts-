local utils, config, language
local data = {
    title = "hammer",
    charge_level = -1,
    impact_burst = false
}

function data.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.Hammer"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.player.Hammer") then return end
        
        if data.charge_level > -1 then managed:set_field("<NowChargeLevel>k__BackingField", data.charge_level) end
        if data.impact_burst then
            managed:set_field("_ImpactPullsTimer", 3600)
            managed:set_field("_IsEnableImapctPulls", true) -- They mispelt this field
            managed:set_field("_IsEnableImpactPulls", true) -- Adding this just incase they fix it in a later version
        end
    end, utils.nothing())
end

function data.draw()

    local changed, any_changed = false, false
    local languagePrefix = data.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

        changed, data.charge_level = imgui.slider_int(language.get(languagePrefix .. "charge_level"), data.charge_level, -1, 2, data.charge_level > -1 and
                                                          language.get(languagePrefix .. "charge_level_prefix") .. " " .. (data.charge_level + 1) or
                                                          language.get(languagePrefix .. "charge_level_disabled"))
        any_changed = changed or any_changed
        changed, data.impact_burst = imgui.checkbox(language.get(languagePrefix .. "impact_burst"), data.impact_burst)
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
            charge_level = data.charge_level,
            impact_burst = data.impact_burst
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.charge_level = config_section.charge_level or data.charge_level
    data.impact_burst = config_section.impact_burst or data.impact_burst
end
return data
