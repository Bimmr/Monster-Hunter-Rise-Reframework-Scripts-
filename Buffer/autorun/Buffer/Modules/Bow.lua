local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local character

local Module = ModuleBase:new("bow", {
    charge_level = -1,
    herculean_draw = false,
    bolt_boost = false
})

function Module:init()
    character = require("Buffer.Modules.Character")
    ModuleBase.init(self)
end

function Module.create_hooks()
    
    Module:init_stagger("bow_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.Bow"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "snow.player.Bow") then return end

        if not Module:should_execute_staggered("bow_update") then return end

        -- Charge level
        if Module.data.charge_level > 0 then 
            managed:set_field("<ChargeLv>k__BackingField", Module.data.charge_level) 
        end
        
        -- Herculean draw
        if Module.data.herculean_draw then 
            managed:set_field("_WireBuffAttackUpTimer", 1800) 
        end
        
        -- Bolt boost
        if Module.data.bolt_boost then 
            managed:set_field("_WireBuffArrowUpTimer", 1800) 
        end
    end, Utils.nothing())
end

function Module.add_ui()
    local changed, any_changed, misc_changed = false, false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.charge_level = imgui.slider_int(Language.get(languagePrefix .. "charge_level"), Module.data.charge_level, -1, 3,
                                                      Module.data.charge_level > -1 and Language.get(languagePrefix .. "charge_level_prefix").." " .. (Module.data.charge_level + 1) or Language.get(languagePrefix .. "charge_level_disabled"))
    any_changed = changed or any_changed
    
    changed, character.data.ammo_and_coatings.unlimited_coatings = imgui.checkbox(Language.get(languagePrefix .. "unlimited_arrows"), character.data.ammo_and_coatings.unlimited_coatings)
    misc_changed = changed or misc_changed
    
    changed, Module.data.herculean_draw = imgui.checkbox(Language.get(languagePrefix .. "herculean_draw"), Module.data.herculean_draw)
    Utils.tooltip(Language.get(languagePrefix .. "herculean_draw_tooltip"))
    any_changed = changed or any_changed
    
    changed, Module.data.bolt_boost = imgui.checkbox(Language.get(languagePrefix .. "bolt_boost"), Module.data.bolt_boost)
    any_changed = changed or any_changed

    if misc_changed then character:save_config() end

    return any_changed
end

return Module
