local utils, config

local data = {
    title = "Charge Blade",
    full_bottles = false,
    sword_charged = false,
    shield_charged = false
}

function data.init()
    utils = require("Buffer Modules.Utils")
    config = require("Buffer Modules.Config")

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
    end, utils.nothing())
end

function data.draw()
    local changed, any_changed = false, false
    changed, data.full_bottles = imgui.checkbox("Full Bottles", data.full_bottles)
    any_changed = changed or any_changed
    changed, data.sword_charged = imgui.checkbox("Sword Charged", data.sword_charged)
    any_changed = changed or any_changed
    changed, data.shield_charged = imgui.checkbox("Shield Charged", data.shield_charged)
    any_changed = changed or any_changed
    
    if any_changed then config.save_section(data.create_config_section()) end
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
