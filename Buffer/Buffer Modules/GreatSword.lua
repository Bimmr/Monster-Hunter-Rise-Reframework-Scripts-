local utils, config
local data = {
    title = "Great Sword",
    charge_level = -1,
    power_sheathe = false
}

function data.init()
    utils = require("Buffer Modules.Utils")
    config = require("Buffer Modules.Config")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.GreatSword"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        
        if data.charge_level > -1 then managed:set_field("_TameLv", data.charge_level) end
        if data.power_sheathe then managed:set_field("MoveWpOffBuffGreatSwordTimer", 1200) end
    end, utils.nothing())
end

function data.draw()
    
    local changed, any_changed = false, false
    changed, data.charge_level = imgui.slider_int("Charge Level", data.charge_level, -1, 3,
                                                         data.charge_level > -1 and "Level %d" or "Off")
    any_changed = changed or any_changed
    changed, data.power_sheathe = imgui.checkbox("Power Sheathe", data.power_sheathe)
    utils.tooltip("No effect will appear on the weapon")
    any_changed = changed or any_changed

    if any_changed then config.save_section(data.create_config_section()) end

end

function data.create_config_section()
    return {
        [data.title] = {
            charge_level = data.charge_level,
            power_sheathe = data.power_sheathe
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.charge_level = config_section.charge_level or data.charge_level
    data.power_sheathe = config_section.power_sheathe or data.power_sheathe
end


return data
