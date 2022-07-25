local utils, config
local data = {
    title = "Hunting Horn",
    infernal_mode = false,
    skillbind_shockwave = false
}

function data.init()
    utils = require("Buffer Modules.Utils")
    config = require("Buffer Modules.Config")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.Horn"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if data.infernal_mode then managed:set_field("<RevoltGuage>k__BackingField", 100) end
        if data.skillbind_shockwave then managed:set_field("_ImpactPullsTimer", 1800) end
    end, utils.nothing())
end

function data.draw()

    local changed, any_changed = false, false
    changed, data.infernal_mode = imgui.checkbox("Infernal Mode", data.infernal_mode)
    any_changed = changed or any_changed
    changed, data.skillbind_shockwave = imgui.checkbox("Skillbind Shockwave", data.skillbind_shockwave)
    any_changed = changed or any_changed

    if any_changed then config.save_section(data.create_config_section()) end
end

function data.create_config_section()
    return {
        [data.title] = {
            infernal_mode = data.infernal_mode,
            skillbind_shockwave = data.skillbind_shockwave
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.infernal_mode = config_section.infernal_mode or data.infernal_mode
    data.skillbind_shockwave = config_section.skillbind_shockwave or data.skillbind_shockwave
end

return data
