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
    local players = WestRP.Client.Callback.TriggerAwait("westrp_admin:server:getPlayers", "all") or {}
    local catalog = WestRP.Client.Callback.TriggerAwait("westrp_admin:server:getItemsCatalog") or {}
    local bans = WestRP.Client.Callback.TriggerAwait("westrp_admin:server:getBansList") or {}
    local weapons = WestRP.Admin.DataWeapons or {}

    local playerRows = BuildPlayerRows(players)
    local banRows = BuildBanRows(bans)

    local targetDisplay = (currentTarget.serverId == myServerId) and "Você (Operador)" or string.format("%s [ID %s]", currentTarget.name, currentTarget.serverId)

    local panelSchema = {
        id = "admin_central_panel",
        title = "MESA DE COMANDO & AUDITORIA",
        tag = "WESTRP • CENTRAL ADMINISTRATIVA",
        subtitle = string.format("Operador: %s [ID %s] • Alvo do Spawner: %s • Online: %s", myName, myServerId, targetDisplay, #players),
        ctaLabel = "EXECUTAR AÇÃO",
        tabs = {
            -- Aba 1: Jogadores Online (Table)
            {
                id = "players_tab",
                label = "Jogadores Online",
                badge = tostring(#players),
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
            -- Aba 2: Catálogo de Itens & Spawner (Grid)
            {
                id = "spawner_tab",
                label = "Item Spawner",
                badge = "ITENS",
                viewType = "grid",
                filterCategory = true,
                pageSize = 24,
                items = catalog
            },
            -- Aba 3: Catálogo de Armamento & Munições (Grid)
            {
                id = "weapons_tab",
                label = "Armamento & Munições",
                badge = tostring(#weapons),
                viewType = "grid",
                filterCategory = true,
                pageSize = 18,
                items = weapons
            },
            -- Aba 4: Banimentos Ativos (Table)
            {
                id = "bans_tab",
                label = "Punições & Bans",
                badge = tostring(#banRows),
                viewType = "table",
                pageSize = 10,
                columns = {
                    { key = "identifier", label = "IDENTIFICADOR (STEAM/LICENÇA)", width = "36%" },
                    { key = "reason", label = "MOTIVO DO BANIMENTO", width = "30%" },
                    { key = "bannedUntil", label = "VALIDADE / EXPIRAÇÃO", width = "20%" },
                    { key = "status", label = "TIPO", width = "14%", align = "center", type = "pill" }
                },
                rows = banRows
            }
        },
        onAction = function(action, item, tabId, qty)
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
                    -- Desbane o jogador selecionado na tabela
                    TriggerServerEvent("westrp_admin:server:executeAction", {
                        action = "unban",
                        payload = {
                            identifier = item.rawIdentifier
                        }
                    })
                    WestRP.Client.UI.ShowToast("PUNIÇÕES", "Solicitado desbanimento para: " .. item.rawIdentifier, "info")
                    Wait(400)
                    WestRP.Admin.Panel.Open() -- Recarrega a tabela de banimentos
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

    WestRP.Client.UI.OpenDialog({
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

