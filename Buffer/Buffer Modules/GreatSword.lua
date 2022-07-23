local utils = require("Buffer Modules.Utils")
local greatsword = {}


-- Great Sword Modifications
greatsword = {
    title = "Great Sword",
    [1] = {
        title = "Charge Level",
        type = "slider",
        value = -1,
        min = -1,
        max = 3,
        display = "Level: %d",
        hook = {
            path = "snow.player.GreatSword",
            func = "update",
            pre = function(args)
                if greatsword[1].value >= 0 then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_TameLv", greatsword[1].value)
                end
            end,
            post = utils.nothing()
        }
    },
    [2] = {
        title = "Power Sheathe",
        type = "checkbox",
        value = false,
        tooltip = "No effect will appear on the weapon",
        hook = {
            path = "snow.player.GreatSword",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if greatsword[2].value then managed:set_field("MoveWpOffBuffGreatSwordTimer", 1200) end
            end,
            post = utils.nothing()
        }
    }
}
return greatsword