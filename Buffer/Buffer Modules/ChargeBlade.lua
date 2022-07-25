local utils

local charge_blade = {
    title = "Charge Blade",
    full_bottles = false,
    sword_charged = false,
    shield_charged = false
}

function charge_blade.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.ChargeAxe"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        
        if charge_blade.full_bottles then
            managed:set_field("<ChargedBottleNum>k__BackingField", 5)
            managed:set_field("_ChargeGauge", 50)
        end
        if charge_blade.sword_charged then managed:set_field("_SwordBuffTimer", 500) end
        if charge_blade.shield_charged then managed:set_field("_ShieldBuffTimer", 1000) end
    end, utils.nothing())
end

function charge_blade.init()
    utils = require("Buffer Modules.Utils")

    charge_blade.init_hooks()
end

function charge_blade.draw()
    local changed = false
    changed, charge_blade.full_bottles = imgui.checkbox("Full Bottles", charge_blade.full_bottles)
    changed, charge_blade.sword_charged = imgui.checkbox("Sword Charged", charge_blade.sword_charged)
    changed, charge_blade.shield_charged = imgui.checkbox("Shield Charged", charge_blade.shield_charged)
    if changed then utils.saveConfig() end
end

return charge_blade
