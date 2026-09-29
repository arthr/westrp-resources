--[[
    WestRP Framework — Hardened RPC & Callback System
    
    Características:
    1. Rate Limiting com Sliding Window (Token Bucket) no Dispatcher do Servidor.
    2. Validação estrita de tipos e sanitização de argumentos (Anti-Exploit).
    3. Timeouts configuráveis com descarte automático de promessas/tickets órfãos (Zero Memory Leaks).
    4. Callbacks Bidirecionais: Client-to-Server e Server-to-Client.
    5. Tratamento de exceções via pcall com fallbacks seguros.
]]

WestRP = WestRP or {}
WestRP.Shared = WestRP.Shared or {}
WestRP.Client = WestRP.Client or {}
WestRP.Server = WestRP.Server or {}

local isServer = IsDuplicityVersion()

local DEFAULT_TIMEOUT_MS = 10000 -- 10 segundos
local CLEANUP_INTERVAL_MS = 30000 -- 30 segundos para sweep de tickets órfãos

if isServer then
    -- ========================================================================
    -- SERVER-SIDE CALLBACK ENGINE
    -- ========================================================================
    WestRP.Server.Callback = {}

    local ServerRegisteredCallbacks = {}
    local ServerClientCallbacks = {}
    local serverTicketCounter = 0

    -- Rate Limiting: Sliding Window (20 requisições por janela de 2 segundos)
    local callbackBuckets = {}
    local RATE_LIMIT_CAPACITY = 20
    local RATE_LIMIT_WINDOW_MS = 2000

    local function CheckCallbackRateLimit(source)
        local now = GetGameTimer()
        local bucket = callbackBuckets[source]

        if not bucket or (now - bucket.resetTime) > RATE_LIMIT_WINDOW_MS then
            callbackBuckets[source] = {
                count = 1,
                resetTime = now,
                warned = false
            }
            return true
        end

        bucket.count = bucket.count + 1
        if bucket.count > RATE_LIMIT_CAPACITY then
            if not bucket.warned then
                bucket.warned = true
                WestRP.Shared.Logger.Warn("SECURITY", "Player %s excedeu o limite de requisições RPC! (%d chamadas em %dms)",
                    source, bucket.count, RATE_LIMIT_WINDOW_MS)
            end
            return false
        end

        return true
    end

    ---Registra um callback no servidor para ser consumido pelos clientes
    ---@param name string
    ---@param cb fun(source: number, done: fun(...: any), ...: any)
    function WestRP.Server.Callback.Register(name, cb)
        if type(name) ~= "string" or type(cb) ~= "function" then
            WestRP.Shared.Logger.Error("CALLBACK", "Tentativa de registrar callback com parâmetros inválidos: %s", tostring(name))
            return
        end
        ServerRegisteredCallbacks[name] = cb
        WestRP.Shared.Logger.Debug("CALLBACK", "Callback registrado no servidor: %s", name)
    end

    ---Invoca um callback em um cliente específico e executa função de retorno
    ---@param source number
    ---@param name string
    ---@param cb fun(...: any)
    ---@param ... any
    function WestRP.Server.Callback.TriggerClient(source, name, cb, ...)
        local src = tonumber(source)
        if not src or not DoesEntityExist(GetPlayerPed(src)) then return end

        serverTicketCounter = (serverTicketCounter + 1) % 2147483647
        local ticket = serverTicketCounter

        ServerClientCallbacks[ticket] = {
            cb = cb,
            createdAt = GetGameTimer(),
            name = name,
            source = src
        }

        TriggerClientEvent('westrp:core:client:triggerClientCallback', src, name, ticket, ...)
    end

    ---Invoca um callback em um cliente específico e aguarda a resposta (bloqueia corrotina com timeout)
    ---@param source number
    ---@param name string
    ---@param timeoutMs? number
    ---@param ... any
    ---@return any
    function WestRP.Server.Callback.TriggerClientAwait(source, name, timeoutMs, ...)
        local p = promise.new()
        local maxWait = timeoutMs or DEFAULT_TIMEOUT_MS
        local resolved = false

        WestRP.Server.Callback.TriggerClient(source, name, function(...)
            if not resolved then
                resolved = true
                p:resolve({ ... })
            end
        end, ...)

        SetTimeout(maxWait, function()
            if not resolved then
                resolved = true
                WestRP.Shared.Logger.Warn("CALLBACK", "Server-to-Client callback '%s' para source %s expirou após %sms!", name, source, maxWait)
                p:resolve({ nil, "timeout" })
            end
        end)

        local result = Citizen.Await(p)
        return table.unpack(result)
    end

    -- Dispatcher de Callbacks disparados pelo Cliente
    RegisterNetEvent('westrp:core:server:triggerCallback', function(name, ticket, ...)
        local src = source

        -- 1. Validação estrita de tipos
        if type(name) ~= "string" or type(ticket) ~= "number" or #name == 0 or #name > 64 then
            WestRP.Shared.Logger.Warn("SECURITY", "Player %s enviou argumentos inválidos no dispatcher RPC!", src)
            return
        end

        -- 2. Verificação de Rate Limit (Anti-Flood)
        if not CheckCallbackRateLimit(src) then
            TriggerClientEvent('westrp:core:client:callbackResponse', src, ticket, false, "rate_limited")
            return
        end

        -- 3. Verificação de existência
        local handler = ServerRegisteredCallbacks[name]
        if not handler then
            WestRP.Shared.Logger.Warn("CALLBACK", "Player %s tentou invocar callback inexistente: '%s'", src, name)
            TriggerClientEvent('westrp:core:client:callbackResponse', src, ticket, false, "not_found")
            return
        end

        -- 4. Execução protegida com resposta garantida
        local responded = false
        local function respond(...)
            if responded then return end
            responded = true
            TriggerClientEvent('westrp:core:client:callbackResponse', src, ticket, true, ...)
        end

        local ok, err = pcall(handler, src, respond, ...)
        if not ok then
            WestRP.Shared.Logger.Error("CALLBACK", "Exceção no callback '%s' para player %s: %s", name, src, tostring(err))
            respond(nil, "internal_error")
        end
    end)

    -- Resposta de Server-to-Client callback
    RegisterNetEvent('westrp:core:server:clientCallbackResponse', function(ticket, success, ...)
        local item = ServerClientCallbacks[ticket]
        if item then
            ServerClientCallbacks[ticket] = nil
            if item.cb then
                if success then
                    item.cb(...)
                else
                    item.cb(nil)
                end
            end
        end
    end)

    -- Limpeza de memória ao desconectar
    AddEventHandler('playerDropped', function()
        local src = source
        callbackBuckets[src] = nil
    end)

    -- Thread de Limpeza de Tickets Órfãos no Servidor
    CreateThread(function()
        while true do
            Wait(CLEANUP_INTERVAL_MS)
            local now = GetGameTimer()
            for ticket, item in pairs(ServerClientCallbacks) do
                if (now - item.createdAt) > (CLEANUP_INTERVAL_MS * 2) then
                    ServerClientCallbacks[ticket] = nil
                end
            end
        end
    end)

