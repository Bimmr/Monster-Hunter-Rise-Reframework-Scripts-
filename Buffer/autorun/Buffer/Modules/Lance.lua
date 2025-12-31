local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("lance", {
    anchor_rage = -1
})

function Module.create_hooks()
    
    Module:init_stagger("lance_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.Lance"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if managed:get_type_definition():is_a("snow.player.Lance") == false then return end

        if not Module:should_execute_staggered("lance_update") then return end

        -- Anchor rage
        if Module.data.anchor_rage > -1 then
            managed:set_field("_GuardRageTimer", 3000)
            managed:set_field("_GuardRageBuffType", Module.data.anchor_rage)
        end
    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.anchor_rage        = imgui.slider_int(Language.get(languagePrefix .. "anchor_rage"), Module.data.anchor_rage, -1, 3, Module.data.anchor_rage == -1 and Language.get("base.disabled") or tostring(Module.data.anchor_rage + 1))
    any_changed = changed or any_changed

    return any_changed
end

return Module
