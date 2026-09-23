------------------------------------------------------------------------------------------------------------
---------------------------------------- TELEPORTS ---------------------------------------------------------
local lastLocation = {}
local autotpm = false
local lastCoords = nil
local T = Translation.Langs[Config.Lang]

--- Returns true when the player is currently in a Guarma area.
local function isPlayerInGuarma()
    local pedCoords = GetEntityCoords(PlayerPedId())
    local area = GetMapZoneAtCoords(pedCoords, 10)
    return Config.GuamarmaCoords.GuarmaAreaHashes[area] == true
end

--- Applies Guarma world state and minimap settings.
local function setGuarmaWorldState(enabled)
    if enabled then
        Citizen.InvokeNative(0x74E2261D2A66849A, true)
        Citizen.InvokeNative(0xE8770EE02AEE45C2, 1)
        Citizen.InvokeNative(0xA657EC9DBC6CC900, 1935063277)
        return
    end

    Citizen.InvokeNative(0x74E2261D2A66849A, false)
    Citizen.InvokeNative(0xE8770EE02AEE45C2, 0)
    Citizen.InvokeNative(0xA657EC9DBC6CC900, -1868977180)
end

--- Teleports the ped after a fade transition.
local function teleportPedToCoords(ped, coords)
    DoScreenFadeOut(500)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    Wait(1000)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    repeat Wait(0) until HasCollisionLoadedAroundEntity(ped)
    Wait(1000)
    DoScreenFadeIn(650)
end

