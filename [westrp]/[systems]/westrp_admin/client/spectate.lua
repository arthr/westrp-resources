WestRP = WestRP or {}
WestRP.Admin = WestRP.Admin or {}
WestRP.Admin.Spectate = {}

local isSpectating = false
local spectateCam = nil
local savedCoords = nil
local targetServerId = nil

---Alterna o modo espectador sobre um jogador alvo
---@param targetId number Server ID do jogador
---@param targetCoords vector3 Coordenadas do alvo
function WestRP.Admin.Spectate.Toggle(targetId, targetCoords)
    local admin = PlayerPedId()

    if not isSpectating then
        if not targetId or not targetCoords then return end

        DoScreenFadeOut(500)
        repeat Wait(0) until not IsScreenFadingOut()

        savedCoords = GetEntityCoords(admin)
        targetServerId = targetId

        -- Torna o admin intangível e invisível
        SetEntityVisible(admin, false)
        SetEntityCanBeDamaged(admin, false)
        SetEntityInvincible(admin, true)
        SetEntityCollision(admin, false, false)

        -- Posiciona o admin próximo ao alvo
        SetEntityCoords(admin, targetCoords.x, targetCoords.y, targetCoords.z + 10.0, false, false, false, false)
        Wait(300)

        local targetPlayer = GetPlayerFromServerId(targetId)
        local targetPed = GetPlayerPed(targetPlayer)

        -- Cria câmera roteirizada acoplada
        spectateCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        if DoesEntityExist(targetPed) then
            AttachCamToEntity(spectateCam, targetPed, 0.0, -2.2, 0.8, false)
        else
            SetCamCoord(spectateCam, targetCoords.x, targetCoords.y - 2.5, targetCoords.z + 1.5)
            PointCamAtCoord(spectateCam, targetCoords.x, targetCoords.y, targetCoords.z)
        end

        SetCamActive(spectateCam, true)
        RenderScriptCams(true, true, 500, true, true, 0)

        DoScreenFadeIn(500)
        isSpectating = true
        WestRP.Client.UI.ShowToast("MODO ESPECTADOR", "Monitorando jogador ID: " .. tostring(targetId), "info")
    else
        DoScreenFadeOut(500)
        repeat Wait(0) until not IsScreenFadingOut()

        RenderScriptCams(false, false, 0, true, true, 0)
        if spectateCam then
            DestroyCam(spectateCam, true)
            spectateCam = nil
        end
        DestroyAllCams(true)

        -- Retorna o admin à posição original
        if savedCoords then
            SetEntityCoords(admin, savedCoords.x, savedCoords.y, savedCoords.z, false, false, false, false)
            savedCoords = nil
        end

        SetEntityVisible(admin, true)
        SetEntityCanBeDamaged(admin, true)
        SetEntityInvincible(admin, false)
        SetEntityCollision(admin, true, true)

        DoScreenFadeIn(500)
        isSpectating = false
        targetServerId = nil
        WestRP.Client.UI.ShowToast("MODO ESPECTADOR", "Modo espectador encerrado", "info")
    end
end

---Retorna se o operador está espectando no momento
---@return boolean
function WestRP.Admin.Spectate.IsSpectating()
    return isSpectating
end

--------------------------------------------------------------------------------
-- NETEVENTS DO SERVIDOR
--------------------------------------------------------------------------------
RegisterNetEvent("westrp_admin:client:spectatePlayer", function(tId, tCoords)
    WestRP.Admin.Spectate.Toggle(tId, tCoords)
end)

AddEventHandler("onResourceStop", function(resName)
    if resName ~= GetCurrentResourceName() then return end
    if isSpectating then
        local admin = PlayerPedId()
        RenderScriptCams(false, false, 0, true, true, 0)
        if spectateCam then
            DestroyCam(spectateCam, true)
        end
        DestroyAllCams(true)
        if savedCoords then
            SetEntityCoords(admin, savedCoords.x, savedCoords.y, savedCoords.z, false, false, false, false)
        end
        SetEntityVisible(admin, true)
        SetEntityCanBeDamaged(admin, true)
        SetEntityInvincible(admin, false)
        SetEntityCollision(admin, true, true)
    end
end)
