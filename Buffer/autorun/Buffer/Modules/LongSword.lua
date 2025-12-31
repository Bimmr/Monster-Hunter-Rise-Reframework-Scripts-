local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("long_sword", {
    guage_max = false,
    guage_level = -1
})

function Module.create_hooks()
    
    Module:init_stagger("long_sword_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.LongSword"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if managed:get_type_definition():is_a("snow.player.LongSword") == false then return end

        if not Module:should_execute_staggered("long_sword_update") then return end

        -- Max gauge
        if Module.data.guage_max then 
            managed:set_field("_LongSwordGauge", 100) 
        end
        
        -- Gauge level
        if Module.data.guage_level > -1 then 
            managed:set_field("_LongSwordGaugeLv", Module.data.guage_level) 
        end
    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.guage_level    = imgui.slider_int(Language.get(languagePrefix .. "guage_level"), Module.data.guage_level, -1, 3, Module.data.guage_level == -1 and Language.get("base.disabled") or tostring(Module.data.guage_level + 1))
    any_changed = changed or any_changed

    changed, Module.data.guage_max      = imgui.checkbox(Language.get(languagePrefix .. "guage_max"), Module.data.guage_max)
    any_changed = changed or any_changed
    
    return any_changed
end

return Module
