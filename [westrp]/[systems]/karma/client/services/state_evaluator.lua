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
KarmaState.recentAimThreats = {}  -- [ped] = timestamp quando o ped mirou no jogador
KarmaState.playerAggressions = {} -- [ped] = timestamp quando o jogador agrediu/provocou o ped primeiro
KarmaState.bleedingVictims = {}   -- [ped] = { author: ped, weaponHash: hash, timestamp: number, penaltyPaid: number }
KarmaState.lastMeleeHealth = {}   -- [ped] = lastKnownHealth
KarmaState.lastCombatTime = 0     -- timestamp do último confronto

---Hashes e tags de ossos anatômicos cranianos e vitais do RDR3
local HEAD_BONE_TAGS = {
    [31086] = true, -- SKEL_Head (Tag canônica do RDR2/RAGE)
    [21030] = true, -- SKEL_Head alt
    [46065] = true, -- SKEL_L_Jaw
    [46066] = true, -- SKEL_R_Jaw
    [GetHashKey("SKEL_HEAD")] = true,
    [GetHashKey("SKEL_Head")] = true,
    [GetHashKey("FACIAL_facialRoot")] = true
}

local NECK_BONE_TAGS = {
    [14283] = true, -- SKEL_NECK0
    [14284] = true, -- SKEL_NECK1
    [14285] = true, -- SKEL_NECK2
    [39317] = true, -- SKEL_Neck alt
    [GetHashKey("SKEL_NECK0")] = true,
    [GetHashKey("SKEL_Neck0")] = true,
    [GetHashKey("SKEL_NECK1")] = true,
    [GetHashKey("SKEL_Neck1")] = true,
    [GetHashKey("SKEL_NECK2")] = true
}

---Grupos de relacionamento de autoridades da lei no RDR2
local lawRelationshipHashes = {
    [GetHashKey("LAW")] = true,
    [GetHashKey("COP")] = true,
    [GetHashKey("REL_COP")] = true,
    [GetHashKey("DISPATCH_POLICE")] = true,
    [GetHashKey("GUARDS")] = true,
    [GetHashKey("REL_GUARDS")] = true
}

---Classifica a categoria do alvo com validação defensiva para RedM
---@param ped integer
---@return "PLAYER" | "CIVILIAN" | "LAWMAN" | "ANIMAL" | "UNKNOWN"
function KarmaState.ClassifyTarget(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) or not IsEntityAPed(ped) then
        return "UNKNOWN"
    end
    local isPlayer = IsPedAPlayer(ped)
    if isPlayer == true or isPlayer == 1 then
        return "PLAYER"
    end
    local isHuman = IsPedHuman(ped)
    if isHuman == false or isHuman == 0 then
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
---Retorna a arma em mãos (attachPoint 0) ou WEAPON_UNARMED se desarmado (não lê coldres de cinto/costas)
---@param ped integer?
---@return integer
function KarmaState.GetPlayerHeldWeapon(ped)
    ped = ped or PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return `WEAPON_UNARMED`
    end

    -- 1. Inspeciona a arma ativa na mão principal (attachPoint 0)
    local okWep, hasWep, wepHash = pcall(GetCurrentPedWeapon, ped, true, 0, false)
    if not okWep or not hasWep or not wepHash or wepHash == 0 then
        okWep, hasWep, wepHash = pcall(GetCurrentPedWeapon, ped, false, 0, false)
    end

    if okWep and hasWep and wepHash and wepHash ~= 0 and not Weapons.IsUnarmed(wepHash) then
        return wepHash
    end

    -- 2. Suporte a empunhadura secundária / off-hand (attachPoint 1) apenas se houver arma sacada
    -- A verificação com IsPedArmed(ped, 4) garante que só lemos o attachPoint 1 se o ped estiver
    -- efetivamente segurando uma arma de fogo nas mãos (dual-wielding ou off-hand ativa),
    -- impedindo categoricamente que uma arma guardada no coldre lateral seja interpretada como arma atual.
    local isHoldingGun = false
    local okArmed, armedFlag = pcall(IsPedArmed, ped, 4)
    if okArmed and armedFlag then
        isHoldingGun = true
    end

    if isHoldingGun then
        local okOff, hasOff, offHash = pcall(GetCurrentPedWeapon, ped, true, 1, false)
        if okOff and hasOff and offHash and offHash ~= 0 and not Weapons.IsUnarmed(offHash) then
            return offHash
        end
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

    -- 2. Vida zerada ou negativa
    local hp = GetEntityHealth(ped)
    if hp <= 0 then
        return true
    end

    -- 3. Native estrita de morte do RDR3 com p1 = true (inclui agonia / animação de morte)
    local okDead, deadOrDying = pcall(IsPedDeadOrDying, ped, true)
    if okDead and deadOrDying then
        return true
    end

    -- 4. Padrão de referência do baseevents/deathevents.lua: Ferimento fatal
    local okFatally, fatallyInjured = pcall(IsPedFatallyInjured, ped)
    if okFatally and fatallyInjured then
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

