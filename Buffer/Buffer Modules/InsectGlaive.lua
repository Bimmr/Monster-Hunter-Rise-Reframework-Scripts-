local utils
local insect_glaive = {
    title = "Insect Glaive",
    red_extract = false,
    white_extract = false,
    orange_extract = false,
    aerials = false,
    kinsect_stamina = false
}


function insect_glaive.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.InsectGlaive"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if insect_glaive.red_extract then managed:set_field("_RedExtractiveTime", 1800) end
        if insect_glaive.white_extract then managed:set_field("_WhiteExtractTime", 1800) end
        if insect_glaive.orange_extract then managed:set_field("_OrangeExtractTime", 1800) end
        if insect_glaive.aerials then managed:set_field("_AerialCount", 2) end
        if insect_glaive.kinsect_stamina then managed:set_field("<_Stamina>k__BackingField", 100) end
    end, utils.nothing())
end

function insect_glaive.init()
    utils = require("Buffer Modules.Utils")

    insect_glaive.init_hooks()
end
function insect_glaive.draw()
    local changed = false
    changed, insect_glaive.red_extract = imgui.checkbox("Red Extract", insect_glaive.red_extract)
    changed, insect_glaive.white_extract = imgui.checkbox("White Extract", insect_glaive.white_extract)
    changed, insect_glaive.orange_extract = imgui.checkbox("Orange Extract", insect_glaive.orange_extract)
    changed, insect_glaive.aerials = imgui.checkbox("Unlimited Aerials ", insect_glaive.aerials)
    changed, insect_glaive.kinsect_stamina = imgui.checkbox("Unlimited Kinsect Stamina", insect_glaive.kinsect_stamina)
    if changed then utils.saveConfig() end
end

return insect_glaive
