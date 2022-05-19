local configPath = "Buffer.json"
local data = {}

local function nothing(retval)
    return retval
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
        for k, v in pairs(table) do
            if v.title == key then
                table[k].value = value
            end
        end
    end

end
local function loadConfig()
    if json ~= nil then
        local settings = json.load_file(configPath)
        if settings then
            for settingsKey, settingsValue in pairs(settings) do
                setConfig(settingsKey, settingsValue)
            end
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

-- Miscellaneous Modifications
data[1] = {
    title = "Miscellaneous",
    [1] = {
        title = "Unlimited Ammo",
        type = "checkbox",
        value = false,
        hook = {
            [1] = {
                path = "snow.data.bulletSlider.BottleSliderFunc",
                func = "consumeItem",
                pre = function(args)
                    if data[1][1].value then
                        return sdk.PreHookResult.SKIP_ORIGINAL
                    end
                end,
                post = nothing()
            },
            [2] = {
                path = "snow.data.bulletSlider.BulletSliderFunc",
                func = "consumeItem",
                pre = function(args)
                    if data[1][1].value then
                        return sdk.PreHookResult.SKIP_ORIGINAL
                    end
                end,
                post = nothing()
            }
        },
        onChange = function()
            data[14][2].value = data[1][1].value
            data[15][3].value = data[1][1].value
        end
    },
    [2] = {
        title = "Unlimited Consumables",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.data.ItemSlider",
            func = "notifyConsumeItem",
            pre = function(args)
                if data[1][2].value then
                    return sdk.PreHookResult.SKIP_ORIGINAL
                end
            end,
            post = nothing()
        }
    },
    [3] = {
        title = "White Sharpness",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = nothing(),
            post = function(args)
                if data[1][3].value then
                    local playerManager = sdk.get_managed_singleton("snow.player.PlayerManager")
                    local playerbase = playerManager:call("findMasterPlayer")
                    -- playerbase:set_field("<SharpnessLv>k__BackingField", 5) -- Sharpness Level
                    playerbase:set_field("<SharpnessGauge>k__BackingField", 400) -- Sharpness Value
                    playerbase:set_field("<SharpnessGaugeMax>k__BackingField", 400)
                end
            end
        }
    },
    [4] = {
        title = "Unlimited Wirebugs",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.fsm.PlayerFsm2ActionHunterWire",
            func = "start",
            pre = nothing(),
            post = function(retval)
                if data[1][4].value then

                    local playerManager = sdk.get_managed_singleton("snow.player.PlayerManager")
                    local playerbase = playerManager:call("findMasterPlayer")
                    local wireGuages = playerbase:get_field("_HunterWireGauge")

                    if not wireGuages then
                        return
                    end
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
    [5] = {
        title = "Unlimited Stamina",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = function()
                if data[1][5].value then
                    local playerManager = sdk.get_managed_singleton("snow.player.PlayerManager")
                    local playerbase = playerManager:call("findMasterPlayer")
                    local playerData = playerbase:call("get_PlayerData")

                    local maxStamina = playerData:get_field("_staminaMax")
                    playerData:set_field("_stamina", maxStamina)
                end
            end,
            post = nothing()
        }
    },
    [6] = {
        title = "Health Options",
        [1] = {
            title = "Constant Healing",
            type = "checkbox",
            value = false,
            hook = {
                path = "snow.player.PlayerManager",
                func = "update",
                pre = function(args)
                    if data[1][6][1].value then
                        local playerManager = sdk.get_managed_singleton("snow.player.PlayerManager")
                        local playerbase = playerManager:call("findMasterPlayer")
                        local playerData = playerbase:call("get_PlayerData")
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
                    if data[1][6][2].value then
                        local playerManager = sdk.get_managed_singleton("snow.player.PlayerManager")
                        local playerbase = playerManager:call("findMasterPlayer")
                        local playerData = playerbase:call("get_PlayerData")
                        local max = playerData:get_field("_vitalMax")

                        playerData:set_field("_r_Vital", max)
                        playerData:call("set__vital", max)
                    end
                end,
                post = nothing()
            }
        }
    },
    [7] = {
        title = "100% Dango Skills",
        [1] = {
            title = "With Ticket",
            type = "checkbox",
            value = false,
            data = {
                managed = nil,
                chance = 0
            },
            hook = {
                path = "snow.data.DangoData",
                func = "get_SkillActiveRate",
                pre = function(args)
                    if data[1][7][1].value then
                        local managed = sdk.to_managed_object(args[2])
                        local facilityDataManager = sdk.get_managed_singleton("snow.data.FacilityDataManager")
                        if not facilityDataManager then
                            return
                        end
                        local kitchen = facilityDataManager:get_field("_Kitchen")
                        if not kitchen then
                            return
                        end
                        local mealFunc = kitchen:get_field("_MealFunc")
                        if not mealFunc then
                            return
                        end
                        local isUsingTicket = mealFunc:call("getMealTicketFlag")

                        if isUsingTicket then
                            data[1][7][1].data.managed = managed
                            data[1][7][1].data.chance = managed:get_field("_Param"):get_field("_SkillActiveRate")
                            managed:get_field("_Param"):set_field("_SkillActiveRate", 100)
                        end
                    end
                end,
                post = function(retval)
                    if data[1][7][1].value and data[1][7][1].data.managed then
                        data[1][7][1].data.managed:get_field("_Param"):set_field("_SkillActiveRate",
                            data[1][7][1].data.chance)
                    end
                    return retval
                end
            }
        },
        [2] = {
            title = "Without Ticket (Cheater)",
            type = "checkbox",
            value = false,
            data = {
                managed = nil,
                chance = 0
            },
            hook = {
                path = "snow.data.DangoData",
                func = "get_SkillActiveRate",
                pre = function(args)
                    if data[1][7][2].value then
                        local managed = sdk.to_managed_object(args[2])
                        local facilityDataManager = sdk.get_managed_singleton("snow.data.FacilityDataManager")
                        if not facilityDataManager then
                            return
                        end
                        local kitchen = facilityDataManager:get_field("_Kitchen")
                        if not kitchen then
                            return
                        end
                        local mealFunc = kitchen:get_field("_MealFunc")
                        if not mealFunc then
                            return
                        end
                        data[1][7][2].data.managed = managed
                        data[1][7][2].data.chance = managed:get_field("_Param"):get_field("_SkillActiveRate")
                        managed:get_field("_Param"):set_field("_SkillActiveRate", 100)
                    end
                end,
                post = function(retval)
                    if data[1][7][2].value and data[1][7][2].data.managed then
                        data[1][7][2].data.managed:get_field("_Param"):set_field("_SkillActiveRate",
                            data[1][7][2].data.chance)
                    end
                    return retval
                end
            }
        }
    }
}
-- Great Sword Modifications
data[2] = {
    title = "Great Sword",
    [1] = {
        title = "Charge Level",
        type = "slider",
        value = -1,
        min = -1,
        max = 3,
        hook = {
            path = "snow.player.GreatSword",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[2][1].value >=0 then
                    managed:set_field("_TameLv", data[2][1].value)
                end
            end,
            post = nothing()
        }
    }
    -- [2] = {
    --     title = "Wirebug Buff",
    --     type = "checkbox",
    --     value = false,
    --     hook = {
    --         path = "snow.player.GreatSword",
    --         func = "update",
    --         pre = function(args)
    --             local managed = sdk.to_managed_object(args[2])
    --             if data[2][2].value then
    --                 -- managed:call("setMoveWpOffDamageUp")
    --             end
    --         end,
    --         post = nothing()
    --     }
    -- }
}
-- Long Sword Modifications
data[3] = {
    title = "Long Sword",

    [1] = {
        title = "Spirit Guage Max",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.LongSword",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[3][1].value then
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
        hook = {
            path = "snow.player.LongSword",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[3][2].value >= 0 then
                    managed:set_field("_LongSwordGaugeLv", data[3][2].value)
                end
            end,
            post = nothing()
        }
    }
}
-- Sword & Shield ... Can't find anything useful...
data[4] = {
    -- title = "Sword & Shield",
}
-- Dual Blade Modifications
data[5] = {
    title = "Dual Blades",

    [1] = {
        title = "ArchDemon Mode",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.DualBlades",
            func = "update",
            pre = function(args)
                if data[5][1].value then
                    local managed = sdk.to_managed_object(args[2])
                    managed:set_field("<KijinKyoukaGuage>k__BackingField", 100)
                end
            end,
            post = nothing()
        }
    }

}
-- Nothing Yet - Lance
data[6] = {
    -- title = "Lance",
}
-- Nothing Yet - Gunlance
data[7] = {
    -- title = "Gunlance",
}
-- Hammer Modifications
data[8] = {
    title = "Hammer",

    [1] = {
        title = "Charge Level",
        type = "slider",
        value = -1,
        min = -1,
        max = 2,
        hook = {
            path = "snow.player.Hammer",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[8][1].value >= 0 then
                    managed:set_field("<NowChargeLevel>k__BackingField", data[8][1].value)
                end
            end,
            post = nothing()
        }
    }
}
-- Hunting Horn Modifications
data[9] = {
    title = "Hunting Horn",
    [1] = {
        title = "Infernal Mode",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.HuntingHorn",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[9][1].value then
                    managed:set_field("<RevoltGuage>k__BackingField", 100)
                end
            end,
            post = nothing()
        }
    }
}
-- Switch Axe Modifications... why is it called a SlashAxe...
data[10] = {
    title = "Switch Axe",

    [1] = {
        title = "Max Charge",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.SlashAxe",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[10][1].value then
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
                local managed = sdk.to_managed_object(args[2])
                if data[10][2].value then
                    managed:set_field("_BottleAwakeGauge", 150)
                end
            end,
            post = nothing()
        }
    }
}
-- Charge Blade Modifications... why is it called a ChargeAxe...
data[11] = {
    title = "Charge Blade",

    [1] = {
        title = "Full Bottles",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.ChargeAxe",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[11][1].value then
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
                local managed = sdk.to_managed_object(args[2])
                if data[11][2].value then
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
                local managed = sdk.to_managed_object(args[2])
                if data[11][3].value then
                    managed:set_field("_ShieldBuffTimer", 1000)
                end
            end,
            post = nothing()
        }
    }
}
-- Insect Glaive Modifications
data[12] = {
    title = "Insect Glaive",

    [1] = {
        title = "Red Extract",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.InsectGlaive",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[12][1].value then
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
                local managed = sdk.to_managed_object(args[2])
                if data[12][2].value then
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
                local managed = sdk.to_managed_object(args[2])
                if data[12][3].value then
                    managed:set_field("_OrangeExtractiveTime", 8000)
                end
            end,
            post = nothing()
        }
    },
    [4] = {
        title = "Unlimited Aerial",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.InsectGlaive",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[12][4].value then
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
                local managed = sdk.to_managed_object(args[2])
                if data[12][5].value then
                    igb:set_field("<_Stamina>k__BackingField", 100)
                end
            end,
            post = nothing()
        }
    }
}
-- Nothing Yet - Light Bowgun
data[13] = {}
-- Heavy Bowgun Modifications
data[14] = {
    title = "Heavy Bowgun",

    [1] = {
        title = "Charge Level",
        type = "slider",
        value = -1,
        min = -1,
        max = 3,
        hook = {
            path = "snow.player.HeavyBowgun",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[14][1].value >= 0 then
                    managed:set_field("_ShotChargeLv", data[14][1].value)
                    managed:set_field("_ShotChargeFrame", 30 * data[14][1].value)
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "Unlimited Ammo",
        type = "checkbox",
        value = false,
        dontSave = true,
        onChange = function()
            data[1][1].value = data[14][2].value
            data[1][1].onChange()
        end
    }
}
-- Bow Modifications
data[15] = {
    title = "Bow",

    [1] = {
        title = "Charge Level",
        type = "slider",
        value = -1,
        min = -1,
        max = 3,
        hook = {
            path = "snow.player.Bow",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[15][1].value >= 0 then
                    managed:set_field("<ChargeLv>k__BackingField", data[15][1].value)
                end
            end,
            post = nothing()
        }
    },
    [2] = {
        title = "Wirebug Buff",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.Bow",
            func = "update",
            pre = function(args)
                local managed = sdk.to_managed_object(args[2])
                if data[15][2].value then
                    managed:set_field("<IsWireBuffSetting>k__BackingField", true)
                    managed:set_field("_WireBuffAttackUpTimer", 1800)
                    -- managed:call("setWireBuffAttackUp")
                end
            end,
            post = nothing()
        }
    },
    [3] = {
        title = "Unlimited Ammo",
        type = "checkbox",
        value = false,
        dontSave = true,
        onChange = function()
            data[1][1].value = data[15][3].value
            data[1][1].onChange()
        end
    }
}

