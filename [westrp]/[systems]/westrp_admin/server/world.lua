WestRP = WestRP or {}
WestRP.Server = WestRP.Server or {}
WestRP.Server.Admin = WestRP.Server.Admin or {}
WestRP.Server.Admin.World = {}

---Dispara anúncio global para todos os cidadãos conectados
---Transmite via notificação Top nativa do RDR3 (padrão vorp_admin através da Bridge),
---Toast dourado da WestRP UI e registro no Chat Global.
---@param source number Operador (ou -1 se disparado por rotina do servidor)
---@param message string Conteúdo do anúncio
function WestRP.Server.Admin.World.Announce(source, message)
    if not message or message == "" then return end

    local operatorName = "Console / Sistema"
    if source and source > 0 then
        operatorName = GetPlayerName(source) or "Staff"
    end

    -- 1. Notificação nativa RDR3 Feed Top para toda a cidade (padrão vorp_admin via Bridge)
    if WestRP.Shared.Bridge.World and WestRP.Shared.Bridge.World.BroadcastAnnouncement then
        WestRP.Shared.Bridge.World.BroadcastAnnouncement("COMUNICADO OFICIAL", message, 10000)
    else
        TriggerClientEvent("vorp:ShowTopNotification", -1, "COMUNICADO OFICIAL", message, 10000)
    end

    -- 2. Notificação NUI Toast WestRP UI para todos os clientes
    TriggerClientEvent("westrp_ui:client:showToast", -1, "COMUNICADO OFICIAL", message, "gold", 10000)

    -- 3. Registro no Chat Global
    TriggerClientEvent("chat:addMessage", -1, {
        color = { 212, 175, 55 },
        multiline = true,
        args = { "📢 [COMUNICADO OFICIAL]", message }
    })

    -- 4. Notificação de confirmação ao operador
    if source and source > 0 then
        WestRP.Shared.Bridge.Player.Notify(source, "Anúncio transmitido com sucesso para todo o servidor", 4000)
    end

    -- 5. Registro de auditoria no Discord
    WestRP.Server.Admin.Logger.Log("General", "Anúncio Global", string.format("Operador: %s\nMensagem: %s", operatorName, message), source)
end
