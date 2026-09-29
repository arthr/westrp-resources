-- ====================================================================
-- WestRP Karma — Shared: Moral Tiers & Evaluator
-- File: shared/tiers.lua
-- ====================================================================

---@class TierEvaluator
TierEvaluator = {}

---@type table<string, KarmaTier>
local KARMA_TIERS = {
    DISOWNED = {
        id = "DISOWNED",
        name = "Desonrado / Suspeito",
        minKarma = -1000,
        maxKarma = -501,
        shopDiscount = -0.15, -- Preços 15% mais caros
        bountyEligible = true,
        baseBounty = 100.0
    },
    NOTORIOUS = {
        id = "NOTORIOUS",
        name = "Notório / Problemático",
        minKarma = -500,
        maxKarma = -201,
        shopDiscount = -0.05,
        bountyEligible = false,
        baseBounty = 0.0
    },
    NEUTRAL = {
        id = "NEUTRAL",
        name = "Neutro / Cidadão Comum",
        minKarma = -200,
        maxKarma = 200,
        shopDiscount = 0.00,
        bountyEligible = false,
        baseBounty = 0.0
    },
    RESPECTED = {
        id = "RESPECTED",
        name = "Respeitado / Prestativo",
        minKarma = 201,
        maxKarma = 500,
        shopDiscount = 0.05, -- 5% de desconto
        bountyEligible = false,
        baseBounty = 0.0
    },
    HONORABLE = {
        id = "HONORABLE",
        name = "Honorável / Protetor",
        minKarma = 501,
        maxKarma = 1000,
        shopDiscount = 0.10, -- 10% de desconto
        bountyEligible = false,
        baseBounty = 0.0
    }
}

---Resolve deterministicamente o Tier correspondente ao valor numérico de karma
---@param karma integer
---@return KarmaTier
function TierEvaluator.Resolve(karma)
    local clamped = math.max(-1000, math.min(1000, karma or 0))

    if clamped <= -501 then
        return KARMA_TIERS.DISOWNED
    elseif clamped <= -201 then
        return KARMA_TIERS.NOTORIOUS
    elseif clamped <= 200 then
        return KARMA_TIERS.NEUTRAL
    elseif clamped <= 500 then
        return KARMA_TIERS.RESPECTED
    else
        return KARMA_TIERS.HONORABLE
    end
end

---Retorna a lista completa de Tiers configurados
---@return table<string, KarmaTier>
function TierEvaluator.GetAllTiers()
    return KARMA_TIERS
end
