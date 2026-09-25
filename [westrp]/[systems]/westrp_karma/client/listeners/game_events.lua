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

    -- Se a vítima for o próprio jogador (ou sua montaria), registramos o agressor para Legítima Defesa
    local isPlayerVictim = (victim == playerPed) or (IsPedOnMount(playerPed) and victim == GetMount(playerPed))
    if isPlayerVictim then
        local attacker = culprit
        if attacker and attacker ~= 0 and DoesEntityExist(attacker) then
            if IsEntityAVehicle(attacker) then
                local pedInVeh = GetPedInVehicleSeat(attacker, -1)
                if pedInVeh and pedInVeh ~= 0 then attacker = pedInVeh end
            end
        end

        if attacker and attacker ~= 0 and attacker ~= playerPed and DoesEntityExist(attacker) and IsEntityAPed(attacker) then
            local now = GetGameTimer()
            local isLawman = (KarmaState.ClassifyTarget(attacker) == "LAWMAN")
            local playerStarted = KarmaState.playerAggressions and KarmaState.playerAggressions[attacker]
            -- Autoridades da lei não geram direito de legítima defesa (desacato/resistência não é lícita)
            -- E apenas concede se o jogador NÃO foi o provocador/agressor inicial
            if not isLawman and (not playerStarted or (now - playerStarted) > ((Config.SelfDefenseDuration or 45) * 1000)) then
                KarmaState.recentAttackers[attacker] = now
                KarmaState.recentAimThreats[attacker] = now
                KarmaState.lastCombatTime = now

                -- Identifica arma/munição do disparo ou agressão recebida
                local rawWeapon = 0
                if args then
                    local candidates = { args[7], args[5], args[8], args[9] }
                    for _, c in ipairs(candidates) do
                        local num = tonumber(c)
                        if num and num ~= 0 and not Weapons.IsUnarmed(num) then
                            rawWeapon = num
                            break
                        end
                    end
                end
                local wepLabel = (rawWeapon ~= 0) and Weapons.GetWeaponLabel(rawWeapon) or "Ataque Físico/Armado"

                if Config.Debug then
                    print(string.format("^5[DEBUG]^7 [^3KARMA_DEFENSE^7] Agressão/Disparo sofrido pelo jogador -> Agressor: Ped #%d (%s) (Legítima Defesa ativa)^0", attacker, wepLabel))
                    TriggerServerEvent('westrp_karma:server:relayClientDebug', 'KARMA_DEFENSE',
                        string.format("Agressão/Disparo sofrido pelo jogador -> Agressor: Ped #%d (%s)", attacker, wepLabel))
                end
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
