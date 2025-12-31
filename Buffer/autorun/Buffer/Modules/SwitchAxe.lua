local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("switch_axe", {
    max_charge = false,
    max_sword_ammo = false,
    power_axe = false,
    switch_charger = false
})

function Module.create_hooks()
    
    Module:init_stagger("switch_axe_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.SlashAxe"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if managed:get_type_definition():is_a("snow.player.SlashAxe") == false then return end

        if not Module:should_execute_staggered("switch_axe_update") then return end

        -- Max charge
        if Module.data.max_charge then 
            managed:set_field("_BottleGauge", 100) 
        end
        
        -- Max sword ammo
        if Module.data.max_sword_ammo then 
            managed:set_field("_BottleAwakeGauge", 150) 
        end
        
        -- Power axe
        if Module.data.power_axe then 
            managed:set_field("_BottleAwakeAssistTimer", 3600) 
        end
        
        -- Switch charger
        if Module.data.switch_charger then 
            managed:set_field("_NoUseSlashGaugeTimer", 400) 
        end
    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.max_charge         = imgui.checkbox(Language.get(languagePrefix .. "max_charge"), Module.data.max_charge)
    any_changed = changed or any_changed
    
    changed, Module.data.max_sword_ammo     = imgui.checkbox(Language.get(languagePrefix .. "max_sword_ammo"), Module.data.max_sword_ammo)
    any_changed = changed or any_changed
    
    changed, Module.data.power_axe          = imgui.checkbox(Language.get(languagePrefix .. "power_axe"), Module.data.power_axe)
    any_changed = changed or any_changed
    
    changed, Module.data.switch_charger     = imgui.checkbox(Language.get(languagePrefix .. "switch_charger"), Module.data.switch_charger)
    any_changed = changed or any_changed

    return any_changed
end

return Module
