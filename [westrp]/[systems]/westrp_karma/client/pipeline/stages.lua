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

    -- 1. Verifica montaria do jogador
    if not isDirect and IsPedOnMount(ctx.playerPed) then
        isDirect = (ctx.culprit == GetMount(ctx.playerPed))
    end

    -- 2. Verifica veículo/carroça do jogador
    if not isDirect and IsPedInAnyVehicle(ctx.playerPed, false) then
        local veh = GetVehiclePedIsIn(ctx.playerPed, false)
        if veh and veh ~= 0 and ctx.culprit == veh then
            isDirect = true
        end
    end

    -- 3. Verifica se é vítima de sangramento prévio causado pelo jogador
    if not isDirect and KarmaState.bleedingVictims[ctx.victim] then
        if KarmaState.bleedingVictims[ctx.victim].author == ctx.playerPed then
            isDirect = true
        end
    end

    -- 4. Verifica native de dano físico direto
    if not isDirect then
        local ok, damaged = pcall(HasEntityBeenDamagedByEntity, ctx.victim, ctx.playerPed, 1)
        if not ok or not damaged then
            ok, damaged = pcall(HasEntityBeenDamagedByEntity, ctx.victim, ctx.playerPed, true)
        end
        if ok and damaged then
            isDirect = true
        end
    end

    -- 5. Verifica fonte da morte
    if not isDirect then
        local sourceDeath = GetPedSourceOfDeath(ctx.victim)
        ctx.killerSource = sourceDeath
        if sourceDeath == ctx.playerPed or (IsPedOnMount(ctx.playerPed) and sourceDeath == GetMount(ctx.playerPed)) then
            isDirect = true
        end
    end

    -- 6. Verifica alvo de combate corporal / mira ativa
    if not isDirect then
        if IsPedInMeleeCombat(ctx.playerPed) and GetMeleeTargetForPed(ctx.playerPed) == ctx.victim then
            isDirect = true
        end
    end

    -- 7. Verifica se o jogador estava em mira livre mirando na vítima
    if not isDirect then
        local isAiming, aimEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
        if isAiming and aimEntity == ctx.victim then
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
---@return boolean success, string? reason, boolean? isSilentHalt
function CombatStages.TargetType(ctx)
    local targetType = KarmaState.ClassifyTarget(ctx.victim)
    if targetType == "ANIMAL" then
        return false, "Alvo é um animal (ignorado pelo sistema de moralidade humana)", true
    end
    if targetType == "UNKNOWN" then
        return false, "Tipo de alvo desconhecido ou entidade não reconhecida", true
    end

    -- Canal Autoritativo de PvP: A pipeline cliente processa o ecossistema PvE de IA.
    -- Disparos e mortes de jogadores reais são arbitrados pelo servidor via VORP Core.
    if targetType == "PLAYER" then
        local pIdx = NetworkGetPlayerIndexFromPed(ctx.victim)
        local sId = (pIdx and pIdx ~= -1) and GetPlayerServerId(pIdx) or nil
        if sId and sId > 0 then
            local dmgLoc, _ = KarmaState.GetDamageLocation(ctx.victim)
            local isHeadshot = (dmgLoc == "HEAD")
            local heldWeapon = KarmaState.GetPlayerHeldWeapon(ctx.playerPed)
            local rawWeapon = 0
            if ctx.args then
                local candidates = { ctx.args[7], ctx.args[5], ctx.args[8], ctx.args[9] }
                for _, c in ipairs(candidates) do
                    local num = tonumber(c)
                    if num and num ~= 0 and not Weapons.IsUnarmed(num) then
                        rawWeapon = num
                        break
                    end
                end
            end
            local resolvedWeapon = Weapons.ResolveWeaponFromAmmo((rawWeapon ~= 0 and rawWeapon or heldWeapon), heldWeapon)
            TriggerServerEvent('westrp_karma:server:reportPvPAggression', sId, isHeadshot, resolvedWeapon)
        end
        if KarmaHUD:IsVisible() then
            KarmaHUD:PushLog(
                "pvp",
                "PvP ENGAGED",
                string.format("Confronto com Cidadão [ID: %s] | Arbitragem pelo Servidor", tostring(sId or "—")),
                "0 pts",
                0
            )
        end
        return false, "Alvo é jogador humano (Processado pelo Canal Autoritativo de PvP no Servidor)", true
    end

    ctx.targetType = targetType
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

    -- Varre múltiplos índices potenciais de arma/munição nos argumentos de CEventNetworkEntityDamage
    local rawWeapon = 0
    if ctx.args then
        local candidates = { ctx.args[7], ctx.args[5], ctx.args[8], ctx.args[9] }
        for _, c in ipairs(candidates) do
            local num = tonumber(c)
            if num and num ~= 0 and not Weapons.IsUnarmed(num) then
                rawWeapon = num
                break
            end
        end
    end

    local heldWeapon = KarmaState.GetPlayerHeldWeapon(ctx.playerPed)

    if not cause or cause == 0 or Weapons.IsUnarmed(cause) then
        if rawWeapon and rawWeapon ~= 0 and not Weapons.IsUnarmed(rawWeapon) then
            cause = rawWeapon
        elseif ctx.weaponHash and ctx.weaponHash ~= 0 and not Weapons.IsUnarmed(ctx.weaponHash) then
            cause = ctx.weaponHash
        else
            cause = heldWeapon
        end
    end

    -- Se a hash for de munição ou desconhecida, resolve via família balística
    local resolvedWeapon = Weapons.ResolveWeaponFromAmmo(cause, heldWeapon)
    ctx.weaponHash = resolvedWeapon
    ctx.weaponLabel = Weapons.GetWeaponLabel(resolvedWeapon)

    -- Distância balística euclidiana
    local pCoords = GetEntityCoords(ctx.playerPed)
    local vCoords = GetEntityCoords(ctx.victim)
    local dist = #(pCoords - vCoords)

    ---@type BallisticDetails
    ctx.ballistic = {
        weaponCategory = Weapons.GetWeaponCategory(resolvedWeapon),
        ammoHash = (rawWeapon and rawWeapon ~= 0) and rawWeapon or nil,
        damageBone = 0,
        isHeadshot = false,
        distanceMeters = math.floor(dist * 10) / 10,
        isBleedoutPromotion = false
    }

    return true
