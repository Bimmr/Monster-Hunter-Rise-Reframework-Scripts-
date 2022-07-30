local utils, config
local data = {
    title = "Character",
    unlimited_stamina = false,
    health = {
        healing = false,
        insta_healing = false,
        max_dragonheart = false,
        max_heroics = false,
        max_adrenaline = false
    },
    conditions_and_blights = {
        blights = {
            fire = false,
            water = false,
            ice = false,
            thunder = false,
            dragon = false,
            bubble = false,
            blast = false
        },
        conditions = {
            bleeding = false,
            stun = false,
            poison = false,
            sleep = false,
            frenzy = false,
            qurio = false,
            defence_and_resistance = false,
            hellfire_and_stentch = false
        }
    },
    stats = {
        attack = -1,
        defence = -1
    },
    data = {
        attack_original = nil,
        defence_original = nil
    }
}

function data.init()
    utils = require("Buffer Modules.Utils")
    config = require("Buffer Modules.Config")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)

        local playerBase = utils.getPlayerBase()
        if not playerBase then return end
        local playerData = utils.getPlayerData()
        if not playerData then return end

        if data.unlimited_stamina then
            local maxStamina = playerData:get_field("_staminaMax")
            playerData:set_field("_stamina", maxStamina)
        end

        if data.health.healing then
            local max = playerData:get_field("_vitalMax")
            playerData:set_field("_r_Vital", max)
        end

        if data.health.insta_healing then
            local max = playerData:get_field("_vitalMax")

            local maxFloat = max + .0
            playerData:set_field("_r_Vital", max)
            playerData:call("set__vital", maxFloat)
        end

        if data.health.max_dragonheart then
            local max = playerData:get_field("_vitalMax")
            local playerSkills = playerBase:call("get_PlayerSkillList")
            if playerSkills then
                local dhSkill = playerSkills:call("getSkillData", 103) -- Dragonheart Skill ID
                if dhSkill then
                    local dhLevel = dhSkill:get_field("SkillLv")

                    -- Depending on level set health percent
                    local newHealth = max
                    if dhLevel == 1 or dhLevel == 2 then newHealth = math.floor(max * 0.5) end
                    if dhLevel == 3 or dhLevel == 4 then newHealth = math.floor(max * 0.7) end
                    if dhLevel == 5 then newHealth = math.floor(max * 0.8) end

                    playerData:set_field("_r_Vital", math.min(max, newHealth) + .0)
                    playerData:call("set__vital", math.min(max, newHealth) + .0)
                end
            end
        end

        if data.health.max_heroics then
            local max = playerData:get_field("_vitalMax")
            local newHealth = math.floor(max * 0.35)

            playerData:set_field("_r_Vital", math.min(max, newHealth) + .0)
            playerData:call("set__vital", math.min(max, newHealth) + .0)
        end

        if data.health.max_adrenaline then
            local max = playerData:get_field("_vitalMax")
            local newHealth = 10.0

            playerData:set_field("_r_Vital", math.min(max, newHealth) + .0)
            playerData:call("set__vital", math.min(max, newHealth) + .0)
        end

        if data.conditions_and_blights.blights.fire then
            playerBase:set_field("_FireLDurationTimer", 0) -- The fire timer
            playerBase:set_field("_FireDamageTimer", 0) -- The fire damage timer
        end

        if data.conditions_and_blights.blights.water then
            playerBase:set_field("_WaterLDurationTimer", 0) -- The water blight timer
        end

        if data.conditions_and_blights.blights.ice then
            playerBase:set_field("_IceLDurationTimer", 0) -- The ice blight timer
        end

        if data.conditions_and_blights.blights.thunder then
            playerBase:set_field("_ThunderLDurationTimer", 0) -- The thunder blight timer
        end

        if data.conditions_and_blights.blights.dragon then
            playerBase:set_field("_DragonLDurationTimer", 0) -- The dragon blight timer
        end

        if data.conditions_and_blights.blights.bubble then
            playerBase:set_field("_BubbleDamageTimer", 0) -- The bubble timer
            -- playerData:set_field("_BubbleType", 0) -- | 0=None | 1=BubbleS | 2=BubbleL |
        end

        if data.conditions_and_blights.blights.blast then
            playerBase:set_field("_BombDurationTimer", 0) -- The blast timer
        end

        if data.conditions_and_blights.conditions.bleeding then
            playerBase:set_field("_BleedingDebuffTimer", 0) -- The bleeding timer
        end

        if data.conditions_and_blights.conditions.stun then
            playerBase:set_field("_StunDurationTimer", 0) -- The stun timer
        end

        if data.conditions_and_blights.conditions.poison then
            playerBase:set_field("_PoisonDurationTimer", 0) -- The poison timer
            playerBase:set_field("_PoisonDamageTimer", 0) -- How long till next poison tick
            -- playerData:set_field("_PoisonLv", 0) -- | 0=None | 1=Poison | 2=NoxiousPoison | 3=DeadlyPoison | 
        end

        if data.conditions_and_blights.conditions.sleep then
            playerBase:set_field("_SleepDurationTimer", 0) -- The sleep timer
            playerBase:set_field("<SleepMovableTimer>k__BackingField", 0) -- The sleep walking timer
        end

        if data.conditions_and_blights.conditions.frenzy then
            playerBase:set_field("_IsVirusLatency", false) -- The frenzy virus
            playerBase:set_field("_VirusTimer", 0) -- How long till the next frenzy virus tick
            playerBase:set_field("_VirusAccumulator", 0) -- Total ticks of Frenzy
        end

        if data.conditions_and_blights.conditions.qurio then
            playerBase:set_field("_MysteryDebuffTimer", 0) -- The qurio timer
            playerBase:set_field("_MysteryDebuffDamageTimer", 0) -- The qurio damage timer")
        end

        if data.conditions_and_blights.conditions.defence_and_resistance then
            playerBase:set_field("_ResistanceDownDurationTimer", 0) -- The resistance down timer
            playerBase:set_field("_DefenceDownDurationTimer", 0) -- The defence down timer
        end

        if data.conditions_and_blights.conditions.hellfire_and_stentch then
            playerBase:set_field("_OniBombDurationTimer", 0) -- The hellfire timer
            playerBase:set_field("_StinkDurationTimer", 0) -- The putrid gas damage timer
        end

        if data.stats.attack > -1 then
            -- Set the original attack value
            if data.data.attack_original == nil then data.data.attack_original = playerData:get_field("_Attack") end

            -- Setup variables to determine how much extra attack needs to be added to get to the set value
            local attack = data.data.attack_original
            local attackTarget = data.stats.attack
            local attackMod = attackTarget - attack

            -- Add the extra attack
            playerData:set_field("_AtkUpAlive", attackMod)

            -- Restore the original attack value if disabled    
        elseif data.data.attack_original ~= nil then
            playerData:set_field("_AtkUpAlive", 0)
            data.data.attack_original = nil
        end

        if data.stats.defence > -1 then
            -- Set the original defence value
            if data.data.defence_original == nil then data.data.defence_original = playerData:get_field("_Defence") end

            -- Setup variables to determine how much extra defence needs to be added to get to the set value
            local defence = data.data.defence_original
            local defenceTarget = data.stats.defence
            local defenceMod = defenceTarget - defence

            -- Add the extra defence
            playerData:set_field("_DefUpAlive", defenceMod)

            -- Restore the original defence value if disabled    
        elseif data.data.defence_original ~= nil then
            playerData:set_field("_DefUpAlive", 0)
            data.data.defence_original = nil
        end
    end)
    utils.nothing()
