local utils, config, language

local data = {
    title = "charge_blade",
    full_bottles = false,
    sword_charged = false,
    shield_charged = false,
    chainsaw_buff = false,
}

function data.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.ChargeAxe"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        
        if data.full_bottles then
            managed:set_field("<ChargedBottleNum>k__BackingField", 5)
            managed:set_field("_ChargeGauge", 50)
        end
        if data.sword_charged then managed:set_field("_SwordBuffTimer", 500) end
        if data.shield_charged then managed:set_field("_ShieldBuffTimer", 1000) end
        if data.chainsaw_buff then managed:set_field("_IsChainsawBuff", true) end
    end, utils.nothing())
end

function data.draw()
    local changed, any_changed = false, false
    local languagePrefix = data.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

        changed, data.full_bottles = imgui.checkbox(language.get(languagePrefix .. "full_bottles"), data.full_bottles)
        any_changed = changed or any_changed
        changed, data.sword_charged = imgui.checkbox(language.get(languagePrefix .. "sword_charged"), data.sword_charged)
        any_changed = changed or any_changed
        changed, data.shield_charged = imgui.checkbox(language.get(languagePrefix .. "shield_charged"), data.shield_charged)
        any_changed = changed or any_changed
        changed, data.chainsaw_buff = imgui.checkbox(language.get(languagePrefix .. "chainsaw_buff"), data.chainsaw_buff)
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
            full_bottles = data.full_bottles,
            sword_charged = data.sword_charged,
            shield_charged = data.shield_charged
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.full_bottles = config_section.full_bottles or data.full_bottles
    data.sword_charged = config_section.sword_charged or data.sword_charged
    data.shield_charged = config_section.shield_charged or data.shield_charged
end


return data
