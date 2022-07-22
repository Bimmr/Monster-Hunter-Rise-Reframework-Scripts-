local utils = require("Buffer Modules.Utils")
local chargeBlade = {}

-- Charge Blade Modifications
chargeBlade = {
    title = "Charge Blade",

    [1] = {
        title = "Full Bottles",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.ChargeAxe",
            func = "update",
            pre = function(args)
                if chargeBlade[1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<ChargedBottleNum>k__BackingField", 5)
                    managed:set_field("_ChargeGauge", 50)
                end
            end,
            post = utils.nothing()
        }
    },
    [2] = {
        title = "Sword Charged",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.ChargeAxe",
            func = "update",
            pre = function(args)
                if chargeBlade[2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_SwordBuffTimer", 500)
                end
            end,
            post = utils.nothing()
        }
    },
    [3] = {
        title = "Shield Charged",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.ChargeAxe",
            func = "update",
            pre = function(args)
                if chargeBlade[3].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_ShieldBuffTimer", 1000)
                end
            end,
            post = utils.nothing()
        }
    }
}
return chargeBlade