WestRP = WestRP or {}
WestRP.Admin = WestRP.Admin or {}
WestRP.Admin.Teleport = {}

local lastCoords = nil
local lastGuarmaCoords = nil
local autoTpmActive = false

--------------------------------------------------------------------------------
-- NATIVAS DE GUARMA & TELEPORTE SEGURO
--------------------------------------------------------------------------------
local function IsPlayerInGuarma()
    local pedCoords = GetEntityCoords(PlayerPedId())
    local area = GetMapZoneAtCoords(pedCoords, 10)
    return Config.Guarma.AreaHashes[area] == true
end

local function SetGuarmaWorldState(enabled)
    if enabled then
        Citizen.InvokeNative(0x74E2261D2A66849A, true)
        Citizen.InvokeNative(0xE8770EE02AEE45C2, 1)
        Citizen.InvokeNative(0xA657EC9DBC6CC900, 1935063277)
    else
        Citizen.InvokeNative(0x74E2261D2A66849A, false)
        Citizen.InvokeNative(0xE8770EE02AEE45C2, 0)
        Citizen.InvokeNative(0xA657EC9DBC6CC900, -1868977180)
    end
end

---Executa teleporte seguro com transição de tela e carregamento de colisão
---@param coords vector3|table
---@param heading? number
function WestRP.Admin.Teleport.SafeTeleport(coords, heading)
    if not coords then return end
    local ped = PlayerPedId()

    -- Salva última localização para possibilidade de retorno
    lastCoords = GetEntityCoords(ped)

    DoScreenFadeOut(400)
    repeat Wait(0) until not IsScreenFadingOut()

    local targetX = coords.x or coords[1]
    local targetY = coords.y or coords[2]
    local targetZ = coords.z or coords[3]

    RequestCollisionAtCoord(targetX, targetY, targetZ)
    SetEntityCoords(ped, targetX, targetY, targetZ, false, false, false, false)

    if heading then
        SetEntityHeading(ped, heading)
    end

    local timeout = 0
    while not HasCollisionLoadedAroundEntity(ped) and timeout < 50 do
        Wait(50)
        timeout = timeout + 1
    end

    Wait(300)
    DoScreenFadeIn(600)
end

--------------------------------------------------------------------------------
-- TELEPORTE PARA MARCADOR (TPM & AUTO-TPM)
--------------------------------------------------------------------------------
function WestRP.Admin.Teleport.TeleportToWaypoint()
    if not IsWaypointActive() then
        WestRP.Client.UI.ShowToast("TELEPORTE", "Nenhum marcador ativo encontrado no mapa", "danger")
        return false
    end

    local waypointCoords = GetWaypointCoords()
    local ped = PlayerPedId()
    local currentCoords = GetEntityCoords(ped)

    -- Busca altitude inicial acima do solo
    local zCoord = 0.0
    local groundFound = false

    -- Testa alturas decrescentes para achar solo sólido
    for height = 100.0, 900.0, 50.0 do
        SetEntityCoords(ped, waypointCoords.x, waypointCoords.y, height, false, false, false, false)
        Wait(20)
        groundFound, zCoord = GetGroundZFor_3dCoord(waypointCoords.x, waypointCoords.y, height, false)
        if groundFound then
            break
        end
    end

    local finalZ = groundFound and (zCoord + 1.0) or (waypointCoords.z or 100.0)
    WestRP.Admin.Teleport.SafeTeleport(vector3(waypointCoords.x, waypointCoords.y, finalZ))

    WestRP.Client.UI.ShowToast("TELEPORTE", "Teleportado para o marcador do mapa", "success")
    TriggerServerEvent("westrp_admin:server:logTeleport", "TPM", currentCoords, vector3(waypointCoords.x, waypointCoords.y, finalZ))
    return true
end

