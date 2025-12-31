local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("great_sword", {
    charge_level = -1,
    power_sheathe = false
})

function Module.create_hooks()
    
    Module:init_stagger("great_sword_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.GreatSword"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "snow.player.GreatSword") then return end

        if not Module:should_execute_staggered("great_sword_update") then return end

        -- Charge level
        if Module.data.charge_level > -1 then 
            managed:set_field("_TameLv", Module.data.charge_level) 
        end
        
        -- Power sheathe
        if Module.data.power_sheathe then 
            managed:set_field("MoveWpOffBuffGreatSwordTimer", 1200) 
        end
    end, Utils.nothing())
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.charge_level = imgui.slider_int(Language.get(languagePrefix .. "charge_level"), Module.data.charge_level, -1, 3, Module.data.charge_level > -1 and
                                                          Language.get(languagePrefix .. "charge_level_prefix") .. " %d" or Language.get(languagePrefix .. "charge_level_disabled"))
    any_changed = changed or any_changed
    
    changed, Module.data.power_sheathe = imgui.checkbox(Language.get(languagePrefix .. "power_sheathe"), Module.data.power_sheathe)
    Utils.tooltip(Language.get(languagePrefix .. "power_sheathe_tooltip"))
    any_changed = changed or any_changed

    return any_changed
end

return Module
