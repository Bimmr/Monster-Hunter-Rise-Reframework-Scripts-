local utils
local hunting_horn = {
    title = "Hunting Horn",
    infernal_mode = false,
    skillbind_shockwave = false
}

function hunting_horn.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.Horn"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if hunting_horn.infernal_mode then managed:set_field("<RevoltGuage>k__BackingField", 100) end
        if hunting_horn.skillbind_shockwave then managed:set_field("_ImpactPullsTimer", 1800) end
    end, utils.nothing())
end

function hunting_horn.init()
    utils = require("Buffer Modules.Utils")

    hunting_horn.init_hooks()
end

function hunting_horn.draw()
    local changed = false
    changed, hunting_horn.infernal_mode = imgui.checkbox("Infernal Mode", hunting_horn.infernal_mode)
    changed, hunting_horn.skillbind_shockwave = imgui.checkbox("Skillbind Shockwave", hunting_horn.skillbind_shockwave)
    if changed then utils.saveConfig() end
end


return hunting_horn
