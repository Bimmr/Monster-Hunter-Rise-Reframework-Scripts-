local utils
local slash_axe = {
    title = "Switch Axe",
    max_charge = false,
    max_sword_ammo = false,
    power_axe = false,
    switch_charger = false
}
function slash_axe.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.SlashAxe"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if slash_axe.max_charge then managed:set_field("_BottleGauge", 100) end
        if slash_axe.max_sword_ammo then managed:set_field("_BottleAwakeGauge", 150) end
        if slash_axe.power_axe then managed:set_field("_BottleAwakeAssistTimer", 3600) end
        if slash_axe.switch_charger then managed:set_field("_NoUseSlashGaugeTimer", 400) end
    end, utils.nothing())
end

function slash_axe.init()
    utils = require("Buffer Modules.Utils")

    slash_axe.init_hooks()
end

function slash_axe.draw()
    local changed = false
    changed, slash_axe.max_charge = imgui.checkbox("Max Charge", slash_axe.max_charge)
    changed, slash_axe.max_sword_ammo = imgui.checkbox("Max Sword Ammo", slash_axe.max_sword_ammo)
    changed, slash_axe.power_axe = imgui.checkbox("Power Axe", slash_axe.power_axe)
    changed, slash_axe.switch_charger = imgui.checkbox("Switch Charger", slash_axe.switch_charger)
    if changed then utils.saveConfig() end
end

return slash_axe
