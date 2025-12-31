local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local character

local Module = ModuleBase:new("heavy_bowgun", {
    charge_level = -1,
    wyvern_sniper = false,
    wyvern_machine_gun = false,
    overheat = false,
    counter_charger = false
})

function Module:init()
    character = require("Buffer.Modules.Character")
    ModuleBase.init(self)
end

function Module.create_hooks()
    
    Module:init_stagger("heavy_bowgun_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.HeavyBowgun"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "snow.player.HeavyBowgun") then return end

        if not Module:should_execute_staggered("heavy_bowgun_update") then return end

        -- Charge level
        if Module.data.charge_level > -1 then
            managed:set_field("_ShotChargeLv", Module.data.charge_level)
            managed:set_field("_ShotChargeFrame", 30 * Module.data.charge_level)
        end
        
        -- Counter charger
        if Module.data.counter_charger then
            managed:set_field("_ReduseChargeTimer", 3000)
        end
        
        -- Auto reload
        if character.data.ammo_and_coatings.auto_reload then 
            managed:call("resetBulletNum") 
        end
    end, Utils.nothing())

    Module:init_stagger("heavy_bowgun_player_manager_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_type_definition():is_a("snow.player.PlayerManager") then return end
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
    end, Utils.nothing())
end

function Module.add_ui()
    local changed, any_changed, misc_changed = false, false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.charge_level = imgui.slider_int(Language.get(languagePrefix .. "charge_level"), Module.data.charge_level, -1, 3, Module.data.charge_level > -1 and
                                                          Language.get(languagePrefix .. "charge_level_prefix") .. " %d" or Language.get(languagePrefix .. "charge_level_disabled"))
    any_changed = changed or any_changed
    
    changed, character.data.ammo_and_coatings.unlimited_ammo = imgui.checkbox(Language.get(languagePrefix .. "unlimited_ammo"), character.data.ammo_and_coatings.unlimited_ammo)
    misc_changed = changed or misc_changed
    
    changed, character.data.ammo_and_coatings.auto_reload = imgui.checkbox(Language.get(languagePrefix .. "auto_reload"), character.data.ammo_and_coatings.auto_reload)
    misc_changed = changed or misc_changed
    
    changed, Module.data.wyvern_sniper = imgui.checkbox(Language.get(languagePrefix .. "wyvern_sniper"), Module.data.wyvern_sniper)
    any_changed = changed or any_changed
    
    changed, Module.data.wyvern_machine_gun = imgui.checkbox(Language.get(languagePrefix .. "wyvern_machine_gun"), Module.data.wyvern_machine_gun)
    any_changed = changed or any_changed
    
    changed, Module.data.overheat = imgui.checkbox(Language.get(languagePrefix .. "overheat"), Module.data.overheat)
    any_changed = changed or any_changed
    
    changed, Module.data.counter_charger = imgui.checkbox(Language.get(languagePrefix .. "counter_charger"), Module.data.counter_charger)
    any_changed = changed or any_changed
    
    changed, character.data.ammo_and_coatings.no_deviation = imgui.checkbox(Language.get(languagePrefix .. "no_deviation"), character.data.ammo_and_coatings.no_deviation)
    misc_changed = changed or misc_changed
    
    changed, character.data.ammo_and_coatings.no_recoil = imgui.checkbox(Language.get(languagePrefix .. "no_recoil"), character.data.ammo_and_coatings.no_recoil)
    misc_changed = changed or misc_changed

    if misc_changed then character:save_config() end

    return any_changed
end

return Module
