-- ====================================================================
-- WestRP Karma — Server: Core Controller & Morality Engine
-- File: server/main.lua
-- ====================================================================

---@class Karma
Karma = {}

-- ====================================================================
-- SISTEMA DE LOGGING PADRONIZADO (INTEGRADO AO WESTRP_CORE)
-- ====================================================================
local function LogDebug(tag, msg, ...)
    if WestRP and WestRP.Shared and WestRP.Shared.Logger and WestRP.Shared.Logger.Debug then
        WestRP.Shared.Logger.Debug(tag, msg, ...)
    elseif Config.Debug then
        local formatted = (select('#', ...) > 0) and string.format(msg, ...) or tostring(msg)
        print(string.format("^5[DEBUG]^7 [^3%s^7] %s^0", tag, formatted))
    end
end

local function LogInfo(tag, msg, ...)
    if WestRP and WestRP.Shared and WestRP.Shared.Logger and WestRP.Shared.Logger.Info then
        WestRP.Shared.Logger.Info(tag, msg, ...)
    else
        local formatted = (select('#', ...) > 0) and string.format(msg, ...) or tostring(msg)
        print(string.format("^2[INFO]^7 [^3%s^7] %s^0", tag, formatted))
    end
end

local function LogWarn(tag, msg, ...)
    if WestRP and WestRP.Shared and WestRP.Shared.Logger and WestRP.Shared.Logger.Warn then
        WestRP.Shared.Logger.Warn(tag, msg, ...)
    else
        local formatted = (select('#', ...) > 0) and string.format(msg, ...) or tostring(msg)
        print(string.format("^3[WARN]^7 [^3%s^7] %s^0", tag, formatted))
    end
end

local VorpCore = nil

---Obtém a instância do VORP Core de forma segura através do Bridge
local function GetVorpCore()
    if not VorpCore then
        local ok, core = pcall(function()
            return exports.vorp_core:GetCore()
        end)
        if ok and core then
            VorpCore = core
        end
    end
    return VorpCore
end

---Obtém o charIdentifier de um jogador ativo através do VORP Core
---@param source integer
---@return integer?
function Karma.GetCharIdentifier(source)
    local core = GetVorpCore()
    if not core then return nil end

    local user = core.getUser(source)
    if not user then return nil end

    local char = user.getUsedCharacter
    return char and char.charIdentifier
end

---Inicializa ou sincroniza os dados morais do jogador ao logar
---@param source integer
---@param charIdentifier integer
---@return CharacterKarmaData
function Karma.OnPlayerLoad(source, charIdentifier)
    local entity = Database.Load(charIdentifier, source)

    -- Sincroniza o cliente com seu estado moral atual
    TriggerClientEvent('westrp_karma:client:onKarmaUpdated', source, {
        currentKarma = entity.karma,
        delta = 0,
        tier = entity.tier,
        reason = "LOGIN_SYNC"
    })

    return entity
end

---Descarrega o jogador da memória ao desconectar
---@param source integer
function Karma.OnPlayerDrop(source)
    Database.Unload(source)
end

---Aplica uma variação de karma com cálculo de patamares e eventos
---@param source integer
---@param amount integer
---@param reason string
---@return boolean success
---@return integer? newKarma
function Karma.Modify(source, amount, reason)
    local entity = Database.GetBySource(source)
    if not entity then
        local charId = Karma.GetCharIdentifier(source)
        if charId then
            entity = Database.Load(charId, source)
        else
            return false, nil
        end
    end

    local oldTier = entity.tier
    entity.karma = math.max(-1000, math.min(1000, entity.karma + amount))
    entity.tier = TierEvaluator.Resolve(entity.karma)
    entity.isDirty = true

    -- Sincroniza com o cliente
    TriggerClientEvent('westrp_karma:client:onKarmaUpdated', source, {
        currentKarma = entity.karma,
        delta = amount,
        tier = entity.tier,
        reason = reason
    })

    -- Transição de patamar moral
    if oldTier.id ~= entity.tier.id then
        TriggerEvent('westrp_karma:server:onTierChanged', source, oldTier, entity.tier)
    end

    if Config.Debug then
        LogDebug("KARMA_SERVER", "ModifyKarma [%d]: Delta=%d -> Total=%d (Tier: %s) Motivo: %s",
            source, amount, entity.karma, entity.tier.name, reason or "")
    end

    return true, entity.karma
