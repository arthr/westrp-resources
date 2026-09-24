-- ====================================================================
-- WestRP Karma — Domain Service: SelfDefensePool
-- File: server/domain/self_defense_pool.lua
-- ====================================================================

---@class SelfDefensePool
---@field private registry table<string, AggressionRecord>
SelfDefensePool = {
    registry = {}
}

---Gera uma chave determinística para o par agressor-vítima
---@param attackerSrc integer
---@param victimSrc integer
---@return string
local function MakeKey(attackerSrc, victimSrc)
    return string.format("%d:%d", attackerSrc, victimSrc)
end

---Registra uma agressão física de attackerSrc contra victimSrc
---@param attackerSrc integer
---@param victimSrc integer
---@param duration integer? Duração em segundos (opcional, padrão do config)
function SelfDefensePool.RegisterAggression(attackerSrc, victimSrc, duration)
    if attackerSrc == victimSrc then return end
    
    local now = os.time()
    local expiryTime = now + (duration or Config.SelfDefenseDuration or 180)
    local key = MakeKey(attackerSrc, victimSrc)
    
    SelfDefensePool.registry[key] = {
        attackerSrc = attackerSrc,
        victimSrc = victimSrc,
        timestamp = now,
        expiresAt = expiryTime
    }
    
    if Config.Debug then
        print(string.format("[westrp_karma] Agressão registrada: [%d] atacou [%d]. Expira em %ds.", attackerSrc, victimSrc, duration or 180))
    end
end

---Verifica se targetSrc foi um agressor prévio de actorSrc (isto é: se actorSrc pode retaliar em legítima defesa)
---@param actorSrc integer Quem está desferindo o ataque agora
---@param targetSrc integer Quem está recebendo o ataque
---@return boolean isSelfDefense
function SelfDefensePool.IsSelfDefense(actorSrc, targetSrc)
    local now = os.time()
    -- Checa se targetSrc atacou actorSrc no passado recente
    local key = MakeKey(targetSrc, actorSrc)
    local record = SelfDefensePool.registry[key]
    
    if not record then
        return false
    end
    
    if now > record.expiresAt then
        -- Expirado: remove do registro (Lazy GC)
        SelfDefensePool.registry[key] = nil
        return false
    end
    
    return true
end

---Limpa todos os registros que envolvam um determinado player (ex: na desconexão)
---@param source integer
function SelfDefensePool.ClearPlayer(source)
    for key, record in pairs(SelfDefensePool.registry) do
        if record.attackerSrc == source or record.victimSrc == source then
            SelfDefensePool.registry[key] = nil
        end
    end
end

---Executa limpeza ativa de registros expirados no buffer
function SelfDefensePool.PurgeExpired()
    local now = os.time()
    for key, record in pairs(SelfDefensePool.registry) do
        if now > record.expiresAt then
            SelfDefensePool.registry[key] = nil
        end
    end
end
