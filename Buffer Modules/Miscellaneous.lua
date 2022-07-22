local utils = require("Buffer Modules.Utils")
local lightBowgun, heavyBowgun, bow
local miscellaneous = {}

function miscellaneous.init()
    lightBowgun = require("Buffer Modules.LightBowgun")
    heavyBowgun = require("Buffer Modules.HeavyBowgun")
    bow = require("Buffer Modules.Bow")

    -- Update items that have multiple triggers
    miscellaneous[3][1].onChange()
    miscellaneous[3][2].onChange()
    miscellaneous[3][3].onChange()
    miscellaneous[3][4].onChange()
end

-- Miscellaneous Modifications
miscellaneous = {
    title = "Miscellaneous",

    [1] = {
        title = "Unlimited Consumables",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.data.ItemSlider",
            func = "notifyConsumeItem",
            pre = function(args)
                if miscellaneous[1].value then return sdk.PreHookResult.SKIP_ORIGINAL end
            end,
            post = utils.nothing()
        }
    },
    [2] = {
        title = "Sharpness",
        type = "slider",
        min = -1,
        max = 6,
        value = -1,
        display = {"Red", "Orange", "Yellow", "Green", "Blue", "White", "Purple"},
        data = {
            sharpness = -1
        },
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = utils.nothing(),
            post = function(args)
                if miscellaneous[2].value >= 0 then
                    local playerBase = utils.getPlayerBase()
                    if not playerBase then return end
                    -- 0=Red | 1=Orange | 2=Yellow | 3=Green | 4=Blue | 5=White | 6=Purple
                    if miscellaneous[2].data.sharpness == -1 then
                        miscellaneous[2].data.sharpness = playerBase:get_field("<SharpnessLv>k__BackingField")
                    end
                    playerBase:set_field("<SharpnessLv>k__BackingField", miscellaneous[2].value) -- Sharpness Level of Purple
                    -- playerBase:set_field("<SharpnessGauge>k__BackingField", 400) -- Sharpness Value
                    -- playerBase:set_field("<SharpnessGaugeMax>k__BackingField", 400) -- Max Sharpness
                else
                    if miscellaneous[2].data.sharpness >= 0 then
                        local playerBase = utils.getPlayerBase()
                        if not playerBase then return end
                        playerBase:set_field("<SharpnessLv>k__BackingField", miscellaneous[2].data.sharpness)
                        miscellaneous[2].data.sharpness = -1
                    end
                end
            end
        }
    },
    [3] = {
        title = "Ammo & Coating Options",
        [1] = {
            title = "Unlimited Coatings (Arrows)",
            type = "checkbox",
            value = false,
            hook = {
                path = "snow.data.bulletSlider.BottleSliderFunc",
                func = "consumeItem",
                pre = function(args)
                    if miscellaneous[3][1].value then return sdk.PreHookResult.SKIP_ORIGINAL end
                end,
                post = utils.nothing()
            },
            onChange = function()
                bow[2].value = miscellaneous[3][1].value -- Bow
            end
        },
        [2] = {
            title = "Unlimited Ammo (Bowguns)",
            type = "checkbox",
            value = false,
            hook = {
                path = "snow.data.bulletSlider.BulletSliderFunc",
                func = "consumeItem",
                pre = function(args)
                    if miscellaneous[3][2].value then return sdk.PreHookResult.SKIP_ORIGINAL end
                end,
                post = utils.nothing()
            },
            onChange = function()
                local value = miscellaneous[3][2].value
                lightBowgun[1].value = value -- Light Bowgun
                heavyBowgun[2].value = value -- Heavy Bowgun
            end
        },
        [3] = {
            title = "Auto Reload (Bowguns)",
            type = "checkbox",
            value = false,

            -- No hook as this is called per weapon
            onChange = function()
                local value = miscellaneous[3][3].value
                lightBowgun[2].value = value -- Light bow gun
                heavyBowgun[3].value = value -- Heavy bow gun
            end
        },
        [4] = {
            title = "No Deviation (Bowguns)",
            type = "checkbox",
            value = false,
            data = {
                isDeviation = false
            },
            hook = {
                path = "snow.equip.BulletWeaponBaseUserData.Param",
                func = "get_Fluctuation",
                pre = function(args)
                    local managed = sdk.to_managed_object(args[2])
                    if not managed then return end
                    if not managed:get_type_definition():is_a("snow.equip.BulletWeaponBaseUserData.Param") then
                        return
                    end
                    if miscellaneous[3][4].value then
                        miscellaneous[3][4].data.isDeviation = true
                        return sdk.PreHookResult.SKIP_ORIGINAL
                    end
                end,
                post = function(retval)
                    if miscellaneous[3][4].data.isDeviation then
                        miscellaneous[3][4].data.isDeviation = false
                        if miscellaneous[3][4].value then return 0 end
                    end
                    return retval
                end
            },
            onChange = function()
                local value = miscellaneous[3][4].value
                lightBowgun[4].value = value -- Light Bowgun
                heavyBowgun[7].value = value -- Heavy Bowgun
            end
        }
    },
    [4] = {
        title = "Wirebugs",
        [1] = {
            title = "Unlimited Wirebugs Out of Combat",
            type = "checkbox",
            value = false,
            hook = {
                path = "snow.player.fsm.PlayerFsm2ActionHunterWire",
                func = "start",
                pre = utils.nothing(),
                post = function(retval)
                    if (miscellaneous[4][1].value and not utils.checkIfInBattle()) or miscellaneous[4][2].value then
                        local playerBase = utils.getPlayerBase()
                        if not playerBase then return end
                        local wireGuages = playerBase:get_field("_HunterWireGauge")
                        if not wireGuages then return end
                        wireGuages = wireGuages:get_elements()
                        for i, gauge in ipairs(wireGuages) do
                            gauge:set_field("_RecastTimer", 0)
                            gauge:set_field("_RecoverWaitTimer", 0)
                        end
                    end
                    return retval
                end
            }
        },
        [2] = {
            title = "Unlimited Wirebugs Everywhere",
            type = "checkbox",
            value = false
            -- Hook moved to Unlimited Wirebugs Out of Combat so we aren't double hooking
        },
        [3] = {
            title = "3 Wirebugs",
            type = "checkbox",
            value = false,
            hook = {
                path = "snow.player.PlayerManager",
                func = "update",
                pre = function(args)
                    if miscellaneous[4][3].value then
                        local playerBase = utils.getPlayerBase()
                        if not playerBase then return end
                        playerBase:set_field("<HunterWireWildNum>k__BackingField", 1)
                        playerBase:set_field("_HunterWireNumAddTime", 7000)
                    end
                end,
                post = utils.nothing()
            }
        },
        [4] = {
            title = "Permanent Wirebug Powerup",
            type = "checkbox",
            value = false,
            hook = {
                path = "snow.player.PlayerManager",
                func = "update",
                pre = function(args)
                    if miscellaneous[4][4].value then
                        local playerData = utils.getPlayerData()
                        if not playerData then return end
                        playerData:set_field("_WireBugPowerUpTimer", 10700)
                    end
                end,
                post = utils.nothing()
            }
        }
    },
    [5] = {
        title = "Canteen",
        data = {
            managed = nil,
            chance = 0
        },
        [1] = {
            title = "100% Dango Skills With Ticket",
            type = "checkbox",
            value = false,
            hook = {
                path = "snow.data.DangoData",
                func = "get_SkillActiveRate",
                pre = function(args)
                    if miscellaneous[5][1].value or miscellaneous[5][2].value then
                        local managed = sdk.to_managed_object(args[2])
                        if not managed then return end
                        if not managed:get_type_definition():is_a("snow.data.DangoData") then
                            return
                        end

                        local isUsingTicket = utils.getMealFunc():call("getMealTicketFlag")

                        if isUsingTicket or miscellaneous[5][2].value then
                            miscellaneous[5].data.managed = managed
                            miscellaneous[5].data.chance = managed:get_field("_Param"):get_field("_SkillActiveRate")
                            managed:get_field("_Param"):set_field("_SkillActiveRate", 200)
                        end
                    end
                end,
                post = function(retval)
                    -- Restore the original value
                    if (miscellaneous[5][1].value or miscellaneous[5][2].value) and miscellaneous[5].data.managed then
                        miscellaneous[5].data.managed:get_field("_Param"):set_field("_SkillActiveRate",
                                                                                    miscellaneous[5].data.chance)
                        miscellaneous[5].data.managed = nil
                    end
                    return retval
                end
            }
        },
        [2] = {
            title = "100% Dango Skills Without Ticket",
            type = "checkbox",
            value = false
            -- Hook moved to 100% Dango Skills With Ticket so we aren't double hooking
        }
    }
}
return miscellaneous
