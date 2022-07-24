local utils = require("Buffer Modules.Utils")
local misc
local bow = {
    title = "Bow",
    charge_level = 0,
    herculean_draw = false,
    bolt_boost = false
}

function bow.init()
    misc = require("Buffer Modules.Miscellaneous")
end

function bow.draw()
    local changed = false
    if imgui.collapsing_header(bow.title) then
        changed, bow.charge_level = imgui.slider_int("Charge Level", bow.charge_level, 0, 4, bow.charge_level < 0 and "Level %d" or "Off")
        changed, misc.unlimited_arrows = imgui.checkbox("Unlimited Arrows", misc.unlimited_arrows)
        changed, bow.herculean_draw = imgui.checkbox("Herculean Draw", bow.herculean_draw)
        changed, bow.bolt_boost = imgui.checkbox("Bolt Boost", bow.bolt_boost)
    end
    if changed then utils.saveConfig() end   
end

function bow.initHooks()
    sdk.hook(sdk.find_type_definition("snow.player.Bow"):get_method("update"), 
    function(args)
        
        local managed = sdk.to_managed_object(args[2])

        if bow.charge_level > 0 then
            managed:set_field("<ChargeLv>k__BackingField", bow[1].value)
        end
        if bow.herculean_draw then
            managed:set_field("_WireBuffAttackUpTimer", 1800)
        end
        if bow.bolt_boost then
            managed:set_field("_WireBuffArrowUpTimer", 1800)
        end
    end,
    utils.nothing()
)
end

return bow