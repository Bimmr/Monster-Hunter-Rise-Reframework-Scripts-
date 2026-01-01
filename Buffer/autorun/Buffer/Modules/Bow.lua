local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("bow", {
    charge_level = -1,
    herculean_draw = false,
    bolt_boost = false,
    unlimited_coatings = false,
})

function Module.create_hooks()
    
    Module:init_stagger("bow_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.Bow"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if managed:get_type_definition():is_a("snow.player.Bow") == false then return end

        -- Charge level
        if Module.data.charge_level > 0 then 
            managed:set_field("<ChargeLv>k__BackingField", Module.data.charge_level) 
        end
        
        if not Module:should_execute_staggered("bow_update") then return end

        -- Herculean draw
        if Module.data.herculean_draw then 
            managed:set_field("_WireBuffAttackUpTimer", 1800) 
        end
        
        -- Bolt boost
        if Module.data.bolt_boost then 
            managed:set_field("_WireBuffArrowUpTimer", 1800) 
        end
    end)

    
    -- Unlimited coatings
    sdk.hook(sdk.find_type_definition("snow.data.bulletSlider.BottleSliderFunc"):get_method("consumeItem"), function(args)
        if Module.data.unlimited_coatings then 
            return sdk.PreHookResult.SKIP_ORIGINAL 
        end
    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.charge_level           = imgui.slider_int(Language.get(languagePrefix .. "charge_level"), Module.data.charge_level, -1, 3, Module.data.charge_level == -1 and Language.get("base.disabled") or "%d")
    any_changed = changed or any_changed
    
    changed, Module.data.unlimited_coatings     = imgui.checkbox(Language.get(languagePrefix .. "unlimited_coatings"), Module.data.unlimited_coatings)
    any_changed = changed or any_changed
    
    changed, Module.data.herculean_draw         = imgui.checkbox(Language.get(languagePrefix .. "herculean_draw"), Module.data.herculean_draw)
    Utils.tooltip(Language.get(languagePrefix .. "herculean_draw_tooltip"))
    any_changed = changed or any_changed
    
    changed, Module.data.bolt_boost             = imgui.checkbox(Language.get(languagePrefix .. "bolt_boost"), Module.data.bolt_boost)
    any_changed = changed or any_changed

    return any_changed
end

return Module
