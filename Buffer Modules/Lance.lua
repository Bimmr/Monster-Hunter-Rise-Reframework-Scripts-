local utils = require("Buffer Modules.Utils")
local lance = {}

-- Lance Modifications
lance = {
    title = "Lance",
    [1] = {
        title = "Anchor Rage",
        type = "slider",
        value = -1,
        min = -1,
        max = 3,
        display = "Level: %d",
        hook = {
            path = "snow.player.Lance",
            func = "update",
            pre = function(args)
                if lance[1].value >= 0 then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_GuardRageTimer", 3000)
                    managed:set_field("_GuardRageBuffType", lance[1].value)
                end
            end,
            post = utils.nothing()
        }
    }
}
return lance