local utils, config, language
local data = {
    title = "character",
    sharpness_level = -1,
    unlimited_stamina = false,
    hyper_armor = false,
    super_armor = false,
    skills = {
        intrepid_heart = false,
        frost_craft = false
    },
    health = {
        healing = false,
        insta_healing = false,
        max_dragonheart = false,
        max_heroics = false,
        max_adrenaline = false
    },
    ammo_and_coatings = {
        unlimited_ammo = false,
        unlimited_coatings = false,
        auto_reload = false, -- Drawn here, but no hook
        no_deviation = false,
        no_recoil = false
    },
    conditions_and_blights = {
        blights = {
            fire = false,
            water = false,
            ice = false,
            thunder = false,
            dragon = false,
            bubble = false,
            blast = false,
            all = false
        },
        conditions = {
            bleeding = false,
            stun = false,
            poison = false,
            sleep = false,
            frenzy = false,
            qurio = false,
            defence_and_resistance = false,
            hellfire_and_stentch = false,
            paralyze = false,
            thread = false,
            all = false
        }
    },
    stats = {
        attack = -1,
        defence = -1,
        affinity = -1,
        element = {
            type = -1,
            value = -1
        }
    },
    hidden = {
        sharpness_level_old = -1
    }
}

function data.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    data.init_hooks()
end

