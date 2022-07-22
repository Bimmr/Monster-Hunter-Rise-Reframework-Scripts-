local utils = require("Buffer Modules.Utils")
local hammer = {}

-- Hammer Modifications
hammer = {
    title = "Hammer",

    [1] = {
        title = "Charge Level ",
        type = "slider",
        value = -1,
        min = -1,
        max = 2,
        display = "Level: %d",
        hook = {
            path = "snow.player.Hammer",
            func = "update",
            pre = function(args)
                if hammer[1].value >= 0 then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<NowChargeLevel>k__BackingField", hammer[1].value)
                end
            end,
            post = utils.nothing()
        }
    },
    [2] = {
        title = "Impact Burst",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.Hammer",
            func = "update",
            pre = function(args)
                if hammer[2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_ImpactPullsTimer", 3600)
                    managed:set_field("_IsEnableImapctPulls", true) -- They mispelt this field
                    managed:set_field("_IsEnableImpactPulls", true) -- Adding this just incase they fix it in a later version
                end
            end,
            post = utils.nothing()
        }
    }
}
return hammer