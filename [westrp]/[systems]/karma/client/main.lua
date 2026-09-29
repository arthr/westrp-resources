-- ====================================================================
-- WestRP Karma — Client: Main Lifecycle & Exports
-- File: client/main.lua
-- ====================================================================

local localKarma = Config.DefaultKarma
local localTier = TierEvaluator.Resolve(localKarma)

local isInitialized = false
local KarmaClientModule = {}

---Compatibility Shim for legacy calls to CombatDetector
CombatDetector = {
    StartTasks = function(_) CombatWatcher.Start() end,
    StopTasks = function(_) CombatWatcher.Stop() end,
    SetHUDVisible = function(_, visible) KarmaHUD:SetVisible(visible) end,
    IsHUDVisible = function(_) return KarmaHUD:IsVisible() end
}

function KarmaClientModule:OnLoad()
    if isInitialized then return end
    isInitialized = true

    if WestRP and WestRP.Shared and WestRP.Shared.Logger and WestRP.Shared.Logger.Info then
        pcall(WestRP.Shared.Logger.Info, "KARMA", "Módulo de moralidade inicializado no cliente.")
    end
    print("^2[westrp_karma:client] Módulo de moralidade inicializado no cliente (Debug: " .. tostring(Config.Debug) .. ")^0")
    if Config.Debug then
        TriggerServerEvent('westrp_karma:server:relayClientDebug', 'KARMA_CLIENT', 'Cliente inicializado e conectado ao sistema de Karma.')
    end

    CombatWatcher.Start()

    -- Inicializa o HUD de telemetria conforme a configuração
    if Config.DebugHUD then
        KarmaHUD:SetVisible(true)
        SendNUIMessage({
            action = 'updatePlayerStatus',
            karma = localKarma,
            tierName = localTier.name
        })
    end

    CreateThread(function()
        Wait(1500)
        TriggerServerEvent('westrp_karma:server:requestSync')
    end)
end

-- Callback recebido quando a página NUI termina de carregar
RegisterNUICallback('nuiReady', function(data, cb)
    if cb then cb({ status = 'ok' }) end
    if Config.DebugHUD or KarmaHUD:IsVisible() then
        KarmaHUD:SetVisible(true)
        SendNUIMessage({
            action = 'updatePlayerStatus',
            karma = localKarma,
            tierName = localTier.name
        })
    end
end)

function KarmaClientModule:OnUnload()
    if not isInitialized then return end
    isInitialized = false

    if WestRP and WestRP.Shared and WestRP.Shared.Logger and WestRP.Shared.Logger.Info then
        pcall(WestRP.Shared.Logger.Info, "KARMA", "Descarregando tarefas de combate no cliente...")
    end
    CombatWatcher.Stop()
    KarmaHUD:SetVisible(false)
end

-- Manipulador de sincronização de moralidade emitido pelo servidor
RegisterNetEvent('westrp_karma:client:onKarmaUpdated', function(payload)
    if not payload then return end

    localKarma = payload.currentKarma
    localTier = payload.tier or TierEvaluator.Resolve(localKarma)

    -- Atualiza dados do jogador no HUD de telemetria
    SendNUIMessage({
        action = 'updatePlayerStatus',
        karma = localKarma,
        tierName = localTier.name
    })

    if Config.Debug or (payload.delta and payload.delta ~= 0) then
        if WestRP and WestRP.Shared and WestRP.Shared.Logger then
            WestRP.Shared.Logger.Info("KARMA_CLIENT", "Sincronização de Karma: %d (Delta: %d) | Tier: %s | Motivo: %s",
                localKarma, payload.delta or 0, localTier.name, payload.reason or "SYNC")
        else
            print(string.format("^2[westrp_karma:client] Sincronização de Karma: %d (Delta: %d) | Tier: %s | Motivo: %s^0",
                localKarma, payload.delta or 0, localTier.name, payload.reason or "SYNC"))
        end
    end
end)

-- Eventos de ciclo de vida para suporte perfeito ao ensure e hot-reload
local function handleResourceStop(resName)
    if resName == GetCurrentResourceName() then
        KarmaClientModule:OnUnload()
    end
end

AddEventHandler('onResourceStop', handleResourceStop)
AddEventHandler('onClientResourceStop', handleResourceStop)

AddEventHandler('onResourceStart', function(resName)
    if resName == GetCurrentResourceName() then
        KarmaClientModule:OnLoad()
    end
end)

CreateThread(function()
    KarmaClientModule:OnLoad()
end)

-- ====================================================================
-- CLIENT COMMANDS
-- ====================================================================

-- Comando para alternar a exibição do HUD de telemetria de combate
RegisterCommand('karmahud', function()
    local newState = not KarmaHUD:IsVisible()
    KarmaHUD:SetVisible(newState)

    if newState then
        -- Envia sincronização imediata de dados para preenchimento
        SendNUIMessage({
            action = 'updatePlayerStatus',
            karma = localKarma,
            tierName = localTier.name
        })
    end

    local statusMsg = newState and "^2ativado (Visível na tela)^0" or "^1desativado (Oculto)^0"
    print("^3[westrp_karma] HUD de Telemetria de Combate " .. statusMsg .. ".^0")

    TriggerEvent('chat:addMessage', {
        color = { 218, 165, 32 },
        args = { "[Karma WestRP]", "HUD de Telemetria " .. (newState and "ATIVADO." or "DESATIVADO.") }
    })
end, false)

-- Comando informativo local para inspecionar moralidade atual
RegisterCommand('karma', function()
    print(string.format("^3[Karma WestRP] Sua moralidade atual: %d (%s)^0", localKarma, localTier.name))

    TriggerEvent('chat:addMessage', {
        color = { 218, 165, 32 },
        args = { "[Karma WestRP]", string.format("Sua moralidade atual: %d (%s). Use /karmahud para o painel em tempo real.", localKarma, localTier.name) }
    })
end, false)

-- ====================================================================
-- CLIENT EXPORTS
-- ====================================================================

exports('GetLocalKarma', function()
    return localKarma
end)

exports('GetLocalTier', function()
    return localTier
end)

exports('ToggleHUD', function(visible)
    if visible == nil then
        visible = not KarmaHUD:IsVisible()
    end
    KarmaHUD:SetVisible(visible)
end)
