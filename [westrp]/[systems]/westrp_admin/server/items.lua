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

local DEFAULT_WEAPONS_CATALOG = {
    { id = "WEAPON_REVOLVER_CATTLEMAN", title = "Revólver Cattleman", subtitle = "Arma Curta • 6 tiros • Calibre .45", category = "Revólveres", icon = "nui://vorp_inventory/html/img/items/weapon_revolver_cattleman.png", badge = "REVÓLVER", badgeType = "gold" },
    { id = "WEAPON_REVOLVER_SCHOFIELD", title = "Revólver Schofield", subtitle = "Arma Curta • Precisão superior • Calibre .45", category = "Revólveres", icon = "nui://vorp_inventory/html/img/items/weapon_revolver_schofield.png", badge = "REVÓLVER", badgeType = "gold" },
    { id = "WEAPON_REVOLVER_DOUBLEACTION", title = "Revólver de Ação Dupla", subtitle = "Arma Curta • Alta cadência • 6 tiros", category = "Revólveres", icon = "nui://vorp_inventory/html/img/items/weapon_revolver_doubleaction.png", badge = "REVÓLVER", badgeType = "gold" },
    { id = "WEAPON_REVOLVER_LEMAT", title = "Revólver LeMat", subtitle = "Arma Curta • 9 balas + cano calibre 20", category = "Revólveres", icon = "nui://vorp_inventory/html/img/items/weapon_revolver_lemat.png", badge = "REVÓLVER", badgeType = "gold" },
    { id = "WEAPON_REVOLVER_NAVY", title = "Revólver Navy", subtitle = "Arma Curta • Poder de parada excepcional", category = "Revólveres", icon = "nui://vorp_inventory/html/img/items/weapon_revolver_navy.png", badge = "REVÓLVER", badgeType = "gold" },
    { id = "WEAPON_PISTOL_VOLCANIC", title = "Pistola Volcanic", subtitle = "Pistola de alavanca • Calibre pesado .50", category = "Pistolas", icon = "nui://vorp_inventory/html/img/items/weapon_pistol_volcanic.png", badge = "PISTOLA", badgeType = "gold" },
    { id = "WEAPON_PISTOL_SEMIAUTO", title = "Pistola Semi-Automática", subtitle = "Alta cadência • Carregador em pente", category = "Pistolas", icon = "nui://vorp_inventory/html/img/items/weapon_pistol_semiauto.png", badge = "PISTOLA", badgeType = "gold" },
    { id = "WEAPON_PISTOL_MAUSER", title = "Pistola Mauser", subtitle = "Pistola alemã • Pente com 10 projéteis", category = "Pistolas", icon = "nui://vorp_inventory/html/img/items/weapon_pistol_mauser.png", badge = "PISTOLA", badgeType = "gold" },
    { id = "WEAPON_PISTOL_M1899", title = "Pistola M1899", subtitle = "Tecnologia moderna • Recarga rápida", category = "Pistolas", icon = "nui://vorp_inventory/html/img/items/weapon_pistol_m1899.png", badge = "PISTOLA", badgeType = "gold" },
    { id = "WEAPON_REPEATER_CARBINE", title = "Carabina de Repetição", subtitle = "Repetidora de sela • 7 projéteis", category = "Repetidoras", icon = "nui://vorp_inventory/html/img/items/weapon_repeater_carbine.png", badge = "REPETIDORA", badgeType = "gold" },
    { id = "WEAPON_REPEATER_WINCHESTER", title = "Repetidora Lancaster", subtitle = "Winchester • 14 tiros • Versatilidade máxima", category = "Repetidoras", icon = "nui://vorp_inventory/html/img/items/weapon_repeater_winchester.png", badge = "REPETIDORA", badgeType = "gold" },
    { id = "WEAPON_REPEATER_HENRY", title = "Repetidora Litchfield", subtitle = "Henry • 16 tiros • Alto dano médio alcance", category = "Repetidoras", icon = "nui://vorp_inventory/html/img/items/weapon_repeater_henry.png", badge = "REPETIDORA", badgeType = "gold" },
    { id = "WEAPON_REPEATER_EVANS", title = "Repetidora Evans", subtitle = "Carregador tubular gigante • 26 tiros", category = "Repetidoras", icon = "nui://vorp_inventory/html/img/items/weapon_repeater_evans.png", badge = "REPETIDORA", badgeType = "gold" },
    { id = "WEAPON_RIFLE_SPRINGFIELD", title = "Rifle Springfield", subtitle = "Tiro único potente • Longo alcance", category = "Rifles", icon = "nui://vorp_inventory/html/img/items/weapon_rifle_springfield.png", badge = "RIFLE", badgeType = "gold" },
    { id = "WEAPON_RIFLE_BOLTACTION", title = "Rifle de Ferrolho", subtitle = "Bolt Action • 5 projéteis de alto impacto", category = "Rifles", icon = "nui://vorp_inventory/html/img/items/weapon_rifle_boltaction.png", badge = "RIFLE", badgeType = "gold" },
    { id = "WEAPON_RIFLE_VARMINT", title = "Rifle Antipragas (Varmint)", subtitle = "Calibre .22 • Caça pequena e precisão", category = "Rifles", icon = "nui://vorp_inventory/html/img/items/weapon_rifle_varmint.png", badge = "RIFLE", badgeType = "gold" },
    { id = "WEAPON_SNIPERRIFLE_ROLLINGBLOCK", title = "Rifle Rolling Block", subtitle = "Rifle de precisão com luneta", category = "Rifles", icon = "nui://vorp_inventory/html/img/items/weapon_sniperrifle_rollingblock.png", badge = "SNIPER", badgeType = "gold" },
    { id = "WEAPON_SNIPERRIFLE_CARCANO", title = "Rifle Carcano", subtitle = "Ferrolho com mira óptica • 6 tiros", category = "Rifles", icon = "nui://vorp_inventory/html/img/items/weapon_sniperrifle_carcano.png", badge = "SNIPER", badgeType = "gold" },
    { id = "WEAPON_RIFLE_ELEPHANT", title = "Rifle de Elefante (Nitro Express)", subtitle = "Calibre colossal duplo • Dano maciço", category = "Rifles", icon = "nui://vorp_inventory/html/img/items/weapon_rifle_elephant.png", badge = "RIFLE", badgeType = "danger" },
    { id = "WEAPON_SHOTGUN_DOUBLEBARREL", title = "Escopeta de Cano Duplo", subtitle = "Calibre 12 • Disparo duplo letal", category = "Escopetas", icon = "nui://vorp_inventory/html/img/items/weapon_shotgun_doublebarrel.png", badge = "ESCOPETA", badgeType = "gold" },
    { id = "WEAPON_SHOTGUN_PUMP", title = "Escopeta de Ação por Bomba", subtitle = "Pump Action • 5 cartuchos calibre 12", category = "Escopetas", icon = "nui://vorp_inventory/html/img/items/weapon_shotgun_pump.png", badge = "ESCOPETA", badgeType = "gold" },
    { id = "WEAPON_SHOTGUN_SAWEDOFF", title = "Escopeta de Cano Serrado", subtitle = "Arma secundária de coldre • Devastadora", category = "Escopetas", icon = "nui://vorp_inventory/html/img/items/weapon_shotgun_sawedoff.png", badge = "ESCOPETA", badgeType = "gold" },
    { id = "WEAPON_SHOTGUN_REPEATING", title = "Escopeta de Repetição", subtitle = "Alavanca de repetição • 6 tiros", category = "Escopetas", icon = "nui://vorp_inventory/html/img/items/weapon_shotgun_repeating.png", badge = "ESCOPETA", badgeType = "gold" },
    { id = "WEAPON_SHOTGUN_SEMIAUTO", title = "Escopeta Semi-Automática", subtitle = "Fogo contínuo rápido • Calibre 12", category = "Escopetas", icon = "nui://vorp_inventory/html/img/items/weapon_shotgun_semiauto.png", badge = "ESCOPETA", badgeType = "gold" },
    { id = "WEAPON_BOW", title = "Arco de Caça", subtitle = "Silencioso e letal para caça e combate", category = "Arcos & Laços", icon = "nui://vorp_inventory/html/img/items/weapon_bow.png", badge = "ARCO", badgeType = "gold" },
    { id = "WEAPON_BOW_IMPROVED", title = "Arco Aprimorado", subtitle = "Maior tração e menor consumo de estamina", category = "Arcos & Laços", icon = "nui://vorp_inventory/html/img/items/weapon_bow_improved.png", badge = "ARCO", badgeType = "gold" },
    { id = "WEAPON_LASSO", title = "Laço Tradicional", subtitle = "Corda para capturas e animais", category = "Arcos & Laços", icon = "nui://vorp_inventory/html/img/items/weapon_lasso.png", badge = "UTILITÁRIO", badgeType = "off" },
    { id = "WEAPON_LASSO_REINFORCED", title = "Laço Reforçado", subtitle = "Fibra trançada inquebrável para alvos fugitivos", category = "Arcos & Laços", icon = "nui://vorp_inventory/html/img/items/weapon_lasso_reinforced.png", badge = "UTILITÁRIO", badgeType = "gold" },
    { id = "WEAPON_MELEE_KNIFE", title = "Faca de Caça", subtitle = "Lâmina afiada multiuso e esfolamento", category = "Armas Brancas", icon = "nui://vorp_inventory/html/img/items/weapon_melee_knife.png", badge = "MELEE", badgeType = "off" },
    { id = "WEAPON_MELEE_KNIFE_JAWBONE", title = "Faca de Mandíbula", subtitle = "Artefato rústico talhado em ossos", category = "Armas Brancas", icon = "nui://vorp_inventory/html/img/items/weapon_melee_knife_jawbone.png", badge = "MELEE", badgeType = "gold" },
    { id = "WEAPON_MELEE_CLEAVER", title = "Cutelo de Açougueiro", subtitle = "Lâmina pesada de aço forjado", category = "Armas Brancas", icon = "nui://vorp_inventory/html/img/items/weapon_melee_cleaver.png", badge = "MELEE", badgeType = "gold" },
    { id = "WEAPON_MELEE_MACHETE", title = "Facão Machete", subtitle = "Lâmina longa para matagais e combate", category = "Armas Brancas", icon = "nui://vorp_inventory/html/img/items/weapon_melee_machete.png", badge = "MELEE", badgeType = "gold" },
    { id = "WEAPON_MELEE_HATCHET_HUNTER", title = "Machadinha de Caçador", subtitle = "Equilibrada para corte e arremesso", category = "Armas Brancas", icon = "nui://vorp_inventory/html/img/items/weapon_melee_hatchet_hunter.png", badge = "MELEE", badgeType = "gold" },
    { id = "WEAPON_THROWN_TOMAHAWK", title = "Tomahawk Indígena", subtitle = "Machadinha leve de arremesso veloz", category = "Armas Brancas", icon = "nui://vorp_inventory/html/img/items/weapon_thrown_tomahawk.png", badge = "ARREMESSO", badgeType = "gold" }
}

---Retorna o catálogo de armas disponíveis
---@return table
function WestRP.Server.Admin.Items.GetWeaponsCatalog()
    return DEFAULT_WEAPONS_CATALOG
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
