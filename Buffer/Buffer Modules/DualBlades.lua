local utils
local dual_blades = {
    title = "Dual Blades",
    archdemon_mode = false,
    ironshine_silk = false
}


function dual_blades.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.DualBlades"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if dual_blades.archdemon_mode then managed:set_field("<KijinKyoukaGuage>k__BackingField", 100) end
        if dual_blades.ironshine_silk then managed:set_field("SharpnessRecoveryBuffValidTimer", 3000) end
    end, utils.nothing())
end

function dual_blades.init()
    utils = require("Buffer Modules.Utils")

    dual_blades.init_hooks()
end
function dual_blades.draw()
    local changed = false
    changed, dual_blades.archdemon_mode = imgui.checkbox("ArchDemon Mode", dual_blades.archdemon_mode)
    changed, dual_blades.ironshine_silk = imgui.checkbox("Ironshine Silk", dual_blades.ironshine_silk)
    if changed then utils.saveConfig() end

end

return dual_blades