-- Function to get length of table
local function getLength(obj)
    local count = 0
    for _ in pairs(obj) do
        count = count + 1
    end
    return count
end

-- Initialize the hooks
local function initHooks(table)
    table = table or data
    for k, v in pairs(table) do
        if type(v) == "table" then
            if v.path then
                -- log.debug("          " .. v.path)
                sdk.hook(sdk.find_type_definition(v.path):get_method(v.func), v.pre, v.post)

            elseif v.title then
                -- log.debug("Checking hooks for " .. v.title)
            end
            initHooks(v)
        end
    end
end

-- Initialize the updates
local function initUpdates(table)
    table = table or data
    for k, v in pairs(table) do
        if type(v) == "table" then
            if v.update then
                -- log.debug("Initializing updates for " .. v.title)
                re.on_pre_application_entry("UpdateBehavior", v.update)
            else
                initUpdates(v)
            end
        end
    end
end

-- Draw the menu
local function drawMenu(table)
    table = table or data
    for i = 1, getLength(table) + 1 do
        local obj = table[i]
        if type(obj) == "table" and obj.title then
            if obj.value ~= nil then
                local changed = false
                if obj.type == "checkbox" then
                    changed, obj.value = imgui.checkbox(obj.title, obj.value)
                else
                    if obj.type == "slider" then
                        local sliderValue = "Off"
                        if (obj.value >= 0) then
                            sliderValue = "Lvl " .. obj.value
                        end
                        changed, obj.value = imgui.slider_int(obj.title, obj.value, obj.min, obj.max, sliderValue)
                    end
                end
                if changed then
                    saveConfig()
                end
                if changed and obj.onChange then
                    obj.onChange()
                end

            elseif imgui.tree_node(obj.title) then
                drawMenu(obj)
                imgui.tree_pop()
            end
        end
    end
end

-- Load and Initialize everything that we need
loadConfig()
initHooks()
initUpdates()

-- Update items that have multiple triggers
data[1][1].onChange()

-- Add a button to the REFramework Script Generated UI
re.on_draw_ui(function()
    imgui.begin_window("Modifiers & Settings", nil, ImGuiWindowFlags_AlwaysAutoResize)
    drawMenu()
    imgui.end_window()
end)
