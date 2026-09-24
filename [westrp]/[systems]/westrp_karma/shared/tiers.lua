-- ====================================================================
-- WestRP Karma — Moral Tiers & Pure Domain Evaluator
-- File: shared/tiers.lua
-- ====================================================================

KarmaTiers = {
    {
        id = "saint",
        name = "Santo do Oeste",
        min = 801,
        max = 1000,
        nativeState = 16,
        shopDiscount = -0.20, -- 20% de desconto geral em lojas legais
        bountyEligible = false,
        baseBounty = 0.00,
        color = "#D4AF37"
    },
    {
        id = "righteous",
        name = "Íntegro & Justo",
        min = 501,
        max = 800,
        nativeState = 14,
        shopDiscount = -0.10, -- 10% de desconto
        bountyEligible = false,
        baseBounty = 0.00,
        color = "#A3E635"
    },
    {
        id = "honorable",
        name = "Cidadão Honrado",
        min = 201,
        max = 500,
        nativeState = 11,
        shopDiscount = -0.05, -- 5% de desconto
        bountyEligible = false,
        baseBounty = 0.00,
        color = "#60A5FA"
    },
    {
        id = "neutral",
        name = "Indiferente / Neutro",
        min = -200,
        max = 200,
        nativeState = 8,
        shopDiscount = 0.00,
        bountyEligible = false,
        baseBounty = 0.00,
        color = "#9CA3AF"
    },
    {
        id = "dishonorable",
        name = "Desonrado / Suspeito",
        min = -500,
        max = -201,
        nativeState = 5,
        shopDiscount = 0.10, -- 10% de acréscimo em lojas legais
        bountyEligible = false,
        baseBounty = 0.00,
        color = "#F97316"
    },
    {
        id = "outlaw",
        name = "Fora-da-Lei Conhecido",
        min = -800,
        max = -501,
        nativeState = 3,
        shopDiscount = 0.25, -- 25% de sobretaxa
        bountyEligible = true,
        baseBounty = 25.00,
        color = "#EF4444"
    },
    {
        id = "scourge",
        name = "Flagelo das Fronteiras",
        min = -1000,
        max = -801,
        nativeState = 1,
        shopDiscount = 0.50, -- 50% de sobretaxa (mercados clandestinos aplicam o inverso)
        bountyEligible = true,
        baseBounty = 75.00,
        color = "#7F1D1D"
    }
}

---@class TierEvaluator
TierEvaluator = {}

---Resolve o objeto KarmaTier correspondente a uma pontuação
---@param karma integer
---@return KarmaTier
function TierEvaluator.Resolve(karma)
    local clamped = TierEvaluator.Clamp(karma)
    for _, tier in ipairs(KarmaTiers) do
        if clamped >= tier.min and clamped <= tier.max then
            return tier
        end
    end
    return KarmaTiers[4] -- Retorna 'neutral' por garantia
end

---Limita o karma ao intervalo estrito de configuração
---@param karma integer
---@return integer
function TierEvaluator.Clamp(karma)
    if not karma then return Config.DefaultKarma or 0 end
    if karma < Config.MinKarma then return Config.MinKarma end
    if karma > Config.MaxKarma then return Config.MaxKarma end
    return math.floor(karma)
end

---Calcula o índice nativo do HonorIcon (escala de 1 a 16) de forma suave e contínua
---@param karma integer
---@return integer
function TierEvaluator.CalculateNativeState(karma)
    local clamped = TierEvaluator.Clamp(karma)
    -- Mapeia [-1000, 1000] para a faixa de inteiros [1, 16]
    local normalized = (clamped - Config.MinKarma) / (Config.MaxKarma - Config.MinKarma) -- 0.0 a 1.0
    local state = math.floor(normalized * 15 + 1 + 0.5)
    if state < 1 then state = 1 end
    if state > 16 then state = 16 end
    return state
end
