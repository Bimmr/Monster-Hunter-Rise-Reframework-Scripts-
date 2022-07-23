local utils = require("Buffer Modules.Utils")
local misc
local bow = {}

function bow.init()
    misc = require("Buffer Modules.Miscellaneous")
end

-- Bow Modifications
bow = {
    title = "Bow",

    [1] = {
        title = "Charge Level   ",
        type = "slider",
        value = -1,
        min = -1,
        max = 3,
        display = "Level: %d",
        hook = {
            path = "snow.player.Bow",
            func = "update",
            pre = function(args)
                if bow[1].value >= 0 then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<ChargeLv>k__BackingField", bow[1].value)
                end
            end,
            post = utils.nothing()
        }
    },
    [2] = {
        title = "Unlimited Coatings",
        type = "checkbox",
        value = false,
        dontSave = true,
        onChange = function()
            -- Change and update Miscellaneous/Ammo & Coating Options/Unlimited Coatings (Arrows)
            misc[3][1].value = bow[2].value
            misc[1].onChange()
        end
    },
    [3] = {
        title = "Herculean Draw",
        type = "checkbox",
        value = false,
        tooltip = "No effect will appear on the weapon",
        hook = {
            path = "snow.player.Bow",
            func = "update",
            pre = function(args)
                if bow[3].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_WireBuffAttackUpTimer", 1800)
                end
            end,
            post = utils.nothing()
        }
    },
    [4] = {
        title = "Bolt Boost",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.Bow",
            func = "update",
            pre = function(args)
                if bow[4].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_WireBuffArrowUpTimer", 1800)
                end
            end,
            post = utils.nothing()
        }
    }
}
return bow