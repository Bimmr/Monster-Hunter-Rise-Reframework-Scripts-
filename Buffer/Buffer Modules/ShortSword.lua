local utils
local shortsword = {
    title = "Sword & Shield",
    destroyer_oil = false
}
function shortsword.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.ShortSword"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if shortsword.destroyer_oil then
            managed:set_field("<IsOilBuffSetting>k__BackingField", true)
            managed:set_field("_OilBuffTimer", 3000)
        end
    end, utils.nothing())
end
function shortsword.init()
    utils = require("Buffer Modules.Utils")

    shortsword.init_hooks()
end
function shortsword.draw()
    local changed = false
    changed, shortsword.destroyer_oil = imgui.checkbox("Destroyer Oil", shortsword.destroyer_oil)
    if changed then utils.saveConfig() end
end

return shortsword
