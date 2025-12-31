local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("gun_lance", {
    dragon_cannon = false,
    aerials = false,
    auto_reload = false,
    ground_splitter = false,
    errupting_cannon = false
})

function Module.create_hooks()
    
    Module:init_stagger("gun_lance_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.GunLance"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "snow.player.GunLance") then return end

        if not Module:should_execute_staggered("gun_lance_update") then return end

        -- Aerials
        if Module.data.aerials then 
            managed:set_field("_AerialCount", 0) 
        end
        
        -- Auto reload
        if Module.data.auto_reload then 
            managed:call("reloadBullet") 
        end
        
        -- Ground splitter
        if Module.data.ground_splitter then 
            managed:set_field("_ShotDamageUpDurationTimer", 1800) 
        end
        
        -- Errupting cannon
        if Module.data.errupting_cannon then
            managed:set_field("_ExplodePileBuffTimer", 1800)
            managed:set_field("_ExplodePileAttackRate", 1.3)
            managed:set_field("_ExplodePileElemRate", 1.3)
        end
    end, Utils.nothing())

    Module:init_stagger("gun_lance_player_manager_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        local playerData = Utils.getPlayerData()
        if not playerData then return end

        if not Module:should_execute_staggered("gun_lance_player_manager_update") then return end

        -- Dragon cannon
        if Module.data.dragon_cannon then 
            playerData:set_field("_ChargeDragonSlayCannonTime", 0) 
        end
    end, Utils.nothing())
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.dragon_cannon = imgui.checkbox(Language.get(languagePrefix .. "dragon_cannon"), Module.data.dragon_cannon)
    any_changed = changed or any_changed
    
    changed, Module.data.aerials = imgui.checkbox(Language.get(languagePrefix .. "aerials"), Module.data.aerials)
    any_changed = changed or any_changed
    
    changed, Module.data.auto_reload = imgui.checkbox(Language.get(languagePrefix .. "auto_reload"), Module.data.auto_reload)
    any_changed = changed or any_changed
    
    changed, Module.data.ground_splitter = imgui.checkbox(Language.get(languagePrefix .. "ground_splitter"), Module.data.ground_splitter)
    any_changed = changed or any_changed
    
    changed, Module.data.errupting_cannon = imgui.checkbox(Language.get(languagePrefix .. "errupting_cannon"), Module.data.errupting_cannon)
    any_changed = changed or any_changed

    return any_changed
end

return Module
