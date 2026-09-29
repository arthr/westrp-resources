WestRP = WestRP or {}
WestRP.Admin = WestRP.Admin or {}
WestRP.Admin.Panel = {}

local isPanelOpen = false

---Constrói os dados de linhas para a tabela de jogadores online
---@param playersList table
---@return table rows
local function BuildPlayerRows(playersList)
    local rows = {}
    for _, p in ipairs(playersList or {}) do
        local statusLabel = "VIVO"
        local statusType = "on"
        if p.isDead then
            statusLabel = "MORTO"
            statusType = "danger"
        elseif p.isFrozen then
            statusLabel = "CONGELADO"
            statusType = "off"
        end

        local groupType = "off"
        if p.group == "admin" or p.group == "root" then
            groupType = "gold"
        elseif p.group == "moderator" then
            groupType = "on"
        end

        rows[#rows + 1] = {
            id          = "p_" .. p.serverId,
            serverId    = p.serverId,
            staticId    = p.staticId,
            code        = "#" .. p.serverId,
            charName    = p.charName,
            steam       = p.name,
            jobDesc     = p.job .. " (" .. p.jobGrade .. ")",
            group       = string.upper(p.group),
            group_type  = groupType,
            cash        = string.format("$ %.2f", p.money or 0),
            status      = statusLabel,
            status_type = statusType,
            rawData     = p
        }
    end
    return rows
end

---Constrói os dados de linhas para a tabela de banimentos ativos
---@param bansList table
---@return table rows
local function BuildBanRows(bansList)
    local rows = {}
    for i, b in ipairs(bansList or {}) do
        rows[#rows + 1] = {
            id          = "ban_" .. i,
            identifier  = b.identifier,
            reason      = b.reason or "Banimento Administrativo",
            bannedUntil = b.bannedUntil or "Permanente",
            status      = b.isPermanent and "PERMANENTE" or "TEMPORÁRIO",
            status_type = b.isPermanent and "danger" or "gold",
            rawIdentifier = b.identifier
        }
    end
    return rows
end

local currentTarget = nil

---Obtém a posição configurada do dock salva no KVP local
---@return string
local function GetSavedDockPosition()
    local saved = GetResourceKvpString("westrp_admin:dock_position")
    if saved and saved ~= "" then
        return saved
    end
    return Config.DefaultDockPosition or "mid_left"
end

---Obtém as preferências de ações rápidas ativas salvas no KVP
---@return table<string, boolean>
local function GetSavedQuickActions()
    local raw = GetResourceKvpString("westrp_admin:quick_actions")
    if raw and raw ~= "" then
        local success, decoded = pcall(json.decode, raw)
        if success and type(decoded) == "table" then
            return decoded
        end
    end

    local defaults = {}
    for _, qa in ipairs(Config.QuickActions or {}) do
        defaults[qa.id] = qa.defaultEnabled ~= false
    end
    return defaults
end

---Abre modal de diálogo para teleporte até coordenadas manuais
function WestRP.Admin.Panel.TeleportCoordsDialog()
    WestRP.Admin.Panel.Close()
    Wait(100)
    WestRP.Client.UI.OpenDialog({
        id = "tp_coords_dialog",
        tag = "TELEPORTE",
        title = "TELEPORTAR PARA COORDENADAS",
        subtitle = "Insira as coordenadas tridimensionais (X, Y, Z)",
        submitLabel = "TELEPORTAR",
        fields = {
            { id = "coords", label = "Coordenadas (vector3)", placeholder = "ex: 1269.72, -6855.15, 43.16", required = true }
        },
        onSubmit = function(values)
            WestRP.Admin.Teleport.TeleportToCoords(values.coords)
        end,
        onCancel = function()
            Wait(100)
            WestRP.Admin.Panel.Open()
        end
    })
end

---Abre modal de diálogo para spawn de montaria
function WestRP.Admin.Panel.SpawnHorseDialog()
    WestRP.Admin.Panel.Close()
    Wait(100)
    WestRP.Client.UI.OpenDialog({
        id = "spawn_horse_dialog",
        tag = "SPAWNER",
        title = "SPAWNAR MONTARIA / CAVALO",
        subtitle = "Informe o modelo do cavalo (ex: a_c_horse_turkoman_gold)",
        submitLabel = "SPAWNAR",
        fields = {
            { id = "model", label = "Modelo do Cavalo", type = "text", placeholder = "a_c_horse_turkoman_gold", required = true }
        },
        onSubmit = function(values)
            local modelName = values.model or "a_c_horse_turkoman_gold"
            local modelHash = GetHashKey(modelName)
            RequestModel(modelHash)
            local timeout = 0
            while not HasModelLoaded(modelHash) and timeout < 50 do
                Wait(50)
                timeout = timeout + 1
            end
            local ped = PlayerPedId()
            local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.0, 0.0)
            local horse = CreatePed(modelHash, coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false, false, false)
            Citizen.InvokeNative(0x283978A15512B2FE, horse, true)
            SetModelAsNoLongerNeeded(modelHash)
            WestRP.Client.UI.ShowToast("SPAWNER", "Montaria criada com sucesso", "success")
            Wait(150)
            WestRP.Admin.Panel.Open()
        end,
        onCancel = function()
            Wait(100)
            WestRP.Admin.Panel.Open()
        end
    })
end

---Abre modal de diálogo para spawn de carroça
function WestRP.Admin.Panel.SpawnWagonDialog()
    WestRP.Admin.Panel.Close()
    Wait(100)
    WestRP.Client.UI.OpenDialog({
        id = "spawn_wagon_dialog",
        tag = "SPAWNER",
        title = "SPAWNAR VEÍCULO / CARROÇA",
        subtitle = "Informe o modelo da carroça (ex: coach2, wagon02x, cart01)",
        submitLabel = "SPAWNAR",
        fields = {
            { id = "model", label = "Modelo da Carroça", type = "text", placeholder = "coach2", required = true }
        },
        onSubmit = function(values)
            local modelName = values.model or "coach2"
            local modelHash = GetHashKey(modelName)
            RequestModel(modelHash)
            local timeout = 0
            while not HasModelLoaded(modelHash) and timeout < 50 do
                Wait(50)
                timeout = timeout + 1
            end
            local ped = PlayerPedId()
            local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 4.0, 0.0)
            local veh = CreateVehicle(modelHash, coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false, false, false)
            SetVehicleOnGroundProperly(veh)
            SetModelAsNoLongerNeeded(modelHash)
            WestRP.Client.UI.ShowToast("SPAWNER", "Carroça criada com sucesso", "success")
            Wait(150)
            WestRP.Admin.Panel.Open()
        end,
        onCancel = function()
            Wait(100)
            WestRP.Admin.Panel.Open()
        end
    })
