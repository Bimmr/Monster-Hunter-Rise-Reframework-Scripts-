local configPath = "Buffer.json"
local kitchenFacility, mealFunc
local playerInput
local data = {}

-- Do nothing
local function nothing(retval)
    return retval
end

-- Get Player Base
local function getPlayerBase()
    if not playerInput then
        local inputManager = sdk.get_managed_singleton("snow.StmInputManager")
        local inGameInputDevice = inputManager:get_field("_InGameInputDevice")
        playerInput = inGameInputDevice:get_field("_pl_input")
    end
    return playerInput:get_field("RefPlayer")
end

-- Get Player Data from Player Base
local function getPlayerData()
    local playerBase = getPlayerBase()
    if not playerBase then return end
    return playerBase:call("get_PlayerData")
end

-- Get kitchen Facility
local function getKitchenFacility()
    if not kitchenFacility then
        local facilityDataManager = sdk.get_managed_singleton("snow.data.FacilityDataManager")
        if not facilityDataManager then return end
        kitchenFacility = facilityDataManager:get_field("_Kitchen")
    end
    return kitchenFacility
end

-- Get MealFunct from Kitchen Facility
local function getMealFunc()
    if not mealFunc then
        local kitchenFacility = getKitchenFacility()
        if not kitchenFacility then return end
        mealFunc = kitchenFacility:get_field("_MealFunc")
    end
    return mealFunc
end

-- Load the config
local function setConfig(key, value, table)
    table = table or data

    local dotIndex = string.find(key, '.', 1, true)
    if dotIndex then
        -- log.debug(". found in "..key)
        local left = string.sub(key, 1, dotIndex - 1)
        local notLeft = string.sub(key, dotIndex + 1)

        for k, v in pairs(table) do
            if type(v) == "table" and v.title == left then
                -- log.debug("Going deeper")
                setConfig(notLeft, value, v)
            end
        end
    else
        -- log.debug("Checking for "..key)
        for k, v in pairs(table) do if v.title == key then table[k].value = value end end
    end

end
local function loadConfig()
    if json ~= nil then
        local settings = json.load_file(configPath)
        if settings then
            for settingsKey, settingsValue in pairs(settings) do setConfig(settingsKey, settingsValue) end
        end
    end
end

-- Save the config
local saveData = {}
local function generateSaveData(table, keyPrefix)
    keyPrefix = keyPrefix or ""
    for key, value in pairs(table) do
        if type(value) == "table" then
            if value.title and value.value ~= nil and not value.dontSave then
                saveData[string.sub(keyPrefix .. "." .. value.title, 2)] = value.value
            elseif value.title then
                generateSaveData(value, keyPrefix .. "." .. value.title)
            else
                generateSaveData(value, keyPrefix)
            end
        end
    end
end

local function saveConfig()
    if json ~= nil then
        generateSaveData(data)
        json.dump_file(configPath, saveData)
        saveData = {}
    end
end

-- Check if player is in battle, base code by raffRun
local musicManager, questManager
local function checkIfInBattle()

    if not musicManager then musicManager = sdk.get_managed_singleton("snow.wwise.WwiseMusicManager") end
    if not questManager then questManager = sdk.get_managed_singleton("snow.QuestManager") end

    local currentMusicType = musicManager:get_field("_FightBGMType")
    local currentBattleState = musicManager:get_field("_CurrentEnemyAction")

    local currentQuestType = questManager:get_field("_QuestType")
    local currentQuestStatus = questManager:get_field("_QuestStatus")

    local inBattle = currentBattleState == 3 -- Fighting a monster
    or currentMusicType == 25 -- Fighting a wave of monsters
    or currentQuestType == 8 -- Fighting in the arena (Village/Hub quests)
    or currentQuestType == 64 -- Fighting in the arena (Utsushi)

    local isQuestComplete = currentQuestStatus == 3 -- Completed the quest

    return inBattle and not isQuestComplete
end

