-- ====================================================================
-- WestRP Karma — Client Pipeline: Atomic Confrontation Stages
-- File: client/pipeline/stages.lua
-- Padrão: Pipeline Linear Funcional (Filter Chain)
-- ====================================================================

---@class CombatStages
CombatStages = {}

CombatStages.Names = {
    "1. Sanidade",
    "2. Autoria",
    "3. Classificação",
    "4. Resolução de Arma",
    "5. Desfecho do Confronto",
    "6. Iniciativa & Defesa",
    "7. Deduplicação",
    "8. Despacho"
}

---Estágio 1: Sanidade das entidades envolvidas
---@param ctx CombatContext
---@return boolean success, string? reason
function CombatStages.Sanity(ctx)
    if not DoesEntityExist(ctx.victim) then
        return false, "Vítima não existe no motor de jogo"
    end
    if not IsEntityAPed(ctx.victim) then
        return false, "Entidade não é um Ped (objeto/veículo/cenário descartado)"
    end
    if ctx.victim == ctx.playerPed then
        return false, "Dano auto-infligido pelo próprio jogador (ignorado)"
    end
    return true
end

---Estágio 2: Confirmação de Autoria do Jogador
---@param ctx CombatContext
---@return boolean success, string? reason
function CombatStages.Authorship(ctx)
    local isDirect = (ctx.culprit == ctx.playerPed)

    -- Verifica montaria do jogador
    if not isDirect and IsPedOnMount(ctx.playerPed) then
        isDirect = (ctx.culprit == GetMount(ctx.playerPed))
    end

    -- Verifica native de dano físico direto
    if not isDirect then
        local ok, damaged = pcall(HasEntityBeenDamagedByEntity, ctx.victim, ctx.playerPed, 1)
        if not ok or not damaged then
            ok, damaged = pcall(HasEntityBeenDamagedByEntity, ctx.victim, ctx.playerPed, true)
        end
        if ok and damaged then
            isDirect = true
        end
    end

    -- Verifica fonte da morte
    if not isDirect then
        local sourceDeath = GetPedSourceOfDeath(ctx.victim)
        ctx.killerSource = sourceDeath
        if sourceDeath == ctx.playerPed or (IsPedOnMount(ctx.playerPed) and sourceDeath == GetMount(ctx.playerPed)) then
            isDirect = true
        end
    end

    -- Verifica alvo de combate corporal / mira ativa
    if not isDirect then
        if IsPedInMeleeCombat(ctx.playerPed) and GetMeleeTargetForPed(ctx.playerPed) == ctx.victim then
            isDirect = true
        end
    end

    if not isDirect then
        return false, string.format("Jogador não foi o autor deste confronto (Culprit: %s)", tostring(ctx.culprit))
    end

    ctx.isAuthor = true
    return true
end

---Estágio 3: Classificação do Alvo (Civil, Policial, Player, Animal)
---@param ctx CombatContext
---@return boolean success, string? reason
function CombatStages.TargetType(ctx)
    local targetType = KarmaState.ClassifyTarget(ctx.victim)
    if targetType == "ANIMAL" then
        return false, "Alvo é um animal (ignorado pelo sistema de moralidade humana)"
    end
    if targetType == "UNKNOWN" then
        return false, "Tipo de alvo desconhecido ou entidade não reconhecida"
    end

    ctx.targetType = targetType

    if targetType == "PLAYER" then
        local playerIdx = NetworkGetPlayerIndexFromPed(ctx.victim)
        if playerIdx and playerIdx ~= -1 then
            ctx.victimServerId = GetPlayerServerId(playerIdx)
        end
    end

    return true
end

---Estágio 4: Resolução da Causa e Arma Utilizada
---@param ctx CombatContext
---@return boolean success, string? reason
function CombatStages.Weapon(ctx)
    local cause = 0
    if ctx.isDead or KarmaState.IsPedActuallyDead(ctx.victim) then
        cause = GetPedCauseOfDeath(ctx.victim)
    end

    if not cause or cause == 0 or Weapons.IsUnarmed(cause) then
        local rawWeapon = ctx.args and (ctx.args[7] or ctx.args[5]) or 0
        if rawWeapon ~= 0 and not Weapons.IsUnarmed(rawWeapon) then
            cause = rawWeapon
        else
            cause = KarmaState.GetPlayerHeldWeapon(ctx.playerPed)
        end
    end

    ctx.weaponHash = cause
    ctx.weaponLabel = Weapons.GetWeaponLabel(cause)
    return true
