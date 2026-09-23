WestRP = WestRP or {}
WestRP.Server = WestRP.Server or {}

---Retorna o objeto do WestRP Framework no lado do servidor
---@return table
function GetCoreObject()
    return WestRP
end

exports('GetCoreObject', GetCoreObject)

CreateThread(function()
    WestRP.Shared.Logger.Info("CORE_SERVER", "WestRP Server Kernel Inicializado com sucesso.")
end)
