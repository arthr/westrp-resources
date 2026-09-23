WestRP = WestRP or {}
WestRP.Server = WestRP.Server or {}
WestRP.Server.Security = {}

local rateLimits = {}

---Valida se o ped do jogador está realmente dentro da distância permitida das coordenadas alvo
---@param source number
---@param targetCoords vector3|table
---@param maxDistance? number
---@return boolean
function WestRP.Server.Security.ValidateDistance(source, targetCoords, maxDistance)
    if not source or not targetCoords then return false end

    local ped = GetPlayerPed(source)
    if not DoesEntityExist(ped) then return false end

    local playerCoords = GetEntityCoords(ped)
    local allowedDist = maxDistance or (WestRP.Config and WestRP.Config.DistanceTolerance) or 3.5

    local targetV3 = type(targetCoords) == "vector3" and targetCoords or vector3(targetCoords.x or targetCoords[1], targetCoords.y or targetCoords[2], targetCoords.z or targetCoords[3])
    local dist = #(playerCoords - targetV3)

    if dist > allowedDist then
        WestRP.Shared.Logger.Warn("SECURITY", "Player %s tentou ação fora de alcance! Distância real: %.2fm (Máx: %.2fm)", source, dist, allowedDist)
        return false
    end

    return true
end

---Verifica se a ação do jogador respeita o limite de taxa (Anti-Spam / Anti-Flood)
---@param source number
---@param actionKey string
---@param cooldownMs? number
---@return boolean
function WestRP.Server.Security.CheckRateLimit(source, actionKey, cooldownMs)
    if not source or not actionKey then return false end

    local now = GetGameTimer()
    local cooldown = cooldownMs or (WestRP.Config and WestRP.Config.DefaultRateLimitMs) or 1000

    rateLimits[source] = rateLimits[source] or {}
    local lastExecution = rateLimits[source][actionKey] or 0

    if (now - lastExecution) < cooldown then
        WestRP.Shared.Logger.Warn("SECURITY", "Player %s excedeu o rate limit para '%s'! Tentou em %sms (Limite: %sms)", source, actionKey, (now - lastExecution), cooldown)
        return false
    end

    rateLimits[source][actionKey] = now
    return true
end

---Verifica se o jogador está vivo
---@param source number
---@return boolean
function WestRP.Server.Security.IsPlayerAlive(source)
    local ped = GetPlayerPed(source)
    if not DoesEntityExist(ped) then return false end
    return GetEntityHealth(ped) > 0
end

-- Limpa histórico de rate limit ao desconectar
AddEventHandler('playerDropped', function()
    local src = source
    if rateLimits[src] then
        rateLimits[src] = nil
    end
end)
