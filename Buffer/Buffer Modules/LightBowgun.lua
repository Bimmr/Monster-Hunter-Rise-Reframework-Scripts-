local utils = require("Buffer Modules.Utils")
local misc 
local lightBowgun = {}

function lightBowgun.init()
    misc = require("Buffer Modules.Misc")
end

-- Light Bowgun Modifications
lightBowgun = {
    title = "Light Bowgun",
    [1] = {
        title = "Unlimited Ammo",
        type = "checkbox",
        value = false,
        dontSave = true,
        onChange = function()
            -- Change and update Miscellaneous/Ammo Options/Unlimited Ammo (Bowguns)
            misc[3][2].value = lightBowgun[1].value
            misc[3][2].onChange()
        end
    },
    [2] = {
        title = "Auto Reload ",
        type = "checkbox",
        value = false,
        dontSave = true,
        hook = {
            path = "snow.player.LightBowgun",
            func = "update",
            pre = function(args)
                if lightBowgun[2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:call("resetBulletNum")
                end
            end,
            post = utils.nothing()
        },
        onChange = function()
            -- Change and update Miscellaneous/Ammo & Coating Options/Auto Reload (Bowguns)
            misc[3][3].value = lightBowgun[2].value
            misc[3][3].onChange()
        end
    },
    [3] = {
        title = "Unlimited Wyvern Blast",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = function(args)
                if lightBowgun[3].value then

                    local playerData = utils.getPlayerData()
                    if not playerData then return end
                    playerData:set_field("_WyvernBlastGauge", 3)
                    playerData:set_field("_WyvernBlastReloadTimer", 0)
                end
            end,
            post = utils.nothing()
        }
    },
    [4] = {
        title = "No Deviation",
        type = "checkbox",
        value = false,
        onChange = function()
            -- Change and update Miscellaneous/Ammo & Coating Options/No Deviation (Bowguns)
            misc[3][4].value = lightBowgun[4].value
            misc[3][4].onChange()
        end
    }
}
return lightBowgun