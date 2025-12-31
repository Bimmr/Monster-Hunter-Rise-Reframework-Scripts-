local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("dual_blades", {
    archdemon_mode = false,
    ironshine_silk = false
})

function Module.create_hooks()
    
    Module:init_stagger("dual_blades_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.DualBlades"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "snow.player.DualBlades") then return end

        if not Module:should_execute_staggered("dual_blades_update") then return end

        -- Archdemon mode
        if Module.data.archdemon_mode then 
            managed:set_field("<KijinKyoukaGuage>k__BackingField", 100) 
        end
        
        -- Ironshine silk
        if Module.data.ironshine_silk then 
            managed:set_field("SharpnessRecoveryBuffValidTimer", 3000) 
        end
    end, Utils.nothing())
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.archdemon_mode = imgui.checkbox(Language.get(languagePrefix .. "archdemon_mode"), Module.data.archdemon_mode)
    any_changed = changed or any_changed
    
    changed, Module.data.ironshine_silk = imgui.checkbox(Language.get(languagePrefix .. "ironshine_silk"), Module.data.ironshine_silk)
    any_changed = changed or any_changed

    return any_changed
end

return Module
