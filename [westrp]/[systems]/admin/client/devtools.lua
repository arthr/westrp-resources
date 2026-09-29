WestRP = WestRP or {}
WestRP.Admin = WestRP.Admin or {}
WestRP.Admin.DevTools = {}

local laserActive = false
local lastHit = { coords = nil, entity = nil }

-- Dicionários hash -> nome para peds e props
local PedNamesByHash = {}
local PropNamesByHash = {}

local function InitializeHashDictionaries()
    if Peds then
        for _, model in ipairs(Peds) do
            PedNamesByHash[GetHashKey(string.lower(model))] = model
        end
    end
    if Props then
        for _, model in ipairs(Props) do
            PropNamesByHash[GetHashKey(string.lower(model))] = model
        end
    end
end

CreateThread(function()
    InitializeHashDictionaries()
end)



--------------------------------------------------------------------------------
-- UTILITÁRIOS DE RENDERIZAÇÃO & CÓPIA
--------------------------------------------------------------------------------
local function DrawText2D(txt, x, y, scale, r, g, b, a)
    local str = CreateVarString(10, "LITERAL_STRING", txt)
    SetTextFontForCurrentCommand(0)
    SetTextScale(scale, scale)
    SetTextColor(r or 255, g or 255, b or 255, a or 255)
    SetTextCentre(true)
    DisplayText(str, x, y)
end

local function RotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local cosx = math.cos(x)
    return vector3(-math.sin(z) * cosx, math.cos(z) * cosx, math.sin(x))
end

local function GetEyesOrigin(ped)
    return GetPedBoneCoords(ped, 21030, 0.0, 0.05, 0.02) -- SKEL_Head
end

---Copia uma string para a área de transferência usando o bridge NUI
---@param text string
function WestRP.Admin.DevTools.CopyToClipboard(text)
    if not text then return end
    SendNUIMessage({
        action = "copyToClipboard",
        text = tostring(text),
        string = tostring(text)
    })
    WestRP.Client.UI.ShowToast("CLIPBOARD", "Copiado para a área de transferência", "success")
end

--------------------------------------------------------------------------------
-- DEV LASER RAYCAST
--------------------------------------------------------------------------------
---Alterna o estado do Dev Laser
---@return boolean novoEstado
function WestRP.Admin.DevTools.ToggleLaser()
    laserActive = not laserActive

    if laserActive then
        WestRP.Client.UI.ShowToast("DEV LASER", "Inspecionador de entidades ativado", "success")
        WestRP.Client.TickManager.RegisterTick("admin_devlaser", function()
            local ped   = PlayerPedId()
            local start = GetEyesOrigin(ped)
            local dir   = RotationToDirection(GetGameplayCamRot(2))
            local dest  = start + (dir * 60.0)

            -- Linha de mira laser
            DrawLine(start.x, start.y, start.z, dest.x, dest.y, dest.z, 220, 40, 40, 255)

            -- Shape Test Raycast
            local ray = StartShapeTestRay(start.x, start.y, start.z, dest.x, dest.y, dest.z, -1, ped, 0)
            local _, hit, endCoords, _, entityHit = GetShapeTestResult(ray)

            local info = string.format("Coords: %.2f, %.2f, %.2f", endCoords.x, endCoords.y, endCoords.z)
            lastHit.coords = endCoords
            lastHit.entity = nil

            if hit == 1 and entityHit ~= 0 and DoesEntityExist(entityHit) then
                lastHit.entity  = entityHit
                local model     = GetEntityModel(entityHit)
                local modelName = PedNamesByHash[model] or PropNamesByHash[model] or "Desconhecido"
                local ec        = GetEntityCoords(entityHit)
                local heading   = GetEntityHeading(entityHit)
                local rot       = GetEntityRotation(entityHit)

                info = string.format(
                    "Coords: %.2f, %.2f, %.2f\nModel Hash: %s\nModel Name: %s\nHeading: %.2f\nRotation: %.2f, %.2f, %.2f",
                    ec.x, ec.y, ec.z, tostring(model), modelName, heading, rot.x, rot.y, rot.z
                )

                -- Cubo delimitador no impacto
                DrawBox(
                    endCoords.x - 0.04, endCoords.y - 0.04, endCoords.z - 0.04,
                    endCoords.x + 0.04, endCoords.y + 0.04, endCoords.z + 0.04,
                    255, 50, 50, 180
                )
            end

            -- HUD Text na tela
            DrawText2D(info, 0.5, 0.80, 0.38, 255, 255, 255, 240)
            DrawText2D("[H] Copiar Info Completa  |  [G] Copiar Vector3  |  [DEL] Excluir Objeto", 0.5, 0.92, 0.34, 212, 175, 55, 240)

            -- Atalhos de teclado
            if IsControlJustPressed(0, 0x24978A28) and lastHit.entity then -- H
                WestRP.Admin.DevTools.CopyToClipboard(info)
            end

            if IsControlJustPressed(0, 0x760A9C6F) and lastHit.coords then -- G
                local c = lastHit.coords
                WestRP.Admin.DevTools.CopyToClipboard(string.format("vector3(%.2f, %.2f, %.2f)", c.x, c.y, c.z))
            end

            if IsControlJustPressed(0, 0x4AF4D473) and lastHit.entity then -- Delete
                local ent = lastHit.entity
                if DoesEntityExist(ent) and not IsPedAPlayer(ent) then
                    SetEntityAsMissionEntity(ent, true, true)
                    DeleteEntity(ent)
                    WestRP.Client.UI.ShowToast("DEV", "Entidade excluída do cenário", "info")
                end
            end
        end)
    else
        WestRP.Client.TickManager.UnregisterTick("admin_devlaser")
        lastHit = { coords = nil, entity = nil }
        WestRP.Client.UI.ShowToast("DEV LASER", "Inspecionador desativado", "info")
    end

    return laserActive
