--[[
    WestRP Framework — Unified Client/Server Initializer
    Inclusão simples no fxmanifest.lua:
        shared_scripts {
            '@westrp_core/init.lua',
            -- seus scripts aqui...
        }
]]

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
        end
    end
end)