end

---Estágio 5: Desfecho do Confronto (KILL vs KNOCKOUT vs ASSAULT)
---@param ctx CombatContext
---@return boolean success, string? reason
function CombatStages.Outcome(ctx)
    -- 1. Primeiro verifica se o alvo morreu de fato (ferimento fatal, IsEntityDead, vida <= 0)
    local isDead = KarmaState.IsPedActuallyDead(ctx.victim)

    -- Flag nativa explícita de dano letal (ex: tiro de fuzil, sniper ou dinamite com args[4]==1/args[6]==1)
    if not isDead and ctx.args and (ctx.args[4] == 1 or ctx.args[6] == 1) then
        if ctx.weaponHash and not Weapons.IsUnarmed(ctx.weaponHash) then
            isDead = true
        end
    end

    if isDead then
        ctx.actionType = "KILL"
        ctx.isDead = true
        KarmaState.deadPeds[ctx.victim] = GetGameTimer()
        KarmaState.knockedOutPeds[ctx.victim] = nil
        return true
    end

    -- 2. Se não está morto, verifica se o alvo foi nocauteado / desacordado
    local isKnockedOut = KarmaState.IsPedActuallyKnockedOut(ctx.victim)

    -- Se acabou de sofrer agressão desarmada e entrou em ragdoll
    if not isKnockedOut and Weapons.IsUnarmed(ctx.weaponHash) and IsPedRagdoll(ctx.victim) then
        isKnockedOut = true
    end

    if isKnockedOut then
        ctx.actionType = "KNOCKOUT"
        ctx.isKnockedOut = true
        KarmaState.knockedOutPeds[ctx.victim] = GetGameTimer()
        KarmaState.deadPeds[ctx.victim] = nil
        return true
    end

    -- 3. Caso contrário, o alvo continua de pé / ativo: é uma Agressão (ASSAULT)
    ctx.actionType = "ASSAULT"
    ctx.isAssault = true
    return true
end

---Estágio 6: Iniciativa & Análise de Legítima Defesa
---@param ctx CombatContext
---@return boolean success, string? reason
function CombatStages.Initiative(ctx)
    local now = GetGameTimer()
    local durationMs = (Config.SelfDefenseDuration or 45) * 1000
    local attackTime = KarmaState.recentAttackers[ctx.victim]
    local isSelfDefense = false

    -- 1. Vítima agrediu o jogador anteriormente dentro do prazo de legítima defesa
    if attackTime and (now - attackTime) <= durationMs then
        isSelfDefense = true
    -- 2. Alvo NPC já estava em combate hostil ativo contra o jogador antes deste golpe
    elseif IsPedInCombat(ctx.victim, ctx.playerPed) and not KarmaState.recentAssaults[ctx.victim] then
        isSelfDefense = true
    end

    if isSelfDefense then
        ctx.initiative = "SELF_DEFENSE"
    else
        ctx.initiative = "UNPROVOKED"
    end

    return true
end

---Estágio 7: Deduplicação e Resfriamento (Rate-Limiting)
---@param ctx CombatContext
---@return boolean success, string? reason
function CombatStages.Deduplication(ctx)
    local now = GetGameTimer()

    if ctx.actionType == "KILL" then
        if KarmaState.deadPeds[ctx.victim] and (now - KarmaState.deadPeds[ctx.victim]) > 1000 then
            return false, "Vítima já processada anteriormente como morta"
        end
    elseif ctx.actionType == "KNOCKOUT" then
        if KarmaState.knockedOutPeds[ctx.victim] and (now - KarmaState.knockedOutPeds[ctx.victim]) < 8000 then
            return false, "Alvo já se encontra desacordado/nocauteado (cooldown 8s)"
        end
    elseif ctx.actionType == "ASSAULT" then
        if KarmaState.recentAssaults[ctx.victim] and (now - KarmaState.recentAssaults[ctx.victim]) < 2000 then
            return false, "Agressão recente ainda em resfriamento (cooldown 2s)"
        end
    end

    return true
end

