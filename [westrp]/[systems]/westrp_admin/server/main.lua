WestRP = WestRP or {}
WestRP.Server = WestRP.Server or {}
WestRP.Server.Admin = WestRP.Server.Admin or {}


local serverStartTime = os.time()
local peakPlayers = 0
local peak24h = 0

--------------------------------------------------------------------------------
-- REGISTRO DE CALLBACKS RPC (WestRP.Callback)
--------------------------------------------------------------------------------
-- Obtenção do resumo do servidor (Server Overview KPI & Operador)
WestRP.Server.Callback.Register("westrp_admin:server:getServerOverview", function(source, cb)
    local players = GetPlayers()
    local onlineCount = #players
    if onlineCount > peakPlayers then peakPlayers = onlineCount end
    if onlineCount > peak24h then peak24h = onlineCount end

    local maxClients = GetConvarInt("sv_maxclients", 32)
    local uptime = os.time() - serverStartTime
    local hours = math.floor(uptime / 3600)
    local mins = math.floor((uptime % 3600) / 60)
    local uptimeStr = string.format("%dh %02dm", hours, mins)

    local role = WestRP.Server.Admin.Security.GetPlayerRole(source)
    local char = WestRP.Shared.Bridge.Player.GetCharacter(source)
    local charName = char and (char.firstname .. " " .. char.lastname) or GetPlayerName(source)

    local roleLabel = "Operador"
    if Config.Roles and Config.Roles[role] then
        roleLabel = Config.Roles[role].label or role
    end

    cb({
        stats = {
            online = onlineCount,
            maxClients = maxClients,
            uptime = uptimeStr,
            uptimeSeconds = uptime,
            peak24h = peak24h,
            peakAllTime = peakPlayers
        },
        operator = {
            name = charName,
            role = roleLabel,
            rawRole = role,
            onDuty = true
        }
    })
end)

-- Obtenção do cargo staff do operador
WestRP.Server.Callback.Register("westrp_admin:server:getStaffRole", function(source, cb)
    local role = WestRP.Server.Admin.Security.GetPlayerRole(source)
    cb(role)
end)

-- Obtenção da lista de jogadores online
WestRP.Server.Callback.Register("westrp_admin:server:getPlayers", function(source, cb, filter)
    if not WestRP.Server.Admin.Security.CanExecute(source, "players_list") then
        return cb({})
    end
    local list = WestRP.Server.Admin.Players.GetList(filter)
    cb(list)
end)

-- Obtenção do catálogo de itens para o Spawner
WestRP.Server.Callback.Register("westrp_admin:server:getItemsCatalog", function(source, cb)
    if not WestRP.Server.Admin.Security.CanExecute(source, "give_item") then
        return cb({})
    end
    local catalog = WestRP.Server.Admin.Items.GetCatalog()
    cb(catalog)
end)

-- Obtenção do catálogo de armas para o Spawner
WestRP.Server.Callback.Register("westrp_admin:server:getWeaponsCatalog", function(source, cb)
    if not WestRP.Server.Admin.Security.CanExecute(source, "give_weapon") then
        return cb({})
    end
    local weapons = WestRP.Server.Admin.Items.GetWeaponsCatalog()
    cb(weapons)
end)

-- Obtenção da lista de banimentos ativos
WestRP.Server.Callback.Register("westrp_admin:server:getBansList", function(source, cb)
    if not WestRP.Server.Admin.Security.CanExecute(source, "ban_player") then
        return cb({})
    end
    local bans = WestRP.Server.Admin.Bans.GetBansList()
    cb(bans)
end)

-- Obtenção do inventário em tempo real para o Inspetor
WestRP.Server.Callback.Register("westrp_admin:server:getPlayerInventory", function(source, cb, targetId)
    if not WestRP.Server.Admin.Security.CanExecute(source, "inspect_inventory", targetId) then
        return cb({ ok = false, message = "Permissão negada para inspecionar inventário!" })
    end
    local data = WestRP.Server.Admin.Items.GetPlayerInventory(source, targetId)
    cb(data)
end)

