-- ====================================================================
-- WestRP Karma — Client Controller: HUD & Telemetry Bridge
-- File: client/controllers/hud.lua
-- ====================================================================

---@class KarmaHUD
KarmaHUD = {}
KarmaHUD.isVisible = false

---Controla a visibilidade do HUD de telemetria
---@param visible boolean
function KarmaHUD:SetVisible(visible)
    self.isVisible = visible
    SendNUIMessage({
        action = 'toggleHUD',
        visible = visible
    })
end

---Retorna se o HUD de telemetria está visível
---@return boolean
function KarmaHUD:IsVisible()
    return self.isVisible
end

---Envia um registro de evento para o HUD
---@param badgeType "kill" | "defense" | "knockout" | "assault" | "pipe_halt" | "pipe_pass" | "filtered"
---@param badgeLabel string
---@param detail string
---@param deltaFormatted string
---@param deltaNum integer
function KarmaHUD:PushLog(badgeType, badgeLabel, detail, deltaFormatted, deltaNum)
    if not self.isVisible then return end
    SendNUIMessage({
        action = 'addCombatLog',
        badgeType = badgeType,
        badgeLabel = badgeLabel,
        detail = detail,
        deltaFormatted = deltaFormatted,
        delta = deltaNum
    })
end

---Identifica de forma dinâmica o alvo atual em foco para apresentação na UI
---Compatível com Mira Livre (Mouse/PC), Trava (Controle), Melee e Proximidade
---@param playerPed integer
---@return integer? targetPed
function KarmaHUD:GetPlayerCurrentTarget(playerPed)
    -- 1. Alvo de Trava / Foco de Mira (Controle ou Lock-on)
    local hasTarget, targetPed = GetPlayerTargetEntity(PlayerId())
    if hasTarget and DoesEntityExist(targetPed) and IsEntityAPed(targetPed) and targetPed ~= playerPed then
        return targetPed
    end

    -- 2. Alvo de Mira Livre com Arma (Crucial para Teclado e Mouse no PC)
    local isAiming, aimEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if isAiming and DoesEntityExist(aimEntity) and IsEntityAPed(aimEntity) and aimEntity ~= playerPed then
        return aimEntity
    end

    -- 3. Alvo de Combate Corporal Imediato
    local meleeTarget = GetMeleeTargetForPed(playerPed)
    if meleeTarget and meleeTarget ~= 0 and DoesEntityExist(meleeTarget) and IsEntityAPed(meleeTarget) and meleeTarget ~= playerPed then
        return meleeTarget
    end

    -- 4. Ped em combate próximo direto contra o jogador
    local pCoords = GetEntityCoords(playerPed)
    local peds = GetGamePool('CPed')
    local closestPed = nil
    local closestDist = 5.0

    for _, ped in ipairs(peds) do
        if ped ~= playerPed and DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            local dist = #(pCoords - GetEntityCoords(ped))
            if dist < closestDist and (IsPedInCombat(ped, playerPed) or IsPedInCombat(playerPed, ped)) then
                closestDist = dist
                closestPed = ped
            end
        end
    end

    return closestPed
end

---Atualiza o status do jogador e alvo na interface do HUD
---@param playerPed integer
---@param inCombat boolean
function KarmaHUD:UpdateFrame(playerPed, inCombat)
    if not self.isVisible then return end

    local combatStateText = inCombat and "EM COMBATE ATIVO" or "FORA DE COMBATE"
    local combatClass = inCombat and "combat" or "idle"
    local heldWep = KarmaState.GetPlayerHeldWeapon(playerPed)

    SendNUIMessage({
        action = 'updatePlayerStatus',
        combatState = combatStateText,
        combatClass = combatClass,
        weaponLabel = Weapons.GetWeaponLabel(heldWep)
    })

    -- Inspeciona alvo atual (mira livre, lock-on ou melee)
    local targetPed = self:GetPlayerCurrentTarget(playerPed)
    if targetPed and DoesEntityExist(targetPed) and IsEntityAPed(targetPed) then
        local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(targetPed))
        local isDead = KarmaState.deadPeds[targetPed] ~= nil or KarmaState.IsPedActuallyDead(targetPed)
        local isKnockedOut = not isDead and KarmaState.IsPedActuallyKnockedOut(targetPed)
        local isRagdoll = IsPedRagdoll(targetPed) or isKnockedOut

        local fsmState = "ACTIVE"
        if isDead then
            fsmState = "DEAD"
        elseif isKnockedOut then
            fsmState = "KNOCKOUT"
        elseif inCombat or IsPedInCombat(targetPed, playerPed) then
            fsmState = "ENGAGED"
        end

        SendNUIMessage({
            action = 'updateTarget',
            hasTarget = true,
            pedId = targetPed,
            targetType = KarmaState.ClassifyTarget(targetPed),
            distance = dist,
            fsmState = fsmState,
            isDead = isDead,
            isRagdoll = isRagdoll
        })
    else
        SendNUIMessage({
            action = 'updateTarget',
            hasTarget = false
        })
    end
end
