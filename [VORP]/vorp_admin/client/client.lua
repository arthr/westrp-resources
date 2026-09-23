local Key = Config.Key
local CanOpen = Config.CanOpenMenuWhenDead
local Inmenu
local spectating = false
local Camera = nil
local lastcoords = { x = 0, y = 0, z = 0 }
local T = Translation.Langs[Config.Lang]
MenuData = exports.vorp_menu:GetMenuData()
VORP = exports.vorp_core:GetCore()


AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    local player = PlayerPedId()
    ClearPedTasksImmediately(player, true, true)
    Closem()
    SetNuiFocus(false, false)
    AdminAllowed = false

    -- Graceful cleanup if resource stopped mid-spectate
    if spectating then
        RenderScriptCams(false, false, 0, true, true, 0)
        if Camera then
            DestroyCam(Camera, true)
            Camera = nil
        end
        DestroyAllCams(true)
        if lastcoords and lastcoords.x and lastcoords.x ~= 0 then
            SetEntityCoords(player, lastcoords.x, lastcoords.y, lastcoords.z, false, false, false, false)
        end
        SetEntityVisible(player, true)
        SetEntityCanBeDamaged(player, true)
        SetEntityInvincible(player, false)
        spectating = false
    end
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    Wait(200)
    TriggerServerEvent("vorp_admin:getStaffInfo")
end)

local function CanOpenUsersMenu()
    if Config.UseUsersMenu then
        TriggerServerEvent("vorp_admin:GetGroup")
        OpenUsersMenu()
    end
end