--------------------------------------------------------------------------------
-- ROTEADOR PRINCIPAL DE AÇÕES ADMINISTRATIVAS (Zero-Trust)
--------------------------------------------------------------------------------
RegisterNetEvent("westrp_admin:server:executeAction", function(data)
    local _source = source
    if not data or not data.action then return end

    local action = tostring(data.action)
    local targetId = data.targetId and tonumber(data.targetId) or nil
    local payload = data.payload or {}

    -- Middleware central de validação
    if not WestRP.Server.Admin.Security.CanExecute(_source, action, targetId) then
        return
    end

    -- Roteamento de comandos
    if action == "goto" and targetId then
        WestRP.Server.Admin.Players.GoTo(_source, targetId)
    elseif action == "bring" and targetId then
        WestRP.Server.Admin.Players.Bring(_source, targetId)
    elseif action == "freeze" and targetId then
        WestRP.Server.Admin.Players.ToggleFreeze(_source, targetId)
    elseif action == "heal" and targetId then
        WestRP.Server.Admin.Players.Heal(_source, targetId)
    elseif action == "revive" and targetId then
        WestRP.Server.Admin.Players.Revive(_source, targetId)
    elseif action == "respawn" and targetId then
        WestRP.Server.Admin.Players.Respawn(_source, targetId)
    elseif action == "spectate" and targetId then
        WestRP.Server.Admin.Players.Spectate(_source, targetId)
    elseif action == "kick" and targetId then
        WestRP.Server.Admin.Players.Kick(_source, targetId, payload.reason)
    elseif action == "ban" and targetId then
        WestRP.Server.Admin.Bans.BanPlayer(_source, targetId, payload.duration or "3d", payload.reason)
    elseif action == "ban_offline" and payload.identifier then
        WestRP.Server.Admin.Bans.BanOffline(_source, payload.identifier, payload.duration or "3d", payload.reason)
    elseif action == "unban" and payload.identifier then
        WestRP.Server.Admin.Bans.Unban(_source, payload.identifier)
    elseif action == "set_job" and targetId then
        WestRP.Server.Admin.Players.SetJob(_source, targetId, payload.job, payload.grade, payload.label)
    elseif action == "set_group" and targetId then
        WestRP.Server.Admin.Players.SetGroup(_source, targetId, payload.group)
    elseif action == "whitelist" and payload.identifier then
        WestRP.Server.Admin.Bans.SetWhitelist(_source, payload.identifier, payload.subAction or "add")
    elseif action == "give_item" and targetId then
        WestRP.Server.Admin.Items.GiveItem(_source, targetId, payload.item, payload.qty)
    elseif action == "give_weapon" and targetId then
        WestRP.Server.Admin.Items.GiveWeapon(_source, targetId, payload.weapon)
    elseif action == "give_currency" and targetId then
        WestRP.Server.Admin.Items.GiveCurrency(_source, targetId, payload.currencyType or 0, payload.amount or 0)
    elseif action == "modify_currency" and targetId then
        WestRP.Server.Admin.Items.ModifyCurrency(_source, targetId, payload.currencyType, payload.operation, payload.amount, payload.reason)
    elseif action == "confiscate_item" and targetId then
        WestRP.Server.Admin.Items.ConfiscateItem(_source, targetId, payload.item, payload.qty, payload.reason)
    elseif action == "confiscate_weapon" and targetId then
        WestRP.Server.Admin.Items.ConfiscateWeapon(_source, targetId, payload.weaponId, payload.weaponName, payload.reason)
    elseif action == "clear_inventory" and targetId then
        WestRP.Server.Admin.Items.ClearInventory(_source, targetId)
    elseif action == "clear_currency" and targetId then
        WestRP.Server.Admin.Items.ClearCurrency(_source, targetId)
    elseif action == "troll" and targetId then
        WestRP.Server.Admin.Players.Troll(_source, targetId, payload.trollType or "lightning")
    elseif action == "announce" then
        WestRP.Server.Admin.World.Announce(_source, payload.message)
    elseif action == "heal_all" then
        WestRP.Server.Admin.Players.HealAll(_source)
    elseif action == "revive_all" then
        WestRP.Server.Admin.Players.ReviveAll(_source)
    elseif action == "bring_all" then
        WestRP.Server.Admin.Players.BringAll(_source)
    elseif action == "kick_all" then
        WestRP.Server.Admin.Players.KickAll(_source, payload.reason)
    end
end)