end

---Estágio 5: Desfecho do Confronto (KILL vs KNOCKOUT vs ASSAULT)
---@param ctx CombatContext
---@return boolean success, string? reason
function CombatStages.Outcome(ctx)
    -- 1. Análise Anatômica Óssea do Impacto (Headshot & Dano Crítico)
    local damageLocation, boneId = KarmaState.GetDamageLocation(ctx.victim)
    local isHeadshot = (damageLocation == "HEAD")

    if ctx.ballistic then
        ctx.ballistic.damageBone = boneId
        ctx.ballistic.isHeadshot = isHeadshot
    end

    -- 2. Verificação de Óbito
    local isDead = KarmaState.IsPedActuallyDead(ctx.victim)
    local hp = GetEntityHealth(ctx.victim)

    -- Flag explícita do motor de jogo (args[4] ou args[6]) com suporte a boolean e int
    local isFatalArg = false
    if ctx.args then
        isFatalArg = (ctx.args[4] == 1 or ctx.args[4] == true or ctx.args[4] == 1.0 or tostring(ctx.args[4]) == "1" or tostring(ctx.args[4]) == "true")
            or (ctx.args[6] == 1 or ctx.args[6] == true or ctx.args[6] == 1.0 or tostring(ctx.args[6]) == "1" or tostring(ctx.args[6]) == "true")
    end

    if not isDead and (hp <= 0 or isFatalArg) then
        isDead = true
    end

    -- Se for Headshot (tiro na cabeça com arma de fogo ou projétil letal)
    if not isDead and isHeadshot then
        if not Weapons.IsUnarmed(ctx.weaponHash) or hp <= 50 then
            isDead = true
        end
    end

    -- Se o ped está em animação terminal de morte (p1=true no RDR3)
    if not isDead then
        local okDying, isDying = pcall(IsPedDeadOrDying, ctx.victim, true)
        if okDying and isDying and not Weapons.IsUnarmed(ctx.weaponHash) then
            isDead = true
        end
    end

    -- Padrão fatal do baseevents
    if not isDead then
        local okFatally, fatallyInjured = pcall(IsPedFatallyInjured, ctx.victim)
        if okFatally and fatallyInjured then
            isDead = true
        end
    end

    if isDead then
        ctx.actionType = "KILL"
        ctx.isDead = true
        KarmaState.knockedOutPeds[ctx.victim] = nil
        return true
    end

    -- 3. Nocaute (Apenas para dano desarmado/não-letal quando NÃO há óbito)
    local isKnockedOut = false
    if Weapons.IsUnarmed(ctx.weaponHash) then
        isKnockedOut = KarmaState.IsPedActuallyKnockedOut(ctx.victim)
        if not isKnockedOut and IsPedRagdoll(ctx.victim) then
            isKnockedOut = true
        end
    end

    if isKnockedOut then
        ctx.actionType = "KNOCKOUT"
        ctx.isKnockedOut = true
        KarmaState.knockedOutPeds[ctx.victim] = GetGameTimer()
        return true
    end

    -- 4. Caso contrário, o alvo continua de pé / ativo: é uma Agressão (ASSAULT)
    ctx.actionType = "ASSAULT"
    ctx.isAssault = true

    -- Se o tiro causou ferimento por arma de fogo ou sangramento lento, registra em bleedingVictims
    if not Weapons.IsUnarmed(ctx.weaponHash) or KarmaState.IsPedInBleedout(ctx.victim) then
        KarmaState.bleedingVictims[ctx.victim] = {
            author = ctx.playerPed,
            weaponHash = ctx.weaponHash,
            assaultTimestamp = GetGameTimer(),
            penaltyPaid = 0,
            isHeadshot = isHeadshot
        }
    end

    return true
