-- ====================================================================
-- WestRP Karma — O CORAÇÃO DO SISTEMA DE DETECÇÃO DE COMBATE E MORALIDADE
-- Arquivo: client/combat_detector.lua
-- ====================================================================
--
-- COMO O SISTEMA FUNCIONA (VISÃO GERAL PARA O DESENVOLVEDOR):
-- 
-- No RedM, todo o combate físico (socos, chutes, estrangulamentos, armas e física
-- Euphoria/ragdoll de NPCs) roda LOCALMENTE na máquina do jogador (Client).
-- Portanto, o "Client" é quem tem acesso aos dados em tempo real da vítima e do agressor.
--
-- O sistema opera em 2 CAMADAS COMPLEMENTARES:
--
-- CAMADA 1: Evento Nativo 'CEventNetworkEntityDamage'
--   - Disparado pelo motor do jogo instantaneamente quando qualquer entidade sofre dano.
--   - Captura socos, tiros, facadas e quem bateu em quem.
--   - Gerencia a iniciativa: se o NPC bateu no jogador primeiro, o jogador ganha
--     "Legítima Defesa" por X segundos (Config.SelfDefenseDuration).
--
-- CAMADA 2: Varredura de Suporte em Thread (Asfixia / Grapple / Nocautes Silenciosos)
--   - Por que ela existe? No RDR2, quando você estrangula um NPC por trás (grapple stealth choke),
--     o jogo executa uma sequência de animações. No momento em que o NPC desmaia e colapsa
--     em ragdoll, NÃO é emitido nenhum evento fatal de dano!
--   - Esta thread monitora alvos próximos que o jogador estava atacando ou agarrando
--     e detecta quando o Ped colapsa inconsciente no chão, despachando o "KNOCKOUT".
-- ====================================================================

-- --------------------------------------------------------------------
-- ESTRUTURAS DE MEMÓRIA LOCAL DO CLIENTE
-- --------------------------------------------------------------------

---Memória de agressores hostis que atacaram o jogador primeiro.
---Chave: entityId (Ped), Valor: timestamp (GetGameTimer) em que a legítima defesa expira.
local hostileAggressors = {}

---Memória de Peds recentemente engajados pelo jogador em combate corporal ou mira próxima.
---Chave: entityId (Ped), Valor: timestamp de expiração (15 segundos).
local recentAttackedPeds = {}

---Estado consolidado de cada vítima: nil -> "ASSAULT" -> "KNOCKOUT" -> "KILL"
---Evita envio repetido de eventos de combate para a mesma vítima em um mesmo estágio.
local entityStates = {}

---Controle de debounce para agressões corporais menores (socos sem nocaute em alvos de pé).
local lastAssaultTime = {}

---Timestamp da última ação de combate corpo a corpo do jogador (para acelerar o loop de varredura).
local lastMeleeCombatTime = 0

-- --------------------------------------------------------------------
-- GRUPOS DE RELACIONAMENTO DE AUTORIDADES NO RDR2
-- --------------------------------------------------------------------
local lawRelationshipHashes = {
    [GetHashKey("LAW")] = true,
    [GetHashKey("COP")] = true,
    [GetHashKey("REL_COP")] = true,
    [GetHashKey("DISPATCH_POLICE")] = true,
    [GetHashKey("GUARDS")] = true,
    [GetHashKey("REL_GUARDS")] = true
}

---Obtém o alvo de combate atual de um Ped usando a nativa segura do RedM (0xCD387431B32A999F)
---@param ped integer Handle da entidade Ped
---@return integer targetPed Retorna o Ped que este NPC está atacando ou 0
local function GetNpcCombatTarget(ped)
    local ok, target = pcall(function()
        if GetCombatTargetForPed then
            return GetCombatTargetForPed(ped)
        end
        return Citizen.InvokeNative(0xCD387431B32A999F, ped)
    end)
    return (ok and target) or 0
end

---Classifica a categoria do alvo com base em sua natureza e grupo de relacionamento
---@param ped integer
---@return "PLAYER" | "CIVILIAN" | "LAWMAN" | "ANIMAL"
local function ClassifyTarget(ped)
    -- 1. Se for outro jogador conectado
    if IsPedAPlayer(ped) then
        return "PLAYER"
    end

    -- 2. Se for um animal da fauna (cavalos soltos, cervos, pássaros, etc.)
    if not IsPedHuman(ped) then
        return "ANIMAL"
    end

    -- 3. Se for autoridade da lei (xerifes, policiais, guardas bancários)
    local defaultRel = GetPedRelationshipGroupDefaultHash(ped)
    local currentRel = GetPedRelationshipGroupHash(ped)
    if lawRelationshipHashes[defaultRel] or lawRelationshipHashes[currentRel] then
        return "LAWMAN"
    end

    -- 4. Padrão: Cidadão civil local
    return "CIVILIAN"
