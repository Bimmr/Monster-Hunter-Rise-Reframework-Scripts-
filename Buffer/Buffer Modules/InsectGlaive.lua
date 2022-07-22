local utils = require("Buffer Modules.Utils")
local insectGlaive = {}

-- Insect Glaive Modifications
insectGlaive = {
    title = "Insect Glaive",

    [1] = {
        title = "Red Extract",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.InsectGlaive",
            func = "update",
            pre = function(args)
                if insectGlaive[1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_RedExtractiveTime", 8000)
                end
            end,
            post = utils.nothing()
        }
    },
    [2] = {
        title = "White Extract",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.InsectGlaive",
            func = "update",
            pre = function(args)
                if insectGlaive[2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_WhiteExtractiveTime", 8000)
                end
            end,
            post = utils.nothing()
        }
    },
    [3] = {
        title = "Orange Extract",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.InsectGlaive",
            func = "update",
            pre = function(args)
                if insectGlaive[3].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_OrangeExtractiveTime", 8000)
                end
            end,
            post = utils.nothing()
        }
    },
    [4] = {
        title = "Unlimited Aerials ",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.InsectGlaive",
            func = "update",
            pre = function(args)
                if insectGlaive[4].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_AerialCount", 2)
                end
            end,
            post = utils.nothing()
        }
    },
    [5] = {
        title = "Unlimited Kinsect Stamina",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.IG_Insect",
            func = "update",
            pre = function(args)
                if insectGlaive[5].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<_Stamina>k__BackingField", 100)
                end
            end,
            post = utils.nothing()
        }
    }
}
return insectGlaive