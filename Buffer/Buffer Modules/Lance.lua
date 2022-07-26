local utils, config
local data = {
    title = "Lance",
    anchor_rage = -1
}

function data.init()
    utils = require("Buffer Modules.Utils")
    config = require("Buffer Modules.Config")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.Lance"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if data.anchor_rage > -1 then
            managed:set_field("_GuardRageTimer", 3000)
            managed:set_field("_GuardRageBuffType", data[1].value)
        end
    end, utils.nothing())

end

function data.draw()

    local changed, any_changed = false, false
    changed, data.anchor_rage = imgui.slider_int("Anchor Rage ", data.anchor_rage, -1, 3, data.anchor_rage > -1 and "Level %d" or "Off")
    any_changed = changed or any_changed

    if any_changed then config.save_section(data.create_config_section()) end
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