end

---Avalia a severidade física da ação sofrida pelo alvo (ASSAULT, KNOCKOUT ou KILL)
---@param ped integer Entidade da vítima
---@param isFatalFlag boolean? Flag nativa de dano letal (vinda do evento de dano)
---@param weaponHash integer? Hash da arma utilizada
---@param previousState ("ASSAULT" | "KNOCKOUT" | "KILL")? Estado prévio registrado
---@return "KILL" | "KNOCKOUT" | "ASSAULT"
local function EvaluateActionSeverity(ped, isFatalFlag, weaponHash, previousState)
    -- Verifica se a entidade colapsou no chão:
    -- - isFatalFlag: o evento do jogo marcou o dano como fatal
    -- - IsEntityDead: o motor marcou a entidade como morta/inoperante
    -- - IsPedDeadOrDying: o ped está em processo de morte ou inconsciente
    -- - IsPedRagdoll: a física Euphoria desativou o ped (comum em nocautes e asfixia)
    local isDown = isFatalFlag or IsEntityDead(ped) or IsPedDeadOrDying(ped, true) or IsPedRagdoll(ped)
    local isUnarmed = Weapons.IsUnarmed(weaponHash)

    if isDown then
        if isUnarmed then
            -- REGRA DO COMBATE DESARMADO:
            -- No RDR2, socos e estrangulamentos NÃO matam imediatamente; eles NOCAUTEIAM o alvo!
            if previousState ~= "KNOCKOUT" then
                return "KNOCKOUT"
            else
                -- Se o alvo já estava no chão nocauteado e o jogador continuou chutando/batendo,
                -- aí sim ocorre a transição para EXECUÇÃO DE ALVO DESACORDADO (KILL).
                return "KILL"
            end
        else
            -- Armas de fogo, facas, explosivos ou armas brancas letais geram MORTE direta ao derrubar
            return "KILL"
        end
    end

    -- Se o ped tomou o golpe mas ainda está de pé e ativo:
    return "ASSAULT"
end

