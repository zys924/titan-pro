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
local function GetMembersWithDebuff(debuffType)
    local results = {};
    for i = 0, GetNumPartyMembers() do
        local partyMember;
        if (i == 0) then
            partyMember = GetObject("player");
        else
            partyMember = GetObject("party" .. i);
        end
        if (partyMember and not UnitIsDead(partyMember)) then
            spellIds = GetUnitAurasByType(partyMember, true, debuffType);
            if (table.getn(spellIds) > 0) then
                table.insert(results, partyMember);
            end
        end
    end
    return results;
end
-- Killers
MageKiller = {
    Action = function(npc)
        -- 获取基本信息
        local playerMana = UnitMana("player") / UnitManaMax("player");
        local castingSpellName, _, castingRemainingTime = MC.GetCastingInfo();
        local channelSpellName, _, channelRemainingTime = MC.GetChannelInfo();
        local npcTarget = GetUnitTarget(npc);
        local isTargetingMe = npcTarget and UnitIsUnit(npcTarget, "player");
        local hasFrostboltDebuff = MC.GetUnitAuraByName(npc, "寒冰箭") or MC.GetUnitAuraByName(npc, "Frostbolt");
        -- 近战范围内展开自动攻击。
        if (MC.GetActualDistance("player", npc) < 5) then
            MC.StartAutoAttacking();
        else
            MC.StopAutoAttacking();
        end
        if ((not UnitAffectingCombat(npc) or not isTargetingMe) and not hasFrostboltDebuff) then
            -- 如果目标没有进入战斗或者当前目标不是我，而且身上没有寒冰箭DEBUFF，则用寒冰箭开局。
            if (MC.IsCastable("寒冰箭", nil, npc)) then
                MC.Cast("寒冰箭", nil, npc);
                ResetAfkTimer();
                return;
            end
        elseif ((castingSpellName == "寒冰箭" or castingSpellName == "Frostbolt") and castingRemainingTime > 0.5) then
            -- 否则则打断刚刚读的寒冰箭。
            SpellStopCasting();
            return;
        end
        if (not castingSpellName and not channelSpellName) then
            -- 解除诅咒。
            local isRemoveLesserCurseLearnt = MC.GetSpellId("解除次级诅咒", nil, true) ~= nil;
            if (isRemoveLesserCurseLearnt) then
                membersWithCurse = GetMembersWithDebuff("Curse");
                for i = 1, table.getn(membersWithCurse) do
                    local memberWithCurse = membersWithCurse[i];
                    if (MC.IsCastable("解除次级诅咒", nil, memberWithCurse)) then
                        MC.Cast("解除次级诅咒", nil, memberWithCurse);
                        ResetAfkTimer();
                        return;
                    end
                end
            end
            -- 优先火冲。
            if (MC.IsCastable("火焰冲击", nil, npc)) then
                MC.Cast("火焰冲击", nil, npc);
                ResetAfkTimer();
                return;
            end
            -- 根据强化奥术飞弹天赋，决定技能策略。
            local _, _, _, _, currentRank, maxRank = GetTalentInfo(1, 3);
            if (currentRank == maxRank) then
                -- 如果点了强化奥术飞弹天赋，则无限奥术飞弹。
                if (MC.IsCastable("奥术飞弹", nil, npc)) then
                    MC.Cast("奥术飞弹", nil, npc);
                    ResetAfkTimer();
                    return;
                end
            else
                -- 如果没点强化奥术飞弹天赋，则无限火球。
                if (MC.IsCastable("火球术", nil, npc)) then
                    MC.Cast("火球术", nil, npc);
                    ResetAfkTimer();
                    return;
                end
            end
            -- 填充射击。
            if (playerMana < 0.1 and MC.IsCastable("射击", nil, npc)) then
                MC.Cast("射击", nil, npc);
                ResetAfkTimer();
                return;
            end
        end
    end,
    LowerDistanceCalculator = function() return 22; end,
    UpperDistanceCalculator = function() return 25; end,
};
PriestKiller = {
    Action = function(npc)
        if (MC.GetActualDistance("player", npc) < 5) then
            MC.StartAutoAttacking();
        else
            MC.StopAutoAttacking();
        end
        -- 治疗模组
        local membersToBeHealed, membersUnderAttackToBeHealed, otherMembersToBeHealed = GetMembersToBeHealedInPriority(0.9);
        for i = 1, table.getn(membersToBeHealed) do
            local healableMember = membersToBeHealed[i];
            -- 给受到攻击的队员上盾
            if (tcontains(membersUnderAttackToBeHealed, healableMember) and MC.IsCastable("真言术：盾", nil, healableMember)) then
                local weakenedSoulAura = MC.GetUnitAuraByName(healableMember, "虚弱灵魂");
                if (not weakenedSoulAura) then
                    weakenedSoulAura = MC.GetUnitAuraByName(healableMember, "Weakened Soul");
                end
                if (not weakenedSoulAura) then
                    MC.Cast("真言术：盾", nil, healableMember);
                    ResetAfkTimer();
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
                    ResetAfkTimer();
                    return;
                end
            end
            -- 治疗术
            if (UnitHealth(healableMember) / UnitHealthMax(healableMember) < 0.6) then
                if (MC.IsCastable("治疗术", nil, healableMember)) then
                    MC.Cast("治疗术", nil, healableMember);
                    ResetAfkTimer();
                    return;
                end
                if (MC.IsCastable("次级治疗术", nil, healableMember)) then
                    MC.Cast("次级治疗术", nil, healableMember);
                    ResetAfkTimer();
                    return;
                end
            end
        end
        -- 攻击模块
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
                    ResetAfkTimer();
                    return;
                end
            end
            -- 神圣之火
            if (MC.IsCastable("神圣之火", nil, npc)) then
                local holyFireAura = MC.GetUnitAuraByName(npc, "神圣之火");
                if (not holyFireAura) then
                    holyFireAura = MC.GetUnitAuraByName(npc, "Holy Fire");
                end
                if (not holyFireAura) then
                    MC.Cast("神圣之火", nil, npc);
                    ResetAfkTimer();
                    return;
                end
            end
            -- 惩击
            if (MC.IsCastable("惩击", nil, npc)) then
                MC.Cast("惩击", nil, npc);
                ResetAfkTimer();
                return;
            end
        end
        -- 填充射击。
        if (table.getn(membersToBeHealed) == 0 and not canUseAttackingSpells and MC.IsCastable("射击", nil, npc)) then
            MC.Cast("射击", nil, npc);
            ResetAfkTimer();
            return;
        end
    end,
    LowerDistanceCalculator = function() return 27; end,
    UpperDistanceCalculator = function() return 30; end,
};
WarriorKiller = {
    Action = function(npc)
        if (MC.GetActualDistance("player", npc) < 5) then
            MC.StartAutoAttacking();
        else
            MC.StopAutoAttacking();
        end
        local npcHealth = UnitHealth(npc) / UnitHealthMax(npc);
        -- 开局使用冲锋。
        if (not UnitAffectingCombat("player")) then
            if (MC.IsCastable("冲锋", nil, npc, true)) then
                MC.Cast("冲锋", nil, npc);
                ResetAfkTimer();
                return;
            end
        end
        -- BUFF战斗怒吼。
        local isBattleShoutLearnt = MC.GetSpellId("战斗怒吼", nil, true) ~= nil;
        if (isBattleShoutLearnt) then
            local _, _, _, _, battleShoutRemainingTime = MC.GetUnitAuraByName("player", "战斗怒吼");
            if (not battleShoutRemainingTime) then
                _, _, _, _, battleShoutRemainingTime = MC.GetUnitAuraByName("player", "Battle Shout");
            end
            if (not battleShoutRemainingTime or battleShoutRemainingTime < 5) then
                if (MC.IsCastable("战斗怒吼")) then
                    MC.Cast("战斗怒吼");
                    ResetAfkTimer();
                    return;
                end
            end
        end
        -- 对目标不是我的怪嘲讽。
        local npcTarget = GetUnitTarget(npc);
        if (npcTarget and not UnitIsUnit(npcTarget, "player") and MC.IsCastable("嘲讽", nil, npc, true)) then
            MC.Cast("嘲讽", nil, npc);
            ResetAfkTimer();
            return;
        end
        -- 如果周围有多个怪，则优先雷霆一击。
        local isThunderClapLearnt = MC.GetSpellId("雷霆一击", nil, true) ~= nil;
        if (isThunderClapLearnt) then
            local surroundingTargetCount = MC.GetAttackableTargetCount(8);
            if (surroundingTargetCount > 1) then
                if (MC.IsCastable("雷霆一击")) then
                    MC.Cast("雷霆一击");
                    ResetAfkTimer();
                    return;
                end
            end
        end
        -- 优先上断筋。
        local isHamstringLearnt = MC.GetSpellId("断筋", nil, true) ~= nil;
        if (isHamstringLearnt) then
            local hamstringAura = MC.GetUnitAuraByName(npc, "断筋") or MC.GetUnitAuraByName(npc, "Hamstring");
            if (not hamstringAura) then
                if (MC.IsCastable("断筋", nil, npc, true)) then
                    MC.Cast("断筋", nil, npc);
                    ResetAfkTimer();
                end
                return;
            end
        end
        -- 如果目标血量够多，则上撕裂。
        local isRendLearnt = MC.GetSpellId("撕裂", nil, true) ~= nil;
        if (isRendLearnt and npcHealth > 0.5) then
            local rendAura = MC.GetUnitAuraByName(npc, "撕裂") or MC.GetUnitAuraByName(npc, "Rend");
            if (not rendAura) then
                if (MC.IsCastable("撕裂", nil, npc, true)) then
                    MC.Cast("撕裂", nil, npc);
                    ResetAfkTimer();
                end
                return;
            end
        end
        -- 填充英勇打击。
        if (not isHamstringLearnt or not isRendLearnt or UnitMana("player") > 20) then
            if (MC.IsCastable("英勇打击", nil, npc, true)) then
                MC.Cast("英勇打击", nil, npc);
                ResetAfkTimer();
                return;
            end
        end
    end,
    LowerDistanceCalculator = function() return 1.5 end,
    UpperDistanceCalculator = function() return 3 end,
};
RogueKiller = {
    Action = function(npc)
        if (MC.GetActualDistance("player", npc) < 5) then
            MC.StartAutoAttacking();
        else
            MC.StopAutoAttacking();
        end
        local playerHealth = UnitHealth("player") / UnitHealthMax("player");
        local npcHealth = UnitHealth(npc) / UnitHealthMax(npc);
        local comboPoints = GetComboPoints();
        -- 血量过低开启闪避。
        if (playerHealth < 0.3) then
            if (MC.IsCastable("闪避", nil, nil, true)) then
                MC.Cast("闪避");
                ResetAfkTimer();
                return;
            end
        end
        -- 三星以上剔骨。
        if (comboPoints > 2 and npcHealth < 0.5 or comboPoints > 3) then
            if (MC.IsCastable("剔骨", nil, npc, true)) then
                MC.Cast("剔骨");
                ResetAfkTimer();
                return;
            end
        end
        -- 如果装备匕首并且在目标背后则使用背刺，否则使用邪恶攻击。
        local mainHandWeapon = SR.GetInventoryItem(16);
        if (mainHandWeapon and mainHandWeapon.SubType == "Daggers" and MC.IsFacingBack("player", npc, math.pi / 2) and MC.IsCastable("背刺", nil, npc)) then
            if (MC.IsCastable("背刺", nil, npc, true)) then
                MC.Cast("背刺");
                ResetAfkTimer();
                return;
            end
        else
            if (MC.IsCastable("邪恶攻击", nil, npc, true)) then
                MC.Cast("邪恶攻击");
                ResetAfkTimer();
                return;
            end
        end
    end,
    LowerDistanceCalculator = function() return 1.5 end,
    UpperDistanceCalculator = function() return 3 end,
};
HunterKiller = {
    Action = function(npc)
        -- 开启雄鹰守护
        if (MC.IsCastable("雄鹰守护")) then
            local aspectOfTheHawkAura = MC.GetUnitAuraByName("player", "雄鹰守护");
            if (not aspectOfTheHawkAura) then
                aspectOfTheHawkAura = MC.GetUnitAuraByName("player", "Aspect of the Hawk");
            end
            if (not aspectOfTheHawkAura) then
                MC.Cast("雄鹰守护");
                ResetAfkTimer();
                return;
            end
        end
        -- 开启强击光环
        if (MC.IsCastable("强击光环")) then
            local trueshotAura = MC.GetUnitAuraByName("player", "强击光环");
            if (not trueshotAura) then
                trueshotAura = MC.GetUnitAuraByName("player", "Trueshot Aura");
            end
            if (not trueshotAura) then
                MC.Cast("强击光环");
                ResetAfkTimer();
                return;
            end
        end
        if (MC.GetActualDistance("player", npc) < 8) then
            -- 距离过近变近战，启动自动攻击。
            if (MC.GetActualDistance("player", npc) < 5) then
                MC.StartAutoAttacking();
            else
                MC.StopAutoAttacking();
            end
            -- 优先使用猫鼬撕咬。
            if (MC.IsCastable("猫鼬撕咬", nil, npc, true)) then
                MC.Cast("猫鼬撕咬", nil, npc);
                ResetAfkTimer();
                return;
            end
            -- 填充猛禽一击。
            if (MC.IsCastable("猛禽一击", nil, npc, true)) then
                MC.Cast("猛禽一击", nil, npc);
                ResetAfkTimer();
                return;
            end
        else
            local npcHealth = UnitHealth(npc) / UnitHealthMax(npc);
            -- 标记。
            local huntersMarkAura = MC.GetUnitAuraByName(npc, "猎人印记");
            if (not huntersMarkAura) then
                huntersMarkAura = MC.GetUnitAuraByName(npc, "Hunter's Mark");
            end
            if (not huntersMarkAura) then
                if (MC.IsCastable("猎人印记", nil, npc)) then
                    MC.Cast("猎人印记", nil, npc);
                    ResetAfkTimer();
                    return;
                end
            end
            -- 开局瞄准射击
            if (MC.IsCastable("瞄准射击", nil, npc)) then
                MC.Cast("瞄准射击", nil, npc);
                ResetAfkTimer();
                return;
            end
            -- 上毒蛇钉刺。
            local serpentStingAura = MC.GetUnitAuraByName(npc, "毒蛇钉刺");
            if (not serpentStingAura) then
                serpentStingAura = MC.GetUnitAuraByName(npc, "Serpent Sting");
            end
            if (not serpentStingAura and npcHealth > 0.5) then
                if (MC.IsCastable("毒蛇钉刺", nil, npc)) then
                    MC.Cast("毒蛇钉刺", nil, npc);
                    ResetAfkTimer();
                    return;
                end
            end
            -- 卡CD打奥术射击。
            if (MC.IsCastable("奥术射击", nil, npc)) then
                MC.Cast("奥术射击", nil, npc);
                ResetAfkTimer();
                return;
            end
            -- 展开自动射击。
            if (MC.IsCastable("自动射击", nil, npc)) then
                MC.Cast("自动射击", nil, npc);
                ResetAfkTimer();
                return;
            end
        end
    end,
    LowerDistanceCalculator = function()
        if (UnitExists("target") and MC.GetActualDistance("player", "target") < 8) then
            return 1.5;
        else
            return 30;
        end
    end,
    UpperDistanceCalculator = function()
        if (UnitExists("target") and MC.GetActualDistance("player", "target") < 8) then
            return 3;
        else
            return 33;
        end
    end,
};
WarlockKiller = {
    Preparation = function(npc)
        local result = true;
        -- 上魔甲术/恶魔皮肤。
        if (not MC.GetUnitAuraByName("player", "魔甲术") and not MC.GetUnitAuraByName("player", "Demon Armor") and not MC.GetUnitAuraByName("player", "恶魔皮肤") and not MC.GetUnitAuraByName("player", "Demon Skin")) then
            if (MC.IsCastable("魔甲术", nil, nil, true)) then
                MC.Cast("魔甲术");
                ResetAfkTimer();
            elseif (MC.IsCastable("恶魔皮肤", nil, nil, true)) then
                MC.Cast("恶魔皮肤");
                ResetAfkTimer();
            end
            result = false;
        end
        -- 如果已经学会了召唤小鬼并且没有宠物，则召唤小鬼。
        if (GetSpellId("召唤小鬼", nil, true) and not UnitExists("pet")) then
            if (not MC.GetCastingInfo()) then
                MC.TryCast("召唤小鬼");
                ResetAfkTimer();
            end
            result = false;
        end
        return result;
    end,
    Action = function(npc)
        -- 获取基本信息
        local playerHealth = UnitHealth("player") / UnitHealthMax("player");
        local playerMana = UnitMana("player") / UnitManaMax("player");
        local castingSpellName, _, castingRemainingTime = MC.GetCastingInfo();
        local channelSpellName, _, channelRemainingTime = MC.GetChannelInfo();
        -- 近战范围内展开自动攻击。
        if (MC.GetActualDistance("player", npc) < 5) then
            MC.StartAutoAttacking();
        else
            MC.StopAutoAttacking();
        end
        -- 打断多余的献祭
        if ((MC.GetUnitAuraByName("target", "献祭") or MC.GetUnitAuraByName("target", "Immolate")) and (castingSpellName == "献祭" or castingSpellName == "Immolate")) then
            SpellStopCasting();
            ResetAfkTimer();
        end
        if (not castingSpellName and not channelSpellName) then
            -- 血换蓝。
            if (playerHealth > 0.7 and playerMana < 0.5 and MC.IsCastable("生命分流")) then
                MC.Cast("生命分流");
                ResetAfkTimer();
                return;
            end
            if (playerMana > 0.1) then
                -- 夜幕
                if (MC.GetUnitAuraByName("player", "夜幕") or MC.GetUnitAuraByName("player", "Nightfall")) then
                    MC.TryCast("暗影箭", nil, npc);
                    ResetAfkTimer();
                    return;
                end
                -- 上献祭DOT
                if (not MC.GetUnitAuraByName("target", "献祭") and not MC.GetUnitAuraByName("target", "Immolate") and MC.IsCastable("献祭", nil, npc)) then
                    MC.Cast("献祭", nil, npc);
                    ResetAfkTimer();
                    return;
                end
                -- 上生命虹吸DOT
                if (not MC.GetUnitAuraByName("target", "生命虹吸") and not MC.GetUnitAuraByName("target", "Siphon Life") and MC.IsCastable("生命虹吸", nil, npc)) then
                    MC.Cast("生命虹吸", nil, npc);
                    ResetAfkTimer();
                    return;
                end
                -- 上痛苦诅咒DOT
                if (not MC.GetUnitAuraByName("target", "痛苦诅咒") and not MC.GetUnitAuraByName("target", "Curse of Agony") and MC.IsCastable("痛苦诅咒", nil, npc)) then
                    MC.Cast("痛苦诅咒", nil, npc);
                    ResetAfkTimer();
                    return;
                end
                -- 如果点满了强化腐蚀术天赋，则上腐蚀术DOT
                local _, _, _, _, currentRank, maxRank = GetTalentInfo(1, 2);
                if (currentRank == maxRank and not MC.GetUnitAuraByName("target", "腐蚀术") and not MC.GetUnitAuraByName("target", "Corruption") and MC.IsCastable("腐蚀术", nil, npc)) then
                    MC.Cast("腐蚀术", nil, npc);
                    ResetAfkTimer();
                    return;
                end
                -- 如果生命值不够，则吸取生命
                if (playerHealth < 0.9 and MC.IsCastable("吸取生命", nil, npc)) then
                    MC.Cast("吸取生命", nil, npc);
                    ResetAfkTimer();
                    return;
                end
                -- 填充暗影箭。
                if (MC.IsCastable("暗影箭", nil, npc)) then
                    MC.Cast("暗影箭", nil, npc);
                    ResetAfkTimer();
                    return;
                end
            else
                -- 蓝量不够则填充射击。
                if (MC.IsCastable("射击", nil, npc)) then
                    MC.Cast("射击", nil, npc);
                    ResetAfkTimer();
                    return;
                end
            end
        end
    end,
    LowerDistanceCalculator = function() return 24; end,
    UpperDistanceCalculator = function() return 27; end,
};
