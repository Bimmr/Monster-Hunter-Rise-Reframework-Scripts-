local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("heavy_bowgun", {
    charge_level = -1,
    wyvern_sniper = false,
    wyvern_machine_gun = false,
    overheat = false,
    counter_charger = false,
    unlimited_ammo = false,
    auto_reload = false,
    no_deviation = false,
    no_recoil = false
})


function Module.create_hooks()
    
    Module:init_stagger("heavy_bowgun_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.HeavyBowgun"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if managed:get_type_definition():is_a("snow.player.HeavyBowgun") == false then return end

        -- Charge level
        if Module.data.charge_level > -1 then
            managed:set_field("_ShotChargeLv", Module.data.charge_level)
            managed:set_field("_ShotChargeFrame", 30 * Module.data.charge_level)
        end
        
        if not Module:should_execute_staggered("heavy_bowgun_update") then return end

        -- Counter charger
        if Module.data.counter_charger then
            managed:set_field("_ReduseChargeTimer", 3000)
        end
        
        -- Auto reload
        if Module.data.auto_reload then 
            managed:call("resetBulletNum") 
        end
    end)

    Module:init_stagger("heavy_bowgun_player_manager_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.player.PlayerManager") then return end
        local masterData = Utils.getMasterPlayer()
        if not masterData then return end
        if not masterData:get_type_definition():is_a("snow.player.HeavyBowgun") then return end
        local playerData = Utils.getPlayerData()
        if not playerData then return end

        if not Module:should_execute_staggered("heavy_bowgun_player_manager_update") then return end

        -- Wyvern sniper
        if Module.data.wyvern_sniper then
            playerData:set_field("_HeavyBowgunWyvernSnipeBullet", 1)
            playerData:set_field("_HeavyBowgunWyvernSnipeTimer", 0)
        end
        
        -- Wyvern machine gun
        if Module.data.wyvern_machine_gun then
            playerData:set_field("_HeavyBowgunWyvernMachineGunBullet", 50)
            playerData:set_field("_HeavyBowgunWyvernMachineGunTimer", 0)
        end
        
        -- Overheat
        if Module.data.overheat then 
            playerData:set_field("_HeavyBowgunHeatGauge", 0) 
        end
    end)

    
    -- Unlimited ammo
    sdk.hook(sdk.find_type_definition("snow.data.bulletSlider.BulletSliderFunc"):get_method("consumeItem"), function(args)
        local masterData = Utils.getMasterPlayer()
        if not masterData:get_type_definition():is_a("snow.player.HeavyBowgun") then return end

        if Module.data.unlimited_ammo then return sdk.PreHookResult.SKIP_ORIGINAL end
    end)

    -- No fluctuation
    sdk.hook(sdk.find_type_definition("snow.data.BulletWeaponData"):get_method("get_Fluctuation"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.data.HeavyBowgunWeaponData") then return end

        if Module.data.no_deviation then thread.get_hook_storage()["prevent_fluctuation"] = true end
    end, 
    function(retval)
        if thread.get_hook_storage()["prevent_fluctuation"] then
            return 0
        end
        return retval
    end)

    -- No recoil
    sdk.hook(sdk.find_type_definition("snow.data.BulletWeaponData"):get_method("getRecoil"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.data.HeavyBowgunWeaponData") then return end
        
        if Module.data.no_recoil then thread.get_hook_storage()["prevent_recoil"] = true end
    end, 
    function(retval)
        if thread.get_hook_storage()["prevent_recoil"] then
            return sdk.to_ptr(6)
        end
        return retval
    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.charge_level = imgui.slider_int(Language.get(languagePrefix .. "charge_level"), Module.data.charge_level, -1, 2, Module.data.charge_level == -1 and Language.get("base.disabled") or tostring(Module.data.charge_level + 1))
    any_changed = changed or any_changed
    
    changed, Module.data.unlimited_ammo     = imgui.checkbox(Language.get(languagePrefix .. "unlimited_ammo"), Module.data.unlimited_ammo)
    any_changed = changed or any_changed
    
    changed, Module.data.auto_reload        = imgui.checkbox(Language.get(languagePrefix .. "auto_reload"), Module.data.auto_reload)
    any_changed = changed or any_changed
    
    changed, Module.data.wyvern_sniper      = imgui.checkbox(Language.get(languagePrefix .. "wyvern_sniper"), Module.data.wyvern_sniper)
    any_changed = changed or any_changed
    
    changed, Module.data.wyvern_machine_gun = imgui.checkbox(Language.get(languagePrefix .. "wyvern_machine_gun"), Module.data.wyvern_machine_gun)
    any_changed = changed or any_changed
    
    changed, Module.data.overheat           = imgui.checkbox(Language.get(languagePrefix .. "overheat"), Module.data.overheat)
    any_changed = changed or any_changed
    
    changed, Module.data.counter_charger    = imgui.checkbox(Language.get(languagePrefix .. "counter_charger"), Module.data.counter_charger)
    any_changed = changed or any_changed
    
    changed, Module.data.no_deviation       = imgui.checkbox(Language.get(languagePrefix .. "no_deviation"), Module.data.no_deviation)
    any_changed = changed or any_changed
    
    changed, Module.data.no_recoil          = imgui.checkbox(Language.get(languagePrefix .. "no_recoil"), Module.data.no_recoil)
    any_changed = changed or any_changed

    return any_changed
end

return Module
