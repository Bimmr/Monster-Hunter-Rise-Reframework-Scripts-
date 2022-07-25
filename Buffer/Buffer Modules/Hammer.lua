local utils, config
local data = {
    title = "Hammer",
    charge_level = -1,
    impact_burst = false
}

function data.init()
    utils = require("Buffer Modules.Utils")
    config = require("Buffer Modules.Config")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.Hammer"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if data.charge_level > -1 then
            managed:set_field("<NowChargeLevel>k__BackingField", data.charge_level)
        end
        if data.impact_burst then
            managed:set_field("_ImpactPullsTimer", 3600)
            managed:set_field("_IsEnableImapctPulls", true) -- They mispelt this field
            managed:set_field("_IsEnableImpactPulls", true) -- Adding this just incase they fix it in a later version
        end
    end, utils.nothing())
end

function data.draw()
    
    local changed, any_changed = false, false
    changed, data.charge_level = imgui.slider_int("Charge Level ", data.charge_level, -1, 3,
                                                    data.charge_level > -1 and "Level %d" or "Off")
    any_changed = changed or any_changed
    changed, data.impact_burst = imgui.checkbox("Impact Burst", data.impact_burst)
    any_changed = changed or any_changed

    if any_changed then config.save_section(data.create_config_section()) end
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
