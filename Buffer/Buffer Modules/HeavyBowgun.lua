local utils
local misc
local heavy_bowgun = {
    title = "Heavy Bowgun",
    charge_level = -1,
    -- unlimited_ammo - In Misc
    -- auto_reload  - In Misc
    wyvern_sniper = false,
    wyvern_machine_gun = false
    -- no_deviation  - In Misc
}
function heavy_bowgun.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.HeavyBowgun"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if heavy_bowgun.charge_level > -1 then
            managed:set_field("_ShotChargeLv", heavy_bowgun.charge_level)
            managed:set_field("_ShotChargeFrame", 30 * heavy_bowgun.charge_level)
        end
        if misc.auto_reload then managed:call("resetBulletNum") end
    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local playerData = utils.getPlayerData()
        if not playerData then return end

        if heavy_bowgun.wyvern_sniper then
            playerData:set_field("_HeavyBowgunWyvernSnipeBullet", 1)
            playerData:set_field("_HeavyBowgunWyvernSnipeTimer", 0)
        end
        if heavy_bowgun.wyvern_machinegun then
            playerData:set_field("_HeavyBowgunWyvernMachineGunBullet", 50)
            playerData:set_field("_HeavyBowgunWyvernMachineGunTimer", 0)
        end
        if heavy_bowgun.overheat then playerData:set_field("_HeavyBowgunHeatGauge", 0) end
    end, utils.nothing())
end

function heavy_bowgun.init()
    utils = require("Buffer Modules.Utils")
    misc = require("Buffer Modules.Miscellaneous")

    heavy_bowgun.init_hooks()
end

function heavy_bowgun.draw()
    local changed = false
    changed, heavy_bowgun.charge_level = imgui.slider_int("Charge Level  ", heavy_bowgun.charge_level, -1, 4,
                                                          heavy_bowgun.charge_level > -1 and "Level %d" or "Off")
    changed, misc.ammo_and_coatings.unlimited_ammo = imgui.checkbox("Unlimited Ammo ", misc.ammo_and_coatings.unlimited_ammo)
    changed, misc.ammo_and_coatings.auto_reload = imgui.checkbox("Auto Reload  ", misc.ammo_and_coatings.auto_reload)
    changed, heavy_bowgun.wyvern_sniper = imgui.checkbox("Unlimited Wyvern Sniper", heavy_bowgun.wyvern_sniper)
    changed, heavy_bowgun.wyvern_machine_gun = imgui.checkbox("Unlimited Wyvern Machine Gun",
                                                              heavy_bowgun.wyvern_machine_gun)
    changed, heavy_bowgun.overheat = imgui.checkbox("Prevent Overheat", heavy_bowgun.overheat)
    changed, misc.ammo_and_coatings.no_deviation = imgui.checkbox("No Deviation  ", misc.ammo_and_coatings.no_deviation)

    if changed then utils.saveConfig() end
end
return heavy_bowgun