end

---Define diretamente uma pontuação moral fixa
---@param source integer
---@param newKarma integer
---@param reason string?
---@return boolean success
---@return integer? newKarma
function Karma.Set(source, newKarma, reason)
    local entity = Database.GetBySource(source)
    if not entity then
        local charId = Karma.GetCharIdentifier(source)
        if charId then
            entity = Database.Load(charId, source)
        else
            return false, nil
        end
    end

    local oldTier = entity.tier
    local delta = newKarma - entity.karma
    entity.karma = math.max(-1000, math.min(1000, newKarma))
    entity.tier = TierEvaluator.Resolve(entity.karma)
    entity.isDirty = true

    TriggerClientEvent('westrp_karma:client:onKarmaUpdated', source, {
        currentKarma = entity.karma,
        delta = delta,
        tier = entity.tier,
        reason = reason or "SET_KARMA"
    })

    if oldTier.id ~= entity.tier.id then
        TriggerEvent('westrp_karma:server:onTierChanged', source, oldTier, entity.tier)
    end

    return true, entity.karma
end

---Retorna a pontuação moral numérica de um jogador
---@param source integer
---@return integer
function Karma.Get(source)
    local entity = Database.GetBySource(source)
    return entity and entity.karma or Config.DefaultKarma
end

---Retorna o Tier moral do jogador
---@param source integer
---@return KarmaTier
function Karma.GetTier(source)
    local entity = Database.GetBySource(source)
    return entity and entity.tier or TierEvaluator.Resolve(Config.DefaultKarma)
end

-- ====================================================================
-- PROCESSAMENTO DE EVENTOS DE COMBATE
-- ====================================================================

