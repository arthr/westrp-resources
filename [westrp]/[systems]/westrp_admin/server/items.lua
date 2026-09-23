WestRP = WestRP or {}
WestRP.Server = WestRP.Server or {}
WestRP.Server.Admin = WestRP.Server.Admin or {}
WestRP.Server.Admin.Items = {}

local cachedCatalog = nil

---Retorna o catálogo completo de itens disponíveis no servidor
---@return table
function WestRP.Server.Admin.Items.GetCatalog()
    if cachedCatalog and #cachedCatalog > 0 then
        return cachedCatalog
    end

    local dbItems = MySQL.query.await("SELECT item, label, `limit`, can_remove, type FROM items ORDER BY label ASC", {})
    local catalog = {}

    if dbItems and #dbItems > 0 then
        for _, it in ipairs(dbItems) do
            catalog[#catalog + 1] = {
                id       = it.item,
                title    = it.label or it.item,
                subtitle = "Limite máx: " .. (it.limit or 10),
                category = it.type or "Geral",
                limit    = it.limit or 10
            }
        end
    else
        -- Fallback caso a tabela ainda não tenha sido consultada
        catalog = {
            { id = "consumable_apple", title = "Maçã Silvestre", subtitle = "Alimento fresco", limit = 10 },
            { id = "consumable_meat_cooked", title = "Carne Assada", subtitle = "Alimento nutritivo", limit = 10 },
            { id = "tool_resource_knife", title = "Faca de Caça", subtitle = "Utilitário", limit = 1 },
            { id = "lockpick", title = "Gazua", subtitle = "Ferramenta", limit = 5 }
        }
    end

    cachedCatalog = catalog
    return catalog
end

---Concede item ao inventário do jogador
---@param source number Operador
---@param targetId number Alvo
---@param itemName string
---@param qty number
function WestRP.Server.Admin.Items.GiveItem(source, targetId, itemName, qty)
    local count = tonumber(qty) or 1
    if count <= 0 then count = 1 end

    local success = WestRP.Shared.Bridge.Inventory.AddItem(targetId, itemName, count)
    local targetName = GetPlayerName(targetId) or "Jogador"

    if success then
        WestRP.Shared.Bridge.Player.Notify(targetId, string.format("Você recebeu %sx de %s de um administrador", count, itemName), 5000)
        WestRP.Shared.Bridge.Player.Notify(source, string.format("Entregue %sx de %s para %s com sucesso", count, itemName, targetName), 4000)
        WestRP.Server.Admin.Logger.Log("Spawner", "Concessão de Item", string.format("Item: `%s`\nQuantidade: %s", itemName, count), source, targetId)
    else
        WestRP.Shared.Bridge.Player.Notify(source, "Falha ao adicionar item: inventário cheio ou item inválido", 4000)
    end
end

---Concede arma ao jogador
---@param source number Operador
---@param targetId number Alvo
---@param weaponName string
function WestRP.Server.Admin.Items.GiveWeapon(source, targetId, weaponName)
    local success = WestRP.Shared.Bridge.Inventory.GiveWeapon(targetId, weaponName)
    local targetName = GetPlayerName(targetId) or "Jogador"

    if success then
        WestRP.Shared.Bridge.Player.Notify(targetId, "Você recebeu uma arma: " .. weaponName, 5000)
        WestRP.Shared.Bridge.Player.Notify(source, string.format("Arma %s entregue para %s", weaponName, targetName), 4000)
        WestRP.Server.Admin.Logger.Log("Spawner", "Concessão de Arma", "Arma: `" .. weaponName .. "`", source, targetId)
    else
        WestRP.Shared.Bridge.Player.Notify(source, "Falha ao conceder arma: inventário indisponível", 4000)
    end
end

---Concede moedas/dinheiro ao personagem do jogador
---@param source number
---@param targetId number
---@param currencyType 0|1|2|"cash"|"gold"|"rol"
---@param amount number
function WestRP.Server.Admin.Items.GiveCurrency(source, targetId, currencyType, amount)
    local val = tonumber(amount) or 0
    if val <= 0 then return end

    local label = "Dinheiro"
    if currencyType == 1 or currencyType == "gold" then
        label = "Ouro"
    elseif currencyType == 2 or currencyType == "rol" then
        label = "Rol"
    end

    local success = WestRP.Shared.Bridge.Player.AddMoney(targetId, currencyType, val)
    local targetName = GetPlayerName(targetId) or "Jogador"

    if success then
        WestRP.Shared.Bridge.Player.Notify(targetId, string.format("Você recebeu $ %.2f em %s da administração", val, label), 5000)
        WestRP.Shared.Bridge.Player.Notify(source, string.format("Adicionado $ %.2f em %s para %s", val, label, targetName), 4000)
        WestRP.Server.Admin.Logger.Log("Spawner", "Concessão de Moeda", string.format("Tipo: %s\nValor: $ %.2f", label, val), source, targetId)
    else
        WestRP.Shared.Bridge.Player.Notify(source, "Falha ao adicionar moeda ao personagem alvo", 4000)
    end
end

---Limpa todo o inventário (itens e armas) do jogador
---@param source number
---@param targetId number
function WestRP.Server.Admin.Items.ClearInventory(source, targetId)
    local targetName = GetPlayerName(targetId) or "Jogador"
    WestRP.Shared.Bridge.Inventory.ClearInventory(targetId)

    WestRP.Shared.Bridge.Player.Notify(targetId, "Seu inventário foi completamente esvaziado por um administrador", 5000)
    WestRP.Shared.Bridge.Player.Notify(source, "Inventário de " .. targetName .. " foi limpo com sucesso", 4000)
    WestRP.Server.Admin.Logger.Log("Spawner", "Limpeza de Inventário", "Todos os itens e armas foram removidos do jogador", source, targetId)
end

---Zera o saldo bancário e em dinheiro do personagem
---@param source number
---@param targetId number
function WestRP.Server.Admin.Items.ClearCurrency(source, targetId)
    local char = WestRP.Shared.Bridge.Player.GetCharacter(targetId)
    if not char then return end

    if char.money and char.money > 0 then
        WestRP.Shared.Bridge.Player.RemoveMoney(targetId, "cash", char.money)
    end
    if char.gold and char.gold > 0 then
        WestRP.Shared.Bridge.Player.RemoveMoney(targetId, "gold", char.gold)
    end

    local targetName = GetPlayerName(targetId) or "Jogador"
    WestRP.Shared.Bridge.Player.Notify(targetId, "Seu saldo de dinheiro e ouro foi zerado pela administração", 5000)
    WestRP.Shared.Bridge.Player.Notify(source, "Moedas de " .. targetName .. " foram zeradas com sucesso", 4000)
    WestRP.Server.Admin.Logger.Log("Spawner", "Limpeza de Saldo", "Dinheiro e ouro zerados", source, targetId)
end
