WestRP = WestRP or {}
WestRP.Server = WestRP.Server or {}
WestRP.Server.Admin = WestRP.Server.Admin or {}
WestRP.Server.Admin.World = {}

---Dispara anúncio global com Toast para todos os cidadãos conectados
---@param source number Operador
---@param message string Conteúdo do anúncio
function WestRP.Server.Admin.World.Announce(source, message)
    if not message or message == "" then return end

    local operatorName = GetPlayerName(source) or "Staff"
    TriggerClientEvent("westrp_ui:client:showToast", -1, "COMUNICADO OFICIAL", message, "gold", 10000)

    WestRP.Shared.Bridge.Player.Notify(source, "Anúncio transmitido para toda a cidade", 3000)
    WestRP.Server.Admin.Logger.Log("General", "Anúncio Global", string.format("Operador: %s\nMensagem: %s", operatorName, message), source)
end
