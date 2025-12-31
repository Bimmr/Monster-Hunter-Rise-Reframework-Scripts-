local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("insect_glaive", {
    red_extract = false,
    white_extract = false,
    orange_extract = false,
    aerials = false,
    kinsect_stamina = false
})

function Module.create_hooks()
    
    Module:init_stagger("insect_glaive_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.InsectGlaive"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if managed:get_type_definition():is_a("snow.player.InsectGlaive") == false then return end

        if not Module:should_execute_staggered("insect_glaive_update") then return end

        -- Red extract
        if Module.data.red_extract then 
            managed:set_field("_RedExtractiveTime", 8000) 
        end
        
        -- White extract
        if Module.data.white_extract then 
            managed:set_field("_WhiteExtractiveTime", 8000) 
        end
        
        -- Orange extract
        if Module.data.orange_extract then 
            managed:set_field("_OrangeExtractiveTime", 8000) 
        end
        
        -- Aerials
        if Module.data.aerials then 
            managed:set_field("_AerialCount", 2) 
        end
    end)

    Module:init_stagger("ig_insect_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.IG_Insect"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_type_definition():is_a("snow.player.IG_Insect") then return end

        if not Module:should_execute_staggered("ig_insect_update") then return end

        -- Kinsect stamina (not working?)
        if Module.data.kinsect_stamina then 
            managed:set_field("<_Stamina>k__BackingField", 100) 
        end
    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.red_extract = imgui.checkbox(Language.get(languagePrefix .. "red_extract"), Module.data.red_extract)
    any_changed = changed or any_changed
    
    changed, Module.data.white_extract = imgui.checkbox(Language.get(languagePrefix .. "white_extract"), Module.data.white_extract)
    any_changed = changed or any_changed
    
    changed, Module.data.orange_extract = imgui.checkbox(Language.get(languagePrefix .. "orange_extract"), Module.data.orange_extract)
    any_changed = changed or any_changed
    
    changed, Module.data.aerials = imgui.checkbox(Language.get(languagePrefix .. "aerials"), Module.data.aerials)
    any_changed = changed or any_changed
    
    changed, Module.data.kinsect_stamina = imgui.checkbox(Language.get(languagePrefix .. "kinsect_stamina"), Module.data.kinsect_stamina)
    any_changed = changed or any_changed

    return any_changed
end

return Module