---Processa e avalia as ações de combate despachadas pelos clientes
---@param attackerSrc integer ID da sessão do jogador agressor
---@param payload CombatActionPayload Dados completos da ação e iniciativa
function Karma.ProcessCombatAction(attackerSrc, payload)
    if not payload or not attackerSrc or attackerSrc <= 0 then return end

    if payload.targetType == "ANIMAL" then
        return -- Animais não alteram a moralidade padrão
    end

    local weaponLabel = Weapons.GetWeaponLabel(payload.weaponHash)

    -- 1. CASO DE LEGÍTIMA DEFESA (O alvo agrediu o jogador primeiro)
    if payload.initiative == "SELF_DEFENSE" then
        if payload.targetType == "PLAYER" then
            LogInfo("KARMA_SERVER", "LEGÍTIMA DEFESA PvP: Jogador [%d] revidou agressão de jogador [%s] (Arma: %s). Honra preservada.",
                attackerSrc, tostring(payload.victimServerId or "desconhecido"), weaponLabel)
        else
            if payload.actionType == "KILL" then
                local reward = Config.Rewards.WantedBanditKill or 15
                Karma.Modify(attackerSrc, reward, "Eliminação de forasteiro hostil")
                LogInfo("KARMA_SERVER", "LEGÍTIMA DEFESA PvE: Jogador [%d] eliminou agressor hostil (Arma: %s | +%d pts).",
                    attackerSrc, weaponLabel, reward)
            else
                LogInfo("KARMA_SERVER", "LEGÍTIMA DEFESA PvE: Jogador [%d] conteve agressor hostil (%s | Arma: %s). Honra preservada.",
                    attackerSrc, payload.actionType, weaponLabel)
            end
        end
        return
    end

    -- 2. CASO DE ATITUDE NEGATIVA NÃO PROVOCADA (Iniciada pelo jogador)
    local delta = 0
    local reason = ""
    local isHeadshot = payload.isHeadshot == true

    if payload.targetType == "PLAYER" then
        if payload.actionType == "KILL" then
            if isHeadshot then
                delta = -150
                reason = "Assassinato de cidadão com tiro na cabeça (PK Headshot)"
            elseif payload.wasKnockedOut then
                delta = -95
                reason = "Execução de cidadão desacordado"
            elseif payload.wasAssaulted then
                delta = -105
                reason = "Assassinato não provocado de outro cidadão (PK)"
            else
                delta = Config.Penalties.PlayerKillUnprovoked or -120
                reason = "Assassinato não provocado de outro cidadão (PK)"
            end
        elseif payload.actionType == "KNOCKOUT" then
            delta = Config.Penalties.PlayerKnockoutUnprovoked or -25
            reason = "Nocaute injustificado de outro cidadão"
        else
            delta = Config.Penalties.PlayerAssaultUnprovoked or -15
            reason = "Agressão armada contra cidadão"
        end
    elseif payload.targetType == "LAWMAN" then
        local killBase = Config.Penalties.LawmanKill or -80
        local assaultBase = Config.Penalties.LawmanAssault or -15
        local knockoutBase = Config.Penalties.LawmanKnockout or -35
        local headshotPenalty = -100

        if payload.actionType == "KILL" then
            if payload.wasAssaulted or payload.isBleedoutPromotion then
                local fullPenalty = isHeadshot and headshotPenalty or killBase
                delta = fullPenalty - assaultBase
                if delta > 0 then delta = 0 end
                reason = isHeadshot
                    and "Óbito de autoridade por tiro na cabeça (Headshot pós-agressão)"
                    or "Óbito de autoridade por ferimentos balísticos (Bleedout)"
            elseif isHeadshot then
                delta = headshotPenalty
                reason = "Assassinato de autoridade com tiro na cabeça (Headshot)"
            elseif payload.wasKnockedOut then
                delta = -45
                reason = "Execução de autoridade desacordada"
            else
                delta = killBase
                reason = "Assassinato de homem da lei"
            end
        elseif payload.actionType == "KNOCKOUT" then
            delta = knockoutBase
            reason = "Nocaute / asfixia contra homem da lei"
        else
            delta = assaultBase
            reason = "Agressão contra autoridade da lei"
        end
    else -- "CIVILIAN"
        local killBase = Config.Penalties.CivilianKill or -35
        local assaultBase = Config.Penalties.CivilianAssault or -5
        local knockoutBase = Config.Penalties.CivilianKnockout or -10
        local headshotPenalty = -45

        if payload.actionType == "KILL" then
            if payload.wasAssaulted or payload.isBleedoutPromotion then
                local fullPenalty = isHeadshot and headshotPenalty or killBase
                delta = fullPenalty - assaultBase
                if delta > 0 then delta = 0 end
                reason = isHeadshot
                    and "Óbito por tiro na cabeça (Headshot pós-agressão de civil)"
                    or "Óbito confirmado por ferimentos de civil (Sangramento/Bleedout)"
            elseif isHeadshot then
                delta = headshotPenalty
                reason = "Assassinato de civil inocente com tiro na cabeça (Headshot)"
            elseif payload.wasKnockedOut then
                delta = -25
                reason = "Execução de civil desacordado"
            else
                delta = killBase
                reason = "Assassinato de civil inocente"
            end
        elseif payload.actionType == "KNOCKOUT" then
            delta = knockoutBase
            reason = "Nocaute / asfixia de civil inocente"
        else
            delta = assaultBase
            reason = "Agressão contra civil inocente"
        end
    end

    local ballisticStr = ""
    if payload.distanceMeters and payload.distanceMeters > 0 then
        ballisticStr = string.format(" | Distância: %.1fm", payload.distanceMeters)
    end
    if isHeadshot then
        ballisticStr = ballisticStr .. " | [CRÍTICO: HEADSHOT]"
    end

    LogWarn("KARMA_SERVER", "ATITUDE NEGATIVA: Jogador [%d] -> Alvo: [%s] | Ação: [%s] | Arma: %s%s | Delta: %d pts | Motivo: %s",
        attackerSrc, payload.targetType, payload.actionType, weaponLabel, ballisticStr, delta, reason)

    local success, newKarma = Karma.Modify(attackerSrc, delta, reason)
    if success and newKarma and Config.Debug then
        LogDebug("KARMA_SERVER", "Novo karma do jogador [%d]: %d", attackerSrc, newKarma)
    end
