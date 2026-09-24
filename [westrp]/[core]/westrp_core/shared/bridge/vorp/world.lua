WestRP = WestRP or {}
WestRP.Shared = WestRP.Shared or {}
WestRP.Shared.Bridge = WestRP.Shared.Bridge or {}
WestRP.Shared.Bridge.World = {}

local isServer = IsDuplicityVersion()

if isServer then
    local VorpCore = nil

    local function GetVorpCore()
        if not VorpCore then
            local ok, core = pcall(function()
                return exports['vorp_core']:GetCore()
            end)
            if ok and core then
                VorpCore = core
            else
                WestRP.Shared.Logger.Error("BRIDGE", "Falha ao conectar com exports['vorp_core']:GetCore()")
            end
        end
        return VorpCore
    end

    ---Transmite um comunicado oficial para todos os jogadores do servidor
    ---Utiliza a notificação Top nativa do RDR3 via VORP Core (idêntico ao vorp_admin)
    ---@param title string Título do comunicado (ex: "COMUNICADO OFICIAL")
    ---@param message string Conteúdo do anúncio
    ---@param duration? number Duração em milissegundos (padrão: 10000)
    function WestRP.Shared.Bridge.World.BroadcastAnnouncement(title, message, duration)
        title = title or "COMUNICADO OFICIAL"
        message = message or ""
        duration = tonumber(duration) or 10000

        local core = GetVorpCore()
        if core and core.NotifySimpleTop then
            core.NotifySimpleTop(-1, title, message, duration)
        else
            TriggerClientEvent("vorp:ShowTopNotification", -1, title, message, duration)
        end
    end

    ---Envia notificação nativa Top simples para um jogador específico ou todos (-1)
    ---@param source number ID do jogador (-1 para broadcast global)
    ---@param title string Título da notificação
    ---@param subtitle string Subtítulo ou mensagem
    ---@param duration? number Duração em milissegundos (padrão: 8000)
    function WestRP.Shared.Bridge.World.NotifySimpleTop(source, title, subtitle, duration)
        source = tonumber(source) or -1
        title = title or "NOTIFICAÇÃO"
        subtitle = subtitle or ""
        duration = tonumber(duration) or 8000

        local core = GetVorpCore()
        if core and core.NotifySimpleTop then
            core.NotifySimpleTop(source, title, subtitle, duration)
        else
            TriggerClientEvent("vorp:ShowTopNotification", source, title, subtitle, duration)
        end
    end
else
    ---Client-side: Dispara notificação nativa Top no cliente local
    ---@param title string Título da notificação
    ---@param subtitle string Subtítulo ou mensagem
    ---@param duration? number Duração em milissegundos (padrão: 8000)
    function WestRP.Shared.Bridge.World.NotifySimpleTop(title, subtitle, duration)
        TriggerEvent("vorp:ShowTopNotification", tostring(title or "NOTIFICAÇÃO"), tostring(subtitle or ""), tonumber(duration or 8000))
    end
end