end

---Abre modal de diálogo para confirmação de expulsão global
function WestRP.Admin.Panel.KickAllDialog()
    WestRP.Admin.Panel.Close()
    Wait(100)
    WestRP.Client.UI.OpenDialog({
        id = "kick_all_dialog",
        tag = "AÇÃO GLOBAL CRÍTICA",
        title = "EXPULSAR TODOS OS JOGADORES",
        subtitle = "Todos os jogadores conectados (exceto staff) serão desconectados do servidor",
        submitLabel = "CONFIRMAR EXPULSÃO",
        fields = {
            { id = "reason", label = "Motivo da Expulsão Global", type = "text", placeholder = "Manutenção emergencial do servidor", required = true }
        },
        onSubmit = function(values)
            TriggerServerEvent("westrp_admin:server:executeAction", { action = "kick_all", payload = { reason = values.reason } })
            Wait(200)
            WestRP.Admin.Panel.Open()
        end,
        onCancel = function()
            Wait(100)
            WestRP.Admin.Panel.Open()
        end
    })
end

---Abre modal de diálogo para comunicado global
function WestRP.Admin.Panel.AnnounceDialog()
    WestRP.Admin.Panel.Close()
    Wait(100)
    WestRP.Client.UI.OpenDialog({
        id = "announce_dialog",
        tag = "COMUNICADO GLOBAL",
        title = "ENVIAR ANÚNCIO NO SERVIDOR",
        subtitle = "Esta mensagem será exibida na tela e chat de todos os jogadores",
        submitLabel = "TRANSMITIR",
        fields = {
            { id = "message", label = "Mensagem do Anúncio", type = "textarea", placeholder = "Digite a mensagem do comunicado...", required = true }
        },
        onSubmit = function(values)
            if values and values.message and values.message ~= "" then
                TriggerServerEvent("westrp_admin:server:executeAction", { action = "announce", payload = { message = values.message } })
            end
            Wait(200)
            WestRP.Admin.Panel.Open()
        end,
        onCancel = function()
            Wait(100)
            WestRP.Admin.Panel.Open()
        end
    })
end

---Abre modal de diálogo para alterar o modelo do ped
function WestRP.Admin.Panel.SetModelDialog()
    WestRP.Admin.Panel.Close()
    Wait(100)
    WestRP.Client.UI.OpenDialog({
        id = "set_model_dialog",
        tag = "MODELO",
        title = "ALTERAR MODELO DO PERSONAGEM",
        subtitle = "Informe o nome do modelo (ex: cs_dutch, mp_female, player_zero)",
        submitLabel = "APLICAR",
        fields = {
            { id = "model", label = "Modelo do Ped", type = "text", placeholder = "cs_dutch", required = true }
        },
        onSubmit = function(values)
            local modelName = values.model
            if not modelName or modelName == "" then return end
            local modelHash = GetHashKey(modelName)
            if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
                WestRP.Client.UI.ShowToast("MODELO", "Modelo inválido ou inexistente", "danger")
                Wait(150)
                WestRP.Admin.Panel.Open()
                return
            end
            RequestModel(modelHash)
            local timeout = 0
            while not HasModelLoaded(modelHash) and timeout < 50 do
                Wait(50)
                timeout = timeout + 1
            end
            SetPlayerModel(PlayerId(), modelHash)
            SetModelAsNoLongerNeeded(modelHash)
            WestRP.Client.UI.ShowToast("MODELO", "Modelo alterado para: " .. modelName, "success")
            Wait(150)
            WestRP.Admin.Panel.Open()
        end,
        onCancel = function()
            Wait(100)
            WestRP.Admin.Panel.Open()
        end
    })
end

---Abre modal de diálogo para alterar a escala corporal do ped
function WestRP.Admin.Panel.SetScaleDialog()
    WestRP.Admin.Panel.Close()
    Wait(100)
    WestRP.Client.UI.OpenDialog({
        id = "set_scale_dialog",
        tag = "ESCALA",
        title = "DEFINIR ESCALA DO PERSONAGEM",
        subtitle = "Informe o multiplicador de escala (padrão: 1.0, mín: 0.2, máx: 3.0)",
        submitLabel = "APLICAR",
        fields = {
            { id = "scale", label = "Multiplicador de Escala", type = "number", placeholder = "1.0", required = true }
        },
        onSubmit = function(values)
            local scale = tonumber(values.scale) or 1.0
            scale = math.max(0.2, math.min(3.0, scale))
            local ped = PlayerPedId()
            SetPedScale(ped, scale)
            WestRP.Client.UI.ShowToast("ESCALA", string.format("Escala ajustada para: %.2fx", scale), "success")
            Wait(150)
            WestRP.Admin.Panel.Open()
        end,
        onCancel = function()
            Wait(100)
            WestRP.Admin.Panel.Open()
        end
    })
end

---Abre modal de diálogo para spawn de objeto / prop
function WestRP.Admin.Panel.SpawnObjectDialog()
    WestRP.Admin.Panel.Close()
    Wait(100)
    WestRP.Client.UI.OpenDialog({
        id = "spawn_object_dialog",
        tag = "SPAWNER",
        title = "SPAWNAR OBJETO / PROP",
        subtitle = "Informe o nome do modelo do prop (ex: p_campfire01x, p_chest01x)",
        submitLabel = "SPAWNAR",
        fields = {
            { id = "model", label = "Modelo do Prop", type = "text", placeholder = "p_campfire01x", required = true }
        },
        onSubmit = function(values)
            local modelName = values.model or "p_campfire01x"
            local modelHash = GetHashKey(modelName)
            RequestModel(modelHash)
            local timeout = 0
            while not HasModelLoaded(modelHash) and timeout < 50 do
                Wait(50)
                timeout = timeout + 1
            end
            local ped = PlayerPedId()
            local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, -0.5)
            local obj = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
            PlaceObjectOnGroundProperly(obj)
            SetEntityAsMissionEntity(obj, true, true)
            SetModelAsNoLongerNeeded(modelHash)
            WestRP.Client.UI.ShowToast("SPAWNER", "Objeto gerado com sucesso", "success")
            Wait(150)
            WestRP.Admin.Panel.Open()
        end,
        onCancel = function()
            Wait(100)
            WestRP.Admin.Panel.Open()
        end
    })
