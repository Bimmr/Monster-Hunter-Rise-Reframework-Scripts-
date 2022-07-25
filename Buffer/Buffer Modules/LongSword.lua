local utils
local long_sword = {
    title = "Long Sword",
    guage_max = false,
    guage_level = -1
}
function long_sword.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.LongSword"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        
        if long_sword.guage_max then managed:set_field("_LongSwordGauge", 100) end
        if long_sword.guage_level > -1 then managed:set_field("_LongSwordGaugeLv", long_sword.guage_level) end
    end, utils.nothing())
end
function long_sword.init()
    utils = require("Buffer Modules.Utils")
    
    long_sword.init_hooks()
end


function long_sword.draw()
    local changed = false
    changed, long_sword.guage_max = imgui.checkbox("Spirit Guage Max", long_sword.guage_max)
    changed, long_sword.guage_level = imgui.slider_int("Spirit Level ", long_sword.guage_level, -1, 3,
                                                      long_sword.guage_level > -1 and "Level %d" or "Off")
    if changed then utils.saveConfig() end
end


return long_sword