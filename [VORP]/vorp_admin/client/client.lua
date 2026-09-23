local Key = Config.Key
local CanOpen = Config.CanOpenMenuWhenDead
local Inmenu
local isDockOpen = false
local spectating = false
local Camera = nil
local lastcoords = { x = 0, y = 0, z = 0 }
local frozenPlayersState = {}
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
    isDockOpen = false
    SetNuiFocusKeepInput(false)
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
    local myPlayerName = GetPlayerName(PlayerId())
    local myServerId = GetPlayerServerId(PlayerId())
    if LocalPlayer.state and LocalPlayer.state.Character then
        if LocalPlayer.state.Character.Group then
            staffRole = tostring(LocalPlayer.state.Character.Group)
        end
        if LocalPlayer.state.Character.Firstname then
            myPlayerName = LocalPlayer.state.Character.Firstname .. " " .. (LocalPlayer.state.Character.Lastname or "")
        end
    end

    isDockOpen = true
    SetNuiFocus(true, false) -- Foco de teclado ativo na NUI, cursor do MOUSE DESATIVADO (false)
    SetNuiFocusKeepInput(true) -- Mantém movimentação e câmera livres no jogo
    SendNUIMessage({
        action = "open",
        players = {},
        boosters = boosters,
        staffRole = staffRole,
        myServerId = myServerId,
        myPlayerName = myPlayerName
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

local function CloseCustomAdminNUI()
    if isDockOpen then
        isDockOpen = false
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "close" })
    end
end

local function ToggleAdminMenu()
    if isDockOpen then
        CloseCustomAdminNUI()
        return true
    end
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

-- Thread de controle para desativar apenas ações de setas e celular do jogo enquanto usa o HUD dock lateral por teclado
CreateThread(function()
    while true do
        if isDockOpen then
            DisableControlAction(0, 0xD9D0E1C0, true) -- INPUT_CELLPHONE_UP
            DisableControlAction(0, 0x39CCABD5, true) -- INPUT_CELLPHONE_DOWN
            DisableControlAction(0, 0x862AE100, true) -- INPUT_CELLPHONE_LEFT
            DisableControlAction(0, 0xA65EBAB4, true) -- INPUT_CELLPHONE_RIGHT
            DisableControlAction(0, 0x3076E97C, true) -- INPUT_CELLPHONE_SELECT
            DisableControlAction(0, 0x156F7119, true) -- INPUT_CELLPHONE_CANCEL
            DisableControlAction(0, 0x07CE1E0E, true) -- Attack
            Wait(0)
        else
            Wait(250)
        end
    end
end)