-- Miscellaneous Modifications
data[1] = {
    title = "Miscellaneous",

    [1] = {
        title = "Unlimited Consumables",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.data.ItemSlider",
            func = "notifyConsumeItem",
            pre = function(args)
                if data[1][1].value then return sdk.PreHookResult.SKIP_ORIGINAL end
            end,
            post = nothing()
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
            pre = nothing(),
            post = function(args)
                if data[1][2].value >= 0 then
                    local playerBase = getPlayerBase()
                    if not playerBase then return end
                    -- 0=Red | 1=Orange | 2=Yellow | 3=Green | 4=Blue | 5=White | 6=Purple
                    if data[1][2].data.sharpness == -1 then
                        data[1][2].data.sharpness = playerBase:get_field("<SharpnessLv>k__BackingField")
                    end
                    playerBase:set_field("<SharpnessLv>k__BackingField", data[1][2].value) -- Sharpness Level of Purple
                    -- playerBase:set_field("<SharpnessGauge>k__BackingField", 400) -- Sharpness Value
                    -- playerBase:set_field("<SharpnessGaugeMax>k__BackingField", 400) -- Max Sharpness
                else
                    if data[1][2].data.sharpness >= 0 then
                        local playerBase = getPlayerBase()
                        if not playerBase then return end
                        playerBase:set_field("<SharpnessLv>k__BackingField", data[1][2].data.sharpness)
                        data[1][2].data.sharpness = -1
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
                    if data[1][3][1].value then return sdk.PreHookResult.SKIP_ORIGINAL end
                end,
                post = nothing()
            },
            onChange = function()
                data[16][2].value = data[1][3][1].value -- Bow
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
                    if data[1][3][2].value then return sdk.PreHookResult.SKIP_ORIGINAL end
                end,
                post = nothing()
            },
            onChange = function()
                local value = data[1][3][2].value
                data[14][1].value = value -- Light Bowgun
                data[15][2].value = value -- Heavy Bowgun
            end
        },
        [3] = {
            title = "Auto Reload (Bowguns)",
            type = "checkbox",
            value = false,

            -- No hook as this is called per weapon
            onChange = function()
                local value = data[1][3][3].value
                data[14][2].value = value -- Light bow gun
                data[15][3].value = value -- Heavy bow gun
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
                pre = nothing(),
                post = function(retval)
                    if (data[1][4][1].value and not checkIfInBattle()) or data[1][4][2].value then
                        local playerBase = getPlayerBase()
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
                    if data[1][4][3].value then
                        local playerBase = getPlayerBase()
                        if not playerBase then return end
                        playerBase:set_field("<HunterWireWildNum>k__BackingField", 1)
                        playerBase:set_field("_HunterWireNumAddTime", 7000)
                    end
                end,
                post = nothing()
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
                    if data[1][4][4].value then
                        local playerData = getPlayerData()
                        if not playerData then return end
                        playerData:set_field("_WireBugPowerUpTimer", 10700)
                    end
                end,
                post = nothing()
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
                    if data[1][5][1].value or data[1][5][2].value then
                        local managed = sdk.to_managed_object(args[2])
                        if not managed then return end
                        if not managed:get_type_definition():is_a("snow.data.DangoData") then
                            return
                        end

                        local isUsingTicket = getMealFunc():call("getMealTicketFlag")

                        if isUsingTicket or data[1][5][2].value then
                            data[1][5].data.managed = managed
                            data[1][5].data.chance = managed:get_field("_Param"):get_field("_SkillActiveRate")
                            managed:get_field("_Param"):set_field("_SkillActiveRate", 200)
                        end
                    end
                end,
                post = function(retval)
                    -- Restore the original value
                    if (data[1][5][1].value or data[1][5][2].value) and data[1][5].data.managed then
                        data[1][5].data.managed:get_field("_Param")
                            :set_field("_SkillActiveRate", data[1][5].data.chance)
                        data[1][5].data.managed = nil
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
-- Character Modifications
data[2] = {
    title = "Character",
    [1] = {
        title = "Unlimited Stamina",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = function()
                if data[2][1].value then
                    local playerData = getPlayerData()
                    if not playerData then return end
                    local maxStamina = playerData:get_field("_staminaMax")
                    playerData:set_field("_stamina", maxStamina)
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "Health Options",
        [1] = {
            title = "Constant Healing",
            type = "checkbox",
            value = false,
            hook = {
                path = "snow.player.PlayerManager",
                func = "update",
                pre = function(args)
                    if data[2][2][1].value then
                        local playerData = getPlayerData()
                        if not playerData then return end
                        local max = playerData:get_field("_vitalMax")
                        playerData:set_field("_r_Vital", max)
                    end
                end,
                post = nothing()
            }
        },
        [2] = {
            title = "Unlimited Health (Cheater)",
            type = "checkbox",
            value = false,
            hook = {
                path = "snow.player.PlayerManager",
                func = "update",
                pre = function(args)
                    if data[2][2][2].value then

                        local playerData = getPlayerData()
                        if not playerData then return end
                        local max = playerData:get_field("_vitalMax")

                        -- Possible fix for Unlimited Health insta-death
                        if max > playerData:get_field("_r_Vital") then
                            local maxFloat = max + .0
                            playerData:set_field("_r_Vital", max)
                            playerData:call("set__vital", maxFloat)
                        end

                    end
                end,
                post = nothing()
            }
        }
    },
    [3] = {
        title = "Stat Modifiers (Cheater)",
        [1] = {
            title = "Attack Modifier",
            type = "slider",
            value = -1,
            min = -1,
            step = 10,
            max = 2600,
            dontSave = true,
            data = {
                value = 0
            },
            -- This way it only affects if YOU are the host
            hook = {
                path = "snow.player.PlayerManager",
                func = "update",
                pre = function(args)

                    local playerData = getPlayerData()
                    if not playerData then return end

                    if data[2][3][1].value >= 0 then
                        -- Set the original attack value
                        if data[2][3][1].data.value == 0 then
                            data[2][3][1].data.value = playerData:get_field("_Attack")
                        end

                        -- Setup variables to determine how much extra attack needs to be added to get to the set value
                        local attack = data[2][3][1].data.value
                        local attackTarget = data[2][3][1].value
                        local attackMod = attackTarget - attack

                        -- Add the extra attack
                        playerData:set_field("_AtkUpAlive", attackMod)

                        -- Restore the original attack value if disabled    
                    elseif data[2][3][1].data.value ~= 0 then
                        playerData:set_field("_AtkUpAlive", 0)
                        data[2][3][1].data.value = 0
                    end
                end,
                post = nothing()
            }
        },
        [2] = {
            title = "Defence Modifier",
            type = "slider",
            value = -1,
            min = -1,
            step = 10,
            max = 3100,
            dontSave = true,
            data = {
                value = 0
            },
            -- This way it only affects if YOU are the host
            hook = {
                path = "snow.player.PlayerManager",
                func = "update",
                pre = function(args)

                    local playerData = getPlayerData()
                    if not playerData then return end

                    if data[2][3][2].value >= 0 then
                        -- Set the original defence value
                        if data[2][3][2].data.value == 0 then
                            data[2][3][2].data.value = playerData:get_field("_Defence")
                        end
                        -- Setup variables to determine how much extra defence needs to be added to get to the set value
                        local defence = data[2][3][2].data.value
                        local defenceTarget = data[2][3][2].value
                        local defenceMod = defenceTarget - defence
                        playerData:set_field("_DefUpAlive", defenceMod)

                        -- Restore the original defence value if disabled
                    elseif data[2][3][2].data.value ~= 0 then
                        playerData:set_field("_DefUpAlive", 0)
                        data[2][3][2].data.value = 0
                    end
                end,
                post = nothing()
            }
        },
        [3] = {
            title = "Drag sliders to the left to reset if the stats break",
            type = "text"
        }
    }
}
-- Great Sword Modifications
data[3] = {
    title = "Great Sword",
    [1] = {
        title = "Charge Level",
        type = "slider",
        value = -1,
        min = -1,
        max = 3,
        display = "Level: %d",
        hook = {
            path = "snow.player.GreatSword",
            func = "update",
            pre = function(args)
                if data[3][1].value >= 0 then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_TameLv", data[3][1].value)
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "Power Sheathe",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.GreatSword",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[3][2].value then managed:set_field("MoveWpOffBuffGreatSwordTimer", 1200) end
            end,
            post = nothing()
        }
    }
}
-- Long Sword Modifications
data[4] = {
    title = "Long Sword",

    [1] = {
        title = "Spirit Guage Max",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.LongSword",
            func = "update",
            pre = function(args)
                if data[4][1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_LongSwordGauge", 100)
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "Spirit Level",
        type = "slider",
        value = -1,
        min = -1,
        max = 3,
        display = "Level: %d",
        hook = {
            path = "snow.player.LongSword",
            func = "update",
            pre = function(args)
                if data[4][2].value >= 0 then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_LongSwordGaugeLv", data[4][2].value)
                end
            end,
            post = nothing()
        }
    }
}
-- Sword & Shield
data[5] = {
    title = "Sword & Shield",
    [1] = {
        title = "Destroyer Oil",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.ShortSword",
            func = "update",
            pre = function(args)
                if data[5][1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<IsOilBuffSetting>k__BackingField", true)
                    managed:set_field("_OilBuffTimer", 3000)
                end
            end,
            post = nothing()
        }
    }
}
-- Dual Blade Modifications
data[6] = {
    title = "Dual Blades",

    [1] = {
        title = "ArchDemon Mode",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.DualBlades",
            func = "update",
            pre = function(args)
                if data[6][1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<KijinKyoukaGuage>k__BackingField", 100)
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "Ironshine Silk",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.DualBlades",
            func = "update",
            pre = function(args)
                if data[6][2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("SharpnessRecoveryBuffValidTimer", 3000)
                end
            end,
            post = nothing()
        }
    }

}
-- Lance Modifications
data[7] = {
    title = "Lance",
    [1] = {
        title = "Anchor Rage",
        type = "slider",
        value = -1,
        min = -1,
        max = 3,
        display = "Level: %d",
        hook = {
            path = "snow.player.Lance",
            func = "update",
            pre = function(args)
                if data[7][1].value >= 0 then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_GuardRageTimer", 3000)
                    managed:set_field("_GuardRageBuffType", data[7][1].value)
                end
            end,
            post = nothing()
        }
    }
}
-- Gunlance Modifications
data[8] = {
    title = "Gunlance",
    [1] = {
        title = "Unlimited Dragon Cannon",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = function(args)
                if data[8][1].value then

                    local playerData = getPlayerData()
                    if not playerData then return end
                    playerData:set_field("_ChargeDragonSlayCannonTime", 0)
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "Unlimited Aerials",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.GunLance",
            func = "update",
            pre = function(args)
                if data[8][2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_AerialCount", 0)
                end
            end,
            post = nothing()
        }
    },
    [3] = {
        title = "Auto Reload ",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.GunLance",
            func = "update",
            pre = function(args)
                if data[8][3].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:call("reloadBullet")
                end
            end,
            post = nothing()
        }
    },
    [4] = {
        title = "Ground Splitter",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.GunLance",
            func = "update",
            pre = function(args)
                if data[8][4].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_ShotDamageUpDurationTimer", 1800)
                end
            end,
            post = nothing()
        }
    },
    [5] = {
        title = "Erupting Cannon",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.GunLance",
            func = "update",
            pre = function(args)
                if data[8][5].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_ExplodePileBuffTimer", 1800)
                    managed:set_field("_ExplodePileAttackRate", 1.3)
                    managed:set_field("_ExplodePileElemRate", 1.3)

                end
            end,
            post = nothing()
        }
    }
}
-- Hammer Modifications
data[9] = {
    title = "Hammer",

    [1] = {
        title = "Charge Level ",
        type = "slider",
        value = -1,
        min = -1,
        max = 2,
        display = "Level: %d",
        hook = {
            path = "snow.player.Hammer",
            func = "update",
            pre = function(args)
                if data[9][1].value >= 0 then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<NowChargeLevel>k__BackingField", data[9][1].value)
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "Impact Burst",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.Hammer",
            func = "update",
            pre = function(args)
                if data[9][2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_ImpactPullsTimer", 3600)
                    managed:set_field("_IsEnableImapctPulls", true) -- They mispelt this field
                    managed:set_field("_IsEnableImpactPulls", true) -- Adding this just incase they fix it in a later version
                end
            end,
            post = nothing()
        }
    }
}
-- Hunting Horn Modifications
data[10] = {
    title = "Hunting Horn",
    [1] = {
        title = "Infernal Mode",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.Horn",
            func = "update",
            pre = function(args)
                if data[10][1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<RevoltGuage>k__BackingField", 100)
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "Skillbind Shockwave",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.Horn",
            func = "update",
            pre = function(args)
                if data[10][2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_ImpactPullsTimer", 1800)
                end
            end,
            post = nothing()
        }
    }
}
-- Switch Axe Modifications
data[11] = {
    title = "Switch Axe",

    [1] = {
        title = "Max Charge",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.SlashAxe",
            func = "update",
            pre = function(args)
                if data[11][1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_BottleGauge", 100)
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "Max Sword Ammo",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.SlashAxe",
            func = "update",
            pre = function(args)
                if data[11][2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_BottleAwakeGauge", 150)
                end
            end,
            post = nothing()
        }
    },
    [3] = {
        title = "Power Axe",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.SlashAxe",
            func = "update",
            pre = function(args)
                if data[11][3].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_BottleAwakeAssistTimer", 3600)
                end
            end,
            post = nothing()
        }
    },
    [4] = {
        title = "Switch Charger",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.SlashAxe",
            func = "update",
            pre = function(args)
                if data[11][4].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_NoUseSlashGaugeTimer", 400)
                end
            end,
            post = nothing()
        }
    }
}
-- Charge Blade Modifications
data[12] = {
    title = "Charge Blade",

    [1] = {
        title = "Full Bottles",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.ChargeAxe",
            func = "update",
            pre = function(args)
                if data[12][1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<ChargedBottleNum>k__BackingField", 5)
                    managed:set_field("_ChargeGauge", 50)
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "Sword Charged",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.ChargeAxe",
            func = "update",
            pre = function(args)
                if data[12][2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_SwordBuffTimer", 500)
                end
            end,
            post = nothing()
        }
    },
    [3] = {
        title = "Shield Charged",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.ChargeAxe",
            func = "update",
            pre = function(args)
                if data[12][3].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_ShieldBuffTimer", 1000)
                end
            end,
            post = nothing()
        }
    }
}
-- Insect Glaive Modifications
data[13] = {
    title = "Insect Glaive",

    [1] = {
        title = "Red Extract",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.InsectGlaive",
            func = "update",
            pre = function(args)
                if data[13][1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_RedExtractiveTime", 8000)
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "White Extract",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.InsectGlaive",
            func = "update",
            pre = function(args)
                if data[13][2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_WhiteExtractiveTime", 8000)
                end
            end,
            post = nothing()
        }
    },
    [3] = {
        title = "Orange Extract",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.InsectGlaive",
            func = "update",
            pre = function(args)
                if data[13][3].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_OrangeExtractiveTime", 8000)
                end
            end,
            post = nothing()
        }
    },
    [4] = {
        title = "Unlimited Aerials ",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.InsectGlaive",
            func = "update",
            pre = function(args)
                if data[13][4].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_AerialCount", 2)
                end
            end,
            post = nothing()
        }
    },
    [5] = {
        title = "Unlimited Kinsect Stamina",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.IG_Insect",
            func = "update",
            pre = function(args)
                if data[13][5].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<_Stamina>k__BackingField", 100)
                end
            end,
            post = nothing()
        }
    }
}
-- Light Bowgun Modifications
data[14] = {
    title = "Light Bowgun",
    [1] = {
        title = "Unlimited Ammo",
        type = "checkbox",
        value = false,
        dontSave = true,
        onChange = function()
            -- Change and update Miscellaneous/Ammo Options/Unlimited Ammo (Bowguns)
            data[1][3][2].value = data[14][1].value
            data[1][3][2].onChange()
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
                if data[14][2].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:call("resetBulletNum")
                end
            end,
            post = nothing()
        },
        onChange = function()
            -- Change and update Miscellaneous/Ammo & Coating Options/Auto Reload (Bowguns)
            data[1][3][3].value = data[14][2].value
            data[1][3][3].onChange()
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
                if data[14][3].value then

                    local playerData = getPlayerData()
                    if not playerData then return end
                    playerData:set_field("_WyvernBlastGauge", 3)
                    playerData:set_field("_WyvernBlastReloadTimer", 0)
                end
            end,
            post = nothing()
        }
    }
}
-- Heavy Bowgun Modifications
data[15] = {
    title = "Heavy Bowgun",
    [1] = {
        title = "Charge Level  ",
        type = "slider",
        value = -1,
        min = -1,
        max = 3,
        display = "Level: %d",
        hook = {
            path = "snow.player.HeavyBowgun",
            func = "update",
            pre = function(args)
                if data[15][1].value >= 0 then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("_ShotChargeLv", data[15][1].value)
                    -- managed:set_field("_ShotChargeFrame", 30 * data[15][1].value) -- Don't think this is needed anymore
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "Unlimited Ammo  ",
        type = "checkbox",
        value = false,
        dontSave = true,
        onChange = function()
            -- Change and update Miscellaneous/Ammo Options/Unlimited Ammo (Bowguns)
            data[1][3][2].value = data[15][2].value
            data[1][3][2].onChange()
        end
    },
    [3] = {
        title = "Auto Reload  ",
        type = "checkbox",
        value = false,
        dontSave = true,
        hook = {
            path = "snow.player.HeavyBowgun",
            func = "update",
            pre = function(args)
                if data[15][3].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:call("resetBulletNum")
                end
            end,
            post = nothing()
        },
        onChange = function()
            -- Change and update Miscellaneous/Ammo & Coating Options/Auto Reload (Bowguns)
            data[1][3][3].value = data[15][3].value
            data[1][3][3].onChange()
        end
    },
    [4] = {
        title = "Unlimited Wyvern Sniper",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = function(args)
                if data[15][4].value then

                    local playerData = getPlayerData()
                    if not playerData then return end
                    playerData:set_field("_HeavyBowgunWyvernSnipeBullet", 1)
                    playerData:set_field("_HeavyBowgunWyvernSnipeTimer", 0)
                end
            end,
            post = nothing()
        }
    },
    [5] = {
        title = "Unlimited Wyvern Machine Gun",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = function(args)
                if data[15][5].value then

                    local playerData = getPlayerData()
                    if not playerData then return end
                    playerData:set_field("_HeavyBowgunWyvernMachineGunBullet", 50)
                    playerData:set_field("_HeavyBowgunWyvernMachineGunTimer", 0)
                end
            end,
            post = nothing()
        }
    },
    [6] = {
        title = "Prevent Overheat",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = function(args)
                if data[15][6].value then

                    local playerData = getPlayerData()
                    if not playerData then return end
                    playerData:set_field("_HeavyBowgunHeatGauge", 0)
                end
            end,
            post = nothing()
        }
    }
}
-- Bow Modifications
data[16] = {
    title = "Bow",

    [1] = {
        title = "Charge Level   ",
        type = "slider",
        value = -1,
        min = -1,
        max = 3,
        display = "Level: %d",
        hook = {
            path = "snow.player.Bow",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[16][1].value >= 0 then
                    managed:set_field("<ChargeLv>k__BackingField", data[16][1].value)
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "Unlimited Coatings",
        type = "checkbox",
        value = false,
        dontSave = true,
        onChange = function()
            -- Change and update Miscellaneous/Ammo & Coating Options/Unlimited Coatings (Arrows)
            data[1][3][1].value = data[16][2].value
            data[1][3][1].onChange()
        end
    },
    [3] = {
        title = "Herculean Draw",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.Bow",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[16][3].value then
                    managed:set_field("_WireBuffAttackUpTimer", 1800)
                    managed:set_field("<IsWireBuffSetting>k__BackingField", true)
                end
            end,
            post = nothing()
        }
    },
    [4] = {
        title = "Bolt Boost",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.Bow",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[16][3].value then managed:set_field("_WireBuffArrowUpTimer", 1800) end
            end,
            post = nothing()
        }
    }
}

