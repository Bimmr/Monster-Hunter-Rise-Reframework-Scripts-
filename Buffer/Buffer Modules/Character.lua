local utils
local character = {
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

function character.init_hooks()
    sdk.hook(sdk.find_type_definition("snow.player.PlayerManager"):get_method("update"), function(args)

        local playerBase = utils.getPlayerBase()
        if not playerBase then return end
        local playerData = utils.getPlayerData()
        if not playerData then return end

        if character.unlimited_stamina then
            local maxStamina = playerData:get_field("_staminaMax")
            playerData:set_field("_stamina", maxStamina)
        end

        if character.health.healing then
            local max = playerData:get_field("_vitalMax")
            playerData:set_field("_r_Vital", max)
        end

        if character.health.insta_healing then
            local max = playerData:get_field("_vitalMax")

            local maxFloat = max + .0
            playerData:set_field("_r_Vital", max)
            playerData:call("set__vital", maxFloat)
        end

        if character.health.max_dragonheart then
            local playerData = utils.getPlayerData()
            if not playerData then return end

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

        if character.health.max_heroics then
            local max = playerData:get_field("_vitalMax")
            local newHealth = math.floor(max * 0.3)

            playerData:set_field("_r_Vital", math.min(max, newHealth) + .0)
            playerData:call("set__vital", math.min(max, newHealth) + .0)
        end

        if character.health.max_adrenaline then
            local max = playerData:get_field("_vitalMax")
            local newHealth = 10.0

            playerData:set_field("_r_Vital", math.min(max, newHealth) + .0)
            playerData:call("set__vital", math.min(max, newHealth) + .0)
        end

        if character.conditions_and_blights.blights.fire then
            playerBase:set_field("_FireLDurationTimer", 0) -- The fire timer
            playerBase:set_field("_FireDamageTimer", 0) -- The fire damage timer
        end

        if character.conditions_and_blights.blights.water then
            playerBase:set_field("_WaterLDurationTimer", 0) -- The water blight timer
        end

        if character.conditions_and_blights.blights.ice then
            playerBase:set_field("_IceLDurationTimer", 0) -- The ice blight timer
        end

        if character.conditions_and_blights.blights.thunder then
            playerBase:set_field("_ThunderLDurationTimer", 0) -- The thunder blight timer
        end

        if character.conditions_and_blights.blights.dragon then
            playerBase:set_field("_DragonLDurationTimer", 0) -- The dragon blight timer
        end

        if character.conditions_and_blights.blights.bubble then
            playerBase:set_field("_BubbleDamageTimer", 0) -- The bubble timer
            -- playerData:set_field("_BubbleType", 0) -- | 0=None | 1=BubbleS | 2=BubbleL |
        end

        if character.conditions_and_blights.blights.blast then
            playerBase:set_field("_BombDurationTimer", 0) -- The blast timer
        end

        if character.conditions_and_blights.conditions.bleeding then
            playerBase:set_field("_BleedingDebuffTimer", 0) -- The bleeding timer
        end

        if character.conditions_and_blights.conditions.stun then
            playerBase:set_field("_StunDurationTimer", 0) -- The stun timer
        end

        if character.conditions_and_blights.conditions.poison then
            playerBase:set_field("_PoisonDurationTimer", 0) -- The poison timer
            playerBase:set_field("_PoisonDamageTimer", 0) -- How long till next poison tick
            -- playerData:set_field("_PoisonLv", 0) -- | 0=None | 1=Poison | 2=NoxiousPoison | 3=DeadlyPoison | 
        end

        if character.conditions_and_blights.conditions.sleep then
            playerBase:set_field("_SleepDurationTimer", 0) -- The sleep timer
            playerBase:set_field("<SleepMovableTimer>k__BackingField", 0) -- The sleep walking timer
        end

        if character.conditions_and_blights.conditions.frenzy then
            playerBase:set_field("_IsVirusLatency", false) -- The frenzy virus
            playerBase:set_field("_VirusTimer", 0) -- How long till the next frenzy virus tick
            playerBase:set_field("_VirusAccumulator", 0) -- Total ticks of Frenzy
        end

        if character.conditions_and_blights.conditions.defence_and_resistance then
            playerBase:set_field("_ResistanceDownDurationTimer", 0) -- The resistance down timer
            playerBase:set_field("_DefenceDownDurationTimer", 0) -- The defence down timer
        end

        if character.conditions_and_blights.conditions.hellfire_and_stentch then
            playerBase:set_field("_OniBombDurationTimer", 0) -- The hellfire timer
            playerBase:set_field("_StinkDurationTimer", 0) -- The putrid gas damage timer
        end

        if character.stats.attack > -1 then
            -- Set the original attack value
            if character.data.attack_original == nil then character.data.attack_original = playerData:get_field("_Attack") end

            -- Setup variables to determine how much extra attack needs to be added to get to the set value
            local attack = character.data.attack_original
            local attackTarget = character.stats.attack
            local attackMod = attackTarget - attack

            -- Add the extra attack
            playerData:set_field("_AtkUpAlive", attackMod)

            -- Restore the original attack value if disabled    
        elseif character.data.attack_original ~= nil then
            playerData:set_field("_AtkUpAlive", 0)
            character.data.attack_original = nil
        end

        if character.stats.defence > -1 then
            -- Set the original defence value
            if character.data.defence_original == nil then character.data.defence_original = playerData:get_field("_Defence") end

            -- Setup variables to determine how much extra defence needs to be added to get to the set value
            local defence = character.data.defence_original
            local defenceTarget = character.stats.defence
            local defenceMod = defenceTarget - defence

            -- Add the extra defence
            playerData:set_field("_DefUpAlive", defenceMod)

            -- Restore the original defence value if disabled    
        elseif character.data.defence_original ~= nil then
            playerData:set_field("_DefUpAlive", 0)
            character.data.defence_original = nil
        end
    end)
    utils.nothing()
end

function character.init()
    utils = require("Buffer Modules.Utils")

    character.init_hooks()
end

function character.draw()
    local changed
    changed, character.unlimited_stamina = imgui.checkbox("Unlimited Stamina", character.unlimited_stamina)
    if imgui.tree_node("Health Options") then
        changed, character.health.healing = imgui.checkbox("Constant Healing", character.health.healing)
        changed, character.health.insta_healing = imgui.checkbox("Instant Healing", character.health.insta_healing)
        changed, character.health.max_dragonheart = imgui.checkbox("Max Dragonheart Health", character.health.max_dragonheart)
        changed, character.health.max_heroics = imgui.checkbox("Max Heroics Health", character.health.max_heroics)
        changed, character.health.max_adrenaline = imgui.checkbox("Max Adrenaline Health", character.health.max_adrenaline)
        imgui.tree_pop()
    end
    if imgui.tree_node("Conditions, Ailments, & Blights") then
        if imgui.tree_node("Blights") then
            changed, character.conditions_and_blights.blights.fire = imgui.checkbox("Fire", character.conditions_and_blights.blights.fire)
            changed, character.conditions_and_blights.blights.water = imgui.checkbox("Water", character.conditions_and_blights.blights.water)
            changed, character.conditions_and_blights.blights.ice = imgui.checkbox("Ice", character.conditions_and_blights.blights.ice)
            changed, character.conditions_and_blights.blights.thunder = imgui.checkbox("Thunder", character.conditions_and_blights.blights.thunder)
            changed, character.conditions_and_blights.blights.dragon = imgui.checkbox("Dragon", character.conditions_and_blights.blights.dragon)
            changed, character.conditions_and_blights.blights.bubble = imgui.checkbox("Bubble", character.conditions_and_blights.blights.bubble)
            changed, character.conditions_and_blights.blights.blast = imgui.checkbox("Blast", character.conditions_and_blights.blights.blast)
            imgui.tree_pop()
        end
        if imgui.tree_node("Conditions") then
            changed, character.conditions_and_blights.conditions.bleeding = imgui.checkbox("Bleeding", character.conditions_and_blights.conditions.bleeding)
            changed, character.conditions_and_blights.conditions.stun = imgui.checkbox("Stun", character.conditions_and_blights.conditions.stun)
            changed, character.conditions_and_blights.conditions.poison = imgui.checkbox("Poison", character.conditions_and_blights.conditions.poison)
            changed, character.conditions_and_blights.conditions.sleep = imgui.checkbox("Sleep", character.conditions_and_blights.conditions.sleep)
            changed, character.conditions_and_blights.conditions.frenzy = imgui.checkbox("Frenzy", character.conditions_and_blights.conditions.frenzy)
            changed, character.conditions_and_blights.conditions.defence_and_resistance = imgui.checkbox("Defence & Resistance", character.conditions_and_blights.conditions.defence_and_resistance)
            changed, character.conditions_and_blights.conditions.hellfire_and_stentch = imgui.checkbox("Hellfire & Stench", character.conditions_and_blights.conditions.hellfire_and_stentch)
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
        if character.stats.attack > -1 then
            stepped_attack_value = math.floor(character.stats.attack / step)
        end
        if character.stats.defence > -1 then
            stepped_defence_value = math.floor(character.stats.defence / step)
        end
        local attack_slider, defence_slider
        changed, attack_slider = imgui.slider_int("Attack", stepped_attack_value, -1, stepped_attack_max, stepped_attack_value > -1 and stepped_attack_value*step or "Off")
        utils.tooltip("Drag slider to the left to reset if the stat break")
        changed, defence_slider = imgui.slider_int("Defence", stepped_defence_value, -1, stepped_defence_max, stepped_defence_value > -1 and stepped_defence_value*step or "Off")
        utils.tooltip("Drag slider to the left to reset if the stat break")
        character.stats.attack = attack_slider * step
        character.stats.defence = defence_slider * step
        imgui.tree_pop()
    end
end

function character.reset()
    -- Until I find a better way of increase attack, I have to reset this on script reset
    if character.stats.attack > -1 then
        local playerData = utils.getPlayerData()
        if not playerData then return end
        playerData:set_field("_AtkUpAlive", 0)
    end

    -- Until I find a better way of increase defence, I have to reset this on script reset
    if character.stats.defence > -1 then
        local playerData = utils.getPlayerData()
        if not playerData then return end
        playerData:set_field("_DefUpAlive", 0)
    end

end
return character
