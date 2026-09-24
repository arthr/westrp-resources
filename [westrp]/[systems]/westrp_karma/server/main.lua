-- ====================================================================
-- WestRP Karma — Server Main Entrypoint & Exports
-- File: server/main.lua
-- ====================================================================

-- Evento de Seleção de Personagem no VORP Core
AddEventHandler('vorp:SelectedCharacter', function(source, character)
    local _source = source
    local charIdentifier = character.charIdentifier
    if charIdentifier then
        KarmaService.OnPlayerLoad(_source, charIdentifier)
    end
end)

-- Evento de Desconexão de Jogador
AddEventHandler('playerDropped', function(reason)
    local _source = source
    KarmaService.OnPlayerDrop(_source)
end)

-- Evento de Parada do Recurso (Flush Imediato de Entidades em Cache)
AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        print("^3[westrp_karma] Salvando dados pendentes em disco antes de descarregar...^0")
        DatabaseAdapter.FlushSync()
        print("^2[westrp_karma] Todos os dados foram sincronizados com sucesso.^0")
    end
end)

-- Evento de Shutdown do txAdmin
AddEventHandler('txAdmin:events:serverStopping', function()
    print("^3[westrp_karma] txAdmin Server Stopping detectado: Executando flush síncrono...^0")
    DatabaseAdapter.FlushSync()
end)

-- Evento de Recebimento de Relatório de Combate
RegisterNetEvent('westrp_karma:server:reportCombat', function(payload)
    local _source = source
    KarmaService.ProcessCombat(_source, payload)
end)

-- ====================================================================
-- PUBLIC EXPORTS
-- ====================================================================

exports('ModifyKarma', function(source, amount, reason)
    return KarmaService.ModifyKarma(source, amount, reason)
end)

exports('GetPlayerKarma', function(source)
    return KarmaService.GetPlayerKarma(source)
end)

exports('GetPlayerTier', function(source)
    return KarmaService.GetPlayerTier(source)
end)

exports('GetShopModifier', function(source)
    return KarmaService.GetShopModifier(source)
end)

exports('IsBountyEligible', function(source)
    return KarmaService.IsBountyEligible(source)
end)

print("^2[westrp_karma] Sistema de Karma e Moralidade WestRP inicializado com sucesso.^0")
