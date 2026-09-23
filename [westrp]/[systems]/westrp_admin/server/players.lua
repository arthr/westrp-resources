WestRP = WestRP or {}
WestRP.Server = WestRP.Server or {}
WestRP.Server.Admin = WestRP.Server.Admin or {}
WestRP.Server.Admin.Players = {}

local frozenStates = {}

---Retorna a lista de todos os jogadores online estruturada para tabelas NUI
---@param filter? string
---@return table
function WestRP.Server.Admin.Players.GetList(filter)
    local players = GetPlayers()
    local list = {}

    for _, pId in ipairs(players) do
        local src = tonumber(pId)
        if src then
            local char = WestRP.Shared.Bridge.Player.GetCharacter(src)
            local steamName = GetPlayerName(src) or "Desconhecido"
            local charName = char and (char.firstname .. " " .. char.lastname) or "Sem Personagem"
            local ping = GetPlayerPing(src)
            local isDead = (char and char.isDead == true) or (Player(src).state.isDead == true)

            local staticId = char and char.charid or src
            local group = char and char.group or "user"
            local job = char and char.job or "unemployed"
            local jobGrade = char and char.jobGrade or 0
            local money = char and char.money or 0.0
            local gold = char and char.gold or 0.0

            local include = true
            if type(filter) == "string" and filter ~= "" and filter ~= "all" then
                local f = string.lower(filter)
                local matchId = tostring(src) == f
                local matchSteam = string.find(string.lower(steamName), f, 1, true) ~= nil
                local matchChar = string.find(string.lower(charName), f, 1, true) ~= nil
                include = matchId or matchSteam or matchChar
            end

            if include then
                list[#list + 1] = {
                    serverId  = src,
                    staticId  = staticId,
                    name      = steamName,
                    charName  = charName,
                    group     = group,
                    job       = job,
                    jobGrade  = jobGrade,
                    money     = money,
                    gold      = gold,
                    ping      = ping,
                    isDead    = isDead,
                    isFrozen  = frozenStates[src] == true
                }
            end
        end
    end

    table.sort(list, function(a, b)
        return a.serverId < b.serverId
    end)

    return list
end

---Teleporta o operador até o jogador alvo
---@param source number
---@param targetId number
function WestRP.Server.Admin.Players.GoTo(source, targetId)
    local targetPed = GetPlayerPed(targetId)
    if not DoesEntityExist(targetPed) then
        return WestRP.Shared.Bridge.Player.Notify(source, "Jogador alvo não existe ou desconectou", 4000)
    end

    local coords = GetEntityCoords(targetPed)
    TriggerClientEvent("westrp_admin:client:teleportToCoords", source, coords)
    WestRP.Server.Admin.Logger.Log("Teleport", "Teleporte Até Jogador (GoTo)", string.format("Operador teleportou até o jogador alvo em: %.2f, %.2f, %.2f", coords.x, coords.y, coords.z), source, targetId)
end

---Puxa o jogador alvo até o operador
---@param source number
---@param targetId number
function WestRP.Server.Admin.Players.Bring(source, targetId)
    local adminPed = GetPlayerPed(source)
    if not DoesEntityExist(adminPed) then return end

    local coords = GetEntityCoords(adminPed)
    TriggerClientEvent("westrp_admin:client:bringPlayer", targetId, coords)
    WestRP.Server.Admin.Logger.Log("Teleport", "Puxar Jogador (Bring)", string.format("Jogador alvo foi puxado para as coordenadas do operador: %.2f, %.2f, %.2f", coords.x, coords.y, coords.z), source, targetId)
end

---Alterna o congelamento do jogador alvo
---@param source number
---@param targetId number
function WestRP.Server.Admin.Players.ToggleFreeze(source, targetId)
    frozenStates[targetId] = not frozenStates[targetId]
    local state = frozenStates[targetId]
    TriggerClientEvent("westrp_admin:client:freeze", targetId, state)

    local msg = state and "Jogador foi congelado" or "Jogador foi descongelado"
    WestRP.Shared.Bridge.Player.Notify(source, msg, 3000)
    WestRP.Server.Admin.Logger.Log("General", "Congelamento de Jogador", msg, source, targetId)
    return state
end

---Cura a vida e os núcleos do jogador alvo
---@param source number
---@param targetId number
function WestRP.Server.Admin.Players.Heal(source, targetId)
    WestRP.Shared.Bridge.Player.Heal(targetId)
    WestRP.Shared.Bridge.Player.Notify(targetId, "Você foi curado por um administrador", 4000)
    WestRP.Shared.Bridge.Player.Notify(source, "Jogador curado com sucesso", 3000)
    WestRP.Server.Admin.Logger.Log("General", "Cura de Jogador", "Operador curou vida e núcleos do jogador alvo", source, targetId)
end

---Revive o jogador alvo caso esteja incapacitado/morto
---@param source number
---@param targetId number
function WestRP.Server.Admin.Players.Revive(source, targetId)
    WestRP.Shared.Bridge.Player.Revive(targetId)
    WestRP.Shared.Bridge.Player.Notify(targetId, "Você foi revivido por um administrador", 4000)
    WestRP.Shared.Bridge.Player.Notify(source, "Jogador revivido com sucesso", 3000)
    WestRP.Server.Admin.Logger.Log("General", "Reviver Jogador", "Operador reanimou o jogador alvo", source, targetId)
