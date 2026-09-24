-- ====================================================================
-- WestRP Karma — Server: Morality Engine & Rules
-- Arquivo: server/karma.lua
-- ====================================================================

---@class Karma
Karma = {}

local VorpCore = nil

---Obtém a instância do VORP Core de forma segura
local function GetVorpCore()
    if not VorpCore then
        local ok, core = pcall(function()
            return exports.vorp_core:GetCore()
        end)
        if ok and core then
            VorpCore = core
        end
    end
    return VorpCore
end

---Obtém o charIdentifier de um jogador ativo através do VORP Core
---@param source integer
---@return integer?
function Karma.GetCharIdentifier(source)
    local core = GetVorpCore()
    if not core then return nil end

    local user = core.getUser(source)
    if not user then return nil end

    local char = user.getUsedCharacter
    return char and char.charIdentifier
end

---Inicializa ou sincroniza os dados morais do jogador ao logar
---@param source integer
---@param charIdentifier integer
---@return KarmaData
function Karma.OnPlayerLoad(source, charIdentifier)
    local entity = Database.Load(charIdentifier, source)

    -- Sincroniza o cliente com seu estado moral atual
    TriggerClientEvent('westrp_karma:client:onKarmaUpdated', source, {
        currentKarma = entity.karma,
        delta = 0,
        tier = entity.tier,
        reason = "LOGIN_SYNC"
    })

    return entity
end

---Descarrega o jogador da memória ao desconectar
---@param source integer
function Karma.OnPlayerDrop(source)
    Database.Unload(source)
end

---Aplica uma variação de karma com cálculo de patamares e eventos
---@param source integer
---@param amount integer
---@param reason string
---@return boolean success
---@return integer? newKarma
function Karma.Modify(source, amount, reason)
    local entity = Database.GetBySource(source)
    if not entity then
        local charId = Karma.GetCharIdentifier(source)
        if charId then
            entity = Database.Load(charId, source)
        else
            return false, nil
        end
    end

    local tierChanged, oldTier = entity:ApplyDelta(amount)

    -- Sincroniza com o cliente
    TriggerClientEvent('westrp_karma:client:onKarmaUpdated', source, {
        currentKarma = entity.karma,
        delta = amount,
        tier = entity.tier,
        reason = reason
    })

    -- Transição de patamar moral
    if tierChanged then
        TriggerEvent('westrp_karma:server:onTierChanged', source, oldTier, entity.tier)

        if entity.tier.bountyEligible and not oldTier.bountyEligible then
            entity.bountyPrice = entity.tier.baseBounty
            TriggerEvent('westrp_karma:server:onBountyEligible', source, entity.bountyPrice)
        end
    end

    if Config.Debug then
        print(string.format("^2[westrp_karma] ModifyKarma [%d]: Delta=%d -> Total=%d (Tier: %s) Motivo: %s^0",
            source, amount, entity.karma, entity.tier.name, reason or ""))
    end

    return true, entity.karma
end

---Define diretamente uma pontuação moral fixa
---@param source integer
---@param newKarma integer
---@param reason string?
---@return boolean success
---@return integer? newKarma
function Karma.Set(source, newKarma, reason)
    local entity = Database.GetBySource(source)
    if not entity then
        local charId = Karma.GetCharIdentifier(source)
        if charId then
            entity = Database.Load(charId, source)
        else
            return false, nil
        end
    end

    local oldTier = entity.tier
    local delta = newKarma - entity.karma
    local tierChanged = entity:SetKarma(newKarma)

    TriggerClientEvent('westrp_karma:client:onKarmaUpdated', source, {
        currentKarma = entity.karma,
        delta = delta,
        tier = entity.tier,
        reason = reason or "SET_KARMA"
    })

    if tierChanged then
        TriggerEvent('westrp_karma:server:onTierChanged', source, oldTier, entity.tier)
    end

    if Config.Debug then
        print(string.format("^2[westrp_karma] SetKarma [%d]: Total=%d (Tier: %s) Motivo: %s^0",
            source, entity.karma, entity.tier.name, reason or "SET_KARMA"))
    end

    return true, entity.karma
end

---Retorna a pontuação moral numérica de um jogador
---@param source integer
---@return integer
function Karma.Get(source)
    local entity = Database.GetBySource(source)
    return entity and entity.karma or Config.DefaultKarma
end

---Retorna a tabela do Tier atual do jogador
---@param source integer
---@return KarmaTier
function Karma.GetTier(source)
    local entity = Database.GetBySource(source)
    return entity and entity.tier or TierEvaluator.Resolve(Config.DefaultKarma)
end

---Retorna o modificador percentual de lojas
---@param source integer
---@return number
function Karma.GetShopModifier(source)
    local entity = Database.GetBySource(source)
    return entity and entity.tier.shopDiscount or 0.00
end

---Verifica se o jogador é elegível para caçadores de recompensa
---@param source integer
---@return boolean isEligible
---@return number bountyPrice
function Karma.IsBountyEligible(source)
    local entity = Database.GetBySource(source)
    if not entity then return false, 0.00 end
    return entity.tier.bountyEligible, entity.bountyPrice
