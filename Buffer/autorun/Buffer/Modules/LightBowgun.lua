local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")
local character = require("Buffer.Modules.Character")


local Module = ModuleBase:new("light_bowgun", {
    wyvern_blast = false,
    fanning_maneuver = false
})

function Module.create_hooks()
    
    Module:init_stagger("light_bowgun_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.LightBowgun"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if managed:get_type_definition():is_a("snow.player.LightBowgun") == false then return end

        if not Module:should_execute_staggered("light_bowgun_update") then return end

        -- Auto reload
        if Module.data.auto_reload then 
            managed:call("resetBulletNum") 
        end
        
        -- Fanning maneuver
        if Module.data.fanning_maneuver then 
            managed:set_field("LightBowgunWireBuffTimer", 1200) 
        end
    end)

    Module:init_stagger("light_bowgun_player_manager_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_type_definition():is_a("snow.player.PlayerManager") then return end
        local masterData = Utils.getMasterPlayer()
        if not masterData then return end
        if not masterData:get_type_definition():is_a("snow.player.LightBowgun") then return end
        local playerData = Utils.getPlayerData()
        if not playerData then return end

        if not Module:should_execute_staggered("light_bowgun_player_manager_update") then return end

        -- Wyvern blast
        if Module.data.wyvern_blast then
            playerData:set_field("_WyvernBlastGauge", 3)
            playerData:set_field("_WyvernBlastReloadTimer", 0)
        end
    end)

    -- Unlimited ammo
    sdk.hook(sdk.find_type_definition("snow.data.bulletSlider.BulletSliderFunc"):get_method("consumeItem"), function(args)
        local masterData = Utils.getMasterPlayer()
        if not masterData then return end
        if not masterData:get_type_definition():is_a("snow.player.LightBowgun") then return end

        if Module.data.unlimited_ammo then return sdk.PreHookResult.SKIP_ORIGINAL end
    end)

    -- No fluctuation
    sdk.hook(sdk.find_type_definition("snow.data.BulletWeaponData"):get_method("get_Fluctuation"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.data.LightBowgunWeaponData") then return end

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
        if not managed:get_type_definition():is_a("snow.data.LightBowgunWeaponData") then return end
        
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

    changed, Module.data.unlimited_ammo         = imgui.checkbox(Language.get(languagePrefix .. "unlimited_ammo"), Module.data.unlimited_ammo)
    any_changed = changed or any_changed
    
    changed, Module.data.auto_reload            = imgui.checkbox(Language.get(languagePrefix .. "auto_reload"), Module.data.auto_reload)
    any_changed = changed or any_changed
    
    changed, Module.data.wyvern_blast           = imgui.checkbox(Language.get(languagePrefix .. "wyvern_blast"), Module.data.wyvern_blast)
    any_changed = changed or any_changed
    
    changed, Module.data.fanning_maneuver       = imgui.checkbox(Language.get(languagePrefix .. "fanning_maneuver"), Module.data.fanning_maneuver)
    any_changed = changed or any_changed
    
    changed, Module.data.no_deviation           = imgui.checkbox(Language.get(languagePrefix .. "no_deviation"), Module.data.no_deviation)
    any_changed = changed or any_changed
    
    changed, Module.data.no_recoil              = imgui.checkbox(Language.get(languagePrefix .. "no_recoil"), Module.data.no_recoil)
    any_changed = changed or any_changed

    return any_changed
end

return Module
