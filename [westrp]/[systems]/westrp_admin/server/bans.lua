WestRP = WestRP or {}
WestRP.Server = WestRP.Server or {}
WestRP.Server.Admin = WestRP.Server.Admin or {}
WestRP.Server.Admin.Bans = {}

local VorpCore = nil
local function GetVorpCore()
    if not VorpCore then
        pcall(function()
            VorpCore = exports['vorp_core']:GetCore()
        end)
    end
    return VorpCore
end

---Converte string de tempo amigável ('2h', '3d', '1w', '1m', '0') em timestamp UNIX
---@param timeStr string
---@return number timestamp
local function ParseBanDuration(timeStr)
    if not timeStr or timeStr == "0" or timeStr == "" then
        return 0 -- Ban Permanente
    end

    local clean = string.lower(string.gsub(timeStr, "%s+", ""))
    local unit = string.sub(clean, -1)
    local val = tonumber(string.sub(clean, 1, -2)) or tonumber(clean) or 0

    local now = os.time()
    local hours = 0

    if unit == "d" then
        hours = val * 24
    elseif unit == "w" then
        hours = val * 168
    elseif unit == "m" then
        hours = val * 720
    elseif unit == "y" then
        hours = val * 8760
    else
        hours = tonumber(clean) or 0
    end

    if hours <= 0 then
        return 0
    end

    return now + (hours * 3600)
end

---Retorna a lista de todos os jogadores banidos ativos
---@return table
function WestRP.Server.Admin.Bans.GetBansList()
    local bans = MySQL.query.await("SELECT identifier, banned, banneduntil, warnings FROM users WHERE banned = 1", {})
    local list = {}

    if bans and #bans > 0 then
        for _, b in ipairs(bans) do
            local isPerm = (b.banneduntil == 0 or not b.banneduntil)
            local dateStr = isPerm and "Permanente" or os.date("%d/%m/%Y %H:%M", tonumber(b.banneduntil))
            
            list[#list + 1] = {
                identifier  = b.identifier,
                reason      = "Banimento Administrativo",
                bannedUntil = dateStr,
                isPermanent = isPerm,
                warnings    = b.warnings or 0
            }
        end
    end

    return list
end

---Aplica banimento em um jogador online
---@param source number Operador
---@param targetId number Jogador Alvo
---@param duration string Duração ('3d', '1w', '0')
---@param reason? string Motivo
function WestRP.Server.Admin.Bans.BanPlayer(source, targetId, duration, reason)
    local targetIdentifier = GetPlayerIdentifier(targetId, 1)
    if not targetIdentifier then
        return WestRP.Shared.Bridge.Player.Notify(source, "Identificador do alvo não encontrado", 4000)
    end

    local banUntil = ParseBanDuration(duration)
    local banReason = reason and reason ~= "" and reason or "Violação das diretrizes do servidor."
    local targetName = GetPlayerName(targetId) or "Jogador"

    MySQL.update.await("UPDATE users SET banned = 1, banneduntil = ? WHERE identifier = ?", { banUntil, targetIdentifier })

    local dateDisplay = (banUntil == 0) and "Permanente" or os.date("%d/%m/%Y às %H:%M", banUntil)
    local kickMsg = string.format("⚖️ WestRP • Você foi banido do servidor!\nDuração: %s\nMotivo: %s", dateDisplay, banReason)

    WestRP.Server.Admin.Logger.Log("Punish", "Banimento de Jogador", string.format("Alvo: %s (%s)\nDuração: %s\nMotivo: %s", targetName, targetIdentifier, dateDisplay, banReason), source, targetId)
    DropPlayer(targetId, kickMsg)
    WestRP.Shared.Bridge.Player.Notify(source, "Jogador " .. targetName .. " banido com sucesso (" .. dateDisplay .. ")", 5000)
end

---Aplica banimento em um jogador offline por identificador Steam/Licença
---@param source number
---@param identifier string
---@param duration string
---@param reason? string
function WestRP.Server.Admin.Bans.BanOffline(source, identifier, duration, reason)
    if not identifier or identifier == "" then return end

    local banUntil = ParseBanDuration(duration)
    local dateDisplay = (banUntil == 0) and "Permanente" or os.date("%d/%m/%Y às %H:%M", banUntil)
    local banReason = reason or "Banimento Offline"

    local affected = MySQL.update.await("UPDATE users SET banned = 1, banneduntil = ? WHERE identifier = ?", { banUntil, identifier })

    if affected and affected > 0 then
        WestRP.Shared.Bridge.Player.Notify(source, "Banimento offline aplicado com sucesso (" .. dateDisplay .. ")", 5000)
        WestRP.Server.Admin.Logger.Log("Punish", "Banimento Offline", string.format("Identificador: %s\nDuração: %s\nMotivo: %s", identifier, dateDisplay, banReason), source)
    else
        WestRP.Shared.Bridge.Player.Notify(source, "Identificador não localizado na base de dados!", 4000)
    end
end

---Remove o banimento de um identificador
---@param source number
---@param identifier string
function WestRP.Server.Admin.Bans.Unban(source, identifier)
    if not identifier or identifier == "" then return end

    local affected = MySQL.update.await("UPDATE users SET banned = 0, banneduntil = 0 WHERE identifier = ?", { identifier })

    if affected and affected > 0 then
        WestRP.Shared.Bridge.Player.Notify(source, "Jogador desbanido com sucesso: " .. identifier, 5000)
        WestRP.Server.Admin.Logger.Log("Punish", "Desbanimento de Jogador", "Operador removeu o banimento do identificador: " .. identifier, source)
    else
        WestRP.Shared.Bridge.Player.Notify(source, "Identificador não encontrado nos registros de ban!", 4000)
    end
end

---Gerencia Whitelist (conceder ou revogar)
---@param source number
---@param identifier string
---@param action "add"|"remove"
function WestRP.Server.Admin.Bans.SetWhitelist(source, identifier, action)
    local core = GetVorpCore()
    if not core or not core.Whitelist then return end

    if action == "add" then
        core.Whitelist.whitelistUser(identifier)
        WestRP.Shared.Bridge.Player.Notify(source, "Whitelist concedida para: " .. identifier, 4000)
        WestRP.Server.Admin.Logger.Log("General", "Whitelist Concedida", "Identificador: " .. identifier, source)
    else
        core.Whitelist.unWhitelistUser(identifier)
        WestRP.Shared.Bridge.Player.Notify(source, "Whitelist revogada de: " .. identifier, 4000)
        WestRP.Server.Admin.Logger.Log("General", "Whitelist Revogada", "Identificador: " .. identifier, source)
    end
end
