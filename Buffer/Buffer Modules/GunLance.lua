local utils
local gun_lance = {
    title = "Gun Lance",
    dragon_cannon = false,
    aerials = false,
    auto_reload = false,
    ground_splitter = false,
    errupting_cannon = false
}

function gun_lance.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.GunLance"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if gun_lance.aerials then managed:set_field("_AerialCount", 0) end
        if gun_lance.auto_reload then managed:call("reloadBullet") end
        if gun_lance.ground_splitter then managed:set_field("_ShotDamageUpDurationTimer", 1800) end
        if gun_lance.errupting_cannon then
            managed:set_field("_ExplodePileBuffTimer", 1800)
            managed:set_field("_ExplodePileAttackRate", 1.3)
            managed:set_field("_ExplodePileElemRate", 1.3)
        end
    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        local playerData = utils.getPlayerData()
        if not playerData then return end

        if gun_lance.dragon_cannon then playerData:set_field("_ChargeDragonSlayCannonTime", 0) end
    end, utils.nothing())
end

function gun_lance.init()
    utils = require("Buffer Modules.Utils")

    gun_lance.init_hooks()
end

function gun_lance.draw()
    local changed = false
    changed, gun_lance.dragon_cannon = imgui.checkbox("Unlimited Dragon Cannon", gun_lance.dragon_cannon)
    changed, gun_lance.aerials = imgui.checkbox("Unlimited Aerials", gun_lance.aerials)
    changed, gun_lance.auto_reload = imgui.checkbox("Auto Reload", gun_lance.auto_reload)
    changed, gun_lance.ground_splitter = imgui.checkbox("Ground Splitter", gun_lance.ground_splitter)
    changed, gun_lance.errupting_cannon = imgui.checkbox("Errupting Cannon", gun_lance.errupting_cannon)
    if changed then utils.saveConfig() end
end

return gun_lance