end

---Retorna se o laser de desenvolvedor está ativo
---@return boolean
function WestRP.Admin.DevTools.IsLaserActive()
    return laserActive
end

--------------------------------------------------------------------------------
-- CÓPIA DE VETORES & INFORMAÇÕES
--------------------------------------------------------------------------------
---Copia coordenadas formatadas conforme o tipo solicitado
---@param type 'v3'|'v4'|'heading'|'interior'
function WestRP.Admin.DevTools.CopyCoords(type)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    if type == "v3" then
        local str = string.format("vector3(%.2f, %.2f, %.2f)", coords.x, coords.y, coords.z)
        WestRP.Admin.DevTools.CopyToClipboard(str)
    elseif type == "v4" then
        local str = string.format("vector4(%.2f, %.2f, %.2f, %.2f)", coords.x, coords.y, coords.z, heading)
        WestRP.Admin.DevTools.CopyToClipboard(str)
    elseif type == "heading" then
        local str = string.format("%.2f", heading)
        WestRP.Admin.DevTools.CopyToClipboard(str)
    elseif type == "interior" then
        local interiorId = GetInteriorFromEntity(ped)
        WestRP.Admin.DevTools.CopyToClipboard(tostring(interiorId))
        WestRP.Client.UI.ShowToast("INTERIOR", "ID do Interior: " .. tostring(interiorId), "info")
    end
end

--------------------------------------------------------------------------------
-- EXCLUSÃO DE OBJETOS & VEÍCULOS NO RAIO
--------------------------------------------------------------------------------
function WestRP.Admin.DevTools.DeleteClosestObject()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local objects = GetGamePool('CObject')
    local closestObj = nil
    local closestDist = 5.0

    for i = 1, #objects do
        local obj = objects[i]
        if DoesEntityExist(obj) and not IsPedAPlayer(obj) then
            local dist = #(GetEntityCoords(obj) - coords)
            if dist < closestDist then
                closestDist = dist
                closestObj = obj
            end
        end
    end

    if closestObj and DoesEntityExist(closestObj) then
        SetEntityAsMissionEntity(closestObj, true, true)
        DeleteEntity(closestObj)
        WestRP.Client.UI.ShowToast("OBJETO", "Objeto próximo excluído com sucesso", "success")
    else
        WestRP.Client.UI.ShowToast("OBJETO", "Nenhum objeto encontrado no raio de 5 metros", "info")
    end
end

--------------------------------------------------------------------------------
-- VISUALIZADORES DE MUNDO (SHOW NAMES & SHOW BLIPS)
--------------------------------------------------------------------------------
local showNamesActive = false

