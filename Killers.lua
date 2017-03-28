-- Killer Helpers
local function CompareHealthForHealingPriority(member1, member2)
    return UnitHealth(member1) / UnitHealthMax(member1) < UnitHealth(member2) / UnitHealthMax(member2);
end
local function GetMembersToBeHealedInPriority(healthThreshold)
    -- 搜索被怪攻击的队员，并按照血量百分比排序
    local membersUnderAttack = {};
    local npcsAttackingUs = MC.GetNpcs(50, "player", nil, GJ.IsNpcAttackingUs);
    for i = 1, table.getn(npcsAttackingUs) do
        local npcTarget = GetUnitTarget(npcsAttackingUs[i]);
        if (UnitHealth(npcTarget) / UnitHealthMax(npcTarget) < healthThreshold and not tcontains(membersUnderAttack, npcTarget)) then
            table.insert(membersUnderAttack, npcTarget);
        end
    end
    table.sort(membersUnderAttack, CompareHealthForHealingPriority);
    -- 搜索其他活着的队员，并按照血量百分比排序
    local otherMembers = {};
    for i = 0, GetNumPartyMembers() do
        local partyMember;
        if (i == 0) then
            partyMember = GetObject("player");
        else
            partyMember = GetObject("party" .. i);
        end
        if (partyMember and not UnitIsDeadOrGhost(partyMember) and UnitHealth(partyMember) / UnitHealthMax(partyMember) < healthThreshold and not tcontains(otherMembers, partyMember)) then
            table.insert(otherMembers, partyMember);
        else
            break;
        end
    end
    table.sort(otherMembers, CompareHealthForHealingPriority);
    -- 产生结果
    local results = {};
    for i = 1, table.getn(membersUnderAttack) do
        table.insert(results, membersUnderAttack[i]);
    end
    for i = 1, table.getn(otherMembers) do
        table.insert(results, otherMembers[i]);
    end
    return results, membersUnderAttack, otherMembers;
