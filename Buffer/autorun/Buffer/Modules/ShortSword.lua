local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("sword_and_shield", {
    destroyer_oil = false
})

function Module.create_hooks()
    
    Module:init_stagger("sword_and_shield_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.ShortSword"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "snow.player.ShortSword") then return end

        if not Module:should_execute_staggered("sword_and_shield_update") then return end

        -- Destroyer oil
        if Module.data.destroyer_oil then
            managed:set_field("<IsOilBuffSetting>k__BackingField", true)
            managed:set_field("_OilBuffTimer", 3000)
        end
    end, Utils.nothing())
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.destroyer_oil = imgui.checkbox(Language.get(languagePrefix .. "destroyer_oil"), Module.data.destroyer_oil)
    any_changed = changed or any_changed

    return any_changed
end

return Module
