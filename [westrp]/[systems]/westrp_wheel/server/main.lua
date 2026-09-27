--[[
    WestRP Wheel — Server Main Controller
    
    Gerencia o endpoint seguro de consumo de itens da roda (westrp:wheel:server:useItem)
    com rate-limiting no servidor, validação de integridade física e autoridade total
    do backend. Zero confiança no cliente.
]]

---Endpoint seguro invocado pelo cliente ao soltar a roda com um item selecionado
RegisterNetEvent('westrp:wheel:server:useItem', function(vorpItemName)
    local source = source
    local src = tonumber(source)
    if not src or not vorpItemName then return end

    -- 1. Anti-Cheat & Rate Limit (Default: 450ms)
    local cooldown = Config.CooldownMs or 450
    if not WestRP.Server.Security.CheckRateLimit(src, 'wheel_use', cooldown) then
        WestRP.Shared.Logger.Warn("WHEEL", "Player %s tentou consumir item muito rápido (Flood/Spam ignorado)", src)
        return
    end

    -- 2. Validação de Vida (Impede consumo se o jogador estiver morto/desmaiado)
    if not WestRP.Server.Security.IsPlayerAlive(src) then
        WestRP.Shared.Logger.Warn("WHEEL", "Player %s tentou consumir item enquanto morto/incapacitado", src)
        return
    end

    -- 3. Whitelist Check (Garante que o item pertence à configuração da roda)
    local cfg = Config.WheelItems and Config.WheelItems[vorpItemName]
    if not cfg then
        WestRP.Shared.Logger.Warn("WHEEL", "Player %s tentou consumir item não cadastrado na whitelist: %s", src, tostring(vorpItemName))
        SyncManager:SyncPlayer(src, true)
        return
    end

    -- 4. Validação no Inventário Real (Server Authority)
    local entry = SyncManager:GetBestUseEntry(src, vorpItemName)
    if not entry or not entry.id then
        WestRP.Shared.Logger.Warn("WHEEL", "Player %s tentou usar '%s', mas não possui entrada válida no banco!", src, vorpItemName)
        -- Restaura a State Bag do cliente para o estado real do banco
        SyncManager:SyncPlayer(src, true)
        return
    end

    -- 5. Registra o uso pendente para aguardar confirmação atômica do OnItemRemoved
    SyncManager:RegisterPendingUse(src, entry.id, entry.name)

    -- 6. Dispara o gatilho de execução de uso oficial do VORP
    TriggerClientEvent('westrp:wheel:client:invokeVorpUse', src, {
        item = entry.name,
        type = entry.type or 'item_standard',
        hash = 0,
        amount = 1,
        id = entry.id
    })

    -- 7. Timeout de segurança: Se o item não foi consumido após 1000ms, reseta o pending
    SetTimeout(1000, function()
        if SyncManager.pendingUses[src] and SyncManager.pendingUses[src].itemId == entry.id then
            SyncManager.pendingUses[src] = nil
            SyncManager:SyncPlayer(src, true)
        end
    end)
end)

-- Sincronização inicial para todos os jogadores online ao carregar/reiniciar o recurso
AddEventHandler('onResourceStart', function(resName)
    if resName == GetCurrentResourceName() then
        Wait(500)
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local src = tonumber(playerId)
            if src then
                SyncManager:SyncPlayer(src, true)
            end
        end
        WestRP.Shared.Logger.Info("WHEEL", "Servidor inicializado e jogadores sincronizados com sucesso!")
    end
end)

-- Export oficial para permitir que outros módulos do WestRP forcem sincronização da roda
exports('SyncPlayerWheel', function(targetSource, force)
    local src = tonumber(targetSource)
    if src then
        SyncManager:SyncPlayer(src, force == true)
        return true
    end
    return false
end)

-- Comando administrativo para forçar ressincronização em testes
RegisterCommand('wheelsync', function(source, _)
    local src = tonumber(source)
    if src and src > 0 then
        SyncManager:SyncPlayer(src, true)
        if WestRP.Client and WestRP.Client.UI and WestRP.Client.UI.ShowToast then
            TriggerClientEvent('westrp:wheel:client:onItemUsed', src, 'wheel_synced')
        end
    else
        WestRP.Shared.Logger.Info("WHEEL", "Uso do comando wheelsync pelo console.")
    end
end, false)
