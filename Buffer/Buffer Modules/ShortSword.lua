local utils = require("Buffer Modules.Utils")
local shortsword = {}

-- Sword & Shield
shortsword = {
    title = "Sword & Shield",
    [1] = {
        title = "Destroyer Oil",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.ShortSword",
            func = "update",
            pre = function(args)
                if shortsword[1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<IsOilBuffSetting>k__BackingField", true)
                    managed:set_field("_OilBuffTimer", 3000)
                end
            end,
            post = utils.nothing()
        }
    }
}
return shortsword