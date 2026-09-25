-- ====================================================================
-- WestRP Karma — Client Listener: Native Game Events
-- File: client/listeners/game_events.lua
-- ====================================================================

-- Escuta de eventos nativos do motor RDR3 / RedM
AddEventHandler('gameEventTriggered', function(eventName, args)
    if eventName ~= 'CEventNetworkEntityDamage' then return end

    local playerPed = PlayerPedId()
    local victim = args[1]
    local culprit = args[2]

    -- Se a vítima for o próprio jogador, registramos o agressor para Legítima Defesa
    if victim == playerPed then
        if culprit and culprit ~= 0 and culprit ~= playerPed and DoesEntityExist(culprit) and IsEntityAPed(culprit) then
            KarmaState.recentAttackers[culprit] = GetGameTimer()
            KarmaState.lastCombatTime = GetGameTimer()
            if Config.Debug then
                print(string.format("^5[DEBUG]^7 [^3KARMA_DEFENSE^7] Agressão sofrida pelo jogador -> Agressor registrado: Ped #%d (Legítima Defesa ativa)^0", culprit))
                TriggerServerEvent('westrp_karma:server:relayClientDebug', 'KARMA_DEFENSE',
                    string.format("Agressão sofrida pelo jogador -> Agressor: Ped #%d", culprit))
            end
        end
        return
    end

    ---@type CombatContext
    local ctx = {
        victim = victim,
        culprit = culprit,
        args = args,
        playerPed = playerPed,
        isAuthor = false,
        isDead = false,
        isKnockedOut = false,
        isAssault = false,
        targetType = "UNKNOWN",
        weaponHash = 0,
        weaponLabel = "",
        actionType = "ASSAULT",
        initiative = "UNPROVOKED",
        victimServerId = nil,
        estimatedDelta = 0,
        killerSource = nil
    }

    CombatPipeline.Run(ctx)
end)
