-- ====================================================================
-- WestRP Karma — Client: CombatDetector
-- File: client/combat_detector.lua
-- ====================================================================

---@class CombatDetector
CombatDetector = {}

---Captura eventos de dano no motor físico do RedM
AddEventHandler('gameEventTriggered', function(eventName, data)
    if eventName ~= 'CEventNetworkEntityDamage' then return end

    local victimEntity = data[1]
    local attackerEntity = data[2]
    local isFatal = data[6] == 1 or data[4] == 1 or IsEntityDead(victimEntity)
    local weaponHash = data[7]

    local playerPed = PlayerPedId()

    -- Interessa apenas se o atacante for o próprio jogador local
    if attackerEntity ~= playerPed then return end

    -- Ignora se o jogador causou dano a si mesmo
    if victimEntity == playerPed then return end

    -- Verifica se a vítima é um jogador ou NPC
    local isPlayer = IsPedAPlayer(victimEntity)
    local victimServerId = nil

    if isPlayer then
        local playerIndex = NetworkGetPlayerIndexFromPed(victimEntity)
        if playerIndex and playerIndex ~= -1 then
            victimServerId = GetPlayerServerId(playerIndex)
        end
    end

    local attackerCoords = GetEntityCoords(playerPed)
    local victimCoords = GetEntityCoords(victimEntity)
    local distance = #(attackerCoords - victimCoords)

    ---@type CombatReportPayload
    local payload = {
        isPlayer = isPlayer,
        victimServerId = victimServerId,
        victimModel = GetEntityModel(victimEntity),
        isFatal = isFatal,
        weaponHash = weaponHash or 0,
        attackerCoords = attackerCoords,
        victimCoords = victimCoords,
        distance = distance
    }

    -- Envia o relatório assinado localmente para o pipeline de verificação do servidor
    TriggerServerEvent('westrp_karma:server:reportCombat', payload)
end)
