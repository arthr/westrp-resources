WestRP = WestRP or {}
WestRP.Admin = WestRP.Admin or {}
WestRP.Admin.Dock = {}

local isDockOpen = false

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

    -- Padrões da configuração caso o jogador ainda não tenha customizado
    local defaults = {}
    for _, qa in ipairs(Config.QuickActions or {}) do
        defaults[qa.id] = qa.defaultEnabled ~= false
    end
    return defaults
end

---Gera o esquema atualizado do menu lateral (Hot Menu)
---@return table
local function BuildDockSchema()
    local bStates = WestRP.Admin.Boosters.GetStates()
    local enabledActions = GetSavedQuickActions()
    local dockPosition = GetSavedDockPosition()

    local quickItems = {}

    -- Constrói itens baseados no catálogo de ações rápidas configuradas
    for _, qa in ipairs(Config.QuickActions or {}) do
        if enabledActions[qa.id] ~= false then
            local it = {
                id = qa.id,
                label = qa.label,
                sublabel = qa.sublabel,
                type = qa.type or "action",
                icon = qa.icon,
                category = qa.category or "general"
            }

            if qa.id == "noclip" then
                it.checked = bStates.noclip
                it.badge = bStates.noclip and "LIGADO" or "DESLIGADO"
                it.badgeType = bStates.noclip and "on" or "off"
            elseif qa.id == "godmode" then
                it.checked = bStates.godmode
                it.badge = bStates.godmode and "IMUNE" or "NORMAL"
                it.badgeType = bStates.godmode and "on" or "off"
            elseif qa.id == "invis" then
                it.checked = bStates.invis
                it.badge = bStates.invis and "OCULTO" or "VISÍVEL"
                it.badgeType = bStates.invis and "on" or "off"
            elseif qa.id == "goldencores" then
                it.checked = bStates.goldencores
                it.badge = bStates.goldencores and "MAX" or "PADRÃO"
                it.badgeType = bStates.goldencores and "gold" or "off"
            elseif qa.id == "infiammo" then
                it.checked = bStates.infiammo
                it.badge = bStates.infiammo and "ILIMITADO" or "NORMAL"
                it.badgeType = bStates.infiammo and "gold" or "off"
            elseif qa.id == "show_names" then
                local st = WestRP.Admin.DevTools.IsShowNamesActive and WestRP.Admin.DevTools.IsShowNamesActive() or false
                it.checked = st
                it.badge = st and "3D TAGS" or "DESLIGADO"
                it.badgeType = st and "on" or "off"
            elseif qa.id == "show_blips" then
                local st = WestRP.Admin.DevTools.IsShowBlipsActive and WestRP.Admin.DevTools.IsShowBlipsActive() or false
                it.checked = st
                it.badge = st and "RADAR" or "DESLIGADO"
                it.badgeType = st and "on" or "off"
            elseif qa.id == "freecam" then
                local st = bStates.freecam
                it.checked = st
                it.badge = st and "LIVRE" or "DESLIGADO"
                it.badgeType = st and "gold" or "off"
            elseif qa.id == "superjump" then
                local st = bStates.superjump
                it.checked = st
                it.badge = st and "ALTO" or "PADRÃO"
                it.badgeType = st and "gold" or "off"
            elseif qa.id == "autotpm" then
                local st = WestRP.Admin.Teleport.GetAutoTPMState and WestRP.Admin.Teleport.GetAutoTPMState() or false
                it.checked = st
                it.badge = st and "ATIVO" or "INATIVO"
                it.badgeType = st and "on" or "off"
            elseif qa.id == "dev_laser" then
                local st = WestRP.Admin.DevTools.IsLaserActive and WestRP.Admin.DevTools.IsLaserActive() or false
                it.checked = st
                it.badge = st and "SCAN 3D" or "DESLIGADO"
                it.badgeType = st and "gold" or "off"
            elseif qa.id == "tp_waypoint" then
                it.badge = "WAYPOINT"
                it.badgeType = "gold"
            elseif qa.id == "self_heal" then
                it.badge = "CURAR"
                it.badgeType = "gold"
            elseif qa.id == "self_revive" then
                it.badge = "REVIVER"
                it.badgeType = "danger"
                it.danger = true
            elseif qa.id == "clean_ped" then
                it.badge = "LIMPAR"
                it.badgeType = "gold"
            elseif qa.id == "copy_coords" then
                it.badge = "COPIAR"
                it.badgeType = "gold"
            elseif qa.id == "delete_object" then
                it.badge = "EXCLUIR"
                it.badgeType = "danger"
                it.danger = true
            elseif qa.id == "clear_area" then
                it.badge = "ÁREA"
                it.badgeType = "danger"
                it.danger = true
            end

            quickItems[#quickItems + 1] = it
        end
    end

    -- Adiciona sempre opção de abrir o painel completo
    quickItems[#quickItems + 1] = {
        id = "open_panel",
        label = "Abrir Painel Completo",
        sublabel = "Dashboard & Gestão Geral [ENTER]",
        badge = "PAINEL",
        badgeType = "gold",
        description = "Abre a mesa de comando central com indicadores do servidor, tabela de jogadores e catálogo."
    }

    return {
        id = "admin_dock",
        title = "QUICK ACTIONS",
        tag = "ADMIN SHORTCUTS",
        position = dockPosition,
        keepInput = true,
        tabs = {
            {
                id = "quick_actions",
                name = "AÇÕES RÁPIDAS",
                items = quickItems
            }
        },
        onSelect = function(item, tabId)
            if item.id == "self_heal" or item.id == "selfheal" then
                WestRP.Admin.Boosters.SelfHeal()
            elseif item.id == "self_revive" or item.id == "selfrevive" then
                WestRP.Admin.Boosters.SelfRevive()
            elseif item.id == "clean_ped" then
                WestRP.Admin.Boosters.CleanPed()
            elseif item.id == "clear_area" then
                WestRP.Admin.Boosters.ClearArea(50.0)
            elseif item.id == "tp_waypoint" or item.id == "tpm" then
                WestRP.Admin.Teleport.TeleportToWaypoint()
            elseif item.id == "goback" then
                WestRP.Admin.Teleport.GoBack()
            elseif item.id == "guarma" then
                WestRP.Admin.Teleport.ToggleGuarma()
            elseif item.id == "copy_coords" or item.id == "copy_v3" then
                WestRP.Admin.DevTools.CopyCoords("v3")
            elseif item.id == "delete_object" or item.id == "del_object" then
                WestRP.Admin.DevTools.DeleteClosestObject()
            elseif item.id == "open_panel" then
                WestRP.Admin.Dock.Close()
                Wait(150)
                WestRP.Admin.Panel.Open()
            end
        end,
        onChange = function(item, newVal, tabId)
            if item.id == "noclip" then
                local res = WestRP.Admin.Boosters.ToggleNoClip()
                WestRP.Client.UI.UpdateItem("noclip", { checked = res, badge = res and "LIGADO" or "DESLIGADO", badgeType = res and "on" or "off" })
            elseif item.id == "godmode" then
                local res = WestRP.Admin.Boosters.ToggleGodMode()
                WestRP.Client.UI.UpdateItem("godmode", { checked = res, badge = res and "IMUNE" or "NORMAL", badgeType = res and "on" or "off" })
            elseif item.id == "invis" then
                local res = WestRP.Admin.Boosters.ToggleInvis()
                WestRP.Client.UI.UpdateItem("invis", { checked = res, badge = res and "OCULTO" or "VISÍVEL", badgeType = res and "on" or "off" })
            elseif item.id == "goldencores" then
                local res = WestRP.Admin.Boosters.ToggleGoldenCores()
                WestRP.Client.UI.UpdateItem("goldencores", { checked = res, badge = res and "MAX" or "PADRÃO", badgeType = res and "gold" or "off" })
            elseif item.id == "infiammo" then
                local res = WestRP.Admin.Boosters.ToggleInfiniteAmmo()
                WestRP.Client.UI.UpdateItem("infiammo", { checked = res, badge = res and "ILIMITADO" or "NORMAL", badgeType = res and "gold" or "off" })
            elseif item.id == "superjump" then
                local res = WestRP.Admin.Boosters.ToggleSuperJump()
                WestRP.Client.UI.UpdateItem("superjump", { checked = res, badge = res and "ALTO" or "PADRÃO", badgeType = res and "gold" or "off" })
            elseif item.id == "freecam" then
                local res = WestRP.Admin.Boosters.ToggleFreecam()
                WestRP.Client.UI.UpdateItem("freecam", { checked = res, badge = res and "LIVRE" or "DESLIGADO", badgeType = res and "gold" or "off" })
            elseif item.id == "show_names" then
                local res = WestRP.Admin.DevTools.TogglePlayerNames()
                WestRP.Client.UI.UpdateItem("show_names", { checked = res, badge = res and "3D TAGS" or "DESLIGADO", badgeType = res and "on" or "off" })
            elseif item.id == "show_blips" then
                local res = WestRP.Admin.DevTools.TogglePlayerBlips()
                WestRP.Client.UI.UpdateItem("show_blips", { checked = res, badge = res and "RADAR" or "DESLIGADO", badgeType = res and "on" or "off" })
            elseif item.id == "autotpm" then
                local res = WestRP.Admin.Teleport.ToggleAutoTPM()
                WestRP.Client.UI.UpdateItem("autotpm", { checked = res, badge = res and "ATIVO" or "INATIVO", badgeType = res and "on" or "off" })
            elseif item.id == "dev_laser" or item.id == "devlaser" then
                local res = WestRP.Admin.DevTools.ToggleLaser()
                WestRP.Client.UI.UpdateItem(item.id, { checked = res, badge = res and "SCAN 3D" or "DESLIGADO", badgeType = res and "gold" or "off" })
            end
        end,
        onClose = function()
            isDockOpen = false
        end
    }
end

---Abre o menu lateral do dock
function WestRP.Admin.Dock.Open()
    local schema = BuildDockSchema()
    WestRP.Client.UI.OpenDock(schema)
    isDockOpen = true
end

---Fecha o menu lateral
function WestRP.Admin.Dock.Close()
    if isDockOpen then
        WestRP.Client.UI.CloseDock()
        isDockOpen = false
    end
end

---Alterna a exibição do menu lateral
function WestRP.Admin.Dock.Toggle()
    if isDockOpen then
        WestRP.Admin.Dock.Close()
    else
        WestRP.Admin.Dock.Open()
    end
end
