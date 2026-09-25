-- ====================================================================
-- WestRP Karma — Client Service: State Evaluator & Domain Logic
-- File: client/services/state_evaluator.lua
-- ====================================================================

---@class KarmaState
KarmaState = {}

---Caches temporais de deduplicação e estado físico
KarmaState.deadPeds = {}          -- [ped] = timestamp do óbito
KarmaState.knockedOutPeds = {}    -- [ped] = timestamp do nocaute
KarmaState.recentAssaults = {}    -- [ped] = timestamp da agressão
KarmaState.recentAttackers = {}   -- [ped] = timestamp quando o ped agrediu o jogador
KarmaState.lastMeleeHealth = {}   -- [ped] = lastKnownHealth
KarmaState.lastCombatTime = 0     -- timestamp do último confronto

---Grupos de relacionamento de autoridades da lei no RDR2
local lawRelationshipHashes = {
    [GetHashKey("LAW")] = true,
    [GetHashKey("COP")] = true,
    [GetHashKey("REL_COP")] = true,
    [GetHashKey("DISPATCH_POLICE")] = true,
    [GetHashKey("GUARDS")] = true,
    [GetHashKey("REL_GUARDS")] = true
}

---Classifica a categoria do alvo
---@param ped integer
---@return "PLAYER" | "CIVILIAN" | "LAWMAN" | "ANIMAL" | "UNKNOWN"
function KarmaState.ClassifyTarget(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) or not IsEntityAPed(ped) then
        return "UNKNOWN"
    end
    if IsPedAPlayer(ped) then
        return "PLAYER"
    end
    if not IsPedHuman(ped) then
        return "ANIMAL"
    end
    local defaultRel = GetPedRelationshipGroupDefaultHash(ped)
    local currentRel = GetPedRelationshipGroupHash(ped)
    if lawRelationshipHashes[defaultRel] or lawRelationshipHashes[currentRel] then
        return "LAWMAN"
    end
    return "CIVILIAN"
end

---Obtém a arma atualmente empunhada/selecionada pelo jogador
---@param ped integer?
---@return integer
function KarmaState.GetPlayerHeldWeapon(ped)
    ped = ped or PlayerPedId()
    local ok, wep = pcall(GetSelectedPedWeapon, ped)
    if ok and wep and wep ~= 0 and not Weapons.IsUnarmed(wep) then
        return wep
    end
    return `WEAPON_UNARMED`
end

---Determina de forma precisa se um Ped está de fato morto (e não apenas nocauteado/desmaiado)
---Utiliza o padrão de referência do baseevents (IsPedFatallyInjured) somado a verificações nativas do RDR3
---@param ped integer
---@return boolean isDead
function KarmaState.IsPedActuallyDead(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end

    -- 1. Se a engine declara o Ped como entidade morta
    if IsEntityDead(ped) then
        return true
    end

    -- 2. Padrão de referência do baseevents/deathevents.lua: Ferimento fatal
    local okFatally, fatallyInjured = pcall(IsPedFatallyInjured, ped)
    if okFatally and fatallyInjured then
        return true
    end

    -- 3. Native estrita de morte do RDR3 SEM flags de melee takedown (p1 = false)
    local okDead, deadOrDying = pcall(IsPedDeadOrDying, ped, false)
    if okDead and deadOrDying then
        return true
    end

    -- 4. Se a vida for 0 ou negativa e possuir causa de morte não-desarmada
    local hp = GetEntityHealth(ped)
    local causeOfDeath = GetPedCauseOfDeath(ped)
    if hp <= 0 and causeOfDeath ~= 0 and not Weapons.IsUnarmed(causeOfDeath) then
        return true
    end

    return false
end

---Determina se um Ped vivo está em estado de nocaute / incapacitado / desacordado
---@param ped integer
---@return boolean isKnockedOut
function KarmaState.IsPedActuallyKnockedOut(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
    if KarmaState.IsPedActuallyDead(ped) then return false end

    -- Se o ped se levantou e está se movendo (acordou do nocaute)
    if not IsPedRagdoll(ped) and GetEntitySpeed(ped) > 0.8 then
        KarmaState.knockedOutPeds[ped] = nil
        return false
    end

    -- 1. Registrado no cache de nocautes recentes e ainda caído
    if KarmaState.knockedOutPeds[ped] and (GetGameTimer() - KarmaState.knockedOutPeds[ped]) < 60000 then
        if IsPedRagdoll(ped) or GetEntitySpeed(ped) < 0.3 then
            return true
        end
    end

    -- 2. Em física de Ragdoll (desacordado no chão)
    if IsPedRagdoll(ped) then
        return true
    end

    -- 3. Native interna de incapacitação do RDR3 (0xB655DB7582AEC805 - IS_PED_INCAPACITATED)
    local okIncap, isIncap = pcall(Citizen.InvokeNative, 0xB655DB7582AEC805, ped)
    if okIncap and isIncap then
        return true
    end

    -- 4. Alvo no chão sem mover-se em combate desarmado
    if not IsPedOnMount(ped) and not IsPedInAnyVehicle(ped, false) then
        local speed = GetEntitySpeed(ped)
        local hp = GetEntityHealth(ped)
        if speed < 0.2 and hp > 0 and (IsPedStill(ped) or IsPedFalling(ped)) then
            if KarmaState.recentAssaults[ped] and (GetGameTimer() - KarmaState.recentAssaults[ped]) < 15000 then
                return true
            end
        end
    end

    return false
end