end

---Força respawn limpo do jogador com transição de tela
---@param source number
---@param targetId number
function WestRP.Server.Admin.Players.Respawn(source, targetId)
    WestRP.Shared.Bridge.Player.Respawn(targetId)
    TriggerClientEvent("westrp_admin:client:respawn", targetId)
    WestRP.Shared.Bridge.Player.Notify(source, "Respawn disparado no jogador alvo", 3000)
    WestRP.Server.Admin.Logger.Log("General", "Respawn de Jogador", "Operador disparou respawn forçado no alvo", source, targetId)
end

---Expulsa o jogador alvo do servidor
---@param source number
---@param targetId number
---@param reason? string
function WestRP.Server.Admin.Players.Kick(source, targetId, reason)
    local kickReason = reason and reason ~= "" and reason or "Expulso pela administração do servidor."
    local targetName = GetPlayerName(targetId) or "Jogador"

    WestRP.Server.Admin.Logger.Log("Punish", "Expulsão de Jogador (Kick)", "Motivo: " .. kickReason, source, targetId)
    DropPlayer(targetId, "👢 WestRP • Você foi expulso do servidor.\nMotivo: " .. kickReason)
    WestRP.Shared.Bridge.Player.Notify(source, "Jogador " .. targetName .. " foi expulso com sucesso", 4000)
end

---Define o emprego e graduação do jogador
---@param source number
---@param targetId number
---@param job string
---@param grade number
---@param label? string
function WestRP.Server.Admin.Players.SetJob(source, targetId, job, grade, label)
    local jobLabel = label or job
    local success = WestRP.Shared.Bridge.Player.SetJob(targetId, job, grade, jobLabel)
    if not success then return end

    WestRP.Shared.Bridge.Player.Notify(targetId, string.format("Seu emprego foi alterado para: %s (Grau %s)", jobLabel, grade), 5000)
    WestRP.Shared.Bridge.Player.Notify(source, string.format("Emprego de ID %s alterado para %s [%s]", targetId, job, grade), 4000)
    WestRP.Server.Admin.Logger.Log("General", "Alteração de Emprego", string.format("Novo emprego: %s | Grau: %s | Rótulo: %s", job, grade, jobLabel), source, targetId)
end

---Define o grupo administrativo/permissão do jogador
---@param source number
---@param targetId number
---@param group string
function WestRP.Server.Admin.Players.SetGroup(source, targetId, group)
    local success = WestRP.Shared.Bridge.Player.SetGroup(targetId, group)
    if not success then return end

    WestRP.Shared.Bridge.Player.Notify(targetId, "Seu grupo administrativo foi alterado para: " .. group, 5000)
    WestRP.Shared.Bridge.Player.Notify(source, string.format("Grupo de ID %s alterado para %s", targetId, group), 4000)
    WestRP.Server.Admin.Logger.Log("General", "Alteração de Grupo", "Novo grupo concedido: " .. group, source, targetId)
end

---Inicia modo espectador sobre o jogador alvo
---@param source number
---@param targetId number
function WestRP.Server.Admin.Players.Spectate(source, targetId)
    local targetPed = GetPlayerPed(targetId)
    if not DoesEntityExist(targetPed) then return end

    local coords = GetEntityCoords(targetPed)
    TriggerClientEvent("westrp_admin:client:spectatePlayer", source, targetId, coords)
    WestRP.Server.Admin.Logger.Log("General", "Modo Espectador", "Operador iniciou observação no jogador alvo", source, targetId)
end

---Executa ações especiais de troll/pegadinha no jogador alvo
---@param source number
---@param targetId number
---@param trollType "lightning"|"fire"|"heaven"|"ragdoll"|"cuff"|"drunk"
function WestRP.Server.Admin.Players.Troll(source, targetId, trollType)
    local targetPed = GetPlayerPed(targetId)
    if not DoesEntityExist(targetPed) then return end

    if trollType == "lightning" then
        local c = GetEntityCoords(targetPed)
        TriggerClientEvent("westrp_admin:client:trollLightning", -1, c)
    elseif trollType == "fire" then
        TriggerClientEvent("westrp_admin:client:trollFire", targetId)
    elseif trollType == "heaven" then
        TriggerClientEvent("westrp_admin:client:trollHeaven", targetId)
    elseif trollType == "ragdoll" then
        TriggerClientEvent("westrp_admin:client:trollRagdoll", targetId)
    elseif trollType == "cuff" then
        TriggerClientEvent("westrp_admin:client:trollCuff", targetId)
    elseif trollType == "drunk" then
        TriggerClientEvent("westrp_admin:client:trollDrunk", targetId)
    end

    WestRP.Shared.Bridge.Player.Notify(source, "Ação '" .. trollType .. "' disparada com sucesso no alvo", 3000)
    WestRP.Server.Admin.Logger.Log("General", "Troll Administrativo", "Disparou efeito: " .. trollType, source, targetId)
end

AddEventHandler("playerDropped", function()
    local src = source
    if frozenStates[src] then
        frozenStates[src] = nil
    end
end)
