WestRP = WestRP or {}
WestRP.Shared = WestRP.Shared or {}
WestRP.Client = WestRP.Client or {}
WestRP.Server = WestRP.Server or {}

local isServer = IsDuplicityVersion()

if isServer then
    WestRP.Server.Callback = {}
    local ServerCallbacks = {}

    ---Registra um callback assíncrono no servidor
    ---@param name string
    ---@param cb fun(source: number, done: fun(...: any), ...: any)
    function WestRP.Server.Callback.Register(name, cb)
        ServerCallbacks[name] = cb
        WestRP.Shared.Logger.Debug("CALLBACK", "Callback registrado no servidor: %s", name)
    end

    RegisterNetEvent('westrp:core:server:triggerCallback', function(name, ticket, ...)
        local src = source
        if not ServerCallbacks[name] then
            WestRP.Shared.Logger.Warn("CALLBACK", "Cliente %s tentou invocar callback inexistente: %s", src, name)
            TriggerClientEvent('westrp:core:client:callbackResponse', src, ticket, false, nil)
            return
        end

        local function respond(...)
            TriggerClientEvent('westrp:core:client:callbackResponse', src, ticket, true, ...)
        end

        local ok, err = pcall(ServerCallbacks[name], src, respond, ...)
        if not ok then
            WestRP.Shared.Logger.Error("CALLBACK", "Erro ao executar callback '%s' para player %s: %s", name, src, err)
            respond(nil)
        end
    end)

else
    WestRP.Client.Callback = {}
    local ClientCallbacks = {}
    local currentTicket = 0

    local function GetNextTicket()
        currentTicket = (currentTicket + 1) % 2147483647
        return currentTicket
    end

    ---Invoca um callback no servidor passando função de retorno
    ---@param name string
    ---@param cb fun(...: any)
    ---@param ... any
    function WestRP.Client.Callback.Trigger(name, cb, ...)
        local ticket = GetNextTicket()
        ClientCallbacks[ticket] = cb
        TriggerServerEvent('westrp:core:server:triggerCallback', name, ticket, ...)
    end

    ---Invoca um callback no servidor e aguarda a resposta sincronicamente (Thread bloqueante)
    ---@param name string
    ---@param ... any
    ---@return any
    function WestRP.Client.Callback.TriggerAwait(name, ...)
        local p = promise.new()
        WestRP.Client.Callback.Trigger(name, function(...)
            p:resolve({ ... })
        end, ...)
        local result = Citizen.Await(p)
        return table.unpack(result)
    end

    RegisterNetEvent('westrp:core:client:callbackResponse', function(ticket, success, ...)
        local cb = ClientCallbacks[ticket]
        if cb then
            ClientCallbacks[ticket] = nil
            if success then
                cb(...)
            else
                cb(nil)
            end
        end
    end)
end