end

-- ====================================================================
-- CANAL AUTORITATIVO DE PVP (DUAL-CHANNEL ARCHITECTURE)
-- ====================================================================

---@type table<integer, number> Timestamp da última morte PvP processada por vítima (debounce de 4 segundos)
local recentPvPDeaths = {}

---@type table<string, { timestamp: number, isHeadshot: boolean?, weaponHash: integer? }> Rastreamento de agressões PvP
local recentPvPAggression = {}

---Registra agressão iniciada entre dois jogadores (para checagem posterior de legítima defesa e headshots)
RegisterNetEvent('westrp_karma:server:reportPvPAggression', function(targetServerId, isHeadshot, weaponHash)
    local attackerSrc = tonumber(source)
    targetServerId = tonumber(targetServerId)
    if not attackerSrc or not targetServerId or attackerSrc == targetServerId then return end
    local key = string.format("%d_%d", attackerSrc, targetServerId)
    recentPvPAggression[key] = {
        timestamp = os.time(),
        isHeadshot = (isHeadshot == true),
        weaponHash = tonumber(weaponHash) or 0
    }
    if Config.Debug then
        LogDebug("KARMA_PVP", "Agressão PvP registrada: Atacante [%d] -> Alvo [%d] | Headshot: %s | Arma: %s",
            attackerSrc, targetServerId, tostring(isHeadshot), tostring(weaponHash or 0))
    end
end)

---Processa a morte autoritativa de um jogador real em combate PvP
---@param victimSource integer Server ID do jogador que faleceu (vítima)
---@param killerServerId integer? Server ID do causador do dano fatal
---@param deathCause integer? Hash da arma ou causa da morte
function Karma.HandlePvPDeath(victimSource, killerServerId, deathCause)
    victimSource = tonumber(victimSource)
    killerServerId = tonumber(killerServerId)
    if not victimSource or victimSource <= 0 then return end

    local now = os.time()

    -- 1. Deduplicação com janela deslizante de 4s (evita duplicar vorp_core e baseevents)
    if recentPvPDeaths[victimSource] and (now - recentPvPDeaths[victimSource]) < 4 then
        if Config.Debug then
            LogDebug("KARMA_PVP", "Morte PvP duplicada descartada para Vítima [%d] (debounce ativo)", victimSource)
        end
        return
    end
    recentPvPDeaths[victimSource] = now

    -- 2. Descarte de suicídios, quedas, acidentes ambientais ou causador inválido
    if not killerServerId or killerServerId <= 0 or killerServerId == victimSource then
        if Config.Debug then
            LogDebug("KARMA_PVP", "Morte não atribuível a outro jogador: Vítima [%d] (Causa: %s)",
                victimSource, tostring(deathCause or 0))
        end
        return
    end

    -- 3. Resolução da arma utilizada
    local weaponHash = tonumber(deathCause) or 0
    local aggressionKeyKillerToVictim = string.format("%d_%d", killerServerId, victimSource)
    local killerAggression = recentPvPAggression[aggressionKeyKillerToVictim]
    if (weaponHash == 0 or Weapons.IsUnarmed(weaponHash)) and killerAggression and killerAggression.weaponHash and killerAggression.weaponHash ~= 0 then
        weaponHash = killerAggression.weaponHash
    end
    local weaponLabel = Weapons.GetWeaponLabel(weaponHash)

    -- 4. Análise de Legítima Defesa PvP (A vítima agrediu o assassino nos últimos 45 segundos?)
    local selfDefenseKey = string.format("%d_%d", victimSource, killerServerId)
    local victimAggression = recentPvPAggression[selfDefenseKey]
    local isSelfDefense = victimAggression and (now - victimAggression.timestamp) <= (Config.SelfDefenseDuration or 45)

    if isSelfDefense then
        LogInfo("KARMA_PVP", "LEGÍTIMA DEFESA PvP: Vítima [%d] foi eliminada pelo Jogador [%d] após tê-lo agredido (Arma: %s). Honra preservada (0 pts).",
            victimSource, killerServerId, weaponLabel)

        recentPvPAggression[selfDefenseKey] = nil

        TriggerClientEvent('chat:addMessage', killerServerId, {
            color = { 50, 205, 50 },
            args = { "[Karma - Legítima Defesa]", "Você se defendeu legitimamente contra uma agressão. Nenhuma penalidade aplicada." }
        })
        return
    end

    -- 5. Assassinato Não Provocado de Cidadão (PK)
    local isHeadshot = killerAggression and (killerAggression.isHeadshot == true) and (now - killerAggression.timestamp) <= 10
    local delta = isHeadshot and -150 or (Config.Penalties.PlayerKillUnprovoked or -120)
    local reason = isHeadshot
        and string.format("Assassinato de cidadão com tiro na cabeça (PK Headshot com %s)", weaponLabel)
        or string.format("Assassinato não provocado de cidadão (PK com %s)", weaponLabel)

    LogWarn("KARMA_PVP", "ATITUDE NEGATIVA (PK%s): Assassino [%d] eliminou Vítima [%d] de forma injustificada | Arma: %s | Delta: %d pts",
        isHeadshot and " HEADSHOT" or "", killerServerId, victimSource, weaponLabel, delta)

    Karma.Modify(killerServerId, delta, reason)

    -- Limpa o registro de agressão consumido
    recentPvPAggression[aggressionKeyKillerToVictim] = nil

    -- Notificação formal no chat do assassino
    TriggerClientEvent('chat:addMessage', killerServerId, {
        color = { 255, 69, 0 },
        args = { "[Karma - Crime Severo]", string.format("Você assassinou um cidadão (%s). Sua honra foi severamente manchada (%d pts).", weaponLabel, delta) }
    })
