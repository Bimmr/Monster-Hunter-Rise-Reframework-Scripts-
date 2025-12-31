local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("hunting_horn", {
    infernal_mode = false,
    skillbind_shockwave = false
})

function Module.create_hooks()
    
    Module:init_stagger("hunting_horn_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.Horn"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if managed:get_type_definition():is_a("snow.player.Horn") == false then return end

        if not Module:should_execute_staggered("hunting_horn_update") then return end

        -- Infernal mode
        if Module.data.infernal_mode then 
            managed:set_field("<RevoltGuage>k__BackingField", 100) 
        end
        
        -- Skillbind shockwave
        if Module.data.skillbind_shockwave then 
            managed:set_field("_ImpactPullsTimer", 1800) 
        end
    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.infernal_mode = imgui.checkbox(Language.get(languagePrefix .. "infernal_mode"), Module.data.infernal_mode)
    any_changed = changed or any_changed
    
    changed, Module.data.skillbind_shockwave = imgui.checkbox(Language.get(languagePrefix .. "skillbind_shockwave"), Module.data.skillbind_shockwave)
    any_changed = changed or any_changed

    return any_changed
end

return Module
