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

    -- Apresenta visualmente no HUD nativo caso haja variação
    if payload.delta and payload.delta ~= 0 then
        HonorPresenter.Show(localKarma, payload.delta)
    end

    if Config.Debug then
        print(string.format("[westrp_karma] Karma atualizado: %d (Delta: %d) | Tier: %s", localKarma, payload.delta or 0, localTier.name))
    end
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
    print(string.format("^3[Karma WestRP]^0 Sua moralidade atual: ^2%d^0 (%s)", localKarma, tier.name))
    HonorPresenter.Show(localKarma, 1) -- Revela a barra nativa
end, false)