end
-- Killers
MageFireKiller = {
    Action = function(npc)
        if (MC.GetActualDistance("player", npc) < 3) then
            MC.StartAutoAttacking();
        else
            MC.StopAutoAttacking();
        end
        local objects = GetObjects(sheepFilter);
        --[[local hasSheep = false;
        for i = table.getn(objects), 1, -1 do
            if (objects[i] == npc) then
                table.remove(objects,i);
            elseif (GetUnitAuraByName(npc, "Polymorph")  or GetUnitAuraByName(npc, "变形术")) then
                hasSheep = true;
            end
        end]]
        local playerHealth = UnitHealth("player") / UnitHealthMax("player");
        local spellName, _, remainingTime = MC.GetCastingInfo();
        if(not spellName) then
            if (not UnitAffectingCombat(npc) and (not _FightPyroblastTime or GetTime() - _FightPyroblastTime > 2)) then
                if (MC.TryCast("Pyroblast", nil, npc)) then
                    ResetAfkTimer();
                    return;
                end
            end
            --[[if (not hasSheep and objects[1] and (not _FightPolymorphTime or GetTime() - _FightPolymorphTime > 2)) then
                if (MC.TryCast("Polymorph", nil, objects[1])) then
                    ResetAfkTimer();
                    return;
                end
            end]]
            if ((UnitHealth(npc) > 15 or playerHealth < 0.3) and MC.TryCast("Fire Blast", nil, npc)) then
                ResetAfkTimer();
                return;
            end
            if (MC.TryCast("Fireball", nil, npc)) then
                ResetAfkTimer();
                return;
            end
        elseif (spellName == "Pyroblast" or spellName == "炎爆术") then
            if (remainingTime < 1) then
                _FightPyroblastTime = GetTime();
            end
        --[[elseif (spellName == "Polymorph" or spellName == "变形术") then
            if (remainingTime < 1) then
                _FightPolymorphTime = GetTime();
            end]]
        end
    end,
    LowerDistanceCalculator = function() 
        local _, _, _, _, currentRank = GetTalentInfo(2, 4);
        return 29 + currentRank * 3; 
    end,
    UpperDistanceCalculator = function()        
        local _, _, _, _, currentRank = GetTalentInfo(2, 4);
        return 34 + currentRank * 3;
    end,
};
MageFrostKiller = {
    Action = function(npc)
        if (MC.GetActualDistance("player", npc) < 3) then
            MC.StartAutoAttacking();
        else
            MC.StopAutoAttacking();
        end
        if (MC.TryCast("Frostbolt", nil, npc)) then
            ResetAfkTimer();
            return;
        end
    end,
    LowerDistanceCalculator = function() return 25; end,
    UpperDistanceCalculator = function() return 30; end,
};
MageArcaneKiller = {
    Action = function(npc)
        if (MC.GetActualDistance("player", npc) < 3) then
            MC.StartAutoAttacking();
        else
            MC.StopAutoAttacking();
        end
        local spellName, _, remainingTime = MC.GetCastingInfo();
        if(not spellName) then
            if (not UnitAffectingCombat(npc) and (not _FightFrostboltTime or GetTime() - _FightFrostboltTime > 2)) then
                if (MC.TryCast("Frostbolt", nil, npc)) then
                    ResetAfkTimer();
                    return;
                end
            end
            local _, _, remainingTime = MC.GetChannelInfo();
            if ((not remainingTime or remainingTime < 0.2) and MC.TryCast("Arcane Missiles", nil, npc)) then
                ResetAfkTimer();
                return;
            end
        elseif (spellName == "Frostbolt" or spellName == "寒冰箭") then
            if (remainingTime < 1) then
                _FightFrostboltTime = GetTime();
            end
        end
    end,
    LowerDistanceCalculator = function() return 25; end,
    UpperDistanceCalculator = function() return 30; end,
};
PriestKiller = {
    Action = function(npc)
        if (MC.GetActualDistance("player", npc) < 3) then
            MC.StartAutoAttacking();
        else
            MC.StopAutoAttacking();
        end
        -- 治疗
        local membersToBeHealed, membersUnderAttackToBeHealed, otherMembersToBeHealed = GetMembersToBeHealedInPriority(0.9);
        for i = 1, table.getn(membersToBeHealed) do
            local healableMember = membersToBeHealed[i];
            -- 给受到攻击的队员上盾
            if (tcontains(membersUnderAttackToBeHealed, healableMember) and MC.IsCastable("真言术：盾", nil, healableMember)) then
                local weakenedSoulAura = MC.GetUnitAuraByName(healableMember, "虚弱灵魂");
                if (not weakenedSoulAura) then
                    weakenedSoulAura = MC.GetUnitAuraByName(healableMember, "Weakened Soul");
                end
                if (not weakenedSoulAuraName) then
                    MC.Cast("真言术：盾", nil, healableMember);
                    return;
                end
            end
            -- 上恢复
            if (MC.IsCastable("恢复", nil, healableMember)) then
                local renewAura = MC.GetUnitAuraByName(healableMember, "恢复");
                if (not renewAura) then
                    renewAura = MC.GetUnitAuraByName(healableMember, "Renew");
                end
                if (not renewAura) then
                    MC.Cast("恢复", nil, healableMember);
                    return;
                end
            end
            -- 使用次级治疗术加血
            if (UnitHealth(healableMember) / UnitHealthMax(healableMember) < 0.6 and MC.IsCastable("次级治疗术", nil, healableMember)) then
                MC.Cast("次级治疗术", nil, healableMember);
                return;
            end
        end
        -- 攻击
        local canUseAttackingSpells = UnitMana("player") / UnitManaMax("player") > 0.5;
        if (canUseAttackingSpells) then
            -- 上痛
            if (MC.IsCastable("暗言术：痛", nil, npc)) then
                local shadowWordPainAura = MC.GetUnitAuraByName(npc, "暗言术：痛");
                if (not shadowWordPainAura) then
                    shadowWordPainAura = MC.GetUnitAuraByName(npc, "Shadow Word: Pain");
                end
                if (not shadowWordPainAura) then
                    MC.Cast("暗言术：痛", nil, npc);
                    return;
                end
            end
            -- 惩击
            if (MC.TryCast("惩击", nil, npc)) then
                return;
            end
        end
        -- 射击
        if (MC.TryCast("射击", nil, npc)) then
            return;
        end
    end,
    LowerDistanceCalculator = function() return 25; end,
    UpperDistanceCalculator = function() return 30; end,
};
WarriorKiller = {
    Action = function(npc)
        if (MC.GetActualDistance("player", npc) < 3) then
            MC.StartAutoAttacking();
        else
            MC.StopAutoAttacking();
        end
        local npcHealth = UnitHealth(npc) / UnitHealthMax(npc);
        -- 冲锋
        if (not UnitAffectingCombat("player") and MC.TryCast("冲锋", nil, npc)) then
            return;
        end
        -- 战斗怒吼
        local isBattleShoutLearnt = MC.GetSpellId("战斗怒吼", nil, true) ~= nil;
        if (isBattleShoutLearnt) then
            local _, _, _, _, battleShoutRemainingTime = MC.GetUnitAuraByName("player", "战斗怒吼");
            if (not battleShoutRemainingTime) then
                _, _, _, _, battleShoutRemainingTime = MC.GetUnitAuraByName("player", "Battle Shout");
            end
            if (not battleShoutRemainingTime or battleShoutRemainingTime < 5) then
                MC.TryCast("战斗怒吼");
                return;
            end
        end
        -- 断筋
        local isRendLearnt = MC.GetSpellId("断筋", nil, true) ~= nil;
        if (isRendLearnt) then
            local _, _, _, _, rendRemainingTime = MC.GetUnitAuraByName(npc, "断筋");
            if (not rendRemainingTime) then
                _, _, _, _, rendRemainingTime = MC.GetUnitAuraByName(npc, "Rend");
            end
            if (not rendRemainingTime or rendRemainingTime < 3) then
                MC.TryCast("断筋", nil, npc);
                return;
            end
        end
        -- 撕裂
        local isRendLearnt = MC.GetSpellId("撕裂", nil, true) ~= nil;
        if (isRendLearnt and npcHealth > 0.5) then
            local _, _, _, _, rendRemainingTime = MC.GetUnitAuraByName(npc, "撕裂");
            if (not rendRemainingTime) then
                _, _, _, _, rendRemainingTime = MC.GetUnitAuraByName(npc, "Rend");
            end
            if (not rendRemainingTime or rendRemainingTime < 3) then
                MC.TryCast("撕裂", nil, npc);
                return;
            end
        end
        -- 雷霆一击
        local isThunderClapLearnt = MC.GetSpellId("雷霆一击", nil, true) ~= nil;
        if (isThunderClapLearnt) then
            local surroundingTargetCount = MC.GetAttackableTargetCount(8);
            if (surroundingTargetCount > 1 and MC.TryCast("雷霆一击")) then
                return;
            end
        end
        -- 英勇打击
        if (not isRendLearnt or UnitAura("player") > 30) then
            if (MC.TryCast("英勇打击", nil, npc)) then
                return;
            end
        end
    end,
    LowerDistanceCalculator = function()
        local chargeSpellId = MC.GetSpellId("冲锋", nil, true);
        if (not UnitAffectingCombat("player") and chargeSpellId and GetSpellCooldownById(chargeSpellId) == 0 and UnitExists("target") and GetDistance("player", "target") > 10) then
            return 20;
        else
            return 2;
        end
    end,
    UpperDistanceCalculator = function()
        local chargeSpellId = MC.GetSpellId("冲锋", nil, true);
        if (not UnitAffectingCombat("player") and chargeSpellId and GetSpellCooldownById(chargeSpellId) == 0 and UnitExists("target") and GetDistance("player", "target") > 10) then
            return 22;
        else
            return 3;
        end
    end,
};
