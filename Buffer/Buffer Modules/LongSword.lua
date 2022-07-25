local utils, config
local data = {
    title = "Long Sword",
    guage_max = false,
    guage_level = -1
}

function data.init()
    utils = require("Buffer Modules.Utils")
    config = require("Buffer Modules.Config")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.LongSword"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if data.guage_max then managed:set_field("_LongSwordGauge", 100) end
        if data.guage_level > -1 then managed:set_field("_LongSwordGaugeLv", data.guage_level) end
    end, utils.nothing())
end

function data.draw()

    local changed, any_changed = false, false
    changed, data.guage_max = imgui.checkbox("Spirit Guage Max", data.guage_max)
    any_changed = changed or any_changed
    changed, data.guage_level = imgui.slider_int("Spirit Level ", data.guage_level, -1, 3, data.guage_level > -1 and "Level %d" or "Off")
    any_changed = changed or any_changed

    if any_changed then config.save_section(data.create_config_section()) end
end

function data.create_config_section()
    return {
        [data.title] = {
            guage_max = data.guage_max,
            guage_level = data.guage_level
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.guage_max = config_section.guage_max or data.guage_max
    data.guage_level = config_section.guage_level or data.guage_level
end

return data