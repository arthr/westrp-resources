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

    if payload.targetType == "PLAYER" then
        if payload.actionType == "KILL" then
            if payload.wasKnockedOut then
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
            reason = "Agressão corporal armada contra cidadão"
        end
    elseif payload.targetType == "LAWMAN" then
        if payload.actionType == "KILL" then
            if payload.wasKnockedOut then
                delta = -45
                reason = "Execução de autoridade desacordada"
            elseif payload.wasAssaulted then
                delta = (Config.Penalties.LawmanKill or -80) - (Config.Penalties.LawmanAssault or -15)
                reason = "Assassinato de homem da lei"
            else
                delta = Config.Penalties.LawmanKill or -80
                reason = "Assassinato de homem da lei"
            end
        elseif payload.actionType == "KNOCKOUT" then
            delta = Config.Penalties.LawmanKnockout or -35
            reason = "Nocaute / asfixia contra homem da lei"
        else
            delta = Config.Penalties.LawmanAssault or -15
            reason = "Agressão contra autoridade da lei"
        end
    else -- "CIVILIAN"
        if payload.actionType == "KILL" then
            if payload.wasKnockedOut then
                delta = -25
                reason = "Execução de civil desacordado"
            elseif payload.wasAssaulted then
                delta = (Config.Penalties.CivilianKill or -35) - (Config.Penalties.CivilianAssault or -5)
                reason = "Assassinato de civil inocente"
            else
                delta = Config.Penalties.CivilianKill or -35
                reason = "Assassinato de civil inocente"
            end
        elseif payload.actionType == "KNOCKOUT" then
            delta = Config.Penalties.CivilianKnockout or -10
            reason = "Nocaute / asfixia de civil inocente"
        else
            delta = Config.Penalties.CivilianAssault or -5
            reason = "Agressão corporal contra civil inocente"
        end
    end

    LogWarn("KARMA_SERVER", "ATITUDE NEGATIVA: Jogador [%d] -> Alvo: [%s] | Ação: [%s] | Arma: %s | Delta: %d pts | Motivo: %s",
        attackerSrc, payload.targetType, payload.actionType, weaponLabel, delta, reason)

    local success, newKarma = Karma.Modify(attackerSrc, delta, reason)
    if success and newKarma and Config.Debug then
        LogDebug("KARMA_SERVER", "Novo karma do jogador [%d]: %d", attackerSrc, newKarma)
    end
end

-- ====================================================================
-- REGISTRO DE EVENTOS E CICLO DE VIDA DO RECURSO
-- ====================================================================

-- Evento de Seleção de Personagem no VORP Core
AddEventHandler('vorp:SelectedCharacter', function(source, character)
    local charIdentifier = character and character.charIdentifier
    if charIdentifier then
        Karma.OnPlayerLoad(source, charIdentifier)
    end
end)

-- Evento de Desconexão de Jogador
AddEventHandler('playerDropped', function(reason)
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

-- Evento de Ação de Combate (Client -> Server)
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