end

-- ====================================================================
-- REGISTRO DE EVENTOS E CICLO DE VIDA DO RECURSO
-- ====================================================================

-- Listener Autoritativo do VORP Core para Morte de Jogadores
RegisterNetEvent('vorp_core:Server:OnPlayerDeath', function(killerServerId, deathCause)
    local victimSource = source
    if Config.Debug then
        LogDebug("KARMA_PVP", "vorp_core:Server:OnPlayerDeath recebido: Vítima [%s] | Assassino [%s] | Causa [%s]",
            tostring(victimSource), tostring(killerServerId), tostring(deathCause))
    end
    Karma.HandlePvPDeath(victimSource, killerServerId, deathCause)
end)

-- Listener de Compatibilidade do BaseEvents para Morte de Jogadores
RegisterNetEvent('baseevents:onPlayerKilled', function(killerId, data)
    local victimSource = source
    local weaponHash = data and data.weaponhash or 0
    if Config.Debug then
        LogDebug("KARMA_PVP", "baseevents:onPlayerKilled recebido: Vítima [%s] | Assassino [%s] | Arma [%s]",
            tostring(victimSource), tostring(killerId), tostring(weaponHash))
    end
    Karma.HandlePvPDeath(victimSource, killerId, weaponHash)
end)

-- Evento de Seleção de Personagem no VORP Core
AddEventHandler('vorp:SelectedCharacter', function(source, character)
    local charIdentifier = character and character.charIdentifier
    if charIdentifier then
        Karma.OnPlayerLoad(source, charIdentifier)
    end
end)

-- Evento de Desconexão de Jogador com Limpeza de Caches
AddEventHandler('playerDropped', function(reason)
    local src = tonumber(source)
    if src then
        recentPvPDeaths[src] = nil
        for k, _ in pairs(recentPvPAggression) do
            if k:find("^" .. src .. "_") or k:find("_" .. src .. "$") then
                recentPvPAggression[k] = nil
            end
        end
    end
    Karma.OnPlayerDrop(source)
end)

-- Evento de Parada do Recurso (Flush Imediato de Entidades em Cache)
AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        WestRP.Shared.Logger.Info("KARMA", "Salvando dados pendentes em disco antes de descarregar...")
        Database.FlushSync()
        WestRP.Shared.Logger.Info("KARMA", "Todos os dados foram sincronizados com sucesso.")
    end
