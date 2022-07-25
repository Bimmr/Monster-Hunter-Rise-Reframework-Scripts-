local utils, config
local data = {
    title = "Gun Lance",
    dragon_cannon = false,
    aerials = false,
    auto_reload = false,
    ground_splitter = false,
    errupting_cannon = false
}

function data.init()
    utils = require("Buffer Modules.Utils")
    config = require("Buffer Modules.Config")

    data.init_hooks()
end
function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.GunLance"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])

        if data.aerials then managed:set_field("_AerialCount", 0) end
        if data.auto_reload then managed:call("reloadBullet") end
        if data.ground_splitter then managed:set_field("_ShotDamageUpDurationTimer", 1800) end
        if data.errupting_cannon then
            managed:set_field("_ExplodePileBuffTimer", 1800)
            managed:set_field("_ExplodePileAttackRate", 1.3)
            managed:set_field("_ExplodePileElemRate", 1.3)
        end
    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        local playerData = utils.getPlayerData()
        if not playerData then return end

        if data.dragon_cannon then playerData:set_field("_ChargeDragonSlayCannonTime", 0) end
    end, utils.nothing())
end


function data.draw()
    local changed, any_changed = false, false
    changed, data.dragon_cannon = imgui.checkbox("Unlimited Dragon Cannon", data.dragon_cannon)
    any_changed = changed or any_changed
    changed, data.aerials = imgui.checkbox("Unlimited Aerials", data.aerials)
    any_changed = changed or any_changed
    changed, data.auto_reload = imgui.checkbox("Auto Reload", data.auto_reload)
    any_changed = changed or any_changed
    changed, data.ground_splitter = imgui.checkbox("Ground Splitter", data.ground_splitter)
    any_changed = changed or any_changed
    changed, data.errupting_cannon = imgui.checkbox("Errupting Cannon", data.errupting_cannon)
    any_changed = changed or any_changed

    if any_changed then config.save_section(data.create_config_section()) end
end


function data.create_config_section()
    return {
        [data.title] = {
            dragon_cannon = data.dragon_cannon,
            aerials = data.aerials,
            auto_reload = data.auto_reload,
            ground_splitter = data.ground_splitter,
            errupting_cannon = data.errupting_cannon
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.dragon_cannon = config_section.dragon_cannon or data.dragon_cannon
    data.aerials = config_section.aerials or data.aerials
    data.auto_reload = config_section.auto_reload or data.auto_reload
    data.ground_splitter = config_section.ground_splitter or data.ground_splitter
    data.errupting_cannon = config_section.errupting_cannon or data.errupting_cannon
end


return data
