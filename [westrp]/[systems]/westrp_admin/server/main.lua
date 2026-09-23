WestRP = WestRP or {}
WestRP.Server = WestRP.Server or {}
WestRP.Server.Admin = WestRP.Server.Admin or {}


--------------------------------------------------------------------------------
-- REGISTRO DE CALLBACKS RPC (WestRP.Callback)
--------------------------------------------------------------------------------
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

-- Obtenção da lista de banimentos ativos
WestRP.Server.Callback.Register("westrp_admin:server:getBansList", function(source, cb)
    if not WestRP.Server.Admin.Security.CanExecute(source, "ban_player") then
        return cb({})
    end
    local bans = WestRP.Server.Admin.Bans.GetBansList()
    cb(bans)
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
    elseif action == "clear_inventory" and targetId then
        WestRP.Server.Admin.Items.ClearInventory(_source, targetId)
    elseif action == "clear_currency" and targetId then
        WestRP.Server.Admin.Items.ClearCurrency(_source, targetId)
    elseif action == "troll" and targetId then
        WestRP.Server.Admin.Players.Troll(_source, targetId, payload.trollType or "lightning")
    elseif action == "announce" then
        WestRP.Server.Admin.World.Announce(_source, payload.message)
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
