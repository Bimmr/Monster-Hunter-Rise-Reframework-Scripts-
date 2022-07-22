local utils = require("Buffer Modules.Utils")
local huntingHorn = {}

-- Hunting Horn Modifications
huntingHorn = {
    title = "Hunting Horn",
    [1] = {
        title = "Infernal Mode",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.Horn",
            func = "update",
            pre = function(args)
                if huntingHorn[1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<RevoltGuage>k__BackingField", 100)
                end
            end,
            post = utils.nothing()
        }
    },
    [2] = {
        title = "Skillbind Shockwave",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.Horn",
            func = "update",
            pre = function(args)
                if huntingHorn[2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_ImpactPullsTimer", 1800)
                end
            end,
            post = utils.nothing()
        }
    }
}
return huntingHorn