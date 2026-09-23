WestRP = WestRP or {}
WestRP.Server = WestRP.Server or {}
WestRP.Server.Admin = WestRP.Server.Admin or {}
WestRP.Server.Admin.Logger = {}

---Envia um log formatado para o canal Discord apropriado
---@param category "General"|"Punish"|"Teleport"|"Spawner"|"DevTools"
---@param title string
---@param description string
---@param source number
---@param targetId? number
function WestRP.Server.Admin.Logger.Log(category, title, description, source, targetId)
    if not Config.Webhooks.Enabled then return end

    local webhookUrl = Config.Webhooks.Urls[category] or Config.Webhooks.Urls.General
    if not webhookUrl or webhookUrl == "" then return end

    local operatorName = GetPlayerName(source) or "Desconhecido"
    local operatorSteam = GetPlayerIdentifierByType(source, "steam") or GetPlayerIdentifier(source, 0) or "Sem Steam"
    local operatorDiscord = "Não Vinculado"
    local discordId = GetPlayerIdentifierByType(source, "discord")
    if discordId then
        operatorDiscord = "<@" .. string.sub(discordId, 9) .. ">"
    end
    local operatorIp = GetPlayerEndpoint(source) or "0.0.0.0"

    local color = Config.Webhooks.Colors.Default
    if category == "Punish" then
        color = Config.Webhooks.Colors.Danger
    elseif category == "Spawner" then
        color = Config.Webhooks.Colors.Success
    elseif category == "Teleport" then
        color = Config.Webhooks.Colors.Info
    end

    local fields = {
        { name = "👮 Operador", value = string.format("**%s** (ID: %s)\n%s", operatorName, source, operatorDiscord), inline = true },
        { name = "🆔 Identificadores", value = string.format("Steam: `%s`\nIP: `%s`", operatorSteam, operatorIp), inline = true }
    }

    if targetId and targetId > 0 then
        local targetName = GetPlayerName(targetId) or "Desconhecido"
        local targetSteam = GetPlayerIdentifierByType(targetId, "steam") or GetPlayerIdentifier(targetId, 0) or "Sem Steam"
        fields[#fields + 1] = { name = "🎯 Alvo da Ação", value = string.format("**%s** (ID: %s)\nSteam: `%s`", targetName, targetId, targetSteam), inline = false }
    end

    local payload = json.encode({
        username = Config.Webhooks.Author,
        avatar_url = Config.Webhooks.AvatarUrl,
        embeds = {
            {
                title = "⚡ [ADMIN AUDIT] " .. title,
                description = description,
                color = color,
                fields = fields,
                footer = { text = "WestRP Framework • " .. os.date("%d/%m/%Y %H:%M:%S") }
            }
        }
    })

    PerformHttpRequest(webhookUrl, function() end, "POST", payload, { ["Content-Type"] = "application/json" })
end
