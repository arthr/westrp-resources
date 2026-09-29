WestRP = WestRP or {}
WestRP.Client = WestRP.Client or {}

---Retorna o objeto do WestRP Framework no lado do cliente
---@return table
function GetCoreObject()
    return WestRP
end

exports('GetCoreObject', GetCoreObject)

CreateThread(function()
    WestRP.Shared.Logger.Info("CORE_CLIENT", "WestRP Client Inicializado com sucesso.")
end)
