local ModuleBase = require("Buffer.Misc.ModuleBase")
local Utils = require("Buffer.Misc.Utils")
local Language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("character", {
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
    }
})

function Module.create_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("snow.player.PlayerManager") then return end

        local playerBase = Utils.getMasterPlayer()
        if not playerBase then return end
        local playerData = Utils.getPlayerData()
        if not playerData then return end
        local is_in_lobby = playerBase:get_field("<IsLobbyPlayer>k__BackingField")
        
        -- | 0=Red | 1=Orange | 2=Yellow | 3=Green | 4=Blue | 5=White | 6=Purple |
        Module:cache_and_update_field("sharpness_level", playerBase, "<SharpnessLv>k__BackingField", Module.data.sharpness_level)

        if Module.data.unlimited_stamina then
            local maxStamina = playerData:get_field("_staminaMax")
            playerData:set_field("_stamina", maxStamina)
        end

        if Module.data.hyper_armor and not is_in_lobby then
            playerBase:set_field("_HyperArmorTimer", 500)
        end
        if Module.data.super_armor and not is_in_lobby then
            playerBase:set_field("_SuperArmorTimer", 500)
        end

        if Module.data.skills.intrepid_heart and not is_in_lobby then
            playerData:set_field("_EquipSkill223Accumulator", 400) -- Intrepid Heart
        end

        if Module.data.skills.frost_craft and not is_in_lobby then
            playerBase:set_field("_EquipSkill228Accumulator", 100) -- Frostcraft
        end

        if Module.data.health.healing then
            local max = playerData:get_field("_vitalMax")
            playerData:set_field("_r_Vital", max)
        end
        

        if Module.data.health.insta_healing then
            local max = playerData:get_field("_vitalMax")

            local maxFloat = max + .0
            playerData:set_field("_r_Vital", max)
            playerData:call("set__vital", maxFloat)
        end

        if Module.data.health.max_dragonheart then
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

                    newHealth = newHealth-1 -- Lower new health by one to prevent Kushala Bless/SuperRecDango from activating/deactivating

                    if currentHealth > newHealth then
                        playerData:set_field("_r_Vital", math.min(currentHealth, newHealth) + .0)
                        playerData:call("set__vital", math.min(currentHealth, newHealth) + .0)
                    end
                end
            end
        end

        if Module.data.health.max_heroics then
            local max = playerData:get_field("_vitalMax")
            local currentHealth = playerData:get_field("_r_Vital")
            local newHealth = math.floor(max * 0.35)
            
            if currentHealth > newHealth then
                playerData:set_field("_r_Vital", math.min(max, newHealth) + .0)
                playerData:call("set__vital", math.min(max, newHealth) + .0)
            end
        end

        if Module.data.health.max_adrenaline then
            local max = playerData:get_field("_vitalMax")
            local currentHealth = playerData:get_field("_r_Vital")
            local newHealth = 10.0

            if currentHealth > newHealth then
                playerData:set_field("_r_Vital", math.min(max, newHealth) + .0)
                playerData:call("set__vital", math.min(max, newHealth) + .0)
            end
        end
        

        if (Module.data.conditions_and_blights.blights.fire or Module.data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_FireLDurationTimer", 0) -- The fire timer
            playerBase:set_field("_FireDamageTimer", 0) -- The fire damage timer
        end

        if (Module.data.conditions_and_blights.blights.water or Module.data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_WaterLDurationTimer", 0) -- The water blight timer
        end

        if (Module.data.conditions_and_blights.blights.ice or Module.data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_IceLDurationTimer", 0) -- The ice blight timer
        end

        if (Module.data.conditions_and_blights.blights.thunder or Module.data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_ThunderLDurationTimer", 0) -- The thunder blight timer
        end

        if (Module.data.conditions_and_blights.blights.dragon or Module.data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_DragonLDurationTimer", 0) -- The dragon blight timer
        end

        if (Module.data.conditions_and_blights.blights.bubble or Module.data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_BubbleDamageTimer", 0) -- The bubble timer
            -- playerData:set_field("_BubbleType", 0) -- | 0=None | 1=BubbleS | 2=BubbleL |
        end

        if (Module.data.conditions_and_blights.blights.blast or Module.data.conditions_and_blights.blights.all) and not is_in_lobby then
            playerBase:set_field("_BombDurationTimer", 0) -- The blast timer
        end

        if (Module.data.conditions_and_blights.conditions.bleeding or Module.data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_BleedingDebuffTimer", 0) -- The bleeding timer
        end

        if (Module.data.conditions_and_blights.conditions.poison or Module.data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_PoisonDurationTimer", 0) -- The poison timer
            playerBase:set_field("_PoisonDamageTimer", 0) -- How long till next poison tick
            -- playerData:set_field("_PoisonLv", 0) -- | 0=None | 1=Poison | 2=NoxiousPoison | 3=DeadlyPoison | 
        end

        if (Module.data.conditions_and_blights.conditions.stun or Module.data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_StunDurationTimer", 0) -- The stun timer -- DOESN'T REMOVE ANIMATION TIME
        end

        if (Module.data.conditions_and_blights.conditions.sleep or Module.data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_SleepDurationTimer", 0) -- The sleep timer
            playerBase:set_field("<SleepMovableTimer>k__BackingField", 0) -- The sleep walking timer
        end

        if (Module.data.conditions_and_blights.conditions.paralyze or Module.data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_ParalyzeDurationTimer", 0) -- The paralysis recovery timer -- DOESN'T REMOVE ANIMATION TIME
        end

        if (Module.data.conditions_and_blights.conditions.frenzy or Module.data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_IsVirusLatency", false) -- The frenzy virus
            playerBase:set_field("_VirusTimer", 0) -- How long till the next frenzy virus tick
            playerBase:set_field("_VirusAccumulator", 0) -- Total ticks of Frenzy
        end

        if (Module.data.conditions_and_blights.conditions.qurio or Module.data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_MysteryDebuffTimer", 0) -- The qurio timer
            playerBase:set_field("_MysteryDebuffDamageTimer", 0) -- The qurio damage timer")
        end

        if (Module.data.conditions_and_blights.conditions.defence_and_resistance or Module.data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_ResistanceDownDurationTimer", 0) -- The resistance down timer
            playerBase:set_field("_DefenceDownDurationTimer", 0) -- The defence down timer
        end

        if (Module.data.conditions_and_blights.conditions.hellfire_and_stentch or Module.data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_OniBombDurationTimer", 0) -- The hellfire timer
            playerBase:set_field("_StinkDurationTimer", 0) -- The putrid gas damage timer
        end
        if (Module.data.conditions_and_blights.conditions.thread or Module.data.conditions_and_blights.conditions.all) and not is_in_lobby then
            playerBase:set_field("_BetoDurationTimer", 0) -- The covered in spider web recovery timer -- DOESN'T REMOVE ANIMATION TIME
        end

        local attack_mod = -1
        if Module.data.stats.attack > -1 then
            -- Set the original attack value
            if Module.data.hidden.attack == nil then Module.data.hidden.attack = playerData:get_field("_Attack") end

            -- Setup variables to determine how much extra attack needs to be added to get to the set value
            local attack = Module.data.hidden.attack
            local attackTarget = Module.data.stats.attack
            attack_mod = attackTarget - attack
        else
            Module.data.hidden.attack = nil
        end
        Module:cache_and_update_field("attack_modifier", playerData, "_AtkUpAlive", attack_mod)

        local defence_mod = -1
        if Module.data.stats.defence > -1 then
            -- Set the original defence value
            if Module.data.hidden.defence == nil then Module.data.hidden.defence = playerData:get_field("_Defence") end

            -- Setup variables to determine how much extra defence needs to be added to get to the set value
            local defence = Module.data.hidden.defence
            local defenceTarget = Module.data.stats.defence
            defence_mod = defenceTarget - defence
        else
            Module.data.hidden.defence = nil
        end
        Module:cache_and_update_field("defence_modifier", playerData, "_DefUpAlive", defence_mod)
    end)

    -- snow.player.HeavyBowgun > RefWeaponData > > > LocalBaseData > > > _WeaponBaseData
    sdk.hook(sdk.find_type_definition("snow.equip.MainWeaponBaseData"):get_method("get_CriticalRate"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_type_definition():is_a("snow.equip.MainWeaponBaseData") then return end
        
        if Module.data.stats.affinity == -1 then 
            Module.data._last_crit_set = nil
            return 
        end
        thread.get_hook_storage()["managed_crit"] = managed
    end, 
    function(retval)
        if thread.get_hook_storage()["managed_crit"] then
            local managed_crit = thread.get_hook_storage()["managed_crit"]
            local player = Utils.getPlayerData():get_field("_CriticalRate") -- Overall player crit rate (This is what this function returns, so it will be different after being set)
            local weapon = managed_crit:get_field("_CriticalRate") -- Weapon's crit rate (this doesn't change)
            local target = Module.data.stats.affinity -- Target crit rate
            
            local last_set = Module.data._last_crit_set or weapon
            local to_set = target - player + last_set

            Module.data._last_crit_set = to_set
            return sdk.to_ptr(to_set) 
        end
        return retval
    end)

    -- snow.player.HeavyBowgun > RefWeaponData > > > LocalBaseData > > > _WeaponBaseData
    sdk.hook(sdk.find_type_definition("snow.data.ElementData"):get_method("get_Element"), function(args)
        if Module.data.stats.element.type == -1 then return end
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_type_definition():is_a("snow.data.ElementData") then return end
        if Module.data.stats.element.type > -1 then
            thread.get_hook_storage()["managed_element"] = true
        end
    end, function(retval)
        if thread.get_hook_storage()["managed_element"] then
            return sdk.to_ptr(Module.data.stats.element.type)
        end
        return retval
    end)

    -- snow.player.HeavyBowgun > RefWeaponData > > > LocalBaseData > > > _WeaponBaseData
    sdk.hook(sdk.find_type_definition("snow.data.ElementData"):get_method("get_ElementVal"), function(args)
        if Module.data.stats.element.value == -1 then return end
            local managed = sdk.to_managed_object(args[2])
            if not managed then return end
            if not managed:get_type_definition():is_a("snow.data.ElementData") then return end

            if Module.data.stats.element.value > -1 then
                thread.get_hook_storage()["managed_element_value"] = true
            end
    end, function(retval)
        if thread.get_hook_storage()["managed_element_value"] then
            return sdk.to_ptr(Module.data.stats.element.value)
        end
        return retval
    end)

end

function Module.add_ui()

    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    languagePrefix = Module.title .. ".sharpness_levels."
    local sharpness_display = {Language.get(languagePrefix .. "disabled"), Language.get(languagePrefix .. "red"), Language.get(languagePrefix .. "orange"),
                                Language.get(languagePrefix .. "yellow"), Language.get(languagePrefix .. "green"), Language.get(languagePrefix .. "blue"),
                                Language.get(languagePrefix .. "white"), Language.get(languagePrefix .. "purple")}

    local languagePrefix = Module.title .. "."
    changed, Module.data.sharpness_level =
        imgui.slider_int(Language.get(languagePrefix .. "sharpness_level"), Module.data.sharpness_level, -1, 6, sharpness_display[Module.data.sharpness_level + 2])
    Utils.tooltip(Language.get(languagePrefix .. "sharpness_level_tooltip"))
    any_changed = any_changed or changed
    changed, Module.data.unlimited_stamina = imgui.checkbox(Language.get(languagePrefix .. "unlimited_stamina"), Module.data.unlimited_stamina)
    any_changed = any_changed or changed
    changed, Module.data.super_armor = imgui.checkbox(Language.get(languagePrefix .. "super_armor"), Module.data.super_armor)
    any_changed = any_changed or changed
    changed, Module.data.hyper_armor = imgui.checkbox(Language.get(languagePrefix .. "hyper_armor"), Module.data.hyper_armor)
    any_changed = any_changed or changed
    
    languagePrefix = Module.title .. ".skills."
    if imgui.tree_node(Language.get(languagePrefix .. "title")) then        
        changed, Module.data.skills.frost_craft = imgui.checkbox(Language.get(languagePrefix .. "frost_craft"), Module.data.skills.frost_craft)
        any_changed = any_changed or changed
        changed, Module.data.skills.intrepid_heart = imgui.checkbox(Language.get(languagePrefix .. "intrepid_heart"), Module.data.skills.intrepid_heart)
        any_changed = any_changed or changed
        imgui.tree_pop()
    end
    languagePrefix = Module.title .. ".health."
    if imgui.tree_node(Language.get(languagePrefix .. "title")) then
        changed, Module.data.health.healing = imgui.checkbox(Language.get(languagePrefix .. "healing"), Module.data.health.healing)
        any_changed = any_changed or changed
        Utils.tooltip(Language.get(languagePrefix .. "healing_tooltip"))
        changed, Module.data.health.insta_healing = imgui.checkbox(Language.get(languagePrefix .. "insta_healing"), Module.data.health.insta_healing)
        any_changed = any_changed or changed
        Utils.tooltip(Language.get(languagePrefix .. "insta_healing_tooltip"))
        changed, Module.data.health.max_dragonheart = imgui.checkbox(Language.get(languagePrefix .. "max_dragonheart"), Module.data.health.max_dragonheart)
        any_changed = any_changed or changed
        Utils.tooltip(Language.get(languagePrefix .. "max_dragonheart_tooltip"))
        changed, Module.data.health.max_heroics = imgui.checkbox(Language.get(languagePrefix .. "max_heroics"), Module.data.health.max_heroics)
        any_changed = any_changed or changed
        changed, Module.data.health.max_adrenaline = imgui.checkbox(Language.get(languagePrefix .. "max_adrenaline"), Module.data.health.max_adrenaline)
        any_changed = any_changed or changed
        imgui.tree_pop()
    end
    
    languagePrefix = Module.title .. ".conditions_and_blights."
    if imgui.tree_node(Language.get(languagePrefix .. "title")) then

        languagePrefix = Module.title .. ".conditions_and_blights.blights."
        if imgui.tree_node(Language.get(languagePrefix .. "title")) then
            changed, Module.data.conditions_and_blights.blights.fire = imgui.checkbox(Language.get(languagePrefix .. "fire"), Module.data.conditions_and_blights.blights.fire)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.blights.water = imgui.checkbox(Language.get(languagePrefix .. "water"), Module.data.conditions_and_blights.blights.water)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.blights.ice = imgui.checkbox(Language.get(languagePrefix .. "ice"), Module.data.conditions_and_blights.blights.ice)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.blights.thunder = imgui.checkbox(Language.get(languagePrefix .. "thunder"), Module.data.conditions_and_blights.blights.thunder)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.blights.dragon = imgui.checkbox(Language.get(languagePrefix .. "dragon"), Module.data.conditions_and_blights.blights.dragon)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.blights.bubble = imgui.checkbox(Language.get(languagePrefix .. "bubble"), Module.data.conditions_and_blights.blights.bubble)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.blights.blast = imgui.checkbox(Language.get(languagePrefix .. "blast"), Module.data.conditions_and_blights.blights.blast)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.blights.all = imgui.checkbox(Language.get(languagePrefix .. "all"), Module.data.conditions_and_blights.blights.all)
            any_changed = any_changed or changed
            imgui.tree_pop()
        end
        languagePrefix = Module.title .. ".conditions_and_blights.conditions."
        if imgui.tree_node(Language.get(languagePrefix .. "title")) then
            changed, Module.data.conditions_and_blights.conditions.bleeding = imgui.checkbox(Language.get(languagePrefix .. "bleeding"),
                                                                                        Module.data.conditions_and_blights.conditions.bleeding)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.conditions.stun = imgui.checkbox(Language.get(languagePrefix .. "stun"), Module.data.conditions_and_blights.conditions.stun)
            Utils.tooltip(Language.get(languagePrefix .. "stun_tooltip"))
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.conditions.poison = imgui.checkbox(Language.get(languagePrefix .. "poison"), Module.data.conditions_and_blights.conditions.poison)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.conditions.sleep = imgui.checkbox(Language.get(languagePrefix .. "sleep"), Module.data.conditions_and_blights.conditions.sleep)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.conditions.frenzy = imgui.checkbox(Language.get(languagePrefix .. "frenzy"), Module.data.conditions_and_blights.conditions.frenzy)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.conditions.qurio = imgui.checkbox(Language.get(languagePrefix .. "qurio"), Module.data.conditions_and_blights.conditions.qurio)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.conditions.defence_and_resistance = imgui.checkbox(Language.get(languagePrefix .. "defence_and_resistance"),
                                                                                                    Module.data.conditions_and_blights.conditions.defence_and_resistance)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.conditions.hellfire_and_stentch = imgui.checkbox(Language.get(languagePrefix .. "hellfire_and_stentch"),
                                                                                                    Module.data.conditions_and_blights.conditions.hellfire_and_stentch)
            any_changed = any_changed or changed
            changed, Module.data.conditions_and_blights.conditions.paralyze = imgui.checkbox(Language.get(languagePrefix .. "paralyze"),
                                                                                        Module.data.conditions_and_blights.conditions.paralyze)
            Utils.tooltip(Language.get(languagePrefix .. "paralyze_tooltip"))
            
            changed, Module.data.conditions_and_blights.conditions.thread = imgui.checkbox(Language.get(languagePrefix .. "thread"), Module.data.conditions_and_blights.conditions.thread)
            Utils.tooltip(Language.get(languagePrefix .. "thread_tooltip"))
            any_changed = any_changed or changed

            changed, Module.data.conditions_and_blights.conditions.all = imgui.checkbox(Language.get(languagePrefix .. "all"), Module.data.conditions_and_blights.conditions.all)
            any_changed = any_changed or changed
            imgui.tree_pop()
        end
        imgui.tree_pop()
    end
    languagePrefix = Module.title .. ".stats."
    if imgui.tree_node(Language.get(languagePrefix .. "title")) then
        Utils.tooltip(Language.get(languagePrefix .. "tooltip"))
        local step = 10
        local attack_max, defence_max = 2600, 4500
        local stepped_attack_max, stepped_defence_max = math.floor(attack_max / step), math.floor(defence_max / step)
        local stepped_attack_value, stepped_defence_value = -1, -1
        if Module.data.stats.attack > -1 then stepped_attack_value = math.floor(Module.data.stats.attack / step) end
        if Module.data.stats.defence > -1 then stepped_defence_value = math.floor(Module.data.stats.defence / step) end
        local attack_slider, defence_slider
        changed, attack_slider = imgui.slider_int(Language.get(languagePrefix .. "attack"), stepped_attack_value, -1, stepped_attack_max,
                                                    stepped_attack_value > -1 and stepped_attack_value * step or Language.get(languagePrefix .. "attack_disabled"))
        any_changed = any_changed or changed
        changed, defence_slider = imgui.slider_int(Language.get(languagePrefix .. "defence"), stepped_defence_value, -1, stepped_defence_max,
                                                    stepped_defence_value > -1 and stepped_defence_value * step or Language.get(languagePrefix .. "attack_disabled"))
        any_changed = any_changed or changed
        Module.data.stats.attack = attack_slider > -1 and attack_slider * step or -1
        Module.data.stats.defence = defence_slider > -1 and defence_slider * step or -1

        changed, Module.data.stats.affinity = imgui.slider_int(Language.get(languagePrefix .. "affinity"), Module.data.stats.affinity, -1, 100,
                                                        Module.data.stats.affinity > -1 and " %d" .. '%%' or Language.get(languagePrefix .. "affinity_disabled"))
        any_changed = any_changed or changed

        languagePrefix = languagePrefix .. "element."
        if imgui.tree_node(Language.get(languagePrefix .. "title")) then
            languagePrefix = languagePrefix .. "types."
            local element_display = {Language.get(languagePrefix .. "disabled"), Language.get(languagePrefix .. "none"), Language.get(languagePrefix .. "fire"), Language.get(languagePrefix .. "water"),
                                        Language.get(languagePrefix .. "thunder"), Language.get(languagePrefix .. "ice"), Language.get(languagePrefix .. "dragon"),
                                        Language.get(languagePrefix .. "poison"), Language.get(languagePrefix .. "sleep"), Language.get(languagePrefix .. "paralyze"),
                                        Language.get(languagePrefix .. "blast")}

            
            languagePrefix = Module.title .. ".stats.element."
            local elm_type = Module.data.stats.element.type + 2
            changed, elm_type = imgui.combo(Language.get(languagePrefix .. "type"), elm_type, element_display)
            Module.data.stats.element.type = elm_type - 2
            any_changed = any_changed or changed
            changed, Module.data.stats.element.value = imgui.slider_int(Language.get(languagePrefix .. "value"), Module.data.stats.element.value, -1, 560,
            Module.data.stats.element.value > -1 and " %d" or Language.get(languagePrefix .. "disabled"))
            any_changed = any_changed or changed
            imgui.tree_pop()
        end
        imgui.tree_pop()
    end

    return any_changed
end

function Module.reset()
    -- Until I find a better way of increase attack, I have to reset this on script reset
    if Module.data.stats.attack > -1 then
        local playerData = Utils.getPlayerData()
        if not playerData then return end
        playerData:set_field("_AtkUpAlive", 0)
    end

    -- Until I find a better way of increase defence, I have to reset this on script reset
    if Module.data.stats.defence > -1 then
        local playerData = Utils.getPlayerData()
        if not playerData then return end
        playerData:set_field("_DefUpAlive", 0)
    end
end

return Module
