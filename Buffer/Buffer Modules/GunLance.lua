local utils = require("Buffer Modules.Utils")
local gunLance = {}

-- Gunlance Modifications
gunLance = {
    title = "Gunlance",
    [1] = {
        title = "Unlimited Dragon Cannon",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = function(args)
                if gunLance[1].value then

                    local playerData = getPlayerData()
                    if not playerData then return end
                    playerData:set_field("_ChargeDragonSlayCannonTime", 0)
                end
            end,
            post = utils.nothing()
        }
    },
    [2] = {
        title = "Unlimited Aerials",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.GunLance",
            func = "update",
            pre = function(args)
                if gunLance[2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_AerialCount", 0)
                end
            end,
            post = utils.nothing()
        }
    },
    [3] = {
        title = "Auto Reload ",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.GunLance",
            func = "update",
            pre = function(args)
                if gunLance[3].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:call("reloadBullet")
                end
            end,
            post = utils.nothing()
        }
    },
    [4] = {
        title = "Ground Splitter",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.GunLance",
            func = "update",
            pre = function(args)
                if gunLance[4].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_ShotDamageUpDurationTimer", 1800)
                end
            end,
            post = utils.nothing()
        }
    },
    [5] = {
        title = "Erupting Cannon",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.GunLance",
            func = "update",
            pre = function(args)
                if gunLance[5].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_ExplodePileBuffTimer", 1800)
                    managed:set_field("_ExplodePileAttackRate", 1.3)
                    managed:set_field("_ExplodePileElemRate", 1.3)

                end
            end,
            post = utils.nothing()
        }
    }
}
return gunLance