---Identifica a região anatômica do último dano sofrido pela entidade
---Utiliza a native GetPedLastDamageBone validando ossos cranianos e cervicais com fallback robusto
---@param ped integer
---@return "HEAD" | "NECK" | "BODY" | "UNKNOWN", integer boneId
function KarmaState.GetDamageLocation(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return "UNKNOWN", 0
    end

    local ok, hasBone, boneId = pcall(GetPedLastDamageBone, ped)
    if ok and hasBone and boneId and boneId ~= 0 then
        local bNum = tonumber(boneId) or 0
        local bUnsigned = (bNum < 0) and (bNum + 0x100000000) or bNum

        -- 1. Verifica tags diretas de crânio/cabeça
        if HEAD_BONE_TAGS[bNum] or HEAD_BONE_TAGS[bUnsigned] then
            return "HEAD", bNum
        end

        -- 2. Verifica tags de pescoço
        if NECK_BONE_TAGS[bNum] or NECK_BONE_TAGS[bUnsigned] then
            return "NECK", bNum
        end

        -- 3. No RedM, GetPedLastDamageBone frequentemente retorna o Bone Index local do Ped
        local headTagsToCheck = { 31086, 21030, `SKEL_Head`, `SKEL_HEAD`, `FACIAL_facialRoot` }
        for _, tag in ipairs(headTagsToCheck) do
            local okIdx, idx = pcall(GetPedBoneIndex, ped, tag)
            if okIdx and idx and idx ~= -1 and bNum == idx then
                return "HEAD", bNum
            end
        end

        local neckTagsToCheck = { 14283, 14284, 14285, 39317, `SKEL_Neck0`, `SKEL_Neck1` }
        for _, tag in ipairs(neckTagsToCheck) do
            local okIdx, idx = pcall(GetPedBoneIndex, ped, tag)
            if okIdx and idx and idx ~= -1 and bNum == idx then
                return "NECK", bNum
            end
        end

        local okNameHead, nameHeadIdx = pcall(GetEntityBoneIndexByName, ped, "SKEL_Head")
        if okNameHead and nameHeadIdx and nameHeadIdx ~= -1 and bNum == nameHeadIdx then
            return "HEAD", bNum
        end

        return "BODY", bNum
    end

    -- Se GetPedLastDamageBone falhou ou retornou false no RedM (muito comum em óbito rápido por disparo):
    -- Fallback: verifica se o jogador estava mirando livremente na região craniana do Ped
    local isAiming, aimEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if isAiming and aimEntity == ped then
        local okHead, headIdx = pcall(GetPedBoneIndex, ped, 31086)
        if not okHead or headIdx == -1 then
            okHead, headIdx = pcall(GetPedBoneIndex, ped, 21030)
        end
        if okHead and headIdx and headIdx ~= -1 then
            return "HEAD", headIdx
        end
    end

    return "UNKNOWN", 0
end

---Determina se um ped vivo está em estado de sangramento lento / agonia no solo
---@param ped integer
---@return boolean isBleeding
function KarmaState.IsPedInBleedout(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
    if KarmaState.IsPedActuallyDead(ped) then return false end

    local hp = GetEntityHealth(ped)
    if hp <= 0 then return false end

    -- 1. Flag nativa de morte iminente / agonia no solo do RDR3
    local okDying, isDying = pcall(IsPedDeadOrDying, ped, true)
    if okDying and isDying and hp < 30 then
        return true
    end

    -- 2. Alvo cambaleando no chão sangrando com velocidade nula
    if IsPedRagdoll(ped) and hp < 20 and KarmaState.recentAssaults[ped] then
        return true
    end

    return false
end