end

---Processa e avalia as ações de combate despachadas pelos clientes
---@param attackerSrc integer ID da sessão do jogador agressor
---@param payload CombatActionPayload Dados completos da ação e iniciativa
function Karma.ProcessCombatAction(attackerSrc, payload)
    if not payload or not attackerSrc or attackerSrc <= 0 then return end

    if payload.targetType == "ANIMAL" then
        return -- Animais não alteram a moralidade padrão
    end

    local weaponLabel = Weapons.GetWeaponLabel(payload.weaponHash)

    -- 1. CASO DE LEGÍTIMA DEFESA (O alvo agrediu o jogador primeiro)
    if payload.initiative == "SELF_DEFENSE" then
        if payload.targetType == "PLAYER" then
            print(string.format("^2[westrp_karma:server] LEGÍTIMA DEFESA PvP: Jogador [%d] revidou agressão de jogador [%s] (Arma: %s). Honra preservada.^0",
                attackerSrc, tostring(payload.victimServerId or "desconhecido"), weaponLabel))
        else
            if payload.actionType == "KILL" then
                local reward = Config.Rewards.WantedBanditKill or 15
                Karma.Modify(attackerSrc, reward, "Eliminação de forasteiro hostil")
                print(string.format("^2[westrp_karma:server] LEGÍTIMA DEFESA PvE: Jogador [%d] eliminou agressor hostil (Arma: %s | +%d pts).^0",
                    attackerSrc, weaponLabel, reward))
            else
                print(string.format("^2[westrp_karma:server] LEGÍTIMA DEFESA PvE: Jogador [%d] conteve agressor hostil (%s | Arma: %s). Honra preservada.^0",
                    attackerSrc, payload.actionType, weaponLabel))
            end
        end
        return
    end

    -- 2. CASO DE ATITUDE NEGATIVA NÃO PROVOCADA (Iniciada pelo jogador)
    local delta = 0
    local reason = ""

    if payload.targetType == "PLAYER" then
        if payload.actionType == "KILL" then
            delta = Config.Penalties.PlayerKillUnprovoked or -120
            reason = "Assassinato não provocado de outro cidadão (PK)"
        elseif payload.actionType == "KNOCKOUT" then
            delta = Config.Penalties.PlayerKnockoutUnprovoked or -25
            reason = "Nocaute injustificado de outro cidadão"
        else
            delta = Config.Penalties.PlayerAssaultUnprovoked or -15
            reason = "Agressão corporal armada contra cidadão"
        end
    elseif payload.targetType == "LAWMAN" then
        if payload.actionType == "KILL" then
            delta = payload.wasKnockedOut and (-45) or (Config.Penalties.LawmanKill or -80)
            reason = payload.wasKnockedOut and "Execução de autoridade desacordada" or "Assassinato de homem da lei"
        elseif payload.actionType == "KNOCKOUT" then
            delta = Config.Penalties.LawmanKnockout or -35
            reason = "Nocaute / asfixia contra homem da lei"
        else
            delta = Config.Penalties.LawmanAssault or -15
            reason = "Agressão contra autoridade da lei"
        end
    else -- "CIVILIAN"
        if payload.actionType == "KILL" then
            delta = payload.wasKnockedOut and (-25) or (Config.Penalties.CivilianKill or -35)
            reason = payload.wasKnockedOut and "Execução de civil desacordado" or "Assassinato de civil inocente"
        elseif payload.actionType == "KNOCKOUT" then
            delta = Config.Penalties.CivilianKnockout or -10
            reason = "Nocaute / asfixia de civil inocente"
        else
            delta = Config.Penalties.CivilianAssault or -5
            reason = "Agressão corporal contra civil inocente"
        end
    end

    print(string.format("^1[westrp_karma:server] ATITUDE NEGATIVA: Jogador [%d] -> Alvo: [%s] | Ação: [%s] | Arma: %s | Delta: %d pts | Motivo: %s^0",
        attackerSrc, payload.targetType, payload.actionType, weaponLabel, delta, reason))

    local success, newKarma = Karma.Modify(attackerSrc, delta, reason)
    if success and newKarma and Config.Debug then
        print(string.format("^2[westrp_karma:server] Novo karma do jogador [%d]: %d^0", attackerSrc, newKarma))
    end
end

-- Aliases legados de compatibilidade
function Karma.ProcessNpcAction(attackerSrc, actionType, npcType, weaponHash, wasKnockedOut)
    Karma.ProcessCombatAction(attackerSrc, {
        targetType = npcType,
        actionType = actionType,
        initiative = (npcType == "HOSTILE") and "SELF_DEFENSE" or "UNPROVOKED",
        isNegative = (npcType ~= "HOSTILE" and npcType ~= "ANIMAL"),
        weaponHash = weaponHash or 0,
        wasKnockedOut = wasKnockedOut
    })
end

function Karma.ProcessNpcDeath(attackerSrc, npcType, weaponHash)
    Karma.ProcessNpcAction(attackerSrc, "KILL", npcType, weaponHash, false)
end

-- Compatibilidade retroativa com referências anteriores a KarmaService
KarmaService = Karma