else
    -- ========================================================================
    -- CLIENT-SIDE CALLBACK ENGINE
    -- ========================================================================
    WestRP.Client.Callback = {}

    local ClientPendingCallbacks = {}
    local ClientRegisteredCallbacks = {}
    local clientTicketCounter = 0

    local function GetNextTicket()
        clientTicketCounter = (clientTicketCounter + 1) % 2147483647
        return clientTicketCounter
    end

    ---Invoca um callback no servidor passando função de retorno com proteção contra timeout
    ---@param name string
    ---@param cb fun(...: any)
    ---@param ... any
    function WestRP.Client.Callback.Trigger(name, cb, ...)
        if type(name) ~= "string" then return end

        local ticket = GetNextTicket()
        ClientPendingCallbacks[ticket] = {
            cb = cb,
            createdAt = GetGameTimer(),
            name = name
        }

        TriggerServerEvent('westrp:core:server:triggerCallback', name, ticket, ...)
    end

    ---Invoca um callback no servidor e aguarda a resposta (bloqueia corrotina local com timeout)
    ---@param name string
    ---@param ... any
    ---@return any
    function WestRP.Client.Callback.TriggerAwait(name, ...)
        local p = promise.new()
        local ticket = GetNextTicket()
        local resolved = false

        -- Temporizador de Segurança (Timeout)
        SetTimeout(DEFAULT_TIMEOUT_MS, function()
            if not resolved then
                resolved = true
                ClientPendingCallbacks[ticket] = nil
                WestRP.Shared.Logger.Warn("CALLBACK", "Callback '%s' (Ticket %s) expirou após %sms sem resposta!", name, ticket, DEFAULT_TIMEOUT_MS)
                p:resolve({ nil, "timeout" })
            end
        end)

        ClientPendingCallbacks[ticket] = {
            cb = function(...)
                if not resolved then
                    resolved = true
                    p:resolve({ ... })
                end
            end,
            createdAt = GetGameTimer(),
            name = name
        }

        TriggerServerEvent('westrp:core:server:triggerCallback', name, ticket, ...)

        local result = Citizen.Await(p)
        return table.unpack(result)
    end

    ---Registra um callback no cliente que pode ser invocado pelo servidor
    ---@param name string
    ---@param cb fun(done: fun(...: any), ...: any)
    function WestRP.Client.Callback.Register(name, cb)
        if type(name) ~= "string" or type(cb) ~= "function" then return end
        ClientRegisteredCallbacks[name] = cb
    end

    -- Resposta do Servidor para um Callback disparado pelo Cliente
    RegisterNetEvent('westrp:core:client:callbackResponse', function(ticket, success, ...)
        local item = ClientPendingCallbacks[ticket]
        if item then
            ClientPendingCallbacks[ticket] = nil
            if item.cb then
                if success then
                    item.cb(...)
                else
                    item.cb(nil, ...)
                end
            end
        end
    end)

    -- Servidor invocando um Callback no Cliente
    RegisterNetEvent('westrp:core:client:triggerClientCallback', function(name, ticket, ...)
        local handler = ClientRegisteredCallbacks[name]
        if not handler then
            TriggerServerEvent('westrp:core:server:clientCallbackResponse', ticket, false, "not_found")
            return
        end

        local responded = false
        local function respond(...)
            if responded then return end
            responded = true
            TriggerServerEvent('westrp:core:server:clientCallbackResponse', ticket, true, ...)
        end

        local ok, err = pcall(handler, respond, ...)
        if not ok then
            WestRP.Shared.Logger.Error("CALLBACK", "Erro no client callback '%s': %s", name, tostring(err))
            respond(nil, "internal_error")
        end
    end)

    -- Thread de Limpeza de Tickets Órfãos no Cliente (Evita acúmulo de memória)
    CreateThread(function()
        while true do
            Wait(CLEANUP_INTERVAL_MS)
            local now = GetGameTimer()
            for ticket, item in pairs(ClientPendingCallbacks) do
                if (now - item.createdAt) > (CLEANUP_INTERVAL_MS * 2) then
                    ClientPendingCallbacks[ticket] = nil
                end
            end
        end
    end)
end
