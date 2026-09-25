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
        local inCombat = (now - KarmaState.lastCombatTime) < 8000
        local desiredInterval = inCombat and 250 or 600

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
                    CombatPipeline.Run(ctx)
                end
                KarmaState.lastMeleeHealth[meleeTarget] = curHp
            end
        end

        -- Atualiza interface visual do HUD
        KarmaHUD:UpdateFrame(playerPed, inCombat)

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
