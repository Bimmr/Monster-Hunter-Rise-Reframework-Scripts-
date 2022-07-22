local utils = require("Buffer Modules.Utils")
local slashAxe = {}

-- Switch Axe Modifications
slashAxe = {
    title = "Switch Axe",

    [1] = {
        title = "Max Charge",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.SlashAxe",
            func = "update",
            pre = function(args)
                if slashAxe[1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_BottleGauge", 100)
                end
            end,
            post = utils.nothing()
        }
    },
    [2] = {
        title = "Max Sword Ammo",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.SlashAxe",
            func = "update",
            pre = function(args)
                if slashAxe[2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_BottleAwakeGauge", 150)
                end
            end,
            post = utils.nothing()
        }
    },
    [3] = {
        title = "Power Axe",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.SlashAxe",
            func = "update",
            pre = function(args)
                if slashAxe[3].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_BottleAwakeAssistTimer", 3600)
                end
            end,
            post = utils.nothing()
        }
    },
    [4] = {
        title = "Switch Charger",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.SlashAxe",
            func = "update",
            pre = function(args)
                if slashAxe[4].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_NoUseSlashGaugeTimer", 400)
                end
            end,
            post = utils.nothing()
        }
    }
}
return slashAxe