-- Function to get length of table
local function getLength(obj)
    local count = 0

    -- Count the items in the table
    for _ in pairs(obj) do count = count + 1 end
    return count
end

-- Initialize the hooks
local function initHooks(table)
    table = table or data
    -- Loop through the table
    for k, v in pairs(table) do

        -- If the value is a table, recursively call initHooks
        if type(v) == "table" then
            -- If the table has a path, then it's a hook
            if v.path then
                log.debug("          " .. v.path)
                sdk.hook(sdk.find_type_definition(v.path):get_method(v.func), v.pre, v.post)

                -- If the table has a title but no path, then you'll have to dig deeper
            elseif v.title then
                log.debug("Checking hooks for " .. v.title)
            end
            -- Check deeper hooks
            initHooks(v)
        end
    end
end

-- Initialize the updates
local function initUpdates(table)
    table = table or data
    -- Loop through the table
    for k, v in pairs(table) do

        -- If the value is a table, recursively call initHooks
        if type(v) == "table" then

            -- If the table has an update, then it needs to be updated
            if v.update then
                -- log.debug("Initializing updates for " .. v.title)
                re.on_pre_application_entry("UpdateBehavior", v.update)

                -- If there is no update, then dig deeper to see if the next level has one
            else
                initUpdates(v)
            end
        end
    end
