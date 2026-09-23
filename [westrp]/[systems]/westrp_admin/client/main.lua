WestRP = WestRP or {}
WestRP.Admin = WestRP.Admin or {}

local isPlayerReady = false

CreateThread(function()
    repeat Wait(1000) until LocalPlayer.state.IsInSession
    isPlayerReady = true
end)

--------------------------------------------------------------------------------
-- REGISTRO DE COMANDOS & KEYMAPPINGS (0.00ms IDLE)
--------------------------------------------------------------------------------
-- Comando para abrir o Dock Lateral
RegisterCommand(Config.CommandAdmin, function()
    if not isPlayerReady then return end
    if not Config.CanOpenWhenDead and IsPedDeadOrDying(PlayerPedId(), false) then
        return
    end

    WestRP.Admin.Dock.Toggle()
end, false)

-- Comando direto para abrir o Painel Central
RegisterCommand(Config.CommandPanel, function()
    if not isPlayerReady then return end
    WestRP.Admin.Panel.Toggle()
end, false)

-- Keymapping nativo do RedM para PGDOWN (Zero polling thread, 0.00ms constante)
RegisterKeyMapping(Config.CommandAdmin, "Abrir Menu Administrativo (WestRP)", "keyboard", "NEXT")

TriggerEvent("chat:addSuggestion", "/" .. Config.CommandAdmin, "Abre o menu lateral rápido da staff", {})
TriggerEvent("chat:addSuggestion", "/" .. Config.CommandPanel, "Abre a mesa de trabalho e painel completo da staff", {})

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
