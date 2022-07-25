local utils
local lance = {
    title = "Lance",
    anchor_rage = -1
}
function lance.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.Lance"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if lance.anchor_rage > -1 then
            managed:set_field("_GuardRageTimer", 3000)
            managed:set_field("_GuardRageBuffType", lance[1].value)
        end
    end, utils.nothing())

end
function lance.init()
    utils = require("Buffer Modules.Utils")

    lance.init_hooks()
end

function lance.draw()
    local changed = false
    changed, lance.anchor_rage = imgui.slider_int("Anchor Rage ", lance.anchor_rage, -1, 3,
                                                  lance.anchor_rage > -1 and "Level %d" or "Off")
    if changed then utils.saveConfig() end
end

return lance