end

-- Draw the menu
local function drawMenu(table, level)
    if not table then table = data end
    if not level then level = 0 end
    -- Loop through the table
    for i = 1, getLength(table) + 1 do
        local obj = table[i]
        -- If it's a table with a title, draw the title
        if type(obj) == "table" and obj.title then
            -- If the table has a value or type is text draw the table item
            if obj.value ~= nil or obj.type == "text" then
                local changed = false

                -- If the table has a type of checkbox
                if obj.type == "checkbox" then
                    changed, obj.value = imgui.checkbox(obj.title, obj.value)

                    -- If the table has a type of slider
                elseif obj.type == "slider" then
                    local sliderDisplay = "%d"
                    local sliderValue = obj.value
                    if obj.value == -1 then
                        sliderDisplay = "Off" -- If Off
                    elseif obj.display and obj.value >= 0 and type(obj.display) == "table" then
                        sliderDisplay = obj.display[obj.value + 1] -- If display is a table
                    elseif obj.display and obj.value >= 0 then
                        sliderDisplay = obj.display -- If a display format is passed
                    end

                    -- To allow for steps we need to set these and divide them by the steps
                    local sliderMax = obj.max
                    local sliderVal = obj.value
                    local steppedVal = 0
                    if obj.step then
                        sliderMax = math.ceil(obj.max / obj.step)
                        -- If the slider value is greater than -1 (Off), adjust the value by step as well
                        if (obj.value > -1) then
                            -- Divide the value by the step to get the reduced value
                            sliderVal = math.floor(obj.value / obj.step)
                            sliderDisplay = obj.value
                        end
                    end
                    changed, steppedVal = imgui.slider_int(obj.title, sliderVal, obj.min, sliderMax, sliderDisplay)
                    -- If there is a step and the slider isn't off, then multiply the stepped value by the step to get the real total
                    if obj.step and obj.value > -1 then steppedVal = steppedVal * obj.step end
                    -- Update the table's value with the new value
                    obj.value = steppedVal

                    -- If the table has a type of drag, not yet used for anything
                elseif obj.type == "drag" then
                    local dragValue = "Off"
                    if (obj.value >= 0) then dragValue = obj.value end
                    changed, obj.value = imgui.drag_int(obj.title, obj.value, obj.speed, obj.min, obj.max, dragValue)
                    -- If the table has a type of text, draw the text
                elseif obj.type == "text" then
                    imgui.text(obj.title)
                end

                -- If anything changed, save the config
                if changed then saveConfig() end

                -- If anything changed, and the table has a onChange function, call it
                if changed and obj.onChange then obj.onChange() end

                -- If the table doesn't have a value and isn't text, go deeper and see if the next level table has to be drawn
            else
                if level == 0 and imgui.collapsing_header(obj.title) then
                    drawMenu(obj, level + 1)
                    imgui.separator()
                    imgui.spacing()
                elseif level > 0 and imgui.tree_node(obj.title) then
                    drawMenu(obj, level + 1)
                    imgui.separator()
                    imgui.spacing()
                    imgui.tree_pop()
                end

            end
        end
    end
end

-- Load and Initialize everything that we need
loadConfig()
initHooks()
initUpdates()

-- Update items that have multiple triggers
data[1][3][1].onChange()
data[1][3][2].onChange()
data[1][3][3].onChange()

-- Add the menu to the REFramework Script Generated UI
re.on_draw_ui(function()
    imgui.begin_window("Modifiers & Settings", nil, ImGuiWindowFlags_AlwaysAutoResize)
    imgui.spacing()
    drawMenu()
    imgui.spacing()
    imgui.end_window()
end)

-- On script reset, reset anything that needs to be reset
re.on_script_reset(function()

    -- Until I find a better way of increase attack, I have to reset this on script reset
    if data[2][3][1].value >= 0 then
        local playerData = getPlayerData()
        if not playerData then return end
        playerData:set_field("_AtkUpAlive", 0)
    end

    -- Until I find a better way of increase defence, I have to reset this on script reset
    if data[2][3][2].value >= 0 then
        local playerData = getPlayerData()
        if not playerData then return end
        playerData:set_field("_DefUpAlive", 0)
    end

end)
