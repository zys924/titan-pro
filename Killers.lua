--------------------------------------------------------------------------------
-- Basics
--------------------------------------------------------------------------------
PREFIX = "GPL-Elwyn-1-12";
WELCOME = GetLocalizedText("The group power leveling script in Elwyn (1 - 12) is loaded.", "艾尔文森林组队升级脚本（1 - 12）已加载。");
local _, playerClass = UnitClass("player");
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Power Level
--------------------------------------------------------------------------------
local northshireAbbeyRendezvousPoint = {-8912.3935546875, -117.79735565186, 82.050354003906};
local goldshireRendezvousPoint = {-9459.4794921875, 42.02933883667, 56.949913024902};
local northshireAbbeySuppliers = { -- 所有补给NPC
    [1] = {
        Type = "Merchant",
        Position = {-8901.298828125, -116.64906311035, 81.901161193848}, -- NPC坐标
        Names = {"Dermot Johns", "德尔莫特·约翰斯"}, -- NPC的所有名字（中英文）
    },
    [2] = {
        Type = "Merchant",
        Position = {-8901.298828125, -116.64906311035, 81.901161193848},
        Names = {"Brother Danil", "丹尼尔修士"},
    },
};
local goldshireSuppliers = { -- 所有补给NPC
    [1] = { -- 闪金镇旅店老板（用于绑炉石）
        Type = "Innkeeper",
        Position = {-9465.2119140625, 14.495690345764, 56.962306976318},
        Names = {"Innkeeper Farley", "旅店老板法雷"},
    },
    [2] = { -- 闪金镇旅店老板（用于买东西）
        Type = "Merchant",
        Position = {-9465.2119140625, 14.495690345764, 56.962306976318},
        Names = {"Innkeeper Farley", "旅店老板法雷"},
    },
    [3] = { -- 闪金镇铁匠
        Type = "Merchant",
        Position = {-9459.6083984375, 96.684219360352, 58.343593597412},
        Names = {"Kurran Steele", "库兰·斯蒂利"},
    },
};
local northshireAbbeyTrainers;
local goldshireTrainers;
if (playerClass == "MAGE") then
    northshireAbbeyTrainers = { -- 学习技能的NPC
        [1] = {
            Type = "Trainer",
            Position = {-8852.623046875, -186.94384765625, 89.313751220703},
            Names = {"Khelden Bremen", "凯尔登·布雷门"},
        },
    };
    goldshireTrainers = { -- 学习技能的NPC
        [1] = {
            Type = "Trainer",
            Position = {-9472.3134765625, 32.344165802002, 63.820873260498},
            Names = {"Zaldimar Wefhellt", "扎尔迪玛·维夫希尔特"},
        },
    };
elseif (playerClass == "PRIEST") then
    northshireAbbeyTrainers = { -- 学习技能的NPC
        [1] = {
            Type = "Trainer",
            Position = {-8856.044921875, -193.21907043457, 81.932441711426},
            Names = {"Priestess Anetta", "女牧师安妮塔"},
        },
    };
    goldshireTrainers = { -- 学习技能的NPC
        [1] = {
            Type = "Trainer",
            Position = {-9460.001953125, 30.720640182495, 63.820537567139},
            Names = {"Priestess Josetta", "女牧师洁塞塔"},
        },
    };
elseif (playerClass == "WARRIOR") then
    northshireAbbeyTrainers = { -- 学习技能的NPC
        [1] = {
            Type = "Trainer",
            Position = {-8917.2197265625, -206.76374816895, 82.121994018555},
            Names = {"Llane Beshere", "莱尼·拜舍尔"},
            InboundPath = {
                {-8913.62890625, -136.43721008301, 80.42162322998},
                {-8903.498046875, -160.88710021973, 81.940063476563},
                {-8907.86328125, -164.53890991211, 81.940063476563},
                {-8911.29296875, -176.37835693359, 81.940063476563},
                {-8906.5126953125, -183.44692993164, 81.940063476563},
                {-8917.091796875, -206.71374511719, 82.119163513184},
                DisablePathFinding = true,
            },
        },
    };
    goldshireTrainers = { -- 学习技能的NPC
        [1] = {
            Type = "Trainer",
            Position = {-9464.8876953125, 109.17049407959, 57.620777130127},
            Names = {"Lyria Du Lac", "里瑞亚·杜拉克"},
        },
    };
