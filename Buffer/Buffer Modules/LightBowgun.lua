local utils
local misc
local light_bowgun = {
    title = "Light Bowgun",
    -- unlimited_ammo -- In Misc
    -- auto_reload   -- In Misc
    wyvern_blast = false
    -- no_deviation  -- In Misc
}
function light_bowgun.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.LightBowgun"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if misc.auto_reload then managed:call("resetBulletNum") end
    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local playerData = utils.getPlayerData()
        if not playerData then return end

        if light_bowgun.wyvern_blast then
            playerData:set_field("_WyvernBlastGauge", 3)
            playerData:set_field("_WyvernBlastReloadTimer", 0)
        end
    end, utils.nothing())
end
function light_bowgun.init()
    utils = require("Buffer Modules.Utils")
    misc = require("Buffer Modules.Miscellaneous")

    light_bowgun.init_hooks()
end


function light_bowgun.draw()
    local changed = false
    changed, misc.ammo_and_coatings.unlimited_ammo = imgui.checkbox("Unlimited Ammo", misc.ammo_and_coatings.unlimited_ammo)
    changed, misc.ammo_and_coatings.auto_reload = imgui.checkbox("Auto Reload ", misc.ammo_and_coatings.auto_reload)
    changed, light_bowgun.wyvern_blast = imgui.checkbox("Unlimited Wyvern Blast", light_bowgun.wyvern_blast)
    changed, misc.ammo_and_coatings.no_deviation = imgui.checkbox("No Deviation ", misc.ammo_and_coatings.no_deviation)

    if changed then utils.saveConfig() end
end

return light_bowgun