CreateThread(function()
    repeat Wait(3000) until LocalPlayer.state.IsInSession

    if Config.useAdminCommand then
        TriggerEvent('chat:addSuggestion', '/' .. Config.commandAdmin, 'Open admin dock or use pagedown', { {} })
        RegisterCommand(Config.commandAdmin, function()
            ToggleAdminMenu()
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
                if not ToggleAdminMenu() then
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
    SetEntityCoords(PlayerPedId(), pl.x, pl.y, pl.z + 200.0, false, false, false, false)
end)

RegisterNetEvent('vorp_admin:ClientTrollTpToHeavenHandler', function()
    TriggerEvent('vorp_admin:ClientTrollTPToHeavenHandler')
end)

RegisterNetEvent('vorp_admin:ClientTrollRagdollPlayerHandler', function()
    local ped = PlayerPedId()
    SetPedCanRagdoll(ped, true)
    ClearPedTasksImmediately(ped)
    SetPedToRagdoll(ped, 6000, 6000, 0, true, true, false)
end)

RegisterNetEvent('vorp_admin:ClientDrainPlayerStamHandler', function()
    local ped = PlayerPedId()
    Citizen.InvokeNative(0xC3D4B754C0E86B9E, ped, -1000.0)
    Citizen.InvokeNative(0xC6258F41D86676E0, ped, 1, 0)
end)

RegisterNetEvent('vorp_admin:ClientTrollDrainPlayerStamHandler', function()
    TriggerEvent('vorp_admin:ClientDrainPlayerStamHandler')
end)

RegisterNetEvent('vorp_admin:ClientHandcuffPlayerHandler', function()
    local player = PlayerPedId()
    if not IsPedCuffed(player) then
        SetEnableHandcuffs(player, true, false)
        if type(CuffPed) == "function" then
            CuffPed(player)
        end
        SetPedCanPlayGestureAnims(player, false)
    else
        if type(UncuffPed) == "function" then
            UncuffPed(player)
        end
        SetEnableHandcuffs(player, false, false)
        SetPedCanPlayGestureAnims(player, true)
        ClearPedTasksImmediately(player)
    end
end)

RegisterNetEvent('vorp_admin:ClientTrollHandcuffPlayerHandler', function()
    TriggerEvent('vorp_admin:ClientHandcuffPlayerHandler')
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
    isDockOpen = false
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closeDock', function(_, cb)
    isDockOpen = false
    SetNuiFocusKeepInput(false)
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
            frozenPlayersState[targetId] = not frozenPlayersState[targetId]
            TriggerServerEvent("vorp_admin:freeze", targetId, frozenPlayersState[targetId], nil, targetName)
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
            TriggerServerEvent('vorp_admin:ServerTrollTPToHeavenHandler', targetId)
        elseif action == "troll_handcuff" then
            TriggerServerEvent('vorp_admin:ServerHandcuffPlayerHandler', targetId)
        elseif action == "troll_ragdoll" then
            TriggerServerEvent('vorp_admin:ServerTrollRagdollPlayerHandler', targetId)
        elseif action == "troll_stam" then
            TriggerServerEvent('vorp_admin:ServerDrainPlayerStamHandler', targetId)
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
    if not data or not data.type then return cb('error') end

    local ok, err = pcall(function()
        local tId = tonumber(data.targetId)
        local myServerId = GetPlayerServerId(PlayerId())
        if not tId or tId <= 0 then
            tId = myServerId
        end
        local tName = tostring(data.targetName or "Player")
        if tName == "Operador Atual" or tName == "Self" or tId == myServerId then
            tName = GetPlayerName(PlayerId())
        end

        if data.type == "giveCurrency" then
            local currencyType = tonumber(data.currencyType) or 0
            local amount = tonumber(data.amount) or 0
            TriggerServerEvent("vorp_admin:givePlayer", tId, "moneygold", currencyType, amount, nil, "vorp.staff.GiveCurrency", tName)
        elseif data.type == "giveItem" then
            local item = tostring(data.item or "")
            local qty = tonumber(data.qty) or 1
            TriggerServerEvent("vorp_admin:givePlayer", tId, "item", item, qty, nil, "vorp.staff.Giveitems", tName)
        elseif data.type == "giveWeapon" then
            local weapon = tostring(data.weapon or "")
            TriggerServerEvent("vorp_admin:givePlayer", tId, "weapon", weapon, nil, nil, "vorp.staff.GiveWeapons", tName)
        elseif data.type == "giveMount" then
            if data.mountType == "horse" then
                local model = tostring(data.model or "A_C_Horse_AmericanPaint_Overo")
                TriggerServerEvent("vorp_admin:givePlayer", tId, "horse", model, "Cavalo", 0, "vorp.staff.GiveHorse", tName)
            else
                local model = tostring(data.model or "cart01")
                TriggerServerEvent("vorp_admin:givePlayer", tId, "wagon", model, "Carroca", nil, "vorp.staff.GiveWagons", tName)
            end
        elseif data.type == "clearInventory" then
            TriggerServerEvent("vorp_admin:ClearAllItems", "items", tId, "vorp.staff.RemoveAllItems", tName)
            TriggerServerEvent("vorp_admin:ClearAllItems", "weapons", tId, "vorp.staff.RemoveAllWeapons", tName)
        elseif data.type == "clearCurrency" then
            local cType = (data.currencyType == "1" or data.currencyType == 1 or data.currencyType == "gold") and "gold" or "money"
            TriggerServerEvent("vorp_admin:ClearCurrency", tId, cType, "vorp.staff.RemoveCurrency", tName)
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