end

function data.draw()

    local changed, any_changed = false, false
    changed, data.unlimited_stamina = imgui.checkbox("Unlimited Stamina", data.unlimited_stamina)
    any_changed = any_changed or changed
    if imgui.tree_node("Health Options") then
        changed, data.health.healing = imgui.checkbox("Constant Healing", data.health.healing)
        any_changed = any_changed or changed
        utils.tooltip("Any missing health will become recoverable.")
        changed, data.health.insta_healing = imgui.checkbox("Instant Healing", data.health.insta_healing)
        any_changed = any_changed or changed
        utils.tooltip("When you take damage, you will instantly heal back to full health.")
        changed, data.health.max_dragonheart = imgui.checkbox("Max Dragonheart Health", data.health.max_dragonheart)
        any_changed = any_changed or changed
        utils.tooltip("Will adjust health depending on the level of Dragonheart.")
        changed, data.health.max_heroics = imgui.checkbox("Max Heroics Health", data.health.max_heroics)
        any_changed = any_changed or changed
        changed, data.health.max_adrenaline = imgui.checkbox("Max Adrenaline Health", data.health.max_adrenaline)
        any_changed = any_changed or changed
        imgui.tree_pop()
    end
    if imgui.tree_node("Conditions, Ailments, & Blights") then
        if imgui.tree_node("Prevent Blights") then
            changed, data.conditions_and_blights.blights.fire = imgui.checkbox("Fire", data.conditions_and_blights.blights.fire)
            any_changed = any_changed or changed
            changed, data.conditions_and_blights.blights.water = imgui.checkbox("Water", data.conditions_and_blights.blights.water)
            any_changed = any_changed or changed
            changed, data.conditions_and_blights.blights.ice = imgui.checkbox("Ice", data.conditions_and_blights.blights.ice)
            any_changed = any_changed or changed
            changed, data.conditions_and_blights.blights.thunder = imgui.checkbox("Thunder", data.conditions_and_blights.blights.thunder)
            any_changed = any_changed or changed
            changed, data.conditions_and_blights.blights.dragon = imgui.checkbox("Dragon", data.conditions_and_blights.blights.dragon)
            any_changed = any_changed or changed
            changed, data.conditions_and_blights.blights.bubble = imgui.checkbox("Bubble", data.conditions_and_blights.blights.bubble)
            any_changed = any_changed or changed
            changed, data.conditions_and_blights.blights.blast = imgui.checkbox("Blast", data.conditions_and_blights.blights.blast)
            any_changed = any_changed or changed
            imgui.tree_pop()
        end
        if imgui.tree_node("Prevent Conditions") then
            changed, data.conditions_and_blights.conditions.bleeding = imgui.checkbox("Bleeding", data.conditions_and_blights.conditions.bleeding)
            any_changed = any_changed or changed
            changed, data.conditions_and_blights.conditions.stun = imgui.checkbox("Stun", data.conditions_and_blights.conditions.stun)
            any_changed = any_changed or changed
            changed, data.conditions_and_blights.conditions.poison = imgui.checkbox("Poison", data.conditions_and_blights.conditions.poison)
            any_changed = any_changed or changed
            changed, data.conditions_and_blights.conditions.sleep = imgui.checkbox("Sleep", data.conditions_and_blights.conditions.sleep)
            any_changed = any_changed or changed
            changed, data.conditions_and_blights.conditions.frenzy = imgui.checkbox("Frenzy", data.conditions_and_blights.conditions.frenzy)
            any_changed = any_changed or changed
            changed, data.conditions_and_blights.conditions.qurio = imgui.checkbox("Qurio", data.conditions_and_blights.conditions.qurio)
            any_changed = any_changed or changed
            changed, data.conditions_and_blights.conditions.defence_and_resistance = imgui.checkbox("Defence & Resistance",
                                                                                                    data.conditions_and_blights.conditions.defence_and_resistance)
            any_changed = any_changed or changed
            changed, data.conditions_and_blights.conditions.hellfire_and_stentch = imgui.checkbox("Hellfire & Stench", data.conditions_and_blights.conditions.hellfire_and_stentch)
            any_changed = any_changed or changed
            imgui.tree_pop()
        end
        imgui.text("Still working on Paralyze and Web")
        imgui.tree_pop()
    end
    if imgui.tree_node("Stat Modifiers") then
        local step = 10
        local attack_max, defence_max = 2600, 3100
        local stepped_attack_max, stepped_defence_max = math.floor(attack_max / step), math.floor(defence_max / step)
        local stepped_attack_value, stepped_defence_value = -1, -1
        if data.stats.attack > -1 then stepped_attack_value = math.floor(data.stats.attack / step) end
        if data.stats.defence > -1 then stepped_defence_value = math.floor(data.stats.defence / step) end
        local attack_slider, defence_slider
        changed, attack_slider = imgui.slider_int("Attack", stepped_attack_value, -1, stepped_attack_max, stepped_attack_value > -1 and stepped_attack_value * step or "Off")
        any_changed = any_changed or changed
        utils.tooltip("Drag slider to the left to reset if the stat break")
        changed, defence_slider = imgui.slider_int("Defence", stepped_defence_value, -1, stepped_defence_max, stepped_defence_value > -1 and stepped_defence_value * step or "Off")
        any_changed = any_changed or changed
        utils.tooltip("Drag slider to the left to reset if the stat break")
        data.stats.attack = attack_slider > -1 and attack_slider * step or -1
        data.stats.defence = defence_slider > -1 and defence_slider * step or -1
        imgui.tree_pop()

    end
    if any_changed then config.save_section(data.create_config_section()) end