--------------------------------------------------------------------------------
-- EVENTOS AUXILIARES DE LOGS & AUTO-CURA
--------------------------------------------------------------------------------
RegisterNetEvent("westrp_admin:server:logBooster", function(boosterName, desc)
    local _source = source
    if WestRP.Server.Admin.Security.CanExecute(_source, "noclip") then
        WestRP.Server.Admin.Logger.Log("General", "Booster Pessoal (" .. boosterName .. ")", desc, _source)
    end
end)

RegisterNetEvent("westrp_admin:server:logTeleport", function(tpType, fromCoords, toCoords)
    local _source = source
    if WestRP.Server.Admin.Security.CanExecute(_source, "tp_to_waypoint") then
        local desc = string.format("Tipo: %s\nDe: %.2f, %.2f, %.2f\nPara: %.2f, %.2f, %.2f", tpType, fromCoords.x, fromCoords.y, fromCoords.z, toCoords.x, toCoords.y, toCoords.z)
        WestRP.Server.Admin.Logger.Log("Teleport", "Teleporte de Operador", desc, _source)
    end
end)

RegisterNetEvent("westrp_admin:server:selfHeal", function()
    local _source = source
    if WestRP.Server.Admin.Security.CanExecute(_source, "selfheal") then
        WestRP.Shared.Bridge.Player.Heal(_source)
        WestRP.Server.Admin.Logger.Log("General", "Auto Cura", "Operador restaurou vida e estamina", _source)
    end
end)

RegisterNetEvent("westrp_admin:server:selfRevive", function()
    local _source = source
    if WestRP.Server.Admin.Security.CanExecute(_source, "selfrevive") then
        WestRP.Shared.Bridge.Player.Revive(_source)
        WestRP.Server.Admin.Logger.Log("General", "Auto Reviver", "Operador reanimou a si mesmo", _source)
    end
end)

local isRestartScheduled = false
local restartMinutesRemaining = 0

RegisterNetEvent("westrp_admin:server:startRestart", function(minutes)
    local _source = source
    if not WestRP.Server.Admin.Security.CanExecute(_source, "server_control") then return end

    local mins = tonumber(minutes) or 5
    isRestartScheduled = true
    restartMinutesRemaining = mins

    WestRP.Server.Admin.World.Announce(_source, string.format("O servidor será reiniciado em %d minuto(s). Por favor, salvem suas ações!", mins))
    WestRP.Server.Admin.Logger.Log("Server", "Restart Agendado", string.format("Reinicialização agendada para %d minutos", mins), _source)

    CreateThread(function()
        while isRestartScheduled and restartMinutesRemaining > 0 do
            Wait(60000)
            if not isRestartScheduled then break end
            restartMinutesRemaining = restartMinutesRemaining - 1
            if restartMinutesRemaining > 0 then
                WestRP.Server.Admin.World.Announce(-1, string.format("ATENÇÃO: Reinicialização do servidor em %d minuto(s)!", restartMinutesRemaining))
            else
                WestRP.Server.Admin.World.Announce(-1, "ATENÇÃO: O servidor está reiniciando agora!")
                Wait(5000)
                local players = GetPlayers()
                for _, pid in ipairs(players) do
                    DropPlayer(pid, "[WestRP] Reinicialização agendada do servidor concluída. Reconecte em instantes.")
                end
            end
        end
    end)
end)

RegisterNetEvent("westrp_admin:server:cancelRestart", function()
    local _source = source
    if not WestRP.Server.Admin.Security.CanExecute(_source, "server_control") then return end

    if isRestartScheduled then
        isRestartScheduled = false
        restartMinutesRemaining = 0
        WestRP.Server.Admin.World.Announce(_source, "O agendamento de reinicialização do servidor foi CANCELADO pela administração.")
        WestRP.Server.Admin.Logger.Log("Server", "Restart Cancelado", "Agendamento de reinicialização cancelado", _source)
    end
end)