function Teleport()
    MenuData.CloseAll()
    local elements = {
        { label = T.Menus.MainTeleportOptions.tpmAuto,                  value = 'autotpm',     desc = T.Menus.MainTeleportOptions.tpmAuto_desc },
        { label = T.Menus.MainTeleportOptions.tpmToMarker,              value = 'tpm',         desc = T.Menus.MainTeleportOptions.tpmToMarker_desc },
        { label = T.Menus.MainTeleportOptions.tpToCoords,               value = 'tptocoords',  desc = T.Menus.MainTeleportOptions.tpToCoords_desc },
        { label = T.Menus.MainTeleportOptions.tpToPlayer,               value = 'tptoplayer',  desc = T.Menus.MainTeleportOptions.tpToPlayer_desc },
        { label = T.Menus.MainTeleportOptions.adminGoBackLastLocation,  value = 'admingoback', desc = T.Menus.MainTeleportOptions.adminGoBackLastLocation_desc },
        { label = T.Menus.MainTeleportOptions.bringPlayer,              value = 'bringplayer', desc = T.Menus.MainTeleportOptions.bringPlayer_desc },
        { label = T.Menus.MainTeleportOptions.sendPlayerToLastLocation, value = 'sendback',    desc = T.Menus.MainTeleportOptions.sendPlayerToLastLocation_desc },
        { label = T.Menus.MainTeleportOptions.teleportToGuarma,         value = 'tptoguarma',    desc = T.Menus.MainTeleportOptions.teleportToGuarma_desc },
    }
    MenuData.Open('default', GetCurrentResourceName(), 'Teleport',
        {
            title    = T.Menus.DefaultsMenusTitle.menuTitle,
            subtext  = T.Menus.DefaultsMenusTitle.menuSubTitleTeleport,
            align    = Config.AlignMenu,
            elements = elements,
            lastmenu = 'OpenMenu', -- Go back
        },

        function(data)
            if data.current == "backup" then
                return _G[data.trigger]()
            end

            if data.current.value == "tpm" then
                local coords = GetEntityCoords(PlayerPedId())
                local waypointCoords = GetWaypointCoords()
                local waypoint = IsWaypointActive()
                if not waypoint then
                    return VORP.NotifyObjective("theres no waypoint set", 5000)
                end

                TriggerServerEvent('vorp:teleportWayPoint', "", coords, waypointCoords)
            elseif data.current.value == 'autotpm' then
                if autotpm == false then
                    autotpm = true
                    TriggerEvent('vorp:TipRight', T.Notify.switchedOn, 3000)
                    runAutoTpmWorker()
                else
                    TriggerEvent('vorp:TipRight', T.Notify.switchedOff, 3000)
                    autotpm = false
                end
            elseif data.current.value == "tptocoords" then
                local AdminAllowed = IsAdminAllowed("tp_to_coords")
                if AdminAllowed then
                    local myInput = Inputs("input", T.Menus.DefaultsInputs.confirm,
                        T.Menus.MainTeleportOptions.InsertCoordsInput.placeholder,
                        T.Menus.MainTeleportOptions.InsertCoordsInput.title, "text",
                        T.Menus.MainTeleportOptions.InsertCoordsInput.errorMsg, '.*{5,60}')
                    local oldCoords = GetEntityCoords(PlayerPedId())
                    TriggerEvent("vorpinputs:advancedInput", json.encode(myInput), function(result)
                        local coords = result
                        local admin = PlayerPedId()
                        if coords ~= "" and coords then
                            local finalCoords = {}
                            coords = string.gsub(coords, "(vector[34])", "")
                            coords = string.gsub(coords, "[^%d%. -]", "")

                            for i in string.gmatch(coords, "%S+") do
                                finalCoords[#finalCoords + 1] = i
                            end
                            local x, y, z = tonumber(finalCoords[1]), tonumber(finalCoords[2]), tonumber(finalCoords[3])
                            teleportPedToCoords(admin, { x = x, y = y, z = z })
                            TriggerServerEvent("vorp_admin:tptocoords", oldCoords, x, y, z)
                        else
                            VORP.NotifyObjective(T.Notify.empty, 5000)
                        end
                    end)
                end
            elseif data.current.value == "tptoplayer" then
                TriggerEvent("vorpinputs:getInput", T.Menus.DefaultsInputs.confirm, T.Menus.DefaultsInputs.serverID,
                    function(result)
                        local TargetID = result
                        if TargetID ~= "" then
                            TriggerServerEvent("vorp_admin:TpToPlayer", TargetID)
                        else
                            VORP.NotifyObjective(T.Notify.empty, 5000)
                        end
                    end)
            elseif data.current.value == "admingoback" then
                if lastLocation then
                    TriggerServerEvent("vorp_admin:sendAdminBack")
                end
            elseif data.current.value == "bringplayer" then
                TriggerEvent("vorpinputs:getInput", T.Menus.DefaultsInputs.confirm, T.Menus.DefaultsInputs.serverID,
                    function(result)
                        local TargetID = result
                        if TargetID ~= "" and lastLocation then
                            local adminCoords = GetEntityCoords(PlayerPedId())
                            TriggerServerEvent("vorp_admin:Bring", TargetID, adminCoords, "", nil, TargetID)
                        else
                            VORP.NotifyObjective(T.Notify.empty, 5000)
                        end
                    end)
            elseif data.current.value == "sendback" then
                TriggerEvent("vorpinputs:getInput", T.Menus.DefaultsInputs.confirm, T.Menus.DefaultsInputs.serverID,
                    function(result)
                        local TargetID = result
                        if TargetID ~= "" and lastLocation then
                            TriggerServerEvent("vorp_admin:TeleportPlayerBack", TargetID)
                        else
                            TriggerEvent("vorp:TipRight", T.Notify.goToPlayerFirst, 4000)
                        end
                    end)
            elseif data.current.value == "tptoguarma" then
                local AdminAllowed = IsAdminAllowed("teleport_to_guarma")
                if AdminAllowed then
                    local admin = PlayerPedId()
                    if isPlayerInGuarma() then
                        local returnCoords = lastCoords or Config.GuamarmaCoords.MainLandCoords

                        setGuarmaWorldState(false)
                        teleportPedToCoords(admin, returnCoords)
                        lastCoords = nil
                    else
                        lastCoords = GetEntityCoords(admin)

                        setGuarmaWorldState(true)
                        teleportPedToCoords(admin, Config.GuamarmaCoords.GuarmaCoords)
                    end
                end
            end
        end,

        function(menu)
            menu.close()
        end)
end

function ToggleGuarmaNUI()
    local AdminAllowed = IsAdminAllowed("teleport_to_guarma")
    if AdminAllowed then
        local admin = PlayerPedId()
        if isPlayerInGuarma() then
            local returnCoords = lastCoords or Config.GuamarmaCoords.MainLandCoords
            setGuarmaWorldState(false)
            teleportPedToCoords(admin, returnCoords)
            lastCoords = nil
            VORP.NotifyObjective("Retornando ao continente...", 4000)
        else
            lastCoords = GetEntityCoords(admin)
            setGuarmaWorldState(true)
            teleportPedToCoords(admin, Config.GuamarmaCoords.GuarmaCoords)
            VORP.NotifyObjective("Zarpando para Guarma...", 4000)
        end
    end
end

function TeleportToWaypointNUI()
    local coords = GetEntityCoords(PlayerPedId())
    local waypointCoords = GetWaypointCoords()
    local waypoint = IsWaypointActive()
    if not waypoint then
        return VORP.NotifyObjective("Nenhum marcador definido no mapa!", 5000)
    end
    TriggerServerEvent('vorp:teleportWayPoint', "", coords, waypointCoords)
end

local autoTpmRunning = false

local function runAutoTpmWorker()
    if autoTpmRunning then return end
    autoTpmRunning = true
    CreateThread(function()
        while autotpm do
            Wait(2000)
            if autotpm and IsWaypointActive() then
                TriggerServerEvent('vorp:teleportWayPoint')
            end
        end
        autoTpmRunning = false
    end)
end

function ToggleAutoTpmNUI()
    if autotpm == false then
        autotpm = true
        VORP.NotifyObjective(T.Notify.switchedOn, 3000)
        runAutoTpmWorker()
    else
        VORP.NotifyObjective(T.Notify.switchedOff, 3000)
        autotpm = false
    end
    return autotpm
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    autotpm = false
end)

function TeleportToCoordsNUI(coordsInput)
    local AdminAllowed = IsAdminAllowed("tp_to_coords")
    if not AdminAllowed then return end
    if not coordsInput or coordsInput == "" then return end

    local oldCoords = GetEntityCoords(PlayerPedId())
    local clean = string.gsub(coordsInput, "(vector[34])", "")
    clean = string.gsub(clean, "[^%d%. -]", "")
    local finalCoords = {}
    for i in string.gmatch(clean, "%S+") do
        finalCoords[#finalCoords + 1] = i
    end

    if #finalCoords >= 3 then
        local x, y, z = tonumber(finalCoords[1]), tonumber(finalCoords[2]), tonumber(finalCoords[3])
        if x and y and z then
            teleportPedToCoords(PlayerPedId(), { x = x, y = y, z = z })
            TriggerServerEvent("vorp_admin:tptocoords", oldCoords, x, y, z)
            VORP.NotifyObjective("Teleportado para coordenadas!", 3000)
        end
    end
end
