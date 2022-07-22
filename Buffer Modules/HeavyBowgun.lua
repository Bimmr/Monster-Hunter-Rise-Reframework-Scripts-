local utils = require("Buffer Modules.Utils")
local misc
local heavyBowgun = {}

function heavyBowgun.init()
    misc = require("Buffer Modules.Miscellaneous")
end

-- Heavy Bowgun Modifications
heavyBowgun = {
    title = "Heavy Bowgun",
    [1] = {
        title = "Charge Level  ",
        type = "slider",
        value = -1,
        min = -1,
        max = 3,
        display = "Level: %d",
        hook = {
            path = "snow.player.HeavyBowgun",
            func = "update",
            pre = function(args)
                if heavyBowgun[1].value >= 0 then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_ShotChargeLv", heavyBowgun[1].value)
                    managed:set_field("_ShotChargeFrame", 30 * heavyBowgun[1].value)
                end
            end,
            post = utils.nothing()
        }
    },
    [2] = {
        title = "Unlimited Ammo  ",
        type = "checkbox",
        value = false,
        dontSave = true,
        onChange = function()
            -- Change and update Miscellaneous/Ammo Options/Unlimited Ammo (Bowguns)
            misc[3][2].value = heavyBowgun[2].value
            misc[3][2].onChange()
        end
    },
    [3] = {
        title = "Auto Reload  ",
        type = "checkbox",
        value = false,
        dontSave = true,
        hook = {
            path = "snow.player.HeavyBowgun",
            func = "update",
            pre = function(args)
                if heavyBowgun[3].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:call("resetBulletNum")
                end
            end,
            post = utils.nothing()
        },
        onChange = function()
            -- Change and update Miscellaneous/Ammo & Coating Options/Auto Reload (Bowguns)
            misc[3][3].value = heavyBowgun[3].value
            misc[3][3].onChange()
        end
    },
    [4] = {
        title = "Unlimited Wyvern Sniper",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = function(args)
                if heavyBowgun[4].value then

                    local playerData = getPlayerData()
                    if not playerData then return end
                    playerData:set_field("_HeavyBowgunWyvernSnipeBullet", 1)
                    playerData:set_field("_HeavyBowgunWyvernSnipeTimer", 0)
                end
            end,
            post = utils.nothing()
        }
    },
    [5] = {
        title = "Unlimited Wyvern Machine Gun",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = function(args)
                if heavyBowgun[5].value then

                    local playerData = getPlayerData()
                    if not playerData then return end
                    playerData:set_field("_HeavyBowgunWyvernMachineGunBullet", 50)
                    playerData:set_field("_HeavyBowgunWyvernMachineGunTimer", 0)
                end
            end,
            post = utils.nothing()
        }
    },
    [6] = {
        title = "Prevent Overheat",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = function(args)
                if heavyBowgun[6].value then

                    local playerData = getPlayerData()
                    if not playerData then return end
                    playerData:set_field("_HeavyBowgunHeatGauge", 0)
                end
            end,
            post = utils.nothing()
        }
    },
    [7] = {
        title = "No Deviation ",
        type = "checkbox",
        value = false,
        onChange = function()
            -- Change and update Miscellaneous/Ammo & Coating Options/No Deviation (Bowguns)
            misc[3][4].value = heavyBowgun[7].value
            misc[3][4].onChange()
        end
    }
}
return heavyBowgun