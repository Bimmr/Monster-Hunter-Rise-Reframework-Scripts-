local utils = require("Buffer Modules.Utils")
local character = {}

function character.reset()
    -- Until I find a better way of increase attack, I have to reset this on script reset
    if character[4][1].value >= 0 then
        local playerData = utils.getPlayerData()
        if not playerData then return end
        playerData:set_field("_AtkUpAlive", 0)
    end

    -- Until I find a better way of increase defence, I have to reset this on script reset
    if character[4][2].value >= 0 then
        local playerData = utils.getPlayerData()
        if not playerData then return end
        playerData:set_field("_DefUpAlive", 0)
    end

end

-- character Modifications
character = {
    title = "Character",
    [1] = {
        title = "Unlimited Stamina",
        type = "checkbox",
        value = false,
        hook = {
            path = "snow.player.PlayerManager",
            func = "update",
            pre = function()
                if character[1].value then
                    local playerData = utils.getPlayerData()
                    if not playerData then return end
                    local maxStamina = playerData:get_field("_staminaMax")
                    playerData:set_field("_stamina", maxStamina)
                end
            end,
            post = utils.nothing()
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
                    if character[2][1].value then
                        local playerData = utils.getPlayerData()
                        if not playerData then return end
                        local max = playerData:get_field("_vitalMax")
                        playerData:set_field("_r_Vital", max)
                    end
                end,
                post = utils.nothing()
            }
        },
        [2] = {
            title = "Insta-Healing (Cheater)",
            type = "checkbox",
            value = false,
            hook = {
                path = "snow.player.PlayerManager",
                func = "update",
                pre = function(args)
                    if character[2][2].value then

                        local playerData = utils.getPlayerData()
                        if not playerData then return end
                        local max = playerData:get_field("_vitalMax")

                        local maxFloat = max + .0
                        playerData:set_field("_r_Vital", max)
                        playerData:call("set__vital", maxFloat)

                    end
                end,
                post = utils.nothing()
            }
        },
        [3] = {
            title = "Max Dragonheart Health",
            type = "checkbox",
            value = false,
            hook = {
                path = "snow.player.PlayerManager",
                func = "update",
                pre = function(args)
                    if character[2][3].value then

                        local playerData = utils.getPlayerData()
                        if not playerData then return end
                        local playerBase = utils.getPlayerBase()
                        if not playerBase then return end

                        local max = playerData:get_field("_vitalMax")
                        local playerSkills = playerBase:call("get_PlayerSkillList")
                        if not playerSkills then return end
                        local dhSkill = playerSkills:call("getSkillData", 103) -- Dragonheart Skill ID
                        if not dhSkill then return end
                        local dhLevel = dhSkill:get_field("SkillLv")

                        -- Depending on level set health percent
                        local newHealth = max
                        if dhLevel == 1 or dhLevel == 2 then newHealth = math.floor(max * 0.5) end
                        if dhLevel == 3 or dhLevel == 4 then newHealth = math.floor(max * 0.7) end
                        if dhLevel == 5 then newHealth = math.floor(max * 0.8) end

                        playerData:set_field("_r_Vital", math.min(max, newHealth) + .0)
                        playerData:call("set__vital", math.min(max, newHealth) + .0)

                    end
                end,
                post = utils.nothing()
            }
        },
        [4] = {
            title = "Max Heroics Health",
            type = "checkbox",
            value = false,
            hook = {
                path = "snow.player.PlayerManager",
                func = "update",
                pre = function(args)
                    if character[2][4].value then

                        local playerData = utils.getPlayerData()
                        if not playerData then return end

                        local max = playerData:get_field("_vitalMax")
                        local newHealth = math.floor(max * 0.3)

                        playerData:set_field("_r_Vital", math.min(max, newHealth) + .0)
                        playerData:call("set__vital", math.min(max, newHealth) + .0)

                    end
                end,
                post = utils.nothing()
            }
        },
        [5] = {
            title = "Max Adrenaline Health",
            type = "checkbox",
            value = false,
            hook = {
                path = "snow.player.PlayerManager",
                func = "update",
                pre = function(args)
                    if character[2][5].value then

                        local playerData = utils.getPlayerData()
                        if not playerData then return end

                        local newHealth = 10.0

                        playerData:set_field("_r_Vital", math.min(max, newHealth) + .0)
                        playerData:call("set__vital", math.min(max, newHealth) + .0)

                    end
                end,
                post = utils.nothing()
            }
        }
    },
    [3] = {
        title = "Conditions, Ailments, & Blights",
        [1] = {
            title = "Prevent Blights",
            [1] = {
                title = "Fire Blight",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][1][1].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end

                            playerBase:set_field("_FireLDurationTimer", 0) -- The fire timer
                            playerBase:set_field("_FireDamageTimer", 0) -- The fire damage timer
                        end
                    end,
                    post = utils.nothing()
                }
            },
            [2] = {
                title = "Water Blight",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][1][2].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end

                            playerBase:set_field("_WaterLDurationTimer", 0) -- The water blight timer
                        end
                    end,
                    post = utils.nothing()
                }
            },
            [3] = {
                title = "Ice Blight",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][1][3].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end

                            playerBase:set_field("_IceLDurationTimer", 0) -- The ice blight timer
                        end
                    end,
                    post = utils.nothing()
                }
            },
            [4] = {
                title = "Thunder Blight",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][1][4].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end

                            playerBase:set_field("_ThunderLDurationTimer", 0) -- The thunder blight timer
                        end
                    end,
                    post = utils.nothing()
                }
            },
            [5] = {
                title = "Dragon Blight",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][1][5].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end

                            playerBase:set_field("_DragonLDurationTimer", 0) -- The dragon blight timer
                        end
                    end,
                    post = utils.nothing()
                }
            },
            [6] = {
                title = "Bubble Blight",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][1][6].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end

                            playerBase:set_field("_BubbleDamageTimer", 0) -- The bubble timer
                            -- playerData:set_field("_BubbleType", 0) -- | 0=None | 1=BubbleS | 2=BubbleL |
                        end
                    end,
                    post = utils.nothing()
                }
            },
            [7] = {
                title = "Blast Blight",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][1][7].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end

                            playerBase:set_field("_BombDurationTimer", 0) -- The blast timer
                        end
                    end,
                    post = utils.nothing()
                }
            }
        },
        [2] = {
            title = "Prevent Conditions",
            [1] = {
                title = "Bleeding",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][2][1].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end

                            playerBase:set_field("_BleedingDebuffTimer", 0) -- The bleeding timer
                        end
                    end,
                    post = utils.nothing()
                }
            },
            [2] = {
                title = "Stun",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][2][2].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end
                            playerBase:set_field("_StunDurationTimer", 0) -- The stun timer

                        end
                    end,
                    post = utils.nothing()
                }
            },

            [3] = {
                title = "Poison",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][2][3].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end

                            playerBase:set_field("_PoisonDurationTimer", 0) -- The poison timer
                            playerBase:set_field("_PoisonDamageTimer", 0) -- How long till next poison tick
                            -- playerData:set_field("_PoisonLv", 0) -- | 0=None | 1=Poison | 2=NoxiousPoison | 3=DeadlyPoison | 
                        end
                    end,
                    post = utils.nothing()
                }
            },
            [4] = {
                title = "Sleep",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][2][4].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end

                            playerBase:set_field("_SleepDurationTimer", 0) -- The sleep timer
                            playerBase:set_field("<SleepMovableTimer>k__BackingField", 0) -- The sleep walking timer
                        end
                    end,
                    post = utils.nothing()
                }
            },
            [5] = {
                title = "Frenzy",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][2][5].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end

                            playerBase:set_field("_IsVirusLatency", false) -- The frenzy virus
                            playerBase:set_field("_VirusTimer", 0) -- How long till the next frenzy virus tick
                            playerBase:set_field("_VirusAccumulator", 0) -- Total ticks of Frenzy
                        end
                    end,
                    post = utils.nothing()
                }
            },
            [6] = {
                title = "Defence/Restistance Down",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][2][6].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end

                            playerBase:set_field("_ResistanceDownDurationTimer", 0) -- The resistance down timer
                            playerBase:set_field("_DefenceDownDurationTimer", 0) -- The defence down timer
                        end
                    end,
                    post = utils.nothing()
                }
            },
            [7] = {
                title = "Prevent Hellfire and Stentch",
                type = "checkbox",
                value = false,
                hook = {
                    path = "snow.player.PlayerManager",
                    func = "update",
                    pre = function(args)
                        if character[3][2][7].value then
                            local playerBase = utils.getPlayerBase()
                            if not playerBase then return end

                            playerBase:set_field("_OniBombDurationTimer", 0) -- The hellfire timer
                            playerBase:set_field("_StinkDurationTimer", 0) -- The putrid gas damage timer
                        end
                    end,
                    post = utils.nothing()
                }
            },
            [8] = {
                title = "Still working on Paralyze and Web",
                type = "text"

                -- playerBase:set_field("_ParalyzeDurationTimer", 0) -- The paralysis recovery timer -- DOESN'T REMOVE ANIMATION TIME
                -- playerBase:set_field("_BetoDurationTimer", 0) -- The covered in spider web recovery timer -- DOESN'T REMOVE ANIMATION TIME
                -- playerBase:set_field("_EarDurationTimer", 0) -- The roar recovery timer -- DOESN'T REMOVE ANIMATION TIME
                -- playerBase:set_field("_QuakeDurationTimer", 0) -- The stomp recovery timer -- DOESN'T REMOVE ANIMATION TIME
            }
        }
    },

    [4] = {
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

                    local playerData = utils.getPlayerData()
                    if not playerData then return end

                    if character[4][1].value >= 0 then
                        -- Set the original attack value
                        if character[4][1].data.value == 0 then
                            character[4][1].data.value = playerData:get_field("_Attack")
                        end

                        -- Setup variables to determine how much extra attack needs to be added to get to the set value
                        local attack = character[4][1].data.value
                        local attackTarget = character[4][1].value
                        local attackMod = attackTarget - attack

                        -- Add the extra attack
                        playerData:set_field("_AtkUpAlive", attackMod)

                        -- Restore the original attack value if disabled    
                    elseif character[4][1].data.value ~= 0 then
                        playerData:set_field("_AtkUpAlive", 0)
                        character[4][1].data.value = 0
                    end
                end,
                post = utils.nothing()
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

                    local playerData = utils.getPlayerData()
                    if not playerData then return end

                    if character[4][2].value >= 0 then
                        -- Set the original defence value
                        if character[4][2].data.value == 0 then
                            character[4][2].data.value = playerData:get_field("_Defence")
                        end
                        -- Setup variables to determine how much extra defence needs to be added to get to the set value
                        local defence = character[4][2].data.value
                        local defenceTarget = character[4][2].value
                        local defenceMod = defenceTarget - defence
                        playerData:set_field("_DefUpAlive", defenceMod)

                        -- Restore the original defence value if disabled
                    elseif character[4][2].data.value ~= 0 then
                        playerData:set_field("_DefUpAlive", 0)
                        character[4][2].data.value = 0
                    end
                end,
                post = utils.nothing()
            }
        },
        [3] = {
            title = "Drag sliders to the left to reset if the stats break",
            type = "text"
        }
    }
}
return character