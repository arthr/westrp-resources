-- ====================================================================
-- WestRP Karma — Application Service: KarmaService
-- File: server/services/karma_service.lua
-- ====================================================================

---@class KarmaService
KarmaService = {}

---Carrega os dados de moralidade de um jogador no login
---@param source integer
---@param charIdentifier integer
---@return KarmaEntity
function KarmaService.OnPlayerLoad(source, charIdentifier)
    local entity = DatabaseAdapter.Load(charIdentifier, source)
    
    -- Notifica o client com seu estado atual de karma
    TriggerClientEvent('westrp_karma:client:onKarmaUpdated', source, {
        currentKarma = entity.karma,
        delta = 0,
        tier = entity.tier,
        reason = "LOGIN_SYNC"
    })
    
    return entity
end

---Descarrega o jogador ao desconectar
---@param source integer
function KarmaService.OnPlayerDrop(source)
    SelfDefensePool.ClearPlayer(source)
    DatabaseAdapter.Unload(source)
end

---Modifica o karma de um jogador aplicando regras de negócio e eventos
---@param source integer
---@param amount integer
---@param reason string
---@return boolean success
---@return integer? newKarma
function KarmaService.ModifyKarma(source, amount, reason)
    local entity = DatabaseAdapter.GetBySource(source)
    if not entity then
        local charId = FrameworkAdapter.GetCharIdentifier(source)
        if charId then
            entity = DatabaseAdapter.Load(charId, source)
        else
            return false, nil
        end
    end

    local tierChanged, oldTier = entity:ApplyDelta(amount)

    -- Notifica o cliente para renderização da UI (Barra nativa)
    TriggerClientEvent('westrp_karma:client:onKarmaUpdated', source, {
        currentKarma = entity.karma,
        delta = amount,
        tier = entity.tier,
        reason = reason
    })

    -- Se houve transição de tier moral
    if tierChanged then
        TriggerEvent('westrp_karma:server:onTierChanged', source, oldTier, entity.tier)
        
        -- Verifica elegibilidade para caçadores de recompensa
        if entity.tier.bountyEligible and not oldTier.bountyEligible then
            entity.bountyPrice = entity.tier.baseBounty
            TriggerEvent('westrp_karma:server:onBountyEligible', source, entity.bountyPrice)
            if Config.UI.NotifyBountyChange then
                FrameworkAdapter.Notify(source, "Você agora é um Fora-da-Lei procurado pela lei!", "error")
            end
        end
    end

    return true, entity.karma
end

---Retorna a pontuação moral de um jogador
---@param source integer
---@return integer
function KarmaService.GetPlayerKarma(source)
    local entity = DatabaseAdapter.GetBySource(source)
    return entity and entity.karma or Config.DefaultKarma
end

---Retorna a tabela do Tier atual de um jogador
---@param source integer
---@return KarmaTier
function KarmaService.GetPlayerTier(source)
    local entity = DatabaseAdapter.GetBySource(source)
    return entity and entity.tier or TierEvaluator.Resolve(Config.DefaultKarma)
end

---Retorna o modificador percentual de preços de loja
---@param source integer
---@return number
function KarmaService.GetShopModifier(source)
    local entity = DatabaseAdapter.GetBySource(source)
    return entity and entity.tier.shopDiscount or 0.00
end

---Verifica se o jogador é procurado por crimes
---@param source integer
---@return boolean isEligible
---@return number bountyPrice
function KarmaService.IsBountyEligible(source)
    local entity = DatabaseAdapter.GetBySource(source)
    if not entity then return false, 0.00 end
    return entity.tier.bountyEligible, entity.bountyPrice
end

---Processa e avalia um relatório de combate do client
---@param attackerSrc integer
---@param payload CombatReportPayload
function KarmaService.ProcessCombat(attackerSrc, payload)
    -- 1. Passa pelo pipeline de segurança
    local valid, reason = CombatVerifier.VerifyReport(attackerSrc, payload)
    if not valid then
        if Config.Debug then
            print(string.format("^3[westrp_karma] Relatório de combate rejeitado de [%d]: %s^0", attackerSrc, reason))
        end
        return
    end

    -- 2. Tratamento PvP
    if payload.isPlayer and payload.victimServerId then
        local victimSrc = payload.victimServerId

        -- Verifica se o atacante está em legítima defesa
        local isSelfDefense = SelfDefensePool.IsSelfDefense(attackerSrc, victimSrc)
        if isSelfDefense then
            -- Ação legítima: Preserva a moralidade
            FrameworkAdapter.Notify(attackerSrc, "Legítima defesa confirmada. Sua honra foi preservada.", "info")
            return
        end

        -- Ataque injustificado: Registra no pool caso seja agressão mútua
        SelfDefensePool.RegisterAggression(attackerSrc, victimSrc)

        -- Aplica penalidade moral
        local penalty = payload.isFatal and Config.Penalties.PlayerKillUnprovoked or Config.Penalties.PlayerAssaultUnprovoked
        local description = payload.isFatal and "Assassinato injustificado de cidadão" or "Agressão corporal armada"
        
        KarmaService.ModifyKarma(attackerSrc, penalty, description)
    else
        -- 3. Tratamento PvE (NPCs)
        local penalty = payload.isFatal and Config.Penalties.InnocentNpcKill or Config.Penalties.InnocentNpcAssault
        KarmaService.ModifyKarma(attackerSrc, penalty, "Agressão contra habitante local")
    end
end
