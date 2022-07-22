local utils = require("Buffer Modules.Utils")
local longsword = {}

-- Long Sword Modifications
longsword = {
    title = "Long Sword",
    [1] = {
        title = "Spirit Guage Max",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.LongSword",
            func = "update",
            pre = function(args)
                if longsword[1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_LongSwordGauge", 100)
                end
            end,
            post = utils.nothing()
        }
    },
    [2] = {
        title = "Spirit Level",
        type = "slider",
        value = -1,
        min = -1,
        max = 3,
        display = "Level: %d",
        hook = {
            path = "snow.player.LongSword",
            func = "update",
            pre = function(args)
                if longsword[2].value >= 0 then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_LongSwordGaugeLv", longsword.spiritLevel.value)
                end
            end,
            post = utils.nothing()
        }
    }
}

return longsword