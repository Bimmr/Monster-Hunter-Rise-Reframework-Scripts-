local utils
local hammer = {
    title = "Hammer",
    charge_level = -1,
    impact_burst = false
}

function hammer.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.Hammer"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if hammer.charge_level > -1 then
            managed:set_field("<NowChargeLevel>k__BackingField", hammer.charge_level)
        end
        if hammer.impact_burst then
            managed:set_field("_ImpactPullsTimer", 3600)
            managed:set_field("_IsEnableImapctPulls", true) -- They mispelt this field
            managed:set_field("_IsEnableImpactPulls", true) -- Adding this just incase they fix it in a later version
        end
    end, utils.nothing())
end

function hammer.init()
    utils = require("Buffer Modules.Utils")

    hammer.init_hooks()
end

function hammer.draw()
    local changed = false
    changed, hammer.charge_level = imgui.slider_int("Charge Level ", hammer.charge_level, -1, 3,
                                                    hammer.charge_level > -1 and "Level %d" or "Off")
    changed, hammer.impact_burst = imgui.checkbox("Impact Burst", hammer.impact_burst)
    if changed then utils.saveConfig() end
end

return hammer
