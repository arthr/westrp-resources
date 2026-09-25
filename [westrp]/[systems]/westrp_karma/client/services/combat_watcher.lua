-- ====================================================================
-- WestRP Karma — Client Service: Combat Watcher & Background Observer
-- File: client/services/combat_watcher.lua
-- ====================================================================

---@class CombatWatcher
CombatWatcher = {}

local isRunning = false
local mainTask = nil
local gcTask = nil

---Inicia as tarefas de observação de combate e telemetria
function CombatWatcher.Start()
    if isRunning then return end
    isRunning = true

    -- Loop adaptativo de combate corporal e atualização do HUD (0.00ms em idle via TickManager)
    local function RunMainLoop(task)
        local playerPed = PlayerPedId()
        local now = GetGameTimer()

        local isAiming = IsPlayerFreeAiming(PlayerId())
        local hasBleedingVictims = (next(KarmaState.bleedingVictims) ~= nil)
        local isDirectCombat = (now - KarmaState.lastCombatTime) < 8000
            or IsPedInMeleeCombat(playerPed)
            or IsPedInCombat(playerPed, 0)
            or isAiming
        local inCombat = isDirectCombat or hasBleedingVictims

        local desiredInterval = inCombat and (isAiming and 100 or 200) or 500

        -- Observador ativo de combate corpo a corpo
        local inMelee = IsPedInMeleeCombat(playerPed)
        if inMelee then
            desiredInterval = 100
            local meleeTarget = GetMeleeTargetForPed(playerPed)
            if meleeTarget and meleeTarget ~= 0 and DoesEntityExist(meleeTarget) and IsEntityAPed(meleeTarget) and meleeTarget ~= playerPed then
                local curHp = GetEntityHealth(meleeTarget)
                local lastHp = KarmaState.lastMeleeHealth[meleeTarget]

                if lastHp and curHp < lastHp then
                    -- Impacto físico corporal detectado
                    ---@type CombatContext
                    local ctx = {
                        victim = meleeTarget,
                        culprit = playerPed,
                        args = nil,
                        playerPed = playerPed,
                        isAuthor = true,
                        isDead = false,
                        isKnockedOut = false,
                        isAssault = false,
                        targetType = "UNKNOWN",
                        weaponHash = KarmaState.GetPlayerHeldWeapon(playerPed),
                        weaponLabel = "",
                        actionType = "ASSAULT",
                        initiative = "UNPROVOKED",
                        victimServerId = nil,
                        estimatedDelta = 0,
                        killerSource = playerPed
                    }
                    pcall(CombatPipeline.Run, ctx)
                end
                KarmaState.lastMeleeHealth[meleeTarget] = curHp
            end
        end

        -- Observador de ameaças armadas reais (inimigos hostis atirando ou empunhando armas contra o jogador)
        local pCoords = GetEntityCoords(playerPed)
        local peds = GetGamePool('CPed')
        for i = 1, #peds do
            local ped = peds[i]
            if ped ~= playerPed and DoesEntityExist(ped) and not IsPedAPlayer(ped) then
                local vCoords = GetEntityCoords(ped)
                if #(pCoords - vCoords) < 45.0 then
                    -- Se o ped estiver em combate contra o jogador
                    if IsPedInCombat(ped, playerPed) then
                        KarmaState.lastCombatTime = now
                        local isLawman = (KarmaState.ClassifyTarget(ped) == "LAWMAN")
                        local playerStarted = KarmaState.playerAggressions and (KarmaState.playerAggressions[ped] ~= nil)

                        if not isLawman and not playerStarted then
                            local isShooting = IsPedShooting(ped)
                            local isArmedWithGun = IsPedArmed(ped, 4) -- 4 = empunhando arma de fogo

                            -- Se estiver disparando OU em combate ativo empunhando arma de fogo
                            if isShooting or isArmedWithGun then
                                KarmaState.recentAimThreats[ped] = now
                                if isShooting then
                                    KarmaState.recentAttackers[ped] = now
                                    if Config.Debug then
                                        print(string.format("^5[DEBUG]^7 [^3KARMA_GUNFIGHT^7] Disparo ativo detectado de Ped #%d contra jogador (Legítima Defesa imediata)^0", ped))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Observador de óbito tardio para alvos feridos por armas de fogo ou em sangramento (Task 3.2)
        if hasBleedingVictims then
            for victimPed, bleedData in pairs(KarmaState.bleedingVictims) do
                if DoesEntityExist(victimPed) and KarmaState.IsPedActuallyDead(victimPed) and not KarmaState.deadPeds[victimPed] then
                    ---@type CombatContext
                    local ctx = {
                        victim = victimPed,
                        culprit = bleedData.author,
                        args = nil,
                        playerPed = playerPed,
                        isAuthor = (bleedData.author == playerPed),
                        isDead = true,
                        isKnockedOut = false,
                        isAssault = false,
                        targetType = "UNKNOWN",
                        weaponHash = bleedData.weaponHash,
                        weaponLabel = "",
                        actionType = "KILL",
                        initiative = "UNPROVOKED",
                        victimServerId = nil,
                        estimatedDelta = 0,
                        killerSource = bleedData.author
                    }
                    pcall(CombatPipeline.Run, ctx)
                end
            end
        end

        -- Atualiza interface visual do HUD
        pcall(function()
            KarmaHUD:UpdateFrame(playerPed, inCombat)
        end)

        if task and task.SetInterval then
            task:SetInterval(desiredInterval)
        end

        return desiredInterval
    end

    -- Integração com WestRP TickManager (com fallback seguro para CreateThread)
    if WestRP and WestRP.Client and WestRP.Client.TickManager and WestRP.Client.TickManager.CreateTask then
        mainTask = WestRP.Client.TickManager.CreateTask('karma_combat_observer', RunMainLoop, 600)
    else
        CreateThread(function()
            while isRunning do
                local sleep = RunMainLoop()
                Wait(sleep or 600)
            end
        end)
    end

    -- Loop periódico de limpeza de memória (Garbage Collection a cada 60s)
    local function RunGCLoop()
        local now = GetGameTimer()

        for ped, killTime in pairs(KarmaState.deadPeds) do
            if not DoesEntityExist(ped) or (now - killTime) > 60000 then
                KarmaState.deadPeds[ped] = nil
            end
        end

        for ped, koTime in pairs(KarmaState.knockedOutPeds) do
            if not DoesEntityExist(ped) or (now - koTime) > 30000 then
                KarmaState.knockedOutPeds[ped] = nil
            end
        end

        for ped, assTime in pairs(KarmaState.recentAssaults) do
            if not DoesEntityExist(ped) or (now - assTime) > 15000 then
                KarmaState.recentAssaults[ped] = nil
            end
        end

        for ped, atkTime in pairs(KarmaState.recentAttackers) do
            if not DoesEntityExist(ped) or (now - atkTime) > ((Config.SelfDefenseDuration or 45) * 1000) then
                KarmaState.recentAttackers[ped] = nil
            end
        end

        for ped, threatTime in pairs(KarmaState.recentAimThreats) do
            if not DoesEntityExist(ped) or (now - threatTime) > 30000 then
                KarmaState.recentAimThreats[ped] = nil
            end
        end

        for ped, aggTime in pairs(KarmaState.playerAggressions) do
            if not DoesEntityExist(ped) or (now - aggTime) > ((Config.SelfDefenseDuration or 45) * 1000) then
                KarmaState.playerAggressions[ped] = nil
            end
        end

        for ped, bleedData in pairs(KarmaState.bleedingVictims) do
            if not DoesEntityExist(ped) or (now - (bleedData.assaultTimestamp or 0)) > 45000 then
                KarmaState.bleedingVictims[ped] = nil
            end
        end

        for ped, _ in pairs(KarmaState.lastMeleeHealth) do
            if not DoesEntityExist(ped) then
                KarmaState.lastMeleeHealth[ped] = nil
            end
        end
    end

    if WestRP and WestRP.Client and WestRP.Client.TickManager and WestRP.Client.TickManager.CreateTask then
        gcTask = WestRP.Client.TickManager.CreateTask('karma_garbage_collector', RunGCLoop, 60000)
    else
        CreateThread(function()
            while isRunning do
                Wait(60000)
                if not isRunning then break end
                RunGCLoop()
            end
        end)
    end
end

---Encerra todas as tarefas de observação e monitoramento de combate
function CombatWatcher.Stop()
    isRunning = false
    if mainTask then
        mainTask:Stop()
        mainTask = nil
    end
    if gcTask then
        gcTask:Stop()
        gcTask = nil
    end
    if WestRP and WestRP.Client and WestRP.Client.TickManager then
        WestRP.Client.TickManager.RemoveTask('karma_combat_observer')
        WestRP.Client.TickManager.RemoveTask('karma_garbage_collector')
    end
end
