local utils = require("Buffer Modules.Utils")
local dualBlades = {}

-- Dual Blade Modifications
dualBlades = {
    title = "Dual Blades",

    [1] = {
        title = "ArchDemon Mode",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.DualBlades",
            func = "update",
            pre = function(args)
                if dualBlades[1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<KijinKyoukaGuage>k__BackingField", 100)
                end
            end,
            post = utils.nothing()
        }
    },
    [2] = {
        title = "Ironshine Silk",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.DualBlades",
            func = "update",
            pre = function(args)
                if dualBlades[2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("SharpnessRecoveryBuffValidTimer", 3000)
                end
            end,
            post = utils.nothing()
        }
    }
}
return dualBlades