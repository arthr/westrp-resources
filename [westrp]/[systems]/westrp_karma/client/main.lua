-- ====================================================================
-- WestRP Karma — Client Main Entrypoint & Exports
-- File: client/main.lua
-- ====================================================================

local localKarma = Config.DefaultKarma
local localTier = TierEvaluator.Resolve(localKarma)

---Manipulador do evento de sincronização de moralidade emitido pelo servidor
RegisterNetEvent('westrp_karma:client:onKarmaUpdated', function(payload)
    if not payload then return end

    localKarma = payload.currentKarma
    localTier = payload.tier or TierEvaluator.Resolve(localKarma)

    -- Foco exclusivo em logs sem poluição de UI na tela
    if Config.Debug or (payload.delta and payload.delta ~= 0) then
        print(string.format("^2[westrp_karma:client] Sincronização de Karma: %d (Delta: %d) | Tier: %s | Motivo: %s^0", 
            localKarma, payload.delta or 0, localTier.name, payload.reason or "SYNC"))
    end
end)

-- Solicita sincronização com o servidor logo na inicialização do client
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('westrp_karma:server:requestSync')
end)

-- ====================================================================
-- CLIENT EXPORTS
-- ====================================================================

exports('GetLocalKarma', function()
    return localKarma
end)

exports('GetLocalTier', function()
    return localTier
end)

-- Comando informativo local para o jogador inspecionar seu próprio alinhamento
RegisterCommand('karma', function()
    local tier = localTier

    -- Log no console F8
    print(string.format("^3[Karma WestRP] Sua moralidade atual: %d (%s)^0", localKarma, tier.name))

    -- Mensagem informativa apenas no Chat
    TriggerEvent('chat:addMessage', {
        color = { 218, 165, 32 },
        args = { "[Karma WestRP]", string.format("Sua moralidade atual: %d (%s).", localKarma, tier.name) }
    })
end, false)
