-- ====================================================================
-- WestRP Karma — Server: Main Entrypoint & Exports
-- Arquivo: server/main.lua
-- ====================================================================

-- Evento de Seleção de Personagem no VORP Core
AddEventHandler('vorp:SelectedCharacter', function(source, character)
    local _source = source
    local charIdentifier = character.charIdentifier
    if charIdentifier then
        Karma.OnPlayerLoad(_source, charIdentifier)
    end
end)

-- Evento de Desconexão de Jogador
AddEventHandler('playerDropped', function(reason)
    local _source = source
    Karma.OnPlayerDrop(_source)
end)

-- Evento de Parada do Recurso (Flush Imediato de Entidades em Cache)
AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        print("^3[westrp_karma] Salvando dados pendentes em disco antes de descarregar...^0")
        Database.FlushSync()
        print("^2[westrp_karma] Todos os dados foram sincronizados com sucesso.^0")
    end
end)

-- Evento de Shutdown do txAdmin
AddEventHandler('txAdmin:events:serverStopping', function()
    print("^3[westrp_karma] txAdmin Server Stopping detectado: Executando flush síncrono...^0")
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
                    print(string.format("^2[westrp_karma] Hot-Reload: Jogador %d (Char: %d) sincronizado no startup.^0", src, charId))
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

-- ====================================================================
-- PROCESSAMENTO DE COMBATE, INICIATIVA E MORALIDADE
-- ====================================================================

-- Evento Unificado de Ação de Combate (Client -> Server)
RegisterNetEvent('westrp_karma:server:onCombatAction', function(payload)
    local _source = source
    if not _source or _source <= 0 or not payload then return end
    Karma.ProcessCombatAction(_source, payload)
end)

-- Eventos de compatibilidade com chamadas legadas
RegisterNetEvent('westrp_karma:server:onNpcAction', function(actionType, npcType, weaponHash, wasKnockedOut)
    local _source = source
    if not _source or _source <= 0 then return end
    Karma.ProcessNpcAction(_source, actionType or "KILL", npcType or "INNOCENT", weaponHash, wasKnockedOut)
end)

RegisterNetEvent('westrp_karma:server:onNpcKilled', function(npcType, weaponHash)
    local _source = source
    if not _source or _source <= 0 then return end
    Karma.ProcessNpcAction(_source, "KILL", npcType or "INNOCENT", weaponHash, false)
end)

-- ====================================================================
-- COMANDO ADMINISTRATIVO: /setkarma
-- ====================================================================
RegisterCommand('setkarma', function(source, args, raw)
    local target = source
    local amount = nil

    if #args == 1 then
        if source == 0 then
            print("^1[westrp_karma] No console do servidor use: setkarma [id] [valor]^0")
            return
        end
        amount = tonumber(args[1])
    elseif #args >= 2 then
        target = tonumber(args[1])
        amount = tonumber(args[2])
    else
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = { 255, 165, 0 },
                args = { "[Karma]", "Uso correto: /setkarma [valor] ou /setkarma [id] [valor]" }
            })
        else
            print("^1[westrp_karma] Uso: setkarma [id] [valor]^0")
        end
        return
    end

    if not amount then
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = { 255, 50, 50 },
                args = { "[Karma]", "O valor precisa ser um número entre -1000 e 1000." }
            })
        else
            print("^1[westrp_karma] O valor precisa ser um número.^0")
        end
        return
    end

    -- Permissão administrativa
    if source > 0 and not Config.Debug then
        if not IsPlayerAceAllowed(source, "command") then
            TriggerClientEvent('chat:addMessage', source, {
                color = { 255, 50, 50 },
                args = { "[Karma]", "Você não possui permissão para executar este comando." }
            })
            return
        end
    end

    local success, newKarma = Karma.Set(target, amount, "Comando Administrativo /setkarma")
    if success then
        local msg = string.format("Karma do jogador %d definido para %d.", target, newKarma)
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = { 50, 205, 50 },
                args = { "[Karma]", msg }
            })
        end
        print("^2[westrp_karma] " .. msg .. "^0")
    else
        local err = string.format("Falha ao definir karma para o jogador %d (personagem não carregado).", target)
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = { 255, 50, 50 },
                args = { "[Karma]", err }
            })
        end
        print("^1[westrp_karma] " .. err .. "^0")
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

exports('GetShopModifier', function(source)
    return Karma.GetShopModifier(source)
end)

exports('IsBountyEligible', function(source)
    return Karma.IsBountyEligible(source)
end)

print("^2[westrp_karma] Sistema de Karma e Moralidade WestRP inicializado com sucesso.^0")