---Alterna a exibição de nomes e IDs 3D sobre jogadores
---@return boolean
function WestRP.Admin.DevTools.TogglePlayerNames()
    showNamesActive = not showNamesActive
    if showNamesActive then
        WestRP.Client.TickManager.RegisterTick("admin_show_names", function()
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            local activePlayers = GetActivePlayers()

            for i = 1, #activePlayers do
                local playerIdx = activePlayers[i]
                local targetPed = GetPlayerPed(playerIdx)

                if DoesEntityExist(targetPed) then
                    local targetCoords = GetEntityCoords(targetPed)
                    local dist = #(myCoords - targetCoords)

                    if dist <= 120.0 then
                        local headCoords = GetPedBoneCoords(targetPed, 12844, 0.0, 0.0, 0.35)
                        local sId = GetPlayerServerId(playerIdx)
                        local pName = GetPlayerName(playerIdx)
                        local hp = GetEntityHealth(targetPed)
                        local maxHp = GetEntityMaxHealth(targetPed)
                        local tagText = string.format("[%s] %s | %d/%d HP", sId, pName, hp, maxHp)

                        local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(headCoords.x, headCoords.y, headCoords.z)
                        if onScreen then
                            local scale = math.max(0.24, 0.38 - (dist / 400.0))
                            DrawText2D(tagText, screenX, screenY, scale, 212, 175, 55, 240)
                        end
                    end
                end
            end
        end)
        WestRP.Client.UI.ShowToast("SHOW NAMES", "ESP de Nomes e IDs Ativado", "success")
    else
        WestRP.Client.TickManager.UnregisterTick("admin_show_names")
        WestRP.Client.UI.ShowToast("SHOW NAMES", "ESP de Nomes Desativado", "info")
    end
    return showNamesActive
end

function WestRP.Admin.DevTools.IsShowNamesActive()
    return showNamesActive
end

local showBlipsActive = false
local playerBlips = {}

---Alterna a exibição de blips de jogadores no radar
---@return boolean
function WestRP.Admin.DevTools.TogglePlayerBlips()
    showBlipsActive = not showBlipsActive
    if showBlipsActive then
        WestRP.Client.TickManager.RegisterTick("admin_show_blips", function()
            local activePlayers = GetActivePlayers()
            local currentPeds = {}

            for i = 1, #activePlayers do
                local playerIdx = activePlayers[i]
                local targetPed = GetPlayerPed(playerIdx)

                if DoesEntityExist(targetPed) then
                    currentPeds[targetPed] = true
                    if not playerBlips[targetPed] or not DoesBlipExist(playerBlips[targetPed]) then
                        local blip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1230993421, targetPed)
                        if blip and blip ~= 0 then
                            SetBlipScale(blip, 0.8)
                            local sId = GetPlayerServerId(playerIdx)
                            local pName = GetPlayerName(playerIdx)
                            Citizen.InvokeNative(0x9CB1A1623062F402, blip, string.format("[%s] %s", sId, pName))
                            playerBlips[targetPed] = blip
                        end
                    end
                end
            end

            -- Remove blips de entidades desconectadas
            for ped, blip in pairs(playerBlips) do
                if not currentPeds[ped] or not DoesEntityExist(ped) then
                    if DoesBlipExist(blip) then
                        RemoveBlip(blip)
                    end
                    playerBlips[ped] = nil
                end
            end
        end)
        WestRP.Client.UI.ShowToast("SHOW BLIPS", "Rastreamento de jogadores no radar ativado", "success")
    else
        WestRP.Client.TickManager.UnregisterTick("admin_show_blips")
        for ped, blip in pairs(playerBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        playerBlips = {}
        WestRP.Client.UI.ShowToast("SHOW BLIPS", "Rastreamento de jogadores desativado", "info")
    end
    return showBlipsActive
end

function WestRP.Admin.DevTools.IsShowBlipsActive()
    return showBlipsActive
end

AddEventHandler("onResourceStop", function(resName)
    if resName ~= GetCurrentResourceName() then return end
    if laserActive then
        WestRP.Client.TickManager.UnregisterTick("admin_devlaser")
        laserActive = false
    end
    if showNamesActive then
        WestRP.Client.TickManager.UnregisterTick("admin_show_names")
        showNamesActive = false
    end
    if showBlipsActive then
        WestRP.Client.TickManager.UnregisterTick("admin_show_blips")
        for ped, blip in pairs(playerBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        playerBlips = {}
        showBlipsActive = false
    end
end)