---Processa e despacha a ação de combate para o servidor e emite logs formatados no F8
---@param victim integer Entidade da vítima
---@param actionType "KILL" | "KNOCKOUT" | "ASSAULT" Tipo de severidade apurada
---@param initiative "UNPROVOKED" | "SELF_DEFENSE" Quem começou a briga
---@param weaponHash integer Hash da arma usada
local function DispatchCombatAction(victim, actionType, initiative, weaponHash)
    if not DoesEntityExist(victim) then return end

    local previousState = entityStates[victim]

    -- Se o corpo já foi finalizado como morto, não despacha novos eventos de combate
    if previousState == "KILL" then
        return
    end

    -- Se o alvo já foi nocauteado e tentou disparar nocaute novamente, ignora
    if actionType == "KNOCKOUT" and previousState == "KNOCKOUT" then
        return
    end

    -- Debounce para agressões corporais em pé (evita flood no console a cada soco rápido em briga de bar)
    local now = GetGameTimer()
    if actionType == "ASSAULT" then
        if previousState == "KNOCKOUT" then return end
        if lastAssaultTime[victim] and (now - lastAssaultTime[victim]) < 3000 then
            return
        end
        lastAssaultTime[victim] = now
    end

    -- Detecta se uma morte foi uma execução de alguém que já estava desacordado no chão
    local wasKnockedOut = (previousState == "KNOCKOUT" and actionType == "KILL")
    entityStates[victim] = actionType

    local targetType = ClassifyTarget(victim)
    local isNegative = (initiative == "UNPROVOKED") and (targetType ~= "ANIMAL")
    local weaponLabel = Weapons.GetWeaponLabel(weaponHash)

    -- Se a vítima for outro jogador, resolve o ServerID da sessão de rede
    local victimServerId = nil
    if targetType == "PLAYER" then
        local playerIdx = NetworkGetPlayerIndexFromPed(victim)
        if playerIdx and playerIdx ~= -1 then
            victimServerId = GetPlayerServerId(playerIdx)
        end
    end

    -- ================================================================
    -- LOGS FORMATADOS NO CONSOLE F8 (CLIENTE)
    -- ================================================================
    if targetType == "ANIMAL" then
        if Config.Debug then
            print(string.format("^3[westrp_karma:client] AÇÃO EM ANIMAL: Ped: %d | Ação: %s (Ignorado pelo Karma)^0", victim, actionType))
        end
        return
    end

    if isNegative then
        print(string.format("^1[westrp_karma:client] ATITUDE NEGATIVA DETECTADA!^0\n" ..
            "  -> Iniciativa: NÃO PROVOCADA (Iniciada pelo Jogador)\n" ..
            "  -> Alvo: %s (Ped: %d%s)\n" ..
            "  -> Ação: %s%s\n" ..
            "  -> Arma: %s",
            targetType, victim, victimServerId and (" | ServerID: " .. victimServerId) or "",
            actionType, wasKnockedOut and " (Execução de alvo desacordado)" or "",
            weaponLabel))
    else
        print(string.format("^2[westrp_karma:client] AÇÃO DE LEGÍTIMA DEFESA!^0\n" ..
            "  -> Iniciativa: DEFESA (O alvo atacou o jogador primeiro)\n" ..
            "  -> Alvo: %s (Ped: %d)\n" ..
            "  -> Ação: %s\n" ..
            "  -> Arma: %s\n" ..
            "  -> Resultado: Honra Preservada",
            targetType, victim, actionType, weaponLabel))
    end

    -- ================================================================
    -- ENVIO DO EVENTO AO SERVIDOR (CONTRATO UNIFICADO)
    -- ================================================================
    ---@type CombatActionPayload
    local payload = {
        targetType = targetType,
        actionType = actionType,
        initiative = initiative,
        isNegative = isNegative,
        weaponHash = weaponHash or 0,
        victimServerId = victimServerId,
        wasKnockedOut = wasKnockedOut
    }

    TriggerServerEvent('westrp_karma:server:onCombatAction', payload)
end

-- ====================================================================
-- CAMADA 1: ESCUTA DE EVENTOS NATIVOS DO MOTOR (CEventNetworkEntityDamage)
-- ====================================================================
AddEventHandler('gameEventTriggered', function(eventName, data)
    if eventName ~= 'CEventNetworkEntityDamage' then return end

    local victim = data[1]
    local attacker = data[2]
    local isFatalFlag = (data[4] == 1) or (data[6] == 1)
    local weaponHash = data[7] or 0
    local playerPed = PlayerPedId()

    if not DoesEntityExist(victim) then return end

    -- ----------------------------------------------------------------
    -- CASO 1: O JOGADOR RECEBEU DANO (Quem atacou o jogador primeiro?)
    -- ----------------------------------------------------------------
    if victim == playerPed then
        if DoesEntityExist(attacker) and attacker ~= playerPed then
            local duration = (Config.SelfDefenseDuration or 45) * 1000
            hostileAggressors[attacker] = GetGameTimer() + duration

            if Config.Debug then
                local isPlayer = IsPedAPlayer(attacker)
                print(string.format("^3[westrp_karma:client] AGRESSÃO RECEBIDA! Alvo %s (Ped: %d) iniciou ataque contra você! Legítima defesa ativa por %ds.^0",
                    isPlayer and "JOGADOR" or "NPC", attacker, Config.SelfDefenseDuration or 45))
            end
        end
        return
    end

    -- ----------------------------------------------------------------
    -- CASO 2: O JOGADOR CAUSOU DANO EM ALGUÉM
    -- ----------------------------------------------------------------
    local isAttacker = (attacker == playerPed)
    if not isAttacker and IsPedOnMount(playerPed) then
        isAttacker = (attacker == GetMount(playerPed))
    end

    if not isAttacker and DoesEntityExist(victim) then
        local killer = GetPedSourceOfDeath(victim)
        if killer == playerPed or (IsPedOnMount(playerPed) and killer == GetMount(playerPed)) then
            isAttacker = true
        elseif HasEntityBeenDamagedByEntity(victim, playerPed, 1) then
            isAttacker = true
        end
    end

    if isAttacker and victim ~= playerPed then
        local now = GetGameTimer()
        recentAttackedPeds[victim] = now + 15000
        lastMeleeCombatTime = now

        -- Checagem de Iniciativa: O alvo já havia agredido o jogador ou está com IA hostil contra ele?
        local isDefending = hostileAggressors[victim] and (now < hostileAggressors[victim])
        if not isDefending and not IsPedAPlayer(victim) then
            if IsPedInCombat(victim, playerPed) or GetNpcCombatTarget(victim) == playerPed then
                isDefending = true
            end
        end

        local initiative = isDefending and "SELF_DEFENSE" or "UNPROVOKED"
        local actionType = EvaluateActionSeverity(victim, isFatalFlag, weaponHash, entityStates[victim])

        DispatchCombatAction(victim, actionType, initiative, weaponHash)
    end
end)