end

function data.reset()
    -- Until I find a better way of increase attack, I have to reset this on script reset
    if data.stats.attack > -1 then
        local playerData = utils.getPlayerData()
        if not playerData then return end
        playerData:set_field("_AtkUpAlive", 0)
    end

    -- Until I find a better way of increase defence, I have to reset this on script reset
    if data.stats.defence > -1 then
        local playerData = utils.getPlayerData()
        if not playerData then return end
        playerData:set_field("_DefUpAlive", 0)
    end
end

function data.create_config_section()
    return {
        [data.title] = {
            unlimited_stamina = data.unlimited_stamina,
            health = {
                healing = data.health.healing,
                insta_healing = data.health.insta_healing,
                max_dragonheart = data.health.max_dragonheart,
                max_heroics = data.health.max_heroics,
                max_adrenaline = data.health.max_adrenaline

            },
            conditions_and_blights = {
                blights = {
                    fire = data.conditions_and_blights.blights.fire,
                    water = data.conditions_and_blights.blights.water,
                    ice = data.conditions_and_blights.blights.ice,
                    thunder = data.conditions_and_blights.blights.thunder,
                    dragon = data.conditions_and_blights.blights.dragon,
                    bubble = data.conditions_and_blights.blights.bubble,
                    blast = data.conditions_and_blights.blights.blast
                },
                conditions = {
                    bleeding = data.conditions_and_blights.conditions.bleeding,
                    stun = data.conditions_and_blights.conditions.stun,
                    poison = data.conditions_and_blights.conditions.poison,
                    sleep = data.conditions_and_blights.conditions.sleep,
                    frenzy = data.conditions_and_blights.conditions.frenzy,
                    qurio = data.conditions_and_blights.conditions.qurio,
                    defence_and_resistance = data.conditions_and_blights.conditions.defence_and_resistance,
                    hellfire_and_stentch = data.conditions_and_blights.conditions.hellfire_and_stentch
                }
            },
            stats = {
                attack = data.stats.attack,
                defence = data.stats.defence
            }
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.unlimited_stamina = config_section.unlimited_stamina or data.unlimited_stamina
    data.health = config_section.health or data.health
    data.conditions_and_blights = config_section.conditions_and_blights or data.conditions_and_blights
    data.stats = config_section.stats or data.stats
end

return data
