local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("charge_blade", {
    full_bottles = false,
    sword_charged = false,
    shield_charged = false,
    chainsaw_buff = false,
})

function Module.create_hooks()
    
    Module:init_stagger("charge_blade_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.ChargeAxe"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "snow.player.ChargeAxe") then return end

        if not Module:should_execute_staggered("charge_blade_update") then return end

        -- Full bottles
        if Module.data.full_bottles then
            managed:set_field("<ChargedBottleNum>k__BackingField", 5)
            managed:set_field("_ChargeGauge", 50)
        end
        
        -- Sword charged
        if Module.data.sword_charged then 
            managed:set_field("_SwordBuffTimer", 500) 
        end
        
        -- Shield charged
        if Module.data.shield_charged then 
            managed:set_field("_ShieldBuffTimer", 1000) 
        end
        
        -- Chainsaw buff
        if Module.data.chainsaw_buff then 
            managed:set_field("_IsChainsawBuff", true) 
        end
    end, Utils.nothing())
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.full_bottles = imgui.checkbox(Language.get(languagePrefix .. "full_bottles"), Module.data.full_bottles)
    any_changed = changed or any_changed
    
    changed, Module.data.sword_charged = imgui.checkbox(Language.get(languagePrefix .. "sword_charged"), Module.data.sword_charged)
    any_changed = changed or any_changed
    
    changed, Module.data.shield_charged = imgui.checkbox(Language.get(languagePrefix .. "shield_charged"), Module.data.shield_charged)
    any_changed = changed or any_changed
    
    changed, Module.data.chainsaw_buff = imgui.checkbox(Language.get(languagePrefix .. "chainsaw_buff"), Module.data.chainsaw_buff)
    any_changed = changed or any_changed

    return any_changed
end

return Module
