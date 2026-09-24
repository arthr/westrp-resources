-- ====================================================================
-- WestRP Karma — Domain Entity: KarmaEntity
-- File: server/domain/karma_entity.lua
-- ====================================================================

---@class KarmaEntity
---@field charIdentifier integer Identificador imutável do personagem
---@field source integer ID da sessão de rede ativa do jogador
---@field karma integer Pontuação numérica atual [-1000, 1000]
---@field tier KarmaTier Objeto do patamar moral atual
---@field bountyPrice number Valor da recompensa sobre a cabeça do jogador
---@field isDirty boolean Flag que sinaliza necessidade de persistência no MySQL
KarmaEntity = {}
KarmaEntity.__index = KarmaEntity

---Fábrica para instanciar uma nova KarmaEntity
---@param charIdentifier integer
---@param source integer
---@param initialKarma integer?
---@param bountyPrice number?
---@return KarmaEntity
function KarmaEntity.New(charIdentifier, source, initialKarma, bountyPrice)
    local self = setmetatable({}, KarmaEntity)
    self.charIdentifier = charIdentifier
    self.source = source
    self.karma = TierEvaluator.Clamp(initialKarma or Config.DefaultKarma)
    self.tier = TierEvaluator.Resolve(self.karma)
    self.bountyPrice = bountyPrice or 0.00
    self.isDirty = false
    return self
end

---Aplica uma variação de karma com clamping automático e marcação dirty
---@param delta integer
---@return boolean tierChanged Indica se houve transição de patamar moral
---@param oldTier KarmaTier Patamar moral anterior
function KarmaEntity:ApplyDelta(delta)
    if delta == 0 then return false, self.tier end
    
    local oldTier = self.tier
    self.karma = TierEvaluator.Clamp(self.karma + delta)
    self.tier = TierEvaluator.Resolve(self.karma)
    self.isDirty = true
    
    local tierChanged = (oldTier.id ~= self.tier.id)
    return tierChanged, oldTier
end

---Define diretamente uma pontuação moral
---@param newKarma integer
---@return boolean tierChanged
function KarmaEntity:SetKarma(newKarma)
    local oldTier = self.tier
    self.karma = TierEvaluator.Clamp(newKarma)
    self.tier = TierEvaluator.Resolve(self.karma)
    self.isDirty = true
    
    return (oldTier.id ~= self.tier.id)
end

---Atualiza o identificador da sessão ativa (ex: após reconexão ou troca de char)
---@param source integer
function KarmaEntity:UpdateSource(source)
    self.source = source
end

---Limpa a flag dirty após sincronização bem-sucedida com o banco
function KarmaEntity:MarkClean()
    self.isDirty = false
end