-- ====================================================================
-- CAMADA 2: VARREDURA DE SUPORTE PARA ASFIXIA, AGARRO E COLAPSO (GRAVI-CHOKE)
-- ====================================================================
-- Esta thread existe exclusivamente para capturar quando um NPC cai
-- inconsciente ou morre sem disparar o evento CEventNetworkEntityDamage
-- (caso clássico de estrangulamento por trás / stealth choke no RDR2).
-- ====================================================================
CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local now = GetGameTimer()

        -- Registra Ped sob mira/agarro próximo do jogador
        local hasTarget, targetPed = GetPlayerTargetEntity(PlayerId())
        if hasTarget and DoesEntityExist(targetPed) and IsEntityAPed(targetPed) and targetPed ~= playerPed then
            local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(targetPed))
            if dist <= 3.0 then
                recentAttackedPeds[targetPed] = now + 15000
                lastMeleeCombatTime = now
            end
        end

        -- Executa checagem de alta frequência (150ms) somente durante ou logo após combate corporal
        if (now - lastMeleeCombatTime) < 8000 or IsPedInMeleeCombat(playerPed) then
            sleep = 150
            local playerCoords = GetEntityCoords(playerPed)
            local peds = GetGamePool('CPed')

            for i = 1, #peds do
                local ped = peds[i]
                if ped ~= playerPed and DoesEntityExist(ped) then
                    local state = entityStates[ped]

                    -- CRÍTICO: Se o ped já está "KNOCKOUT" ou "KILL", a varredura NÃO mexe nele!
                    -- Ele só deve ser promovido a "KILL" se o jogador ativamente bater nele de novo
                    -- (o que dispara o evento CEventNetworkEntityDamage na Camada 1 acima).
                    if state ~= "KILL" and state ~= "KNOCKOUT" then
                        local killer = GetPedSourceOfDeath(ped)
                        local mount = IsPedOnMount(playerPed) and GetMount(playerPed) or nil
                        local isRecentTarget = recentAttackedPeds[ped] and (now < recentAttackedPeds[ped])
                        local isAuthor = (killer == playerPed) or (mount and killer == mount) or HasEntityBeenDamagedByEntity(ped, playerPed, 1) or isRecentTarget

                        if isAuthor then
                            local dist = #(playerCoords - GetEntityCoords(ped))
                            if dist <= 10.0 then
                                local _, currentWeapon = GetCurrentPedWeapon(playerPed, true, 0, false)
                                local isDefending = hostileAggressors[ped] and (now < hostileAggressors[ped])
                                local initiative = isDefending and "SELF_DEFENSE" or "UNPROVOKED"
                                local severity = EvaluateActionSeverity(ped, false, currentWeapon or 0, state)

                                if severity == "KNOCKOUT" then
                                    DispatchCombatAction(ped, "KNOCKOUT", initiative, currentWeapon or 0)
                                elseif severity == "KILL" then
                                    DispatchCombatAction(ped, "KILL", initiative, currentWeapon or 0)
                                end
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ====================================================================
-- LIMPEZA PERIÓDICA DE MEMÓRIA (GARBAGE COLLECTION)
-- ====================================================================
CreateThread(function()
    while true do
        Wait(60000)
        local now = GetGameTimer()
        for ped, expiry in pairs(hostileAggressors) do
            if now > expiry or not DoesEntityExist(ped) then
                hostileAggressors[ped] = nil
            end
        end
        for ped, expiry in pairs(recentAttackedPeds) do
            if now > expiry or not DoesEntityExist(ped) then
                recentAttackedPeds[ped] = nil
            end
        end
        for ped in pairs(entityStates) do
            if not DoesEntityExist(ped) then
                entityStates[ped] = nil
                lastAssaultTime[ped] = nil
            end
        end
    end
end)