---Calcula a variação moral estimada para apresentação ao usuário
---@param ctx CombatContext
---@return integer deltaNum, string deltaFormatted, string badgeType, string badgeLabel
function CombatStages.CalculateEstimatedDelta(ctx)
    if ctx.initiative == "SELF_DEFENSE" then
        if ctx.actionType == "KILL" then
            local r = Config.Rewards and Config.Rewards.WantedBanditKill or 15
            return r, "+" .. tostring(r) .. " pts", "defense", "LEGÍTIMA DEFESA"
        else
            return 0, "0 pts (Preservada)", "defense", "LEGÍTIMA DEFESA"
        end
    end

    -- Não provocado
    local pen = Config.Penalties or {}
    local d = 0

    if ctx.targetType == "PLAYER" then
        if ctx.actionType == "KILL" then d = pen.PlayerKillUnprovoked or -120
        elseif ctx.actionType == "KNOCKOUT" then d = pen.PlayerKnockoutUnprovoked or -25
        else d = pen.PlayerAssaultUnprovoked or -15 end
    elseif ctx.targetType == "LAWMAN" then
        if ctx.actionType == "KILL" then d = pen.LawmanKill or -80
        elseif ctx.actionType == "KNOCKOUT" then d = pen.LawmanKnockout or -35
        else d = pen.LawmanAssault or -15 end
    else -- CIVILIAN
        if ctx.actionType == "KILL" then d = pen.CivilianKill or -35
        elseif ctx.actionType == "KNOCKOUT" then d = pen.CivilianKnockout or -10
        else d = pen.CivilianAssault or -5 end
    end

    local bType = "assault"
    local bLabel = "AGRESSÃO"
    if ctx.actionType == "KILL" then
        bType = "kill"
        bLabel = "KILL DIRETO"
    elseif ctx.actionType == "KNOCKOUT" then
        bType = "knockout"
        bLabel = "NOCAUTE"
    end

    return d, tostring(d) .. " pts", bType, bLabel
end

---Estágio 8: Despacho Autorizado, Log F8 e Telemetria no HUD
---@param ctx CombatContext
---@return boolean success, string? reason
function CombatStages.Dispatch(ctx)
    local now = GetGameTimer()
    KarmaState.lastCombatTime = now

    if ctx.actionType == "KILL" then
        KarmaState.deadPeds[ctx.victim] = now
        KarmaState.knockedOutPeds[ctx.victim] = nil
    elseif ctx.actionType == "KNOCKOUT" then
        KarmaState.knockedOutPeds[ctx.victim] = now
        KarmaState.deadPeds[ctx.victim] = nil
    else
        KarmaState.recentAssaults[ctx.victim] = now
    end

    local deltaNum, deltaFormatted, badgeType, badgeLabel = CombatStages.CalculateEstimatedDelta(ctx)
    ctx.estimatedDelta = deltaNum

    -- Rastreamento estruturado no F8 / Logger do Core / txAdmin
    CombatPipeline.PrintSuccess(ctx, deltaFormatted)

    -- Telemetria no HUD
    KarmaHUD:PushLog(
        badgeType,
        badgeLabel,
        string.format("%s #%d | %s | %s", ctx.targetType, ctx.victim, ctx.actionType, ctx.weaponLabel),
        deltaFormatted,
        deltaNum
    )

    ---@type CombatActionPayload
    local payload = {
        targetType = ctx.targetType,
        actionType = ctx.actionType,
        initiative = ctx.initiative,
        isNegative = (ctx.initiative == "UNPROVOKED"),
        weaponHash = ctx.weaponHash,
        victimServerId = ctx.victimServerId,
        wasKnockedOut = (ctx.actionType == "KILL" and KarmaState.knockedOutPeds[ctx.victim] ~= nil),
        wasAssaulted = (ctx.actionType == "KILL" and KarmaState.recentAssaults[ctx.victim] ~= nil)
    }

    TriggerServerEvent('westrp_karma:server:onCombatAction', payload)
    return true
end

---Lista ordenada dos 8 estágios executados sequencialmente pela pipeline
CombatStages.List = {
    CombatStages.Sanity,
    CombatStages.Authorship,
    CombatStages.TargetType,
    CombatStages.Weapon,
    CombatStages.Outcome,
    CombatStages.Initiative,
    CombatStages.Deduplication,
    CombatStages.Dispatch
}
