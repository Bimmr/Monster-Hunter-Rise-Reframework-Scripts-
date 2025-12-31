local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local character

local Module = ModuleBase:new("light_bowgun", {
    wyvern_blast = false,
    fanning_maneuver = false
})

function Module:init()
    character = require("Buffer.Modules.Character")
    ModuleBase.init(self)
end

function Module.create_hooks()
    
    Module:init_stagger("light_bowgun_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.LightBowgun"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "snow.player.LightBowgun") then return end

        if not Module:should_execute_staggered("light_bowgun_update") then return end

        -- Auto reload
        if character.data.ammo_and_coatings.auto_reload then 
            managed:call("resetBulletNum") 
        end
        
        -- Fanning maneuver
        if Module.data.fanning_maneuver then 
            managed:set_field("LightBowgunWireBuffTimer", 1200) 
        end
    end, Utils.nothing())

    Module:init_stagger("light_bowgun_player_manager_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_type_definition():is_a("snow.player.PlayerManager") then return end
        local playerData = Utils.getPlayerData()
        if not playerData then return end

        if not Module:should_execute_staggered("light_bowgun_player_manager_update") then return end

        -- Wyvern blast
        if Module.data.wyvern_blast then
            playerData:set_field("_WyvernBlastGauge", 3)
            playerData:set_field("_WyvernBlastReloadTimer", 0)
        end
    end, Utils.nothing())
end

function Module.add_ui()
    local changed, any_changed, misc_changed = false, false, false
    local languagePrefix = Module.title .. "."

    changed, character.data.ammo_and_coatings.unlimited_ammo = imgui.checkbox(Language.get(languagePrefix .. "unlimited_ammo"), character.data.ammo_and_coatings.unlimited_ammo)
    misc_changed = changed or misc_changed
    
    changed, character.data.ammo_and_coatings.auto_reload = imgui.checkbox(Language.get(languagePrefix .. "auto_reload"), character.data.ammo_and_coatings.auto_reload)
    misc_changed = changed or misc_changed
    
    changed, Module.data.wyvern_blast = imgui.checkbox(Language.get(languagePrefix .. "wyvern_blast"), Module.data.wyvern_blast)
    any_changed = changed or any_changed
    
    changed, Module.data.fanning_maneuver = imgui.checkbox(Language.get(languagePrefix .. "fanning_maneuver"), Module.data.fanning_maneuver)
    any_changed = changed or any_changed
    
    changed, character.data.ammo_and_coatings.no_deviation = imgui.checkbox(Language.get(languagePrefix .. "no_deviation"), character.data.ammo_and_coatings.no_deviation)
    misc_changed = changed or misc_changed
    
    changed, character.data.ammo_and_coatings.no_recoil = imgui.checkbox(Language.get(languagePrefix .. "no_recoil"), character.data.ammo_and_coatings.no_recoil)
    misc_changed = changed or misc_changed

    if misc_changed then character:save_config() end

    return any_changed
end

return Module
