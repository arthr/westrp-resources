-- ====================================================================
-- WestRP Karma — Security Pipeline: CombatVerifier
-- File: server/security/combat_verifier.lua
-- ====================================================================

---@class CombatVerifier
CombatVerifier = {}

---Valida um payload de combate enviado pelo client antes de aplicar mutações morais
---@param attackerSrc integer ID de rede do agressor
---@param payload CombatReportPayload Dados enviados pelo client
---@return boolean isValid
---@return string reason
function CombatVerifier.VerifyReport(attackerSrc, payload)
    if not payload then
        return false, "EMPTY_PAYLOAD"
    end
    
    local attackerPed = GetPlayerPed(attackerSrc)
    if not DoesEntityExist(attackerPed) then
        return false, "ATTACKER_PED_NOT_FOUND"
    end
    
    local serverAttackerCoords = GetEntityCoords(attackerPed)
    
    -- 1. Verificação de Anti-Spoofing de Coordenadas do Atacante
    local attackerCoordDiff = #(serverAttackerCoords - payload.attackerCoords)
    if attackerCoordDiff > Config.Security.TeleportThreshold then
        return false, string.format("ATTACKER_COORDINATE_SPOOF (Diff: %.1fm)", attackerCoordDiff)
    end
    
    -- 2. Tratamento específico para PvP (Vítima Jogador)
    if payload.isPlayer then
        if not payload.victimServerId then
            return false, "MISSING_VICTIM_SERVER_ID"
        end
        
        local victimPed = GetPlayerPed(payload.victimServerId)
        if not DoesEntityExist(victimPed) then
            return false, "VICTIM_PED_NOT_FOUND"
        end
        
        local serverVictimCoords = GetEntityCoords(victimPed)
        
        -- Verificação de Anti-Spoofing de Coordenadas da Vítima
        local victimCoordDiff = #(serverVictimCoords - payload.victimCoords)
        if victimCoordDiff > Config.Security.TeleportThreshold then
            return false, string.format("VICTIM_COORDINATE_SPOOF (Diff: %.1fm)", victimCoordDiff)
        end
        
        -- Verificação de Cota Espacial de Disparo (Distância física real)
        local realDistance = #(serverAttackerCoords - serverVictimCoords)
        if realDistance > Config.Security.MaxDistance then
            return false, string.format("EXCESSIVE_DISTANCE (Dist: %.1fm > Max: %.1fm)", realDistance, Config.Security.MaxDistance)
        end
        
        -- Verificação de Integridade de Óbito
        if payload.isFatal and Config.Security.EnforceFatalIntegrity then
            local isDead = IsEntityDead(victimPed)
            local health = GetEntityHealth(victimPed)
            if not isDead and health > 0 then
                return false, "FAKE_FATAL_ASSERTION"
            end
        end
    end
    
    return true, "APPROVED"
end
