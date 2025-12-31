local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("hammer", {
    charge_level = -1,
    impact_burst = false
})

function Module.create_hooks()
    
    Module:init_stagger("hammer_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.Hammer"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "snow.player.Hammer") then return end

        if not Module:should_execute_staggered("hammer_update") then return end

        -- Charge level
        if Module.data.charge_level > -1 then 
            managed:set_field("<NowChargeLevel>k__BackingField", Module.data.charge_level) 
        end
        
        -- Impact burst
        if Module.data.impact_burst then
            managed:set_field("_ImpactPullsTimer", 3600)
            managed:set_field("_IsEnableImapctPulls", true) -- They mispelt this field
            managed:set_field("_IsEnableImpactPulls", true) -- Adding this just incase they fix it in a later version
        end
    end, Utils.nothing())
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.charge_level = imgui.slider_int(Language.get(languagePrefix .. "charge_level"), Module.data.charge_level, -1, 2, Module.data.charge_level > -1 and
                                                          Language.get(languagePrefix .. "charge_level_prefix") .. " " .. (Module.data.charge_level + 1) or
                                                          Language.get(languagePrefix .. "charge_level_disabled"))
    any_changed = changed or any_changed
    
    changed, Module.data.impact_burst = imgui.checkbox(Language.get(languagePrefix .. "impact_burst"), Module.data.impact_burst)
    any_changed = changed or any_changed

    return any_changed
end

return Module