local function OpenCustomAdminNUI()
    local boosters = (type(GetBoosterStates) == "function") and GetBoosterStates() or {}
    local staffRole = "Staff"
    if LocalPlayer.state and LocalPlayer.state.Character and LocalPlayer.state.Character.Group then
        staffRole = tostring(LocalPlayer.state.Character.Group)
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
        players = {},
        boosters = boosters,
        staffRole = staffRole
    })

    VORP.Callback.TriggerAsync("vorp_admin:Callback:getplayersinfo", function(cb)
        local raw = cb or {}
        local cleanList = {}
        for _, p in pairs(raw) do
            if type(p) == "table" and p.serverId then
                cleanList[#cleanList + 1] = p
            end
        end
        table.sort(cleanList, function(a, b)
            return (tonumber(a.serverId) or 0) < (tonumber(b.serverId) or 0)
        end)
        SendNUIMessage({
            action = "updatePlayers",
            players = cleanList
        })
    end, { search = "all" })
end

local function OpenAdminMenu()
    local AdminAllowed = IsAdminAllowed("open_menu")
    if AdminAllowed then
        if Config.UseCustomNUI then
            OpenCustomAdminNUI()
            return true
        end
        OpenMenu()
        return true
    end
    return false
end


CreateThread(function()
    repeat Wait(3000) until LocalPlayer.state.IsInSession

    if Config.useAdminCommand then
        TriggerEvent('chat:addSuggestion', '/' .. Config.commandAdmin, 'Open admin menu or use pagedown', { {} })
        RegisterCommand(Config.commandAdmin, function()
            OpenAdminMenu()
        end, false)
    end

    -- 0ms idle loop: only checks IsControlJustPressed per frame, no redundant ped/dead native checks when idle
    while true do
        Wait(0)
        if IsControlJustPressed(0, Key) and not Inmenu then
            local canOpenNow = CanOpen
            if not canOpenNow then
                canOpenNow = not IsPedDeadOrDying(PlayerPedId(), false)
            end
            if canOpenNow then
                if not OpenAdminMenu() then
                    CanOpenUsersMenu()
                end
            end
        end
    end
end)

----- EVENTS
RegisterNetEvent("vorp_admin:Freezeplayer", function(state)
    FreezeEntityPosition(PlayerPedId(), state)
end)

RegisterNetEvent("vorp_admin:respawn", function()
    Wait(50)
    DoScreenFadeOut(1000)
    repeat Wait(0) until not IsScreenFadingOut()
    FreezeEntityPosition(PlayerPedId(), true)
    Wait(1000)
    DoScreenFadeIn(4000)
    repeat Wait(0) until not IsScreenFadingIn()
    FreezeEntityPosition(PlayerPedId(), false)
    TriggerEvent('vorp:ShowBottomRight', T.Notify.reviseRules, 10000)
end)


RegisterNetEvent("vorp_admin:spectatePlayer", function(target, targetCoords)
    local admin = PlayerPedId()
    local ped = 0
    if not spectating then
        DoScreenFadeOut(2000)
        repeat Wait(0) until not IsScreenFadingOut()
        lastcoords = GetEntityCoords(admin)
        SetEntityVisible(admin, false)
        SetEntityCanBeDamaged(admin, false)
        SetEntityInvincible(admin, true)
        SetEntityCoords(admin, targetCoords.x + 15, targetCoords.y + 15, targetCoords.z, false, false, false, false)
        Wait(500)
        ped = GetPlayersClient(target)
        Wait(500)
        Camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        AttachCamToEntity(Camera, ped, 0.0, -2.0, 1.0, false)
        SetCamActive(Camera, true)
        RenderScriptCams(true, true, 1, true, true, 0)
        DoScreenFadeIn(2000)
        repeat Wait(0) until IsScreenFadingIn()
        spectating = true
    else
        DoScreenFadeOut(2000)
        repeat Wait(0) until not IsScreenFadingOut()
        RenderScriptCams(true, false, 1, true, true, 0)
        DestroyCam(Camera, true)
        DestroyAllCams(true)
        SetEntityCoords(admin, lastcoords.x, lastcoords.y, lastcoords.z - 1, false, false, false, false)
        SetEntityVisible(admin, true)
        SetEntityCanBeDamaged(admin, false)
        SetEntityInvincible(admin, true)
        DoScreenFadeIn(2000)
        repeat Wait(0) until IsScreenFadingIn()
        spectating = false
    end
end)
local lastLocation = nil
------------------------- TELEPORT  EVENTS FROM SERVER  -------------------------------
RegisterNetEvent("vorp_admin:gotoPlayer", function(targetCoords)
    lastLocation = GetEntityCoords(PlayerPedId())
    SetEntityCoords(PlayerPedId(), targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
end)

RegisterNetEvent("vorp_admin:sendAdminBack", function()
    if lastLocation then
        SetEntityCoords(PlayerPedId(), lastLocation.x, lastLocation.y, lastLocation.z, false, false, false, false)
        lastLocation = nil
    end
end)

RegisterNetEvent("vorp_admin:Bring", function(adminCoords)
    lastLocation = GetEntityCoords(PlayerPedId())
    SetEntityCoords(PlayerPedId(), adminCoords.x, adminCoords.y, adminCoords.z, false, false, false, false)
end)

RegisterNetEvent("vorp_admin:TeleportPlayerBack", function()
    if lastLocation then
        SetEntityCoords(PlayerPedId(), lastLocation.x, lastLocation.y, lastLocation.z, false, false, false, false)
        lastLocation = nil
    end
end)
-----------------------------------------------------------------------------

-- Show items inventory
RegisterNetEvent("vorp_admin:getplayerInventory", function(inventorydata)
    OpenInventory(inventorydata)
end)

-------------------------- Troll Actions Events ------------------------------
RegisterNetEvent('vorp_admin:ClientTrollKillPlayerHandler', function()
    SetEntityHealth(PlayerPedId(), 0, 0)
end)

RegisterNetEvent('vorp_admin:ClientTrollInvisbleHandler', function()
    local player = PlayerPedId()
    if IsEntityVisible(player) then
        SetEntityVisible(player, false)
    else
        SetEntityVisible(player, true)
    end
end)

RegisterNetEvent('vorp_admin:ClientTrollLightningStrikePlayerHandler', function(coords)
    ForceLightningFlashAtCoords(coords.x, coords.y, coords.z, -1.0)
end)

RegisterNetEvent('vorp_admin:ClientTrollSetPlayerOnFireHandler', function()
    local model = 'p_campfire02xb'
    if not HasModelLoaded(model) then
        RequestModel(model, false)
        repeat Wait(0) until HasModelLoaded(model)
    end
    local object = CreateObject(joaat(model), 0, 0, 0, false, false, false)
    repeat Wait(0) until DoesEntityExist(object)
    AttachEntityToEntity(object, PlayerPedId(), 41, 1000, 1000, 10000, 0, 0, 0, false, false, true, false, 1000, false, false, false)
    Wait(5000)
    DeleteObject(object)
end)

RegisterNetEvent('vorp_admin:ClientTrollTPToHeavenHandler', function()
    local pl = GetEntityCoords(PlayerPedId())
    SetEntityCoords(PlayerPedId(), pl.x, pl.y, pl.z + 200, false, false, false, false)
end)

RegisterNetEvent('vorp_admin:ClientTrollRagdollPlayerHandler', function()
    SetPedToRagdoll(PlayerPedId(), 5000, 5000, 0, false, false, false)
end)

RegisterNetEvent('vorp_admin:ClientDrainPlayerStamHandler', function()
    Citizen.InvokeNative(0xC3D4B754C0E86B9E, PlayerPedId(), -1000.0)
end)

RegisterNetEvent('vorp_admin:ClientHandcuffPlayerHandler', function()
    local player = PlayerPedId()
    if not IsPedCuffed(player) then
        SetEnableHandcuffs(player, true, false)
    else
        SetEnableHandcuffs(player, false, false)
    end
end)

RegisterNetEvent('vorp_admin:ClientTempHighPlayerHandler', function()
    AnimpostfxPlay('MP_BountyLagrasSwamp')
    Wait(15000)
    AnimpostfxStop('MP_BountyLagrasSwamp')
end)

-----------------------------------------------------------------------------
-- NUI CALLBACKS (FRONTIER GAZETTE 1899)
-----------------------------------------------------------------------------

RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('triggerAction', function(data, cb)
    if not data or not data.actionType or not data.targetId then
        return cb('error')
    end

    local ok, err = pcall(function()
        local action = tostring(data.actionType)
        local targetId = tonumber(data.targetId)
        if not targetId then return end
        local targetName = tostring(data.targetName or "Player")

        if action == "goto" then
            TriggerServerEvent("vorp_admin:TpToPlayer", targetId, nil, targetName)
        elseif action == "bring" then
            local adminCoords = GetEntityCoords(PlayerPedId())
            TriggerServerEvent("vorp_admin:Bring", targetId, adminCoords, targetName, nil, targetId)
        elseif action == "heal" then
            TriggerServerEvent("vorp_admin:heal", targetId, nil, targetName)
        elseif action == "revive" then
            TriggerServerEvent("vorp_admin:revive", targetId, nil, targetName)
        elseif action == "freeze" then
            TriggerServerEvent("vorp_admin:FreezePlayer", targetId, targetName)
        elseif action == "spectate" then
            TriggerServerEvent("vorp_admin:spectate", targetId, nil, targetName)
        elseif action == "sendback" then
            TriggerServerEvent("vorp_admin:TeleportPlayerBack", targetId)
        elseif action == "respawn" then
            TriggerServerEvent("vorp_admin:respawnPlayer", targetId, targetName)
        elseif action == "kick" then
            TriggerServerEvent("vorp_admin:kick", targetId, tostring(data.reason or "Kick by admin"), targetName)
        elseif action == "ban" then
            TriggerServerEvent("vorp_admin:ban", targetId, tonumber(data.time) or 0, tostring(data.reason or "Ban by admin"), targetName)
        elseif action == "setJob" then
            TriggerServerEvent("vorp_admin:setJob", targetId, tostring(data.job or "unemployed"), tonumber(data.grade) or 0, tostring(data.jobLabel or data.job), data.staticId, targetName)
        elseif action == "setGroup" then
            TriggerServerEvent("vorp_admin:setGroup", targetId, tostring(data.group or "user"), data.staticId, targetName)
        elseif action == "whitelist" then
            TriggerServerEvent("vorp_admin:Whitelist", targetId, tostring(data.steam or ""), nil, data.staticId, targetName)
        -- Trolls
        elseif action == "troll_lightning" then
            TriggerServerEvent('vorp_admin:ServerTrollLightningStrikePlayerHandler', targetId)
        elseif action == "troll_fire" then
            TriggerServerEvent('vorp_admin:ServerTrollSetPlayerOnFireHandler', targetId)
        elseif action == "troll_heaven" then
            TriggerServerEvent('vorp_admin:ServerTrollTpToHeavenHandler', targetId)
        elseif action == "troll_handcuff" then
            TriggerServerEvent('vorp_admin:ServerTrollHandcuffPlayerHandler', targetId)
        elseif action == "troll_ragdoll" then
            TriggerServerEvent('vorp_admin:ServerTrollRagdollPlayerHandler', targetId)
        elseif action == "troll_stam" then
            TriggerServerEvent('vorp_admin:ServerTrollDrainPlayerStamHandler', targetId)
        end
    end)

    if not ok then
        print("^1[vorp_admin] Error in triggerAction: " .. tostring(err) .. "^7")
        return cb('error')
    end
    cb('ok')
end)

RegisterNUICallback('toggleBooster', function(data, cb)
    if not data or not data.booster then return cb('error') end
    
    local ok, err = pcall(function()
        local booster = tostring(data.booster)
        if booster == "godmode" then
            if type(GODmode) == "function" then GODmode() end
        elseif booster == "noclip" then
            if type(ToggleNoclipNUI) == "function" then ToggleNoclipNUI() end
        elseif booster == "goldencores" then
            if type(GoldenCores) == "function" then GoldenCores() end
        elseif booster == "infiammo" then
            if type(InfiAmmo) == "function" then InfiAmmo() end
        elseif booster == "invis" then
            if type(ToggleInvisNUI) == "function" then ToggleInvisNUI() end
        elseif booster == "selfheal" then
            TriggerServerEvent('vorp_admin:HealSelf', "selfheal")
            if Config.Heal and Config.Heal.Players then Config.Heal.Players() end
        elseif booster == "selfrevive" then
            TriggerServerEvent('vorp_admin:ReviveSelf', "selfrevive")
        elseif booster == "spawnhorse" then
            if type(SpawnHorse) == "function" then SpawnHorse("A_C_Horse_AmericanPaint_Overo") end
        end
    end)

    if not ok then
        print("^1[vorp_admin] Error in toggleBooster: " .. tostring(err) .. "^7")
        return cb('error')
    end
    cb('ok')
end)

RegisterNUICallback('databaseAction', function(data, cb)
    if not data or not data.type or not data.targetId then return cb('error') end

    local ok, err = pcall(function()
        local tId = tonumber(data.targetId)
        if not tId then return end
        local tName = tostring(data.targetName or "Player")

        if data.type == "giveCurrency" then
            TriggerServerEvent("vorp_admin:giveMoneyGold", tId, tonumber(data.currencyType) or 0, tonumber(data.amount) or 0, tName)
        elseif data.type == "giveItem" then
            TriggerServerEvent("vorp_admin:giveItem", tId, tostring(data.item or ""), tonumber(data.qty) or 1, tName)
        elseif data.type == "giveWeapon" then
            TriggerServerEvent("vorp_admin:giveWeapon", tId, tostring(data.weapon or ""), tName)
        elseif data.type == "giveMount" then
            if data.mountType == "horse" then
                TriggerServerEvent("vorp_admin:giveHorse", tId, tostring(data.model or ""), tName)
            else
                TriggerServerEvent("vorp_admin:giveWagon", tId, tostring(data.model or ""), tName)
            end
        elseif data.type == "clearInventory" then
            TriggerServerEvent("vorp_admin:clearInventory", tId, tName)
        elseif data.type == "clearCurrency" then
            TriggerServerEvent("vorp_admin:clearCurrency", tId, tostring(data.currencyType or "0"), tName)
        end
    end)

    if not ok then
        print("^1[vorp_admin] Error in databaseAction: " .. tostring(err) .. "^7")
        return cb('error')
    end
    cb('ok')
end)

RegisterNUICallback('teleportAction', function(data, cb)
    if not data or not data.type then return cb('error') end

    local ok, err = pcall(function()
        if data.type == "tpm" then
            if type(TeleportToWaypointNUI) == "function" then TeleportToWaypointNUI() end
        elseif data.type == "autotpm" then
            if type(ToggleAutoTpmNUI) == "function" then ToggleAutoTpmNUI() end
        elseif data.type == "goback" then
            TriggerServerEvent("vorp_admin:sendAdminBack")
        elseif data.type == "guarma" then
            if type(ToggleGuarmaNUI) == "function" then ToggleGuarmaNUI() end
        elseif data.type == "customCoords" then
            if type(TeleportToCoordsNUI) == "function" then TeleportToCoordsNUI(data.coords) end
        elseif data.type == "announce" then
            TriggerServerEvent("vorp_admin:announce", tostring(data.message or ""))
        end
    end)

    if not ok then
        print("^1[vorp_admin] Error in teleportAction: " .. tostring(err) .. "^7")
        return cb('error')
    end
    cb('ok')
end)

RegisterNUICallback('devtoolsAction', function(data, cb)
    if not data or not data.type then return cb('error') end

    local ok, err = pcall(function()
        if data.type == "laser" then
            if type(ToggleDevLaser) == "function" then ToggleDevLaser() end
        elseif data.type == "copyVector3" then
            local c = GetEntityCoords(PlayerPedId())
            local s = string.format("vector3(%.2f, %.2f, %.2f)", c.x, c.y, c.z)
            SendNUIMessage({ string = s })
        elseif data.type == "copyVector4" then
            local c = GetEntityCoords(PlayerPedId())
            local h = GetEntityHeading(PlayerPedId())
            local s = string.format("vector4(%.2f, %.2f, %.2f, %.2f)", c.x, c.y, c.z, h)
            SendNUIMessage({ string = s })
        elseif data.type == "copyHeading" then
            local h = GetEntityHeading(PlayerPedId())
            local s = string.format("%.2f", h)
            SendNUIMessage({ string = s })
        elseif data.type == "interiorId" then
            local intId = GetInteriorFromEntity(PlayerPedId())
            local msg = "Interior ID: " .. tostring(intId)
            VORP.NotifyObjective(msg, 5000)
            SendNUIMessage({ string = tostring(intId) })
        elseif data.type == "spawnPed" then
            if type(SpawnPedFromNUI) == "function" then SpawnPedFromNUI(data.model) end
        end
    end)

    if not ok then
        print("^1[vorp_admin] Error in devtoolsAction: " .. tostring(err) .. "^7")
        return cb('error')
    end
    cb('ok')
end)