end

---Abre modal de diálogo para spawn de NPC (Ped)
function WestRP.Admin.Panel.SpawnPedDialog()
    WestRP.Admin.Panel.Close()
    Wait(100)
    WestRP.Client.UI.OpenDialog({
        id = "spawn_ped_dialog",
        tag = "SPAWNER",
        title = "SPAWNAR NPC / PED",
        subtitle = "Informe o modelo do ped (ex: cs_dutch, cs_micahbell, u_m_m_valsheriff_01)",
        submitLabel = "SPAWNAR",
        fields = {
            { id = "model", label = "Modelo do Ped", type = "text", placeholder = "cs_dutch", required = true }
        },
        onSubmit = function(values)
            local modelName = values.model or "cs_dutch"
            local modelHash = GetHashKey(modelName)
            RequestModel(modelHash)
            local timeout = 0
            while not HasModelLoaded(modelHash) and timeout < 50 do
                Wait(50)
                timeout = timeout + 1
            end
            local ped = PlayerPedId()
            local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.5, 0.0)
            local newPed = CreatePed(modelHash, coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false, false, false)
            SetEntityAsMissionEntity(newPed, true, true)
            SetModelAsNoLongerNeeded(modelHash)
            WestRP.Client.UI.ShowToast("SPAWNER", "Ped gerado com sucesso", "success")
            Wait(150)
            WestRP.Admin.Panel.Open()
        end,
        onCancel = function()
            Wait(100)
            WestRP.Admin.Panel.Open()
        end
    })
end

---Abre modal de confirmação para agendamento de reinicialização do servidor
function WestRP.Admin.Panel.StartRestartDialog()
    WestRP.Admin.Panel.Close()
    Wait(100)
    WestRP.Client.UI.OpenDialog({
        id = "start_restart_dialog",
        tag = "SERVIDOR",
        title = "AGENDAR REINICIALIZAÇÃO DO SERVIDOR",
        subtitle = "Defina o tempo de contagem regressiva em minutos para alertar os jogadores",
        submitLabel = "INICIAR RESTART",
        fields = {
            { id = "minutes", label = "Tempo em Minutos", type = "number", placeholder = "5", required = true }
        },
        onSubmit = function(values)
            local mins = tonumber(values.minutes) or 5
            mins = math.max(1, math.min(60, mins))
            TriggerServerEvent("westrp_admin:server:startRestart", mins)
            WestRP.Client.UI.ShowToast("SERVIDOR", string.format("Reinicialização agendada para daqui a %d minuto(s)", mins), "danger")
            Wait(150)
            WestRP.Admin.Panel.Open()
        end,
        onCancel = function()
            Wait(100)
            WestRP.Admin.Panel.Open()
        end
    })
end

---Executa ações clicadas diretamente na grade do Dashboard
---@param actId string
---@param tileData? table
function WestRP.Admin.Panel.ExecuteDashboardAction(actId, tileData)
    if not actId then return end

    -- TELEPORT
    if actId == "tp_waypoint" then
        WestRP.Admin.Teleport.TeleportToWaypoint()
    elseif actId == "tp_coords" then
        WestRP.Admin.Panel.TeleportCoordsDialog()
    elseif actId == "copy_coords" then
        WestRP.Admin.DevTools.CopyCoords("v3")

    -- SELF
    elseif actId == "godmode" then
        local st = WestRP.Admin.Boosters.ToggleGodMode()
        WestRP.Client.UI.ShowToast("MODO DEUS", st and "Invulnerabilidade Ativada" or "Invulnerabilidade Desativada", st and "success" or "info")
    elseif actId == "invis" then
        local st = WestRP.Admin.Boosters.ToggleInvis()
        WestRP.Client.UI.ShowToast("INVISIBILIDADE", st and "Invisibilidade Ativada" or "Invisibilidade Desativada", st and "success" or "info")
    elseif actId == "noclip" then
        local st = WestRP.Admin.Boosters.ToggleNoClip()
        WestRP.Client.UI.ShowToast("NOCLIP", st and "Modo Fantasma Ativado" or "Modo Fantasma Desativado", st and "success" or "info")
    elseif actId == "infiammo" then
        WestRP.Admin.Boosters.ToggleInfiniteAmmo()
    elseif actId == "goldencores" then
        local st = WestRP.Admin.Boosters.ToggleGoldenCores()
        WestRP.Client.UI.ShowToast("NÚCLEOS", st and "Núcleos Dourados Máximos" or "Núcleos Restaurados", st and "success" or "info")
    elseif actId == "superjump" then
        WestRP.Admin.Boosters.ToggleSuperJump()
    elseif actId == "kill" then
        WestRP.Admin.Boosters.KillSelf()
    elseif actId == "self_revive" then
        WestRP.Admin.Boosters.SelfRevive()
    elseif actId == "self_heal" then
        WestRP.Admin.Boosters.SelfHeal()
    elseif actId == "set_model" then
        WestRP.Admin.Panel.SetModelDialog()
    elseif actId == "set_scale" then
        WestRP.Admin.Panel.SetScaleDialog()
    elseif actId == "freecam" then
        WestRP.Admin.Boosters.ToggleFreecam()

    -- WORLD TOGGLES
    elseif actId == "show_names" then
        WestRP.Admin.DevTools.TogglePlayerNames()
    elseif actId == "show_blips" then
        WestRP.Admin.DevTools.TogglePlayerBlips()
    elseif actId == "dev_laser" then
        WestRP.Admin.DevTools.ToggleLaser()

    -- SPAWN
    elseif actId == "spawn_object" then
        WestRP.Admin.Panel.SpawnObjectDialog()
    elseif actId == "spawn_vehicle" then
        WestRP.Admin.Panel.SpawnWagonDialog()
    elseif actId == "spawn_ped" then
        WestRP.Admin.Panel.SpawnPedDialog()
    elseif actId == "spawn_horse" then
        WestRP.Admin.Panel.SpawnHorseDialog()

    -- ALL PLAYERS
    elseif actId == "kick_all" then
        WestRP.Admin.Panel.KickAllDialog()
    elseif actId == "bring_all" then
        TriggerServerEvent("westrp_admin:server:executeAction", { action = "bring_all" })
    elseif actId == "revive_all" then
        TriggerServerEvent("westrp_admin:server:executeAction", { action = "revive_all" })
    elseif actId == "heal_all" then
        TriggerServerEvent("westrp_admin:server:executeAction", { action = "heal_all" })

    -- SERVER
    elseif actId == "start_restart" then
        WestRP.Admin.Panel.StartRestartDialog()
    elseif actId == "cancel_restart" then
        TriggerServerEvent("westrp_admin:server:cancelRestart")
    elseif actId == "announce" then
        WestRP.Admin.Panel.AnnounceDialog()
    end