function data.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.player.PlayerManager") then return end

        local playerBase = utils.getPlayerBase()
        if not playerBase then return end
        local playerData = utils.getPlayerData()
        if not playerData then return end
        local is_in_lobby = playerBase:get_field("<IsLobbyPlayer>k__BackingField")
        
        if data.sharpness_level > -1 then
            if data.hidden.sharpness_level_old == -1 then data.hidden.sharpness_level_old = playerBase:get_field("<SharpnessLv>k__BackingField") end
            -- | 0=Red | 1=Orange | 2=Yellow | 3=Green | 4=Blue | 5=White | 6=Purple |
            playerBase:set_field("<SharpnessLv>k__BackingField", data.sharpness_level) -- Sharpness Level of Purple
            -- playerBase:set_field("<SharpnessGauge>k__BackingField", 400) -- Sharpness Value
            -- playerBase:set_field("<SharpnessGaugeMax>k__BackingField", 400) -- Max Sharpness
        elseif data.sharpness_level == -1 and data.hidden.sharpness_level_old > -1 then
            playerBase:set_field("<SharpnessLv>k__BackingField", data.hidden.sharpness_level_old)
            data.hidden.sharpness_level_old = -1
        end

        if data.unlimited_stamina then
            local maxStamina = playerData:get_field("_staminaMax")
            playerData:set_field("_stamina", maxStamina)
        end

        if data.hyper_armor and not is_in_lobby then
            playerBase:set_field("_HyperArmorTimer", 500)
        end
        if data.super_armor and not is_in_lobby then
            playerBase:set_field("_SuperArmorTimer", 500)
        end

        if data.skills.intrepid_heart and not is_in_lobby then
            playerData:set_field("_EquipSkill223Accumulator", 400) -- Intrepid Heart
        end

        if data.skills.frost_craft and not is_in_lobby then
            playerBase:set_field("_EquipSkill228Accumulator", 100) -- Frostcraft
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
                    local currentHealth = playerData:get_field("_r_Vital")
                    if dhLevel == 1 or dhLevel == 2 then newHealth = math.floor(max * 0.5) end
                    if dhLevel == 3 or dhLevel == 4 then newHealth = math.floor(max * 0.7) end
                    if dhLevel == 5 then newHealth = math.floor(max * 0.8) end

                    if currentHealth > newHealth then
                        playerData:set_field("_r_Vital", math.min(currentHealth, newHealth) + .0)
                        playerData:call("set__vital", math.min(currentHealth, newHealth) + .0)
                    end
                end
            end
        end

        if data.health.max_heroics then
            local max = playerData:get_field("_vitalMax")
            local currentHealth = playerData:get_field("_r_Vital")
            local newHealth = Math.floor(max * 0.35)
            
            if currentHealth > newHealth then
                playerData:set_field("_r_Vital", math.min(max, newHealth) + .0)
                playerData:call("set__vital", math.min(max, newHealth) + .0)
            end
        end

        if data.health.max_adrenaline then
            local max = playerData:get_field("_vitalMax")
            local currentHealth = playerData:get_field("_r_Vital")
            local newHealth = 10.0

            if currentHealth > newHealth then
                playerData:set_field("_r_Vital", math.min(max, newHealth) + .0)
                playerData:call("set__vital", math.min(max, newHealth) + .0)
            end
        end
        

        if (data.conditions_and_blights.blights.fire or data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_FireLDurationTimer", 0) -- The fire timer
            playerBase:set_field("_FireDamageTimer", 0) -- The fire damage timer
        end

        if (data.conditions_and_blights.blights.water or data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_WaterLDurationTimer", 0) -- The water blight timer
        end

        if (data.conditions_and_blights.blights.ice or data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_IceLDurationTimer", 0) -- The ice blight timer
        end

        if (data.conditions_and_blights.blights.thunder or data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_ThunderLDurationTimer", 0) -- The thunder blight timer
        end

        if (data.conditions_and_blights.blights.dragon or data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_DragonLDurationTimer", 0) -- The dragon blight timer
        end

        if (data.conditions_and_blights.blights.bubble or data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_BubbleDamageTimer", 0) -- The bubble timer
            -- playerData:set_field("_BubbleType", 0) -- | 0=None | 1=BubbleS | 2=BubbleL |
        end

        if (data.conditions_and_blights.blights.blast or data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_BombDurationTimer", 0) -- The blast timer
        end

        if (data.conditions_and_blights.conditions.bleeding or data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_BleedingDebuffTimer", 0) -- The bleeding timer
        end

        if (data.conditions_and_blights.conditions.poison or data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_PoisonDurationTimer", 0) -- The poison timer
            playerBase:set_field("_PoisonDamageTimer", 0) -- How long till next poison tick
            -- playerData:set_field("_PoisonLv", 0) -- | 0=None | 1=Poison | 2=NoxiousPoison | 3=DeadlyPoison | 
        end

        if (data.conditions_and_blights.conditions.stun or data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_StunDurationTimer", 0) -- The stun timer -- DOESN'T REMOVE ANIMATION TIME
        end

        if (data.conditions_and_blights.conditions.sleep or data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_SleepDurationTimer", 0) -- The sleep timer
            playerBase:set_field("<SleepMovableTimer>k__BackingField", 0) -- The sleep walking timer
        end

        if (data.conditions_and_blights.conditions.paralyze or data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_ParalyzeDurationTimer", 0) -- The paralysis recovery timer -- DOESN'T REMOVE ANIMATION TIME
        end

        if (data.conditions_and_blights.conditions.frenzy or data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_IsVirusLatency", false) -- The frenzy virus
            playerBase:set_field("_VirusTimer", 0) -- How long till the next frenzy virus tick
            playerBase:set_field("_VirusAccumulator", 0) -- Total ticks of Frenzy
        end

        if (data.conditions_and_blights.conditions.qurio or data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_MysteryDebuffTimer", 0) -- The qurio timer
            playerBase:set_field("_MysteryDebuffDamageTimer", 0) -- The qurio damage timer")
        end

        if (data.conditions_and_blights.conditions.defence_and_resistance or data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_ResistanceDownDurationTimer", 0) -- The resistance down timer
            playerBase:set_field("_DefenceDownDurationTimer", 0) -- The defence down timer
        end

        if (data.conditions_and_blights.conditions.hellfire_and_stentch or data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_OniBombDurationTimer", 0) -- The hellfire timer
            playerBase:set_field("_StinkDurationTimer", 0) -- The putrid gas damage timer
        end
        if (data.conditions_and_blights.conditions.thread or data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_BetoDurationTimer", 0) -- The covered in spider web recovery timer -- DOESN'T REMOVE ANIMATION TIME
        end

        if data.stats.attack > -1 then
            -- Set the original attack value
            if data.hidden.attack == nil then data.hidden.attack = playerData:get_field("_Attack") end

            -- Setup variables to determine how much extra attack needs to be added to get to the set value
            local attack = data.hidden.attack
            local attackTarget = data.stats.attack
            local attackMod = attackTarget - attack

            -- Add the extra attack
            playerData:set_field("_AtkUpAlive", attackMod)

            -- Restore the original attack value if disabled    
        elseif data.hidden.attack ~= nil then
            playerData:set_field("_AtkUpAlive", 0)
            data.hidden.attack = nil
        end

        if data.stats.defence > -1 then
            -- Set the original defence value
            if data.hidden.defence == nil then data.hidden.defence = playerData:get_field("_Defence") end

            -- Setup variables to determine how much extra defence needs to be added to get to the set value
            local defence = data.hidden.defence
            local defenceTarget = data.stats.defence
            local defenceMod = defenceTarget - defence

            -- Add the extra defence
            playerData:set_field("_DefUpAlive", defenceMod)
            -- Restore the original defence value if disabled    
        elseif data.hidden.defence ~= nil then
            playerData:set_field("_DefUpAlive", 0)
            data.hidden.defence = nil
        end
    end, utils.nothing())

    local managed_crit = nil
    -- snow.player.HeavyBowgun > RefWeaponData > > > LocalBaseData > > > _WeaponBaseData
    sdk.hook(sdk.find_type_definition("snow.equip.MainWeaponBaseData"):get_method("get_CriticalRate"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_type_definition():is_a("snow.equip.MainWeaponBaseData") then return end
        managed_crit = managed
    end, function(retval)
        if managed_crit ~= nil then
            if data.stats.affinity > -1 then
                if data.hidden.affinity == nil then data.hidden.affinity = utils.getPlayerData():get_field("_CriticalRate") end
                local player = data.hidden.affinity
                local weapon = managed_crit:get_field("_CriticalRate")
                local target = data.stats.affinity
                local to_set = target - player + weapon
                managed_crit = nil
                return sdk.to_ptr(to_set)
            else
                if data.hidden.affinity ~= nil then data.hidden.affinity = nil end
            end
            managed_crit = nil
        end
        return retval
    end)

    local managed_element_type = nil
    -- snow.player.HeavyBowgun > RefWeaponData > > > LocalBaseData > > > _WeaponBaseData
    sdk.hook(sdk.find_type_definition("snow.data.ElementData"):get_method("get_Element"), function(args)
        if data.stats.element.type == -1 then return end
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_type_definition():is_a("snow.data.ElementData") then return end
        managed_element_type = managed
    end, function(retval)
        if managed_element_type ~= nil then
            if data.stats.element.type > -1 then
                managed_element_type = nil
                return sdk.to_ptr(data.stats.element.type)
            end
            managed_element_type = nil
        end
        return retval
    end)

    local managed_element_value = nil
    -- snow.player.HeavyBowgun > RefWeaponData > > > LocalBaseData > > > _WeaponBaseData
    sdk.hook(sdk.find_type_definition("snow.data.ElementData"):get_method("get_ElementVal"), function(args)
        if data.stats.element.value == -1 then return end
            local managed = sdk.to_managed_object(args[2])
            if not managed then return end
            if not managed:get_type_definition():is_a("snow.data.ElementData") then return end
            managed_element_value = managed
    end, function(retval)
        if managed_element_value ~= nil then
            if data.stats.element.value > -1 then
                managed_element_value = nil
                return sdk.to_ptr(data.stats.element.value)
            end
            managed_element_value = nil
        end
        return retval
    end)
    
    sdk.hook(sdk.find_type_definition("snow.data.bulletSlider.BottleSliderFunc"):get_method("consumeItem"), function(args)
        if data.ammo_and_coatings.unlimited_coatings then return sdk.PreHookResult.SKIP_ORIGINAL end
    end, utils.nothing())

    sdk.hook(sdk.find_type_definition("snow.data.bulletSlider.BulletSliderFunc"):get_method("consumeItem"), function(args)
        if data.ammo_and_coatings.unlimited_ammo then return sdk.PreHookResult.SKIP_ORIGINAL end
    end, utils.nothing())

    local managed_fluctuation = nil
    sdk.hook(sdk.find_type_definition("snow.data.BulletWeaponData"):get_method("get_Fluctuation"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_type_definition():is_a("snow.data.BulletWeaponData") then return end
        managed_fluctuation = true
    end, function(retval)
        if managed_fluctuation ~= nil then
            managed_fluctuation = nil
            if data.ammo_and_coatings.no_deviation then return 0 end
        end
        return retval
    end)

    local managed_recoil = nil
    sdk.hook(sdk.find_type_definition("snow.data.BulletWeaponData"):get_method("getRecoil"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_type_definition():is_a("snow.data.BulletWeaponData") then return end
        managed_recoil = true
    end, function(retval)
        if managed_recoil ~= nil then
            managed_recoil = nil
            if data.ammo_and_coatings.no_recoil then 
                return sdk.to_ptr(6)
            end
        end
        return retval
    end)

end

function data.draw()

    local changed, any_changed = false, false
    local languagePrefix = data.title .. "."
    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

        languagePrefix = data.title .. ".sharpness_levels."
        local sharpness_display = {language.get(languagePrefix .. "disabled"), language.get(languagePrefix .. "red"), language.get(languagePrefix .. "orange"),
                                   language.get(languagePrefix .. "yellow"), language.get(languagePrefix .. "green"), language.get(languagePrefix .. "blue"),
                                   language.get(languagePrefix .. "white"), language.get(languagePrefix .. "purple")}

        local languagePrefix = data.title .. "."
        changed, data.sharpness_level =
            imgui.slider_int(language.get(languagePrefix .. "sharpness_level"), data.sharpness_level, -1, 6, sharpness_display[data.sharpness_level + 2])
        utils.tooltip(language.get(languagePrefix .. "sharpness_level_tooltip"))
        any_changed = any_changed or changed
        changed, data.unlimited_stamina = imgui.checkbox(language.get(languagePrefix .. "unlimited_stamina"), data.unlimited_stamina)
        any_changed = any_changed or changed
        changed, data.super_armor = imgui.checkbox(language.get(languagePrefix .. "super_armor"), data.super_armor)
        any_changed = any_changed or changed
        changed, data.hyper_armor = imgui.checkbox(language.get(languagePrefix .. "hyper_armor"), data.hyper_armor)
        any_changed = any_changed or changed
        
        languagePrefix = data.title .. ".skills."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then        
            changed, data.skills.frost_craft = imgui.checkbox(language.get(languagePrefix .. "frost_craft"), data.skills.frost_craft)
            any_changed = any_changed or changed
            changed, data.skills.intrepid_heart = imgui.checkbox(language.get(languagePrefix .. "intrepid_heart"), data.skills.intrepid_heart)
            any_changed = any_changed or changed
            imgui.tree_pop()
        end
        languagePrefix = data.title .. ".health."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then
            changed, data.health.healing = imgui.checkbox(language.get(languagePrefix .. "healing"), data.health.healing)
            any_changed = any_changed or changed
            utils.tooltip(language.get(languagePrefix .. "healing_tooltip"))
            changed, data.health.insta_healing = imgui.checkbox(language.get(languagePrefix .. "insta_healing"), data.health.insta_healing)
            any_changed = any_changed or changed
            utils.tooltip(language.get(languagePrefix .. "insta_healing_tooltip"))
            changed, data.health.max_dragonheart = imgui.checkbox(language.get(languagePrefix .. "max_dragonheart"), data.health.max_dragonheart)
            any_changed = any_changed or changed
            utils.tooltip(language.get(languagePrefix .. "max_dragonheart_tooltip"))
            changed, data.health.max_heroics = imgui.checkbox(language.get(languagePrefix .. "max_heroics"), data.health.max_heroics)
            any_changed = any_changed or changed
            changed, data.health.max_adrenaline = imgui.checkbox(language.get(languagePrefix .. "max_adrenaline"), data.health.max_adrenaline)
            any_changed = any_changed or changed
            imgui.tree_pop()
        end
        languagePrefix = data.title .. ".ammo_and_coatings."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then
            changed, data.ammo_and_coatings.unlimited_coatings = imgui.checkbox(language.get(languagePrefix .. "unlimited_coatings"), data.ammo_and_coatings.unlimited_coatings)
            any_changed = any_changed or changed
            changed, data.ammo_and_coatings.unlimited_ammo = imgui.checkbox(language.get(languagePrefix .. "unlimited_ammo"), data.ammo_and_coatings.unlimited_ammo)
            any_changed = any_changed or changed
            changed, data.ammo_and_coatings.auto_reload = imgui.checkbox(language.get(languagePrefix .. "auto_reload"), data.ammo_and_coatings.auto_reload)
            any_changed = any_changed or changed
            changed, data.ammo_and_coatings.no_deviation = imgui.checkbox(language.get(languagePrefix .. "no_deviation"), data.ammo_and_coatings.no_deviation)
            any_changed = any_changed or changed
            changed, data.ammo_and_coatings.no_recoil = imgui.checkbox(language.get(languagePrefix .. "no_recoil"), data.ammo_and_coatings.no_recoil)
            any_changed = any_changed or changed
            imgui.tree_pop()
        end
        languagePrefix = data.title .. ".conditions_and_blights."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then

            languagePrefix = data.title .. ".conditions_and_blights.blights."
            if imgui.tree_node(language.get(languagePrefix .. "title")) then
                changed, data.conditions_and_blights.blights.fire = imgui.checkbox(language.get(languagePrefix .. "fire"), data.conditions_and_blights.blights.fire)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.blights.water = imgui.checkbox(language.get(languagePrefix .. "water"), data.conditions_and_blights.blights.water)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.blights.ice = imgui.checkbox(language.get(languagePrefix .. "ice"), data.conditions_and_blights.blights.ice)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.blights.thunder = imgui.checkbox(language.get(languagePrefix .. "thunder"), data.conditions_and_blights.blights.thunder)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.blights.dragon = imgui.checkbox(language.get(languagePrefix .. "dragon"), data.conditions_and_blights.blights.dragon)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.blights.bubble = imgui.checkbox(language.get(languagePrefix .. "bubble"), data.conditions_and_blights.blights.bubble)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.blights.blast = imgui.checkbox(language.get(languagePrefix .. "blast"), data.conditions_and_blights.blights.blast)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.blights.all = imgui.checkbox(language.get(languagePrefix .. "all"), data.conditions_and_blights.blights.all)
                any_changed = any_changed or changed
                imgui.tree_pop()
            end
            languagePrefix = data.title .. ".conditions_and_blights.conditions."
            if imgui.tree_node(language.get(languagePrefix .. "title")) then
                changed, data.conditions_and_blights.conditions.bleeding = imgui.checkbox(language.get(languagePrefix .. "bleeding"),
                                                                                          data.conditions_and_blights.conditions.bleeding)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.conditions.stun = imgui.checkbox(language.get(languagePrefix .. "stun"), data.conditions_and_blights.conditions.stun)
                utils.tooltip(language.get(languagePrefix .. "stun_tooltip"))
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.conditions.poison = imgui.checkbox(language.get(languagePrefix .. "poison"), data.conditions_and_blights.conditions.poison)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.conditions.sleep = imgui.checkbox(language.get(languagePrefix .. "sleep"), data.conditions_and_blights.conditions.sleep)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.conditions.frenzy = imgui.checkbox(language.get(languagePrefix .. "frenzy"), data.conditions_and_blights.conditions.frenzy)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.conditions.qurio = imgui.checkbox(language.get(languagePrefix .. "qurio"), data.conditions_and_blights.conditions.qurio)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.conditions.defence_and_resistance = imgui.checkbox(language.get(languagePrefix .. "defence_and_resistance"),
                                                                                                        data.conditions_and_blights.conditions.defence_and_resistance)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.conditions.hellfire_and_stentch = imgui.checkbox(language.get(languagePrefix .. "hellfire_and_stentch"),
                                                                                                      data.conditions_and_blights.conditions.hellfire_and_stentch)
                any_changed = any_changed or changed
                changed, data.conditions_and_blights.conditions.paralyze = imgui.checkbox(language.get(languagePrefix .. "paralyze"),
                                                                                          data.conditions_and_blights.conditions.paralyze)
                utils.tooltip(language.get(languagePrefix .. "paralyze_tooltip"))
                
                changed, data.conditions_and_blights.conditions.thread = imgui.checkbox(language.get(languagePrefix .. "thread"), data.conditions_and_blights.conditions.thread)
                utils.tooltip(language.get(languagePrefix .. "thread_tooltip"))
                any_changed = any_changed or changed

                changed, data.conditions_and_blights.conditions.all = imgui.checkbox(language.get(languagePrefix .. "all"), data.conditions_and_blights.conditions.all)
                any_changed = any_changed or changed
                imgui.tree_pop()
            end
            imgui.tree_pop()
        end
        languagePrefix = data.title .. ".stats."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then
            utils.tooltip(language.get(languagePrefix .. "tooltip"))
            local step = 10
            local attack_max, defence_max = 2600, 4500
            local stepped_attack_max, stepped_defence_max = math.floor(attack_max / step), math.floor(defence_max / step)
            local stepped_attack_value, stepped_defence_value = -1, -1
            if data.stats.attack > -1 then stepped_attack_value = math.floor(data.stats.attack / step) end
            if data.stats.defence > -1 then stepped_defence_value = math.floor(data.stats.defence / step) end
            local attack_slider, defence_slider
            changed, attack_slider = imgui.slider_int(language.get(languagePrefix .. "attack"), stepped_attack_value, -1, stepped_attack_max,
                                                      stepped_attack_value > -1 and stepped_attack_value * step or language.get(languagePrefix .. "attack_disabled"))
            any_changed = any_changed or changed
            changed, defence_slider = imgui.slider_int(language.get(languagePrefix .. "defence"), stepped_defence_value, -1, stepped_defence_max,
                                                       stepped_defence_value > -1 and stepped_defence_value * step or language.get(languagePrefix .. "attack_disabled"))
            any_changed = any_changed or changed
            data.stats.attack = attack_slider > -1 and attack_slider * step or -1
            data.stats.defence = defence_slider > -1 and defence_slider * step or -1

            changed, data.stats.affinity = imgui.slider_int(language.get(languagePrefix .. "affinity"), data.stats.affinity, -1, 100,
                                                            data.stats.affinity > -1 and " %d" .. '%%' or language.get(languagePrefix .. "affinity_disabled"))
            any_changed = any_changed or changed

            languagePrefix = languagePrefix .. "element."
            if imgui.tree_node(language.get(languagePrefix .. "title")) then
                languagePrefix = languagePrefix .. "types."
                local element_display = {language.get(languagePrefix .. "disabled"), language.get(languagePrefix .. "none"), language.get(languagePrefix .. "fire"), language.get(languagePrefix .. "water"),
                                         language.get(languagePrefix .. "thunder"), language.get(languagePrefix .. "ice"), language.get(languagePrefix .. "dragon"),
                                         language.get(languagePrefix .. "poison"), language.get(languagePrefix .. "sleep"), language.get(languagePrefix .. "paralyze"),
                                         language.get(languagePrefix .. "blast")}

                
                languagePrefix = data.title .. ".stats.element."
                local elm_type = data.stats.element.type + 2
                changed, elm_type = imgui.combo(language.get(languagePrefix .. "type"), elm_type, element_display)
                data.stats.element.type = elm_type - 2
                any_changed = any_changed or changed
                changed, data.stats.element.value = imgui.slider_int(language.get(languagePrefix .. "value"), data.stats.element.value, -1, 560,
                data.stats.element.value > -1 and " %d" or language.get(languagePrefix .. "disabled"))
                any_changed = any_changed or changed
            end
            imgui.tree_pop()
        end

        if any_changed then config.save_section(data.create_config_section()) end
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end
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
            sharpness_level = data.sharpness_level,
            unlimited_stamina = data.unlimited_stamina,
            super_armor = data.super_armor,
            hyper_armor = data.hyper_armor,
            skills = data.skills,
            health = data.health,
            ammo_and_coatings = data.ammo_and_coatings,
            conditions_and_blights = data.conditions_and_blights
        }
    }
end

function data.load_from_config(config_section)
    if not config_section then return end
    data.sharpness_level = config_section.sharpness_level or data.sharpness_level
    data.unlimited_stamina = config_section.unlimited_stamina or data.unlimited_stamina
    data.super_armor = config_section.super_armor or data.super_armor
    data.hyper_armor = config_section.hyper_armor or data.hyper_armor
    data.skills = config_section.skills or data.skills
    data.health = config_section.health or data.health
    data.ammo_and_coatings = config_section.ammo_and_coatings or data.ammo_and_coatings
    data.conditions_and_blights = config_section.conditions_and_blights or data.conditions_and_blights
end

return data