function WestRP.Admin.Teleport.ToggleAutoTPM()
    autoTpmActive = not autoTpmActive

    if autoTpmActive then
        WestRP.Client.UI.ShowToast("AUTO-TPM", "Auto teleporte ao marcar o mapa ativado", "success")
        CreateThread(function()
            local lastWaypoint = nil
            while autoTpmActive do
                Wait(1000)
                if autoTpmActive and IsWaypointActive() then
                    local wp = GetWaypointCoords()
                    if not lastWaypoint or #(wp - lastWaypoint) > 5.0 then
                        lastWaypoint = wp
                        WestRP.Admin.Teleport.TeleportToWaypoint()
                    end
                else
                    lastWaypoint = nil
                end
            end
        end)
    else
        WestRP.Client.UI.ShowToast("AUTO-TPM", "Auto teleporte desativado", "info")
    end

    return autoTpmActive
end

---Retorna o estado atual do Auto-TPM
---@return boolean
function WestRP.Admin.Teleport.GetAutoTPMState()
    return autoTpmActive
end

--------------------------------------------------------------------------------
-- RETORNO & TELEPORTE PARA COORDENADAS
--------------------------------------------------------------------------------
function WestRP.Admin.Teleport.GoBack()
    if not lastCoords then
        WestRP.Client.UI.ShowToast("TELEPORTE", "Nenhuma coordenada anterior registrada para retornar", "danger")
        return false
    end

    local target = lastCoords
    lastCoords = nil
    WestRP.Admin.Teleport.SafeTeleport(target)
    WestRP.Client.UI.ShowToast("TELEPORTE", "Retornado à coordenada de origem", "success")
    return true
end

function WestRP.Admin.Teleport.TeleportToCoords(coordsInput)
    if not coordsInput or coordsInput == "" then return end

    local clean = string.gsub(coordsInput, "(vector[34])", "")
    clean = string.gsub(clean, "[^%d%. %-]", "")
    local parts = {}
    for i in string.gmatch(clean, "%S+") do
        parts[#parts + 1] = tonumber(i)
    end

    if #parts >= 3 and parts[1] and parts[2] and parts[3] then
        local target = vector3(parts[1], parts[2], parts[3])
        local heading = parts[4]
        WestRP.Admin.Teleport.SafeTeleport(target, heading)
        WestRP.Client.UI.ShowToast("TELEPORTE", string.format("Teleportado para: %.2f, %.2f, %.2f", target.x, target.y, target.z), "success")
        return true
    end

    WestRP.Client.UI.ShowToast("TELEPORTE", "Coordenadas fornecidas são inválidas", "danger")
    return false
end

--------------------------------------------------------------------------------
-- EXPEDIÇÃO PARA GUARMA / RETORNO
--------------------------------------------------------------------------------
function WestRP.Admin.Teleport.ToggleGuarma()
    local ped = PlayerPedId()
    local inGuarma = IsPlayerInGuarma()

    if inGuarma then
        local returnPos = lastGuarmaCoords or Config.Guarma.MainLandCoords
        SetGuarmaWorldState(false)
        WestRP.Admin.Teleport.SafeTeleport(returnPos)
        lastGuarmaCoords = nil
        WestRP.Client.UI.ShowToast("GUARMA", "Retornado com sucesso ao continente", "info")
    else
        lastGuarmaCoords = GetEntityCoords(ped)
        SetGuarmaWorldState(true)
        WestRP.Admin.Teleport.SafeTeleport(Config.Guarma.Coords)
        WestRP.Client.UI.ShowToast("GUARMA", "Zarpando em direção à ilha de Guarma", "success")
    end
end

--------------------------------------------------------------------------------
-- NETEVENTS DO SERVIDOR
--------------------------------------------------------------------------------
RegisterNetEvent("westrp_admin:client:teleportToCoords", function(coords)
    WestRP.Admin.Teleport.SafeTeleport(coords)
end)

RegisterNetEvent("westrp_admin:client:bringPlayer", function(adminCoords)
    WestRP.Admin.Teleport.SafeTeleport(adminCoords)
    WestRP.Client.UI.ShowToast("STAFF", "Você foi puxado por um administrador", "info")
end)

AddEventHandler("onResourceStop", function(resName)
    if resName ~= GetCurrentResourceName() then return end
    autoTpmActive = false
end)