end

---Estágio 6: Iniciativa & Análise de Legítima Defesa
---@param ctx CombatContext
---@return boolean success, string? reason
function CombatStages.Initiative(ctx)
    local now = GetGameTimer()
    local durationMs = (Config.SelfDefenseDuration or 45) * 1000

    -- Confrontos contra autoridades da lei (homens da lei) nunca admitem legítima defesa
    if ctx.targetType == "LAWMAN" then
        ctx.initiative = "UNPROVOKED"
        return true
    end

    -- Se o jogador iniciou a agressão contra este ped nos últimos 45 segundos,
    -- qualquer confronto subsequente é de iniciativa do jogador (o jogador foi o provocador)
    if KarmaState.playerAggressions and KarmaState.playerAggressions[ctx.victim] then
        local timeSinceAggression = now - KarmaState.playerAggressions[ctx.victim]
        if timeSinceAggression <= durationMs then
            ctx.initiative = "UNPROVOKED"
            return true
        end
    end

    local attackTime = KarmaState.recentAttackers[ctx.victim]
    local aimTime = KarmaState.recentAimThreats and KarmaState.recentAimThreats[ctx.victim]
    local isSelfDefense = false

    -- 1. Vítima agrediu ou feriu o jogador fisicamente (dano comprovado recebido pelo jogador)
    if attackTime and (now - attackTime) <= durationMs then
        isSelfDefense = true
    -- 2. Vítima hostil não-civil disparou contra o jogador em combate armado ativo
    elseif aimTime and (now - aimTime) <= durationMs then
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
        -- Se for promoção de sangramento anterior (Task 3.2), aprova
        if KarmaState.bleedingVictims[ctx.victim] then
            if ctx.ballistic then
                ctx.ballistic.isBleedoutPromotion = true
                if KarmaState.bleedingVictims[ctx.victim].isHeadshot then
                    ctx.ballistic.isHeadshot = true
                end
            end
            return true
        end

        -- Se a morte já foi confirmada e despachada anteriormente para este Ped (cooldown definitivo de óbito)
        if KarmaState.deadPeds[ctx.victim] then
            return false, "Vítima já processada anteriormente como morta"
        end
    elseif ctx.actionType == "KNOCKOUT" then
        if KarmaState.knockedOutPeds[ctx.victim] and (now - KarmaState.knockedOutPeds[ctx.victim]) < 8000 then
            return false, "Alvo já se encontra desacordado/nocauteado (cooldown 8s)"
        end
    elseif ctx.actionType == "ASSAULT" then
        if KarmaState.recentAssaults[ctx.victim] and (now - KarmaState.recentAssaults[ctx.victim]) < 1800 then
            return false, "Agressão recente ainda em resfriamento (cooldown 1.8s)"
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

    local isHeadshot = ctx.ballistic and ctx.ballistic.isHeadshot

    -- Se for promoção de morte por sangramento tardio (Task 3.2)
    if ctx.ballistic and ctx.ballistic.isBleedoutPromotion then
        local bleedData = KarmaState.bleedingVictims[ctx.victim]
        local alreadyPaid = bleedData and bleedData.penaltyPaid or -5
        local fullPenalty = -35
        if ctx.targetType == "LAWMAN" then
            fullPenalty = isHeadshot and -100 or (Config.Penalties.LawmanKill or -80)
        elseif ctx.targetType == "PLAYER" then
            fullPenalty = isHeadshot and -150 or (Config.Penalties.PlayerKillUnprovoked or -120)
        else
            fullPenalty = isHeadshot and -45 or (Config.Penalties.CivilianKill or -35)
        end

        local remainingDelta = fullPenalty - alreadyPaid
        if remainingDelta > 0 then remainingDelta = 0 end
        local bLabel = isHeadshot and "ÓBITO HEADSHOT (BLEEDOUT)" or "ÓBITO (BLEEDOUT)"
        local bType = isHeadshot and "headshot" or "bleedout"
        return remainingDelta, tostring(remainingDelta) .. " pts", bType, bLabel
    end

    -- Não provocado
    local pen = Config.Penalties or {}
    local d = 0

    if ctx.targetType == "PLAYER" then
        if ctx.actionType == "KILL" then
            d = isHeadshot and -150 or (pen.PlayerKillUnprovoked or -120)
        elseif ctx.actionType == "KNOCKOUT" then
            d = pen.PlayerKnockoutUnprovoked or -25
        else
            d = pen.PlayerAssaultUnprovoked or -15
        end
    elseif ctx.targetType == "LAWMAN" then
        if ctx.actionType == "KILL" then
            d = isHeadshot and -100 or (pen.LawmanKill or -80)
        elseif ctx.actionType == "KNOCKOUT" then
            d = pen.LawmanKnockout or -35
        else
            d = pen.LawmanAssault or -15
        end
    else -- CIVILIAN
        if ctx.actionType == "KILL" then
            d = isHeadshot and -45 or (pen.CivilianKill or -35)
        elseif ctx.actionType == "KNOCKOUT" then
            d = pen.CivilianKnockout or -10
        else
            d = pen.CivilianAssault or -5
        end
    end

    local bType = "assault"
    local bLabel = "AGRESSÃO"
    if ctx.actionType == "KILL" then
        bType = isHeadshot and "headshot" or "kill"
        bLabel = isHeadshot and "HEADSHOT KILL" or "KILL DIRETO"
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

    local deltaNum, deltaFormatted, badgeType, badgeLabel = CombatStages.CalculateEstimatedDelta(ctx)
    ctx.estimatedDelta = deltaNum

    local isBleedoutPromo = (ctx.ballistic and ctx.ballistic.isBleedoutPromotion) == true

    if ctx.actionType == "KILL" then
        KarmaState.deadPeds[ctx.victim] = now
        KarmaState.knockedOutPeds[ctx.victim] = nil
        KarmaState.bleedingVictims[ctx.victim] = nil
    elseif ctx.actionType == "KNOCKOUT" then
        KarmaState.knockedOutPeds[ctx.victim] = now
        KarmaState.deadPeds[ctx.victim] = nil
    else
        KarmaState.recentAssaults[ctx.victim] = now
        if KarmaState.bleedingVictims[ctx.victim] then
            KarmaState.bleedingVictims[ctx.victim].penaltyPaid = deltaNum
        end
    end

    -- Registra que o jogador foi o agressor inicial contra este alvo se a iniciativa foi não provocada
    if ctx.initiative == "UNPROVOKED" then
        KarmaState.playerAggressions[ctx.victim] = now
    end

    -- Rastreamento estruturado no F8 / Logger do Core / txAdmin
    CombatPipeline.PrintSuccess(ctx, deltaFormatted)

    -- Telemetria no HUD
    local distSuffix = (ctx.ballistic and ctx.ballistic.distanceMeters) and string.format(" | %.1fm", ctx.ballistic.distanceMeters) or ""
    KarmaHUD:PushLog(
        badgeType,
        badgeLabel,
        string.format("%s #%d | %s | %s%s", ctx.targetType, ctx.victim, ctx.actionType, ctx.weaponLabel, distSuffix),
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
        wasAssaulted = (ctx.actionType == "KILL" and (isBleedoutPromo or KarmaState.recentAssaults[ctx.victim] ~= nil)),
        isHeadshot = (ctx.ballistic and ctx.ballistic.isHeadshot) or false,
        distanceMeters = (ctx.ballistic and ctx.ballistic.distanceMeters) or 0,
        weaponCategory = (ctx.ballistic and ctx.ballistic.weaponCategory) or "UNARMED",
        isBleedoutPromotion = isBleedoutPromo
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
