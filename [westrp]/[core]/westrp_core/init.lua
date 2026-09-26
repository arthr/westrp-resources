--[[
    WestRP Framework — Unified Client/Server Initializer
    Inclusão simples no fxmanifest.lua:
        shared_scripts {
            '@westrp_core/init.lua',
            -- seus scripts aqui...
        }
]]

local function SetupClientUIBridge(core)
    if IsDuplicityVersion() or not core then
        return
    end

    core.Client = core.Client or {}
    core.Client.UI = core.Client.UI or {}

    local uiMethods = {
        'OpenDock', 'CloseDock', 'IsDockOpen', 'UpdateItem', 'ShowToast',
        'OpenPanel', 'ClosePanel', 'IsPanelOpen',
        'OpenDialog', 'CloseDialog', 'IsDialogOpen',
        'OpenConfirm', 'CloseConfirm', 'IsConfirmOpen',
        'StartProgressBar', 'ProgressBar', 'CancelProgressBar', 'IsProgressBarActive'
    }

    for _, method in ipairs(uiMethods) do
        if not core.Client.UI[method] then
            core.Client.UI[method] = function(...)
                if GetResourceState('westrp_ui') == 'started' then
                    return exports['westrp_ui'][method](exports['westrp_ui'], ...)
                end
            end
        end
    end

    setmetatable(core.Client.UI, {
        __index = function(_, k)
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] and exports['westrp_ui'][k] then
                return function(...)
                    return exports['westrp_ui'][k](exports['westrp_ui'], ...)
                end
            end
            return nil
        end
    })
end

local function InitializeWestRP()
    local isCore = GetCurrentResourceName() == 'westrp_core'
    if isCore then
        return
    end

    local attempts = 0
    while GetResourceState('westrp_core') ~= 'started' do
        attempts = attempts + 1
        if attempts > 50 then
            error('^1[WestRP] FALHA CRÍTICA: "westrp_core" não está iniciado ou demorou demais para responder!^0')
            return
        end
        Wait(100)
    end

    WestRP = exports['westrp_core']:GetCoreObject()

    if not WestRP then
        error('^1[WestRP] ERRO: Falha ao obter CoreObject de "westrp_core"!^0')
    end

    SetupClientUIBridge(WestRP)
end

InitializeWestRP()

AddEventHandler('onResourceStart', function(resName)
    if resName == 'westrp_core' then
        Wait(100)
        local ok, core = pcall(function()
            return exports['westrp_core']:GetCoreObject()
        end)
        if ok and core then
            WestRP = core
            SetupClientUIBridge(WestRP)
        end
    end
end)