end

---Abre o Painel Central multimodal
---@param targetOverride? table { serverId: number, name: string }
function WestRP.Admin.Panel.Open(targetOverride)
    local myServerId = GetPlayerServerId(PlayerId())
    local myName = GetPlayerName(PlayerId())

    if targetOverride then
        currentTarget = targetOverride
    elseif not currentTarget then
        currentTarget = { serverId = myServerId, name = myName .. " (Você)" }
    end

    -- Carregamento de dados via RPC assíncrono
    local overview = WestRP.Client.Callback.TriggerAwait("westrp_admin:server:getServerOverview") or {}
    local players = WestRP.Client.Callback.TriggerAwait("westrp_admin:server:getPlayers", "all") or {}
    local catalog = WestRP.Client.Callback.TriggerAwait("westrp_admin:server:getItemsCatalog") or {}
    local bans = WestRP.Client.Callback.TriggerAwait("westrp_admin:server:getBansList") or {}
    local weapons = WestRP.Admin.DataWeapons or {}

    local playerRows = BuildPlayerRows(players)
    local banRows = BuildBanRows(bans)

    local targetDisplay = (currentTarget.serverId == myServerId) and "Você (Operador)" or string.format("%s [ID %s]", currentTarget.name, currentTarget.serverId)

    local bStates = WestRP.Admin.Boosters.GetStates()

    -- Grade de Ações Categorizadas do Dashboard (28 ações em 6 grupos fiéis à referência)
    local dashboardActionGroups = {
        {
            title = "TELEPORT",
            icon = "fas fa-map-marked-alt",
            actions = {
                { id = "tp_waypoint", label = "TP Waypoint", icon = "fas fa-map-pin", type = "action" },
                { id = "tp_coords", label = "TP Coords", icon = "fas fa-crosshairs", type = "action" },
                { id = "copy_coords", label = "Copy Coords", icon = "fas fa-copy", type = "action" }
            }
        },
        {
            title = "SELF",
            icon = "fas fa-user-shield",
            actions = {
                { id = "godmode", label = "God Mode", icon = "fas fa-shield-alt", type = "toggle", active = bStates.godmode },
                { id = "invis", label = "Invisible", icon = "fas fa-eye-slash", type = "toggle", active = bStates.invis },
                { id = "noclip", label = "Noclip", icon = "fas fa-ghost", type = "toggle", active = bStates.noclip },
                { id = "infiammo", label = "Inf. Ammo", icon = "fas fa-infinity", type = "toggle", active = bStates.infiammo },
                { id = "goldencores", label = "Golden Core", icon = "fas fa-star", type = "toggle", active = bStates.goldencores },
                { id = "superjump", label = "Super Jump", icon = "fas fa-arrow-circle-up", type = "toggle", active = bStates.superjump },
                { id = "kill", label = "Kill", icon = "fas fa-skull", type = "action" },
                { id = "self_revive", label = "Revive", icon = "fas fa-heartbeat", type = "action" },
                { id = "self_heal", label = "Heal", icon = "fas fa-medkit", type = "action" },
                { id = "set_model", label = "Set Model", icon = "fas fa-user-edit", type = "action" },
                { id = "set_scale", label = "Set Scale", icon = "fas fa-arrows-alt-v", type = "action" },
                { id = "freecam", label = "Freecam", icon = "fas fa-video", type = "toggle", active = bStates.freecam }
            }
        },
        {
            title = "WORLD TOGGLES",
            icon = "fas fa-globe-americas",
            actions = {
                { id = "show_names", label = "Show Names", icon = "fas fa-id-badge", type = "toggle", active = WestRP.Admin.DevTools.IsShowNamesActive() },
                { id = "show_blips", label = "Show Blips", icon = "fas fa-compass", type = "toggle", active = WestRP.Admin.DevTools.IsShowBlipsActive() },
                { id = "dev_laser", label = "Dev Laser", icon = "fas fa-crosshairs", type = "toggle", active = WestRP.Admin.DevTools.IsLaserActive() }
            }
        },
        {
            title = "SPAWN",
            icon = "fas fa-magic",
            actions = {
                { id = "spawn_object", label = "Spawn Object", icon = "fas fa-cube", type = "action" },
                { id = "spawn_vehicle", label = "Spawn Vehicle", icon = "fas fa-car", type = "action" },
                { id = "spawn_ped", label = "Spawn Ped", icon = "fas fa-user-plus", type = "action" },
                { id = "spawn_horse", label = "Spawn Horse", icon = "fas fa-horse-head", type = "action" }
            }
        },
        {
            title = "ALL PLAYERS",
            icon = "fas fa-users-cog",
            actions = {
                { id = "kick_all", label = "Kick All", icon = "fas fa-user-slash", type = "action" },
                { id = "bring_all", label = "Bring All", icon = "fas fa-magnet", type = "action" },
                { id = "revive_all", label = "Revive All", icon = "fas fa-heartbeat", type = "action" },
                { id = "heal_all", label = "Heal All", icon = "fas fa-plus-circle", type = "action" }
            }
        },
        {
            title = "SERVER",
            icon = "fas fa-server",
            actions = {
                { id = "start_restart", label = "Start Restart", icon = "fas fa-sync-alt", type = "action" },
                { id = "cancel_restart", label = "Cancel Restart", icon = "fas fa-ban", type = "action" },
                { id = "announce", label = "Announce", icon = "fas fa-bullhorn", type = "action" }
            }
        }
    }

    -- Lista de Ações Rápidas da Aba de Configurações
    local savedQuickActions = GetSavedQuickActions()
    local settingsQuickList = {}
    for _, qa in ipairs(Config.QuickActions or {}) do
        settingsQuickList[#settingsQuickList + 1] = {
            id = qa.id,
            label = qa.label,
            icon = qa.icon or "fas fa-bolt",
            category = qa.category or "Geral",
            enabled = savedQuickActions[qa.id] ~= false
        }
    end

    local panelSchema = {
        id = "admin_central_panel",
        title = "PAINEL ADMINISTRATIVO",
        tag = "WESTRP • DASHBOARD & GESTÃO",
        subtitle = string.format("Operador: %s [ID %s] • Alvo do Spawner: %s • Online: %s", myName, myServerId, targetDisplay, #players),
        ctaLabel = "EXECUTAR AÇÃO",
        brand = Config.Brand or { name = "WESTRP SERVER", badge = "ADMIN MENU" },
        operator = overview.operator or { name = myName, role = "Operador", onDuty = true },
        tabs = {
            -- Aba 1: Dashboard Principal
            {
                id = "dashboard_tab",
                label = "Dashboard",
                icon = "fas fa-tachometer-alt",
                viewType = "dashboard",
                stats = overview.stats or {
                    online = #players,
                    maxClients = 32,
                    uptime = "0h 05m",
                    peak24h = #players,
                    peakAllTime = #players
                },
                actionGroups = dashboardActionGroups
            },
            -- Aba 2: Jogadores Online (Table)
            {
                id = "players_tab",
                label = "Jogadores",
                icon = "fas fa-users",
                badge = tostring(#players),
                badgeType = "count-blue",
                viewType = "table",
                pageSize = 10,
                columns = {
                    { key = "code", label = "ID", width = "8%", align = "center" },
                    { key = "charName", label = "PERSONAGEM", width = "24%" },
                    { key = "steam", label = "STEAM", width = "18%" },
                    { key = "jobDesc", label = "EMPREGO / CARGO", width = "16%" },
                    { key = "group", label = "PERMISSÃO", width = "12%", align = "center", type = "pill" },
                    { key = "cash", label = "DINHEIRO", width = "11%", align = "right" },
                    { key = "status", label = "ESTADO", width = "11%", align = "center", type = "pill" }
                },
                rows = playerRows
            },
            -- Aba 3: Catálogo de Itens & Spawner (Grid)
            {
                id = "spawner_tab",
                label = "Item Spawner",
                icon = "fas fa-boxes",
                badge = "ITENS",
                badgeType = "count-orange",
                viewType = "grid",
                filterCategory = true,
                pageSize = 24,
                items = catalog
            },
            -- Aba 4: Catálogo de Armamento & Munições (Grid)
            {
                id = "weapons_tab",
                label = "Armamento",
                icon = "fas fa-shield-alt",
                badge = tostring(#weapons),
                badgeType = "count-orange",
                viewType = "grid",
                filterCategory = true,
                pageSize = 18,
                items = weapons
            },
            -- Aba 5: Banimentos Ativos (Table)
            {
                id = "bans_tab",
                label = "Punições & Bans",
                icon = "fas fa-gavel",
                badge = tostring(#banRows),
                badgeType = "count-blue",
                viewType = "table",
                pageSize = 10,
                columns = {
                    { key = "identifier", label = "IDENTIFICADOR (STEAM/LICENÇA)", width = "36%" },
                    { key = "reason", label = "MOTIVO DO BANIMENTO", width = "30%" },
                    { key = "bannedUntil", label = "VALIDADE / EXPIRAÇÃO", width = "20%" },
                    { key = "status", label = "TIPO", width = "14%", align = "center", type = "pill" }
                },
                rows = banRows
            },
            -- Aba 6: Configurações do Menu & Posição
            {
                id = "settings_tab",
                label = "Configurações",
                icon = "fas fa-cog",
                viewType = "settings",
                currentPosition = GetSavedDockPosition(),
                positions = {
                    { id = "top_left", label = "Top Left" },
                    { id = "top_right", label = "Top Right" },
                    { id = "mid_left", label = "Mid Left" },
                    { id = "mid_right", label = "Mid Right" },
                    { id = "bottom_left", label = "Bottom Left" },
                    { id = "bottom_right", label = "Bottom Right" }
                },
                quickActions = settingsQuickList
            }
        },
        onAction = function(action, item, tabId, qty, data)
            data = data or {}

            -- Ações da aba de Configurações
            if action == "set_menu_position" then
                local pos = data.position or (item and item.id)
                if pos then
                    SetResourceKvp("westrp_admin:dock_position", pos)
                    WestRP.Client.UI.ShowToast("PREFERÊNCIAS", "Posição do Hot Menu definida para: " .. pos, "success")
                end
                return
            elseif action == "toggle_quick_action" then
                local actId = data.actionId or (item and item.id)
                local enabled = data.enabled
                if actId then
                    local current = GetSavedQuickActions()
                    current[actId] = enabled
                    SetResourceKvp("westrp_admin:quick_actions", json.encode(current))
                    WestRP.Client.UI.ShowToast("AÇÕES RÁPIDAS", (enabled and "Ativado no Hot Menu: " or "Desativado do Hot Menu: ") .. actId, "info")
                end
                return
            elseif action == "toggle_duty" then
                local onDuty = data.onDuty
                local msg = onDuty and "Você entrou em serviço administrativo." or "Você saiu de serviço."
                WestRP.Client.UI.ShowToast("STATUS OPERADOR", msg, onDuty and "success" or "alert")
                TriggerServerEvent("westrp_admin:server:logBooster", "Plantão", msg)
                return
            elseif action == "dashboard_action" then
                local actId = data.actionId or (item and item.id)
                WestRP.Admin.Panel.ExecuteDashboardAction(actId, data.tileData or item)
                return
            end

            local count = tonumber(qty) or 1
            local destId = currentTarget and currentTarget.serverId or myServerId
            local destName = currentTarget and currentTarget.name or "Você mesmo"

            if tabId == "players_tab" then
                if action == "confirm" and item and item.serverId then
                    -- Abre menu contextual com as ações rápidas para o jogador selecionado
                    WestRP.Admin.Panel.OpenPlayerActionModal(item)
                end
            elseif tabId == "spawner_tab" then
                if action == "confirm" and item and item.id then
                    TriggerServerEvent("westrp_admin:server:executeAction", {
                        action = "give_item",
                        targetId = destId,
                        payload = {
                            item = item.id,
                            qty = count
                        }
                    })
                    WestRP.Client.UI.ShowToast("SPAWNER", string.format("Enviando %sx de '%s' para %s", count, item.title or item.id, destName), "success")
                end
            elseif tabId == "weapons_tab" then
                if action == "confirm" and item and item.id then
                    if item.isAmmo or string.sub(item.id, 1, 4) == "ammo" then
                        TriggerServerEvent("westrp_admin:server:executeAction", {
                            action = "give_item",
                            targetId = destId,
                            payload = {
                                item = item.id,
                                qty = count
                            }
                        })
                        WestRP.Client.UI.ShowToast("MUNIÇÃO", string.format("Enviando %sx de '%s' para %s", count, item.title or item.id, destName), "success")
                    else
                        TriggerServerEvent("westrp_admin:server:executeAction", {
                            action = "give_weapon",
                            targetId = destId,
                            payload = {
                                weapon = item.id
                            }
                        })
                        WestRP.Client.UI.ShowToast("ARMAMENTO", string.format("Enviando arma '%s' para %s", item.title or item.id, destName), "success")
                    end
                end
            elseif tabId == "bans_tab" then
                if action == "confirm" and item and item.rawIdentifier then
                    TriggerServerEvent("westrp_admin:server:executeAction", {
                        action = "unban",
                        payload = {
                            identifier = item.rawIdentifier
                        }
                    })
                    WestRP.Client.UI.ShowToast("PUNIÇÕES", "Solicitado desbanimento para: " .. item.rawIdentifier, "info")
                    Wait(400)
                    WestRP.Admin.Panel.Open()
                end
            end
        end,
        onClose = function()
            isPanelOpen = false
        end
    }

    WestRP.Client.UI.OpenPanel(panelSchema)
    isPanelOpen = true
end

---Fecha o painel central
function WestRP.Admin.Panel.Close()
    if isPanelOpen then
        WestRP.Client.UI.ClosePanel()
        isPanelOpen = false
    end
end

---Alterna a exibição do painel central
function WestRP.Admin.Panel.Toggle()
    if isPanelOpen then
        WestRP.Admin.Panel.Close()
    else
        WestRP.Admin.Panel.Open()
    end
end

---Abre menu modal de ações rápidas no jogador selecionado
---@param playerRow table
function WestRP.Admin.Panel.OpenPlayerActionModal(playerRow)
    local targetId = playerRow.serverId
    local targetName = playerRow.charName or playerRow.steam or ("ID " .. targetId)
    local myServerId = GetPlayerServerId(PlayerId())
    local preventPanelReopen = false

    WestRP.Admin.Panel.Close()
    Wait(200)

    local targetOptions = {
        {
            id = "inspect_inventory",
            label = "Inspecionar Inventário em Tempo Real",
            badge = "INSPEÇÃO",
            badgeType = "gold",
            description = "Visualiza todos os pertences, itens, ferramentas e armas do jogador com opção de confisco."
        },
        {
            id = "manage_currency",
            label = "Gestão Financeira & Moedas",
            badge = "FINANÇAS",
            badgeType = "gold",
            description = "Injeta, remove ou define saldos de Dinheiro, Ouro ou Rol com justificativa para auditoria."
        },
        {
            id = "set_as_spawner_target",
            label = "Definir como Alvo do Spawner",
            badge = "ALVO",
            badgeType = "gold",
            description = "Define " .. targetName .. " como destinatário para entrega de itens e armas no Spawner."
        }
    }

    if currentTarget and currentTarget.serverId ~= myServerId then
        targetOptions[#targetOptions + 1] = {
            id = "reset_spawner_target",
            label = "Redefinir Alvo para Mim Mesmo",
            badge = "EU",
            badgeType = "off",
            description = "Retorna o destinatário do Spawner para o seu próprio personagem."
        }
    end

    targetOptions[#targetOptions + 1] = {
        id = "clear_inventory",
        label = "Limpar Todo Inventário (Wipe)",
        badge = "WIPE",
        badgeType = "danger",
        danger = true,
        description = "Remove todos os itens, armas e munições da bolsa deste jogador."
    }

    -- Abre o dock lateral focado exclusivamente no jogador selecionado
    WestRP.Client.UI.OpenDock({
        id = "player_action_dock",
        title = "AÇÕES NO JOGADOR",
        tag = string.format("ALVO: %s [ID %s]", string.upper(targetName), targetId),
        keepInput = true,
        tabs = {
            {
                id = "spawner_targets",
                name = "SPAWNER & ITENS",
                items = targetOptions
            },
            {
                id = "teleport_actions",
                name = "DESLOCAMENTO",
                items = {
                    { id = "goto", label = "Teleportar Até Ele (GoTo)", badge = "IR", badgeType = "gold", description = "Leva o operador instantaneamente até as coordenadas do alvo." },
                    { id = "bring", label = "Puxar Para Mim (Bring)", badge = "PUXAR", badgeType = "gold", description = "Teleporta o jogador alvo diretamente para a sua posição." },
                    { id = "spectate", label = "Modo Espectador", badge = "CÂMERA", badgeType = "gold", description = "Observa a visão e movimentação do jogador sem ser notado." }
                }
            },
            {
                id = "health_actions",
                name = "SAÚDE & CONTROLE",
                items = {
                    { id = "heal", label = "Curar Jogador", badge = "CURAR", badgeType = "gold", description = "Restaura 100% da vida e estamina do jogador." },
                    { id = "revive", label = "Reviver Jogador", badge = "REANIMAR", badgeType = "danger", description = "Revive o jogador caso esteja morto ou em coma." },
                    { id = "respawn", label = "Forçar Respawn Limpo", badge = "RESPAWN", badgeType = "danger", description = "Aplica fade de tela e reanima o jogador no local." },
                    { id = "freeze", label = "Alternar Congelamento", badge = "CONGELAR", badgeType = "off", description = "Trava ou destrava a movimentação do ped do jogador." }
                }
            },
            {
                id = "punish_actions",
                name = "PUNIÇÕES",
                items = {
                    { id = "kick", label = "Expulsar do Servidor (Kick)", badge = "KICK", badgeType = "danger", danger = true, description = "Desconecta o jogador da sessão atual." },
                    { id = "ban_3d", label = "Banir por 3 Dias", badge = "3 DIAS", badgeType = "danger", danger = true, description = "Aplica banimento de 72 horas no identificador." },
                    { id = "ban_perm", label = "Banir Permanentemente", badge = "PERMA", badgeType = "danger", danger = true, description = "Aplica banimento vitalício no servidor." }
                }
            },
            {
                id = "troll_actions",
                name = "TROLAGENS",
                items = {
                    { id = "troll_lightning", label = "Raio dos Céus", badge = "RAIO", badgeType = "gold", description = "Dispara relâmpago violento em cima do jogador." },
                    { id = "troll_fire", label = "Colocar em Chamas", badge = "FOGO", badgeType = "danger", description = "Incendeia o ped do jogador temporariamente." },
                    { id = "troll_heaven", label = "Enviar para o Céu", badge = "VOAR", badgeType = "gold", description = "Teleporta o jogador 180 metros para cima." },
                    { id = "troll_ragdoll", label = "Derrubar no Chão (Ragdoll)", badge = "QUEDA", badgeType = "off", description = "Faz o personagem tropeçar e cair sem controle." },
                    { id = "troll_cuff", label = "Algemar / Desalgemar", badge = "ALGEMAS", badgeType = "off", description = "Trava os pulsos do personagem com algemas de ferro." },
                    { id = "troll_drunk", label = "Efeito Embriaguez e Pântano", badge = "BÊBADO", badgeType = "gold", description = "Aplica distorção de tela psicodélica de pântano no jogador." }
                }
            }
        },
        onSelect = function(item, tabId)
            if item.id == "inspect_inventory" then
                preventPanelReopen = true
                WestRP.Admin.Panel.OpenInventoryInspector(targetId, targetName)
                return
            elseif item.id == "manage_currency" then
                preventPanelReopen = true
                WestRP.Admin.Panel.OpenCurrencyDialog(targetId, targetName, playerRow)
                return
            elseif item.id == "set_as_spawner_target" then
                preventPanelReopen = true
                WestRP.Client.UI.CloseDock()
                Wait(150)
                WestRP.Admin.Panel.Open({ serverId = targetId, name = targetName })
                WestRP.Client.UI.ShowToast("SPAWNER", "Alvo selecionado: " .. targetName, "info")
                return
            elseif item.id == "reset_spawner_target" then
                preventPanelReopen = true
                local myName = GetPlayerName(PlayerId())
                WestRP.Client.UI.CloseDock()
                Wait(150)
                WestRP.Admin.Panel.Open({ serverId = myServerId, name = myName .. " (Você)" })
                WestRP.Client.UI.ShowToast("SPAWNER", "Alvo redefinido para você mesmo", "info")
                return
            elseif item.id == "clear_inventory" then
                TriggerServerEvent("westrp_admin:server:executeAction", { action = "clear_inventory", targetId = targetId })
            elseif item.id == "goto" then
                TriggerServerEvent("westrp_admin:server:executeAction", { action = "goto", targetId = targetId })
            elseif item.id == "bring" then
                TriggerServerEvent("westrp_admin:server:executeAction", { action = "bring", targetId = targetId })
            elseif item.id == "spectate" then
                TriggerServerEvent("westrp_admin:server:executeAction", { action = "spectate", targetId = targetId })
            elseif item.id == "heal" then
                TriggerServerEvent("westrp_admin:server:executeAction", { action = "heal", targetId = targetId })
            elseif item.id == "revive" then
                TriggerServerEvent("westrp_admin:server:executeAction", { action = "revive", targetId = targetId })
            elseif item.id == "respawn" then
                TriggerServerEvent("westrp_admin:server:executeAction", { action = "respawn", targetId = targetId })
            elseif item.id == "freeze" then
                TriggerServerEvent("westrp_admin:server:executeAction", { action = "freeze", targetId = targetId })
            elseif item.id == "kick" then
                TriggerServerEvent("westrp_admin:server:executeAction", { action = "kick", targetId = targetId, payload = { reason = "Expulso pelo menu administrativo" } })
                WestRP.Client.UI.CloseDock()
            elseif item.id == "ban_3d" then
                TriggerServerEvent("westrp_admin:server:executeAction", { action = "ban", targetId = targetId, payload = { duration = "3d", reason = "Banimento de 3 dias via painel" } })
                WestRP.Client.UI.CloseDock()
            elseif item.id == "ban_perm" then
                TriggerServerEvent("westrp_admin:server:executeAction", { action = "ban", targetId = targetId, payload = { duration = "0", reason = "Banimento permanente via painel" } })
                WestRP.Client.UI.CloseDock()
            elseif string.sub(item.id, 1, 6) == "troll_" then
                local tType = string.sub(item.id, 7)
                TriggerServerEvent("westrp_admin:server:executeAction", { action = "troll", targetId = targetId, payload = { trollType = tType } })
            end
        end,
        onClose = function()
            -- Ao fechar o menu de ações do player, reabre a mesa de trabalho central
            if not preventPanelReopen then
                Wait(150)
                WestRP.Admin.Panel.Open()
            end
        end
    })
end

---Abre modal de diálogo tipado para injeção ou remoção de moedas
---@param targetId number
---@param targetName string
---@param playerRow table
function WestRP.Admin.Panel.OpenCurrencyDialog(targetId, targetName, playerRow)
    local curMoney = playerRow and playerRow.money or 0.0
    local curGold = playerRow and playerRow.gold or 0.0

    WestRP.Client.UI.CloseDock()
    Wait(100)

    local OpenDialogFn = (WestRP.Client and WestRP.Client.UI and WestRP.Client.UI.OpenDialog)
        or function(opts) return exports['westrp_ui']:OpenDialog(opts) end

    OpenDialogFn({
        id = "currency_modal_" .. targetId,
        tag = "GESTOR FINANCEIRO & ECONÔMICO",
        title = "INJETAR / RETIRAR MOEDA",
        subtitle = string.format("Alvo: %s [ID %s] • Saldo Atual: $ %.2f | Ouro: %.2f", targetName, targetId, curMoney, curGold),
        submitLabel = "CONFIRMAR TRANSAÇÃO",
        cancelLabel = "CANCELAR",
        fields = {
            {
                id = "currencyType",
                label = "Tipo de Moeda",
                type = "select",
                options = {
                    { value = "cash", label = "Dinheiro Comum ($ Cash)", selected = true },
                    { value = "gold", label = "Barras de Ouro (Gold)" },
                    { value = "rol", label = "Fichas de Rol (Roleplay)" }
                },
                required = true
            },
            {
                id = "operation",
                label = "Operação Pretendida",
                type = "select",
                options = {
                    { value = "add", label = "Adicionar (+) ao Saldo", selected = true },
                    { value = "remove", label = "Remover (-) do Saldo" },
                    { value = "set", label = "Definir Saldo Exato (=)" }
                },
                required = true
            },
            {
                id = "amount",
                label = "Quantia / Valor Numérico",
                type = "number",
                min = 0.01,
                step = 0.01,
                placeholder = "Ex: 100.00",
                required = true
            },
            {
                id = "reason",
                label = "Justificativa / Motivo da Transação",
                type = "text",
                placeholder = "Ex: Reembolso de bug, premiação ou moderação",
                required = true
            }
        },
        onSubmit = function(values)
            local amount = tonumber(values.amount)
            if not amount or amount <= 0 then
                WestRP.Client.UI.ShowToast("FINANÇAS", "Valor numérico inválido!", "alert")
                return
            end
            if not values.reason or string.len(values.reason) < 3 then
                WestRP.Client.UI.ShowToast("FINANÇAS", "Justificativa obrigatória (mínimo 3 caracteres)!", "alert")
                return
            end

            TriggerServerEvent("westrp_admin:server:executeAction", {
                action = "modify_currency",
                targetId = targetId,
                payload = {
                    currencyType = values.currencyType or "cash",
                    operation = values.operation or "add",
                    amount = amount,
                    reason = values.reason
                }
            })
            Wait(250)
            WestRP.Admin.Panel.Open()
        end,
        onCancel = function()
            Wait(100)
            WestRP.Admin.Panel.Open()
        end
    })
end

---Abre o Inspetor de Inventário em Tempo Real para o jogador selecionado
---@param targetId number
---@param targetName string
function WestRP.Admin.Panel.OpenInventoryInspector(targetId, targetName)
    WestRP.Client.UI.CloseDock()
    WestRP.Client.UI.ShowToast("INSPEÇÃO", "Carregando inventário de " .. targetName .. "...", "info", 2000)

    WestRP.Client.Callback.Trigger("westrp_admin:server:getPlayerInventory", function(data)
        if not data or not data.ok then
            WestRP.Client.UI.ShowToast("INSPEÇÃO", data and data.message or "Falha ao consultar inventário do jogador!", "error")
            Wait(200)
            WestRP.Admin.Panel.Open()
            return
        end

        local char = data.character or {}
        local rawItems = data.items or {}
        local rawWeapons = data.weapons or {}

        -- Formata Itens para Grid Cards
        local formattedItems = {}
        for _, it in ipairs(rawItems) do
            local iconUrl = "nui://vorp_inventory/html/img/items/" .. (it.id or it.name) .. ".png"
            formattedItems[#formattedItems + 1] = {
                id = it.id or it.name,
                title = it.label or it.name,
                subtitle = string.format("Peso: %.2f kg", (it.weight or 0.1) * (it.count or 1)),
                category = it.type or "Geral",
                icon = iconUrl,
                badge = "x" .. tostring(it.count or 1),
                badgeType = "gold",
                stock = it.count or 1,
                rawItem = it
            }
        end

        -- Formata Armas para Grid Cards
        local formattedWeapons = {}
        for _, wp in ipairs(rawWeapons) do
            local iconUrl = "nui://vorp_inventory/html/img/items/" .. string.lower(wp.name or "") .. ".png"
            formattedWeapons[#formattedWeapons + 1] = {
                id = wp.name,
                weaponId = wp.weaponId,
                title = wp.label or wp.name,
                subtitle = string.format("Munição: %d cartuchos • Peso: %.2f kg", wp.ammo or 0, wp.weight or 1.0),
                category = "Armas Equipadas",
                icon = iconUrl,
                badge = "SERIAL: " .. (wp.serialNumber or tostring(wp.weaponId)),
                badgeType = "danger",
                rawWeapon = wp
            }
        end

        local inspectorSchema = {
            id = "inventory_inspector_" .. targetId,
            tag = "INSPEÇÃO EM TEMPO REAL",
            title = "PERTENCES DE " .. string.upper(targetName),
            subtitle = string.format("Dinheiro: $ %.2f • Ouro: %.2f • Rol: %.2f | Itens: %d • Armas: %d", char.money or 0, char.gold or 0, char.rol or 0, #formattedItems, #formattedWeapons),
            showSearch = true,
            tabs = {
                {
                    id = "inspector_items_tab",
                    label = "Bolsa de Itens (" .. #formattedItems .. ")",
                    icon = "fa-briefcase",
                    viewType = "grid",
                    filterCategory = true,
                    pageSize = 18,
                    ctaLabel = "CONFISCAR ITEM",
                    items = formattedItems
                },
                {
                    id = "inspector_weapons_tab",
                    label = "Armas Equipadas (" .. #formattedWeapons .. ")",
                    icon = "fa-gun",
                    viewType = "grid",
                    filterCategory = true,
                    pageSize = 18,
                    ctaLabel = "CONFISCAR ARMA",
                    items = formattedWeapons
                }
            },
            onAction = function(action, item, tabId, qty)
                if action == "confirm" and item then
                    local count = tonumber(qty) or 1
                    if tabId == "inspector_items_tab" then
                        TriggerServerEvent("westrp_admin:server:executeAction", {
                            action = "confiscate_item",
                            targetId = targetId,
                            payload = {
                                item = item.id,
                                qty = count,
                                reason = "Confisco via Inspetor de Inventário"
                            }
                        })
                        Wait(400)
                        -- Recarrega o inspetor atualizado em tempo real
                        WestRP.Admin.Panel.OpenInventoryInspector(targetId, targetName)
                    elseif tabId == "inspector_weapons_tab" then
                        TriggerServerEvent("westrp_admin:server:executeAction", {
                            action = "confiscate_weapon",
                            targetId = targetId,
                            payload = {
                                weaponId = item.weaponId,
                                weaponName = item.title or item.id,
                                reason = "Confisco via Inspetor de Inventário"
                            }
                        })
                        Wait(400)
                        -- Recarrega o inspetor atualizado em tempo real
                        WestRP.Admin.Panel.OpenInventoryInspector(targetId, targetName)
                    end
                end
            end,
            onClose = function()
                Wait(150)
                WestRP.Admin.Panel.Open()
            end
        }

        WestRP.Client.UI.OpenPanel(inspectorSchema)
    end, targetId)
end

