local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("long_sword", {
    gauge_max = false,
    gauge_level = -1
})

function Module.create_hooks()
    
    Module:init_stagger("long_sword_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.LongSword"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.player.LongSword") then return end

        if not Module:should_execute_staggered("long_sword_update") then return end

        -- Max gauge
        if Module.data.gauge_max then 
            managed:set_field("_LongSwordGauge", 100) 
        end
        
        -- Gauge level
        if Module.data.gauge_level > -1 then 
            managed:set_field("_LongSwordGaugeLv", Module.data.gauge_level) 
        end
    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.gauge_level    = imgui.slider_int(Language.get(languagePrefix .. "gauge_level"), Module.data.gauge_level, -1, 3, Module.data.gauge_level == -1 and Language.get("base.disabled") or tostring(Module.data.gauge_level + 1))
    any_changed = changed or any_changed

    changed, Module.data.gauge_max      = imgui.checkbox(Language.get(languagePrefix .. "gauge_max"), Module.data.gauge_max)
    any_changed = changed or any_changed
    
    return any_changed
end

return Module