end)

-- Evento de Shutdown do txAdmin
AddEventHandler('txAdmin:events:serverStopping', function()
    WestRP.Shared.Logger.Info("KARMA", "txAdmin Server Stopping detectado: Executando flush síncrono...")
    Database.FlushSync()
end)

-- Hot-Reload: Carrega automaticamente jogadores já conectados se o resource for reiniciado
CreateThread(function()
    Wait(1500)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local src = tonumber(playerId)
        if src then
            local charId = Karma.GetCharIdentifier(src)
            if charId then
                Karma.OnPlayerLoad(src, charId)
                if Config.Debug then
                    WestRP.Shared.Logger.Info("KARMA", string.format("Hot-Reload: Jogador %d (Char: %d) sincronizado no startup.", src, charId))
                end
            end
        end
    end
end)

-- Evento de Requisição de Sincronização Sob Demanda (Client -> Server)
RegisterNetEvent('westrp_karma:server:requestSync', function()
    local _source = source
    local charId = Karma.GetCharIdentifier(_source)
    if charId then
        Karma.OnPlayerLoad(_source, charId)
    end
end)

-- Evento de Ação de Combate PvE (Client -> Server)
RegisterNetEvent('westrp_karma:server:onCombatAction', function(payload)
    local _source = source
    if not _source or _source <= 0 or not payload then return end
    Karma.ProcessCombatAction(_source, payload)
end)

-- ====================================================================
-- COMANDO ADMINISTRATIVO: /setkarma
-- ====================================================================
RegisterCommand('setkarma', function(source, args, raw)
    local target = source
    local amount = nil

    if #args == 1 then
        if source == 0 then
            print("^1[westrp_karma] No console use: setkarma [id] [valor]^0")
            return
        end
        amount = tonumber(args[1])
    elseif #args >= 2 then
        target = tonumber(args[1])
        amount = tonumber(args[2])
    else
        local usage = "Uso: /setkarma [valor] ou /setkarma [id] [valor]"
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, { color = { 255, 165, 0 }, args = { "[Karma]", usage } })
        else
            print("^1[westrp_karma] " .. usage .. "^0")
        end
        return
    end

    if not amount then
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, { color = { 255, 50, 50 }, args = { "[Karma]", "O valor deve ser numérico (-1000 a 1000)." } })
        end
        return
    end

    local success, newKarma = Karma.Set(target, amount, "Comando Administrativo /setkarma")
    if success then
        local msg = string.format("Karma do jogador %d definido para %d.", target, newKarma)
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, { color = { 50, 205, 50 }, args = { "[Karma]", msg } })
        end
        print("^2[westrp_karma] " .. msg .. "^0")
    end
end, false)

-- ====================================================================
-- PUBLIC EXPORTS
-- ====================================================================

exports('ModifyKarma', function(source, amount, reason)
    return Karma.Modify(source, amount, reason)
end)

exports('SetPlayerKarma', function(source, amount, reason)
    return Karma.Set(source, amount, reason)
end)

exports('GetPlayerKarma', function(source)
    return Karma.Get(source)
end)

exports('GetPlayerTier', function(source)
    return Karma.GetTier(source)
end)

---Relay de depuração: recebe mensagens de diagnóstico do cliente e imprime no console do servidor (txAdmin)
RegisterNetEvent('westrp_karma:server:relayClientDebug', function(tag, message)
    local src = source
    if not Config.Debug then return end
    print(string.format("^5[DEBUG]^7 [^3%s:CLI#%d^7] %s^0", tag or "KARMA", src, tostring(message or "")))
end)

CreateThread(function()
    Wait(500)
    print("^2====================================================================^0")
    print("^2[westrp_karma] WestRP Karma Core Inicializado com Sucesso!^0")
    print(string.format("^3[westrp_karma] Modo Debug: %s | Default Karma: %d | DebugHUD: %s^0",
        tostring(Config.Debug), Config.DefaultKarma, tostring(Config.DebugHUD)))
    print("^2[westrp_karma] Monitorando eventos de combate e pipeline de moralidade...^0")
    print("^2====================================================================^0")
end)

