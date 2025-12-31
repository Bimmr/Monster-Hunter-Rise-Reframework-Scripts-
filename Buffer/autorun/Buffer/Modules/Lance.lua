local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("lance", {
    anchor_rage = -1
})

function Module.create_hooks()
    
    Module:init_stagger("lance_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.Lance"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "snow.player.Lance") then return end

        if not Module:should_execute_staggered("lance_update") then return end

        -- Anchor rage
        if Module.data.anchor_rage > -1 then
            managed:set_field("_GuardRageTimer", 3000)
            managed:set_field("_GuardRageBuffType", Module.data.anchor_rage)
        end
    end, Utils.nothing())
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.anchor_rage = imgui.slider_int(Language.get(languagePrefix .. "anchor_rage"), Module.data.anchor_rage, -1, 3, Module.data.anchor_rage > -1 and
                                                         Language.get(languagePrefix .. "anchor_rage_prefix") .. " %d" or Language.get(languagePrefix .. "anchor_rage_disabled"))
    any_changed = changed or any_changed

    return any_changed
end

return Module
