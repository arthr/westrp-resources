WestRP = WestRP or {}
WestRP.Admin = WestRP.Admin or {}

local isPlayerReady = false

CreateThread(function()
    if LocalPlayer.state.IsInSession or NetworkIsSessionStarted() then
        isPlayerReady = true
        return
    end
    while not LocalPlayer.state.IsInSession and not NetworkIsSessionStarted() do
        Wait(500)
    end
    isPlayerReady = true
end)

--------------------------------------------------------------------------------
-- REGISTRO DE COMANDOS & KEYMAPPINGS (0.00ms IDLE)
--------------------------------------------------------------------------------
-- Comando principal para abrir o Painel Administrativo Completo (/admin)
RegisterCommand(Config.CommandAdmin, function()
    if not isPlayerReady then return end
    if not Config.CanOpenWhenDead and IsPedDeadOrDying(PlayerPedId(), false) then
        return
    end

    WestRP.Admin.Panel.Toggle()
end, false)

-- Alias secundário (/adminpanel)
RegisterCommand(Config.CommandPanel, function()
    if not isPlayerReady then return end
    if not Config.CanOpenWhenDead and IsPedDeadOrDying(PlayerPedId(), false) then
        return
    end

    WestRP.Admin.Panel.Toggle()
end, false)

-- Comando para abrir o Hot Menu / Dock Lateral de Ações Rápidas (/admhot)
RegisterCommand(Config.CommandHot, function()
    if not isPlayerReady then return end
    if not Config.CanOpenWhenDead and IsPedDeadOrDying(PlayerPedId(), false) then
        return
    end

    WestRP.Admin.Dock.Toggle()
end, false)

-- Keymapping nativo do RedM para PGDOWN (NEXT) -> Abre o Hot Menu (/admhot) (0.00ms constante)
RegisterKeyMapping(Config.CommandHot, "Abrir Hot Menu Administrativo (WestRP)", "keyboard", "NEXT")

TriggerEvent("chat:addSuggestion", "/" .. Config.CommandAdmin, "Abre o painel administrativo de gestão completa (Dashboard)", {})
TriggerEvent("chat:addSuggestion", "/" .. Config.CommandPanel, "Abre o painel administrativo de gestão completa (Alias)", {})
TriggerEvent("chat:addSuggestion", "/" .. Config.CommandHot, "Abre o menu lateral rápido da staff (Hot Menu)", {})

--------------------------------------------------------------------------------
-- EVENTOS DE AÇÕES RECEBIDAS DO SERVIDOR
--------------------------------------------------------------------------------
-- Congelamento de Ped
RegisterNetEvent("westrp_admin:client:freeze", function(frozen)
    FreezeEntityPosition(PlayerPedId(), frozen)
    local msg = frozen and "Você foi congelado por um administrador" or "Você foi descongelado"
    WestRP.Client.UI.ShowToast("STAFF", msg, frozen and "danger" or "info")
end)

-- Respawn Administrativo
RegisterNetEvent("westrp_admin:client:respawn", function()
    DoScreenFadeOut(800)
    repeat Wait(0) until not IsScreenFadingOut()
    FreezeEntityPosition(PlayerPedId(), true)
    Wait(1000)
    DoScreenFadeIn(2500)
    repeat Wait(0) until not IsScreenFadingIn()
    FreezeEntityPosition(PlayerPedId(), false)
    WestRP.Client.UI.ShowToast("RESPAWN", "Você foi reanimado por um administrador", "info")
end)

-- Efeitos de Trolagens (Staff Trolls)
RegisterNetEvent("westrp_admin:client:trollLightning", function(coords)
    ForceLightningFlashAtCoords(coords.x, coords.y, coords.z, -1.0)
end)

RegisterNetEvent("westrp_admin:client:trollFire", function()
    local ped = PlayerPedId()
    StartEntityFire(ped)
    Wait(5000)
    StopEntityFire(ped)
end)

RegisterNetEvent("westrp_admin:client:trollHeaven", function()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    SetEntityCoords(ped, c.x, c.y, c.z + 180.0, false, false, false, false)
end)

RegisterNetEvent("westrp_admin:client:trollRagdoll", function()
    local ped = PlayerPedId()
    SetPedCanRagdoll(ped, true)
    ClearPedTasksImmediately(ped)
    SetPedToRagdoll(ped, 6000, 6000, 0, true, true, false)
end)

RegisterNetEvent("westrp_admin:client:trollCuff", function()
    local ped = PlayerPedId()
    local isCuffed = IsPedCuffed(ped)
    SetEnableHandcuffs(ped, not isCuffed, false)
    SetPedCanPlayGestureAnims(ped, isCuffed)
end)

RegisterNetEvent("westrp_admin:client:trollDrunk", function()
    AnimpostfxPlay("MP_BountyLagrasSwamp")
    Wait(12000)
    AnimpostfxStop("MP_BountyLagrasSwamp")
end)

--------------------------------------------------------------------------------
-- LIMPEZA GERAL AO REINICIAR/PARAR O RESOURCE
--------------------------------------------------------------------------------
AddEventHandler("onResourceStop", function(resName)
    if resName ~= GetCurrentResourceName() then return end
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped, true, true)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)