end
_powerLevels = {
    [1] = { -- 北郡修道院 - 西侧
        MinLevel = 1, -- 最低适用等级
        MaxLevel = 4, -- 最高适用等级
        RendezvousPoint = northshireAbbeyRendezvousPoint, -- 集合点（前往练级区域的起始点或从练级区域回归的终结点，也是NPC和野外的连结点）
        NextPowerLevel = { -- 从集合点前往下一个升级模块的路线
            Index = 2, -- 下一个升级模块序号
            Path = {
                northshireAbbeyRendezvousPoint
            }, -- 前往下一个升级模块的路线
        },
        Suppliers = northshireAbbeySuppliers,
        Trainers = northshireAbbeyTrainers,
        KillingZone = {
            InboundPath = {
                northshireAbbeyRendezvousPoint,
                {-8913.486328125, -80.319519042969, 87.219612121582},
            }, -- 从集合点前往该区域的路径
            OutboundPath = {
                northshireAbbeyRendezvousPoint,
            }, -- 从该区域回归集合点的路径
            PatrolPath = {
                {-8911.75390625, -77.667938232422, 87.416007995605},
                {-8814.2275390625, -53.75573348999, 91.053405761719},
                {-8691.4169921875, -113.07279968262, 89.102386474609},
                {-8645.107421875, -130.57055664063, 87.514595031738},
                {-8579.12109375, -154.62106323242, 90.210975646973},
                {-8546.8134765625, -207.84271240234, 85.052680969238},
                {-8577.201171875, -153.77264404297, 89.922966003418},
                {-8767.115234375, -75.580924987793, 90.966888427734},
                {-8865.6572265625, -90.801345825195, 82.020851135254},
            }, -- 区域巡逻路径
            AttackTargetFilter = {UpperLevelDifference = 3},
        },
    },
    [2] = { -- 北郡修道院 - 葡萄酒庄
        MinLevel = 4, -- 最低适用等级
        MaxLevel = 6, -- 最高适用等级
        RendezvousPoint = northshireAbbeyRendezvousPoint, -- 集合点（前往练级区域的起始点或从练级区域回归的终结点，也是NPC和野外的连结点）
        NextPowerLevel = { -- 从集合点前往下一个升级模块的路线
            Index = 3, -- 下一个升级模块序号
            Path = {
                {-9065.318359375, -42.847637176514, 88.068901062012},
                {-9167.421875, -111.00511932373, 72.126945495605},
                {-9227.201171875, -105.42440795898, 71.10856628418},
                {-9298.0634765625, -59.170364379883, 67.236145019531},
                {-9354.072265625, -38.984191894531, 64.601554870605},
                {-9454.1796875, 64.856582641602, 56.025276184082},
                {-9459.4794921875, 42.02933883667, 56.949913024902},
                goldshireRendezvousPoint,
            }, -- 前往下一个升级模块的路线
        },
        Suppliers = northshireAbbeySuppliers,
        Trainers = northshireAbbeyTrainers,
        KillingZone = {
            InboundPath = {
                northshireAbbeyRendezvousPoint,
                {-8954.048828125, -153.82118225098, 82.032257080078},
                {-8964.59375, -233.29570007324, 76.272605895996},
                {-8960.3564453125, -273.73187255859, 74.247940063477},
                {-8974.0791015625, -287.39111328125, 72.025825500488},
            }, -- 从集合点前往该区域的路径
            OutboundPath = {
                {-8974.0791015625, -287.39111328125, 72.025825500488},
                {-8960.3564453125, -273.73187255859, 74.247940063477},
                {-8964.59375, -233.29570007324, 76.272605895996},
                {-8954.048828125, -153.82118225098, 82.032257080078},
                northshireAbbeyRendezvousPoint,
            }, -- 从该区域回归集合点的路径
            PatrolPath = {
                {-8997.9697265625, -309.25820922852, 71.935066223145},
                {-8870.1181640625, -349.41693115234, 71.156623840332},
                {-8884.1083984375, -444.21585083008, 64.751037597656},
                {-9023.4453125, -401.18310546875, 71.883201599121},
                {-9108.4169921875, -313.28707885742, 73.356323242188},
                {-9076.5498046875, -247.87854003906, 73.651237487793},
            }, -- 区域巡逻路径
            UseHearthStone = true,
            AttackTargetFilter = {UpperLevelDifference = 3},
        },
    },
    [3] = { -- 艾尔文森林 - 西南
        MinLevel = 6, -- 最低适用等级
        MaxLevel = 10, -- 最高适用等级
        RendezvousPoint = goldshireRendezvousPoint, -- 集合点（前往练级区域的起始点或从练级区域回归的终结点，也是NPC和野外的连结点）
        --[[NextPowerLevel = { -- 从集合点前往下一个升级模块的路线
            Index = 6, -- 下一个升级模块序号
            Path = {
                goldshireRendezvousPoint,
            }, -- 前往下一个升级模块的路线
        },]]
        Suppliers = goldshireSuppliers,
        Trainers = goldshireTrainers,
        KillingZone = { -- 所有击杀区域（如果有多个区域，当完成一个区域后，会回归集合点，然后再前往下一个区域）
            InboundPath = { -- 从集合点前往该区域的路径
                goldshireRendezvousPoint,
                {-9489.3310546875, 66.256393432617, 56.018615722656},
                {-9540.52734375, -36.5436668396, 56.445819854736},
                {-9548.1083984375, -71.534675598145, 57.445426940918},
                {-9551.3388671875, -131.03578186035, 57.42493057251},
                {-9574.5966796875, -160.64231872559, 57.57152557373},
                {-9610.0458984375, -260.34051513672, 57.062839508057},
                {-9598.986328125, -229.37852478027, 57.37931060791},
                {-9619.0625, -309.21203613281, 57.420459747314},
                {-9619.6083984375, -378.27780151367, 57.654361724854},
            },
            OutboundPath = { -- 从该区域回归集合点的路径
                {-9619.6083984375, -378.27780151367, 57.654361724854},
                {-9619.0625, -309.21203613281, 57.420459747314},
                {-9598.986328125, -229.37852478027, 57.37931060791},
                {-9610.0458984375, -260.34051513672, 57.062839508057},
                {-9574.5966796875, -160.64231872559, 57.57152557373},
                {-9551.3388671875, -131.03578186035, 57.42493057251},
                {-9548.1083984375, -71.534675598145, 57.445426940918},
                {-9540.52734375, -36.5436668396, 56.445819854736},
                {-9489.3310546875, 66.256393432617, 56.018615722656},
                goldshireRendezvousPoint,
            }, 
            PatrolPath = {
                {-9659.2470703125, -396.40475463867, 56.294166564941},
                {-9799.4345703125, -697.39038085938, 35.947105407715},
                {-9707.2392578125, -715.10076904297, 45.342021942139},
            }, -- 区域巡逻路径
            UseHearthStone = true,
            AttackTargetFilter = {UpperLevelDifference = 3},
        },
    },
};
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Test Killers
--------------------------------------------------------------------------------
local tcontains = MC.tcontains;
function GetCurrentKiller()
    local _, playerClass = UnitClass("player");
    if (playerClass == "PRIEST") then
        return PriestKiller;
    elseif (playerClass == "WARRIOR") then
        return WarriorKiller;
    else
        return nil;
    end
end
-- >>> PASTE FROM HERE <<<
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
        -- 撕裂
        local isRendLearnt = MC.GetSpellId("撕裂", nil, true) ~= nil;
        if (isRendLearnt) then
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
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Test SpellsToLearn
--------------------------------------------------------------------------------
SpellsToLearn = { 
    PRIEST = { -- 职业通用名称（即英文名称的大写版）
        [1] = {
            {"真言术：韧", 1}, -- {技能名称, 技能等级[, 过滤函数(即只有该函数返回true是才认为该技能为可学习技能，可空)]}
        },
        [4] = {
            {"暗言术：痛", 1},
            {"次级治疗术", 2},
        },
        [6] = {
            {"真言术：盾", 1},
            {"惩击", 2},
        },
    },
    WARRIOR = {
        [1] = {
            {"战斗怒吼", 1},
        },
        [4] = {
            {"冲锋", 1},
            {"撕裂", 1},
        },
        [6] = {
            {"雷霆一击", 1},
            {"招架"},
        },
    },
};
GJ.SpellsToLearn.PRIEST = SpellsToLearn.PRIEST;
GJ.SpellsToLearn.WARRIOR = SpellsToLearn.WARRIOR;
--------------------------------------------------------------------------------
