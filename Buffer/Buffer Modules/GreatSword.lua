local utils
local great_sword = {
    title = "Great Sword",
    charge_level = -1,
    power_sheathe = false
}

function great_sword.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.GreatSword"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        
        if great_sword.charge_level > -1 then managed:set_field("_TameLv", great_sword.charge_level) end
        if great_sword.power_sheathe then managed:set_field("MoveWpOffBuffGreatSwordTimer", 1200) end
    end, utils.nothing())
end

function great_sword.init()
    utils = require("Buffer Modules.Utils")

    great_sword.init_hooks()
end

function great_sword.draw()
    local changed = false
    changed, great_sword.charge_level = imgui.slider_int("Charge Level", great_sword.charge_level, -1, 3,
                                                         great_sword.charge_level > -1 and "Level %d" or "Off")
    changed, great_sword.power_sheathe = imgui.checkbox("Power Sheathe", great_sword.power_sheathe)
    utils.tooltip("No effect will appear on the weapon")
    if changed then utils.saveConfig() end

end

return great_sword
