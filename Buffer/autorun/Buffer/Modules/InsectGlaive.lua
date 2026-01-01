local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("insect_glaive", {
    red_extract = false,
    white_extract = false,
    orange_extract = false,
    aerials = false,
    kinsect_stamina = false
})

function Module.create_hooks()
    
    Module:init_stagger("insect_glaive_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.InsectGlaive"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if managed:get_type_definition():is_a("snow.player.InsectGlaive") == false then return end

        if not Module:should_execute_staggered("insect_glaive_update") then return end

        -- Red extract
        if Module.data.red_extract then 
            managed:set_field("_RedExtractiveTime", 8000) 
        end
        
        -- White extract
        if Module.data.white_extract then 
            managed:set_field("_WhiteExtractiveTime", 8000) 
        end
        
        -- Orange extract
        if Module.data.orange_extract then 
            managed:set_field("_OrangeExtractiveTime", 8000) 
        end
        
        -- Aerials
        if Module.data.aerials then 
            managed:set_field("_AerialCount", 2) 
        end
    end)

    Module:init_stagger("ig_insect_update", 10)
    sdk.hook(sdk.find_type_definition("snow.player.IG_Insect"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_type_definition():is_a("snow.player.IG_Insect") then return end

        if not Module:should_execute_staggered("ig_insect_update") then return end

        if Module.data.kinsect_stamina then 
            managed:set_field("<_Stamina>k__BackingField", managed:get_field("StaminaMax")) 
        end
    end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    local EXTRACT_KEYS = {"red_extract", "white_extract", "orange_extract"}
    local max_width = 0
    local row_width = imgui.calc_item_width()
    for _, key in ipairs(EXTRACT_KEYS) do
        local text = Language.get(languagePrefix .. key)
        max_width = math.max(max_width, imgui.calc_text_size(text).x)
    end
    local col_width = math.max(max_width + 24 + 20, row_width / 3)

    imgui.begin_table(Module.title.."1", 3, 0)
    imgui.table_setup_column("1", 16 + 4096, col_width)
    imgui.table_setup_column("2", 16 + 4096, col_width)
    imgui.table_setup_column("3", 16 + 4096, col_width)
    imgui.table_next_row()

    for _, key in ipairs(EXTRACT_KEYS) do
        imgui.table_next_column()
        changed, Module.data[key] = imgui.checkbox(Language.get(languagePrefix .. key), Module.data[key])
        any_changed = any_changed or changed
    end

    imgui.end_table()
    
    changed, Module.data.aerials = imgui.checkbox(Language.get(languagePrefix .. "aerials"), Module.data.aerials)
    any_changed = changed or any_changed
    
    changed, Module.data.kinsect_stamina = imgui.checkbox(Language.get(languagePrefix .. "kinsect_stamina"), Module.data.kinsect_stamina)
    any_changed = changed or any_changed

    return any_changed
end

return Module
