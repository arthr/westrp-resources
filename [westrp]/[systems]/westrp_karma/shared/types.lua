---@meta
-- ====================================================================
-- WestRP Karma — Domain Types & Data Contracts
-- File: shared/types.lua
-- ====================================================================

---@class KarmaTier
---@field id string Identificador unívoco do tier (ex: 'saint', 'honorable', 'neutral', 'outlaw', 'scourge')
---@field name string Nome legível e amigável para exibição em menus/HUD
---@field min integer Limite inferior inclusivo da pontuação moral [-1000, 1000]
---@field max integer Limite superior inclusivo da pontuação moral [-1000, 1000]
---@field nativeState integer Mapeamento visual para o HonorIcon nativo (1 = Mais sombrio, 16 = Mais honrado)
---@field shopDiscount number Multiplicador de preço nas lojas (-0.15 = 15% desc., +0.25 = 25% acréscimo)
---@field bountyEligible boolean Flag que indica se o jogador pode receber cartaz de caça a recompensa
---@field baseBounty number Valor monetário padrão colocado pela lei sobre a cabeça do criminoso
---@field color string Código de cor hexadecimal ou classe CSS para representação visual

---@class CombatReportPayload
---@field isPlayer boolean Indica se o alvo é um jogador (true) ou NPC (false)
---@field victimServerId integer? Server ID da vítima (se for jogador)
---@field victimModel integer? Hash numérico do modelo da entidade alvo (especialmente para NPCs)
---@field isFatal boolean Flag indicando se a agressão resultou em óbito/incapacitação
---@field weaponHash integer Hash numérico da arma empregada no disparo/golpe
---@field attackerCoords vector3 Vetor tridimensional do agressor no instante da ação
---@field victimCoords vector3 Vetor tridimensional da vítima no instante do impacto
---@field distance number Distância euclidiana calculada no client

---@class AggressionRecord
---@field attackerSrc integer Server ID do agressor original
---@field victimSrc integer Server ID da vítima
---@field timestamp integer Momento Unix em segundos do registro da agressão
---@field expiresAt integer Momento Unix em segundos após o qual a legítima defesa expira

---@class CombatVerificationResult
---@field valid boolean Flag que indica aprovação em todos os filtros de segurança
---@field reason string Código de erro ou justificativa do veredito (ex: 'APPROVED', 'DISTANCE_EXCEEDED')

---@class KarmaUpdatePayload
---@field currentKarma integer Pontuação moral atualizada
---@field delta integer Quantidade adicionada ou deduzida
---@field tier KarmaTier Objeto do patamar moral correspondente
---@field reason string Descritivo da ação geradora do evento
