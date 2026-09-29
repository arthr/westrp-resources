-- ═══════════════════════════════════════════════════════════════════════════
-- rsm_stables — servidor (VORP + oxmysql)
-- O servidor é o dono de tudo o que vale algo: preço, vaga, dono do animal,
-- arreios comprados, vínculo e ferimentos. O cliente só pede; aqui se decide.
-- Cada personagem é lido do banco UMA vez e fica em memória enquanto está
-- no servidor; toda mudança grava na hora (nada se perde num crash).
-- ═══════════════════════════════════════════════════════════════════════════

local Core = exports.vorp_core:GetCore()

local function log(...)
    if Config.Debug then print("^3[rsm_stables]^0", ...) end
end

-- ── catálogo (montado uma vez a partir do config.lua) ──────────────────────

local Horse = {} -- modelo → { breed, coat, price, gold }
for _, breed in ipairs(Config.Breeds) do
    for _, c in ipairs(breed.coats) do
        Horse[c.model] = { breed = breed, coat = c.coat, price = c.price or breed.price, gold = c.gold or breed.gold }
    end
end

local Cart = {} -- modelo → carroça
for _, c in ipairs(Config.Carts) do Cart[c.model] = c end

local TackCat, TackStyle, TackByHash = {}, {}, {}
for _, cat in ipairs(Config.Tack) do
    TackCat[cat.id] = cat
    TackStyle[cat.id] = {}
    for _, style in ipairs(cat.styles) do
        TackStyle[cat.id][style.id] = style
        for variant, hash in ipairs(style.hashes) do
            TackByHash[hash & 0xFFFFFFFF] = { cat = cat.id, style = style.id, variant = variant }
        end
    end
end

-- Arreios no formato da interface (igual para todos os estábulos)
local TackPayload = {}
for _, cat in ipairs(Config.Tack) do
    local styles = {}
    for _, s in ipairs(cat.styles) do
        styles[#styles + 1] = { id = s.id, label = s.label, price = s.price, variants = #s.hashes }
    end
    TackPayload[#TackPayload + 1] = { id = cat.id, label = cat.label, art = cat.art, styles = styles }
end

-- O que cada estábulo vende: lista para a interface + conjunto para validar
local Shop, Stock = {}, {}
for idx, st in ipairs(Config.Stables) do
    local only = {}
    for _, m in ipairs(st.horses or {}) do only[m] = true end
    local horses, horseSet = {}, {}
    for _, breed in ipairs(Config.Breeds) do
        for _, c in ipairs(breed.coats) do
            if not st.horses or only[c.model] then
                local h = Horse[c.model]
                horses[#horses + 1] = {
                    model = c.model, breed = breed.label, coat = c.coat, cls = breed.class,
                    price = h.price, gold = h.gold, stats = breed.stats, capacity = breed.capacity,
                }
                horseSet[c.model] = true
            end
        end
    end
    local onlyCarts = {}
    for _, m in ipairs(st.carts or {}) do onlyCarts[m] = true end
    local carts, cartSet = {}, {}
    for _, c in ipairs(Config.Carts) do
        if not st.carts or onlyCarts[c.model] then
            carts[#carts + 1] = {
                model = c.model, label = c.label, cls = c.class, price = c.price,
                seats = c.seats, capacity = c.capacity, stats = c.stats,
            }
            cartSet[c.model] = true
        end
    end
    Shop[idx] = { horses = horses, carts = carts }
    Stock[idx] = { horse = horseSet, cart = cartSet }
end

local Limits = {
    horse = Config.Limits.horse,
    cart = Config.Limits.cart,
    name = { min = Config.Name.min, max = Config.Name.max },
    transferMax = Config.Transfer.maxPrice,
}

-- ── banco de dados ──────────────────────────────────────────────────────────

local ready = false

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rsm_stables_rides` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `charid` INT NOT NULL,
            `type` VARCHAR(8) NOT NULL,
            `model` VARCHAR(64) NOT NULL,
            `name` VARCHAR(40) NOT NULL,
            `active` TINYINT(1) NOT NULL DEFAULT 0,
            `xp` INT NOT NULL DEFAULT 0,
            `health` TINYINT UNSIGNED NOT NULL DEFAULT 100,
            `injured_until` INT UNSIGNED NOT NULL DEFAULT 0,
            `gear` TEXT NULL,
            `legacy_id` INT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `charid` (`charid`),
            UNIQUE KEY `legacy_id` (`legacy_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rsm_stables_tack` (
            `charid` INT NOT NULL,
            `item` VARCHAR(96) NOT NULL,
            PRIMARY KEY (`charid`, `item`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rsm_stables_offers` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `ride_id` INT UNSIGNED NOT NULL,
            `from_charid` INT NOT NULL,
            `from_name` VARCHAR(64) NOT NULL,
            `to_charid` INT NOT NULL,
            `price` INT NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `ride_id` (`ride_id`),
            KEY `to_charid` (`to_charid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rsm_stables_payouts` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `charid` INT NOT NULL,
            `amount` DECIMAL(12,2) NOT NULL,
            `note` VARCHAR(128) NULL,
            PRIMARY KEY (`id`),
            KEY `charid` (`charid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    ready = true
    log("banco pronto")

    -- propostas esquecidas somem sozinhas
    while true do
        MySQL.update.await("DELETE FROM rsm_stables_offers WHERE created_at < (NOW() - INTERVAL ? DAY)", { Config.Transfer.expireDays })
        Wait(60 * 60 * 1000)
    end
end)

local function waitReady()
    while not ready do Wait(100) end
end

-- ── utilidades ──────────────────────────────────────────────────────────────

local function u32(n)
    n = math.tointeger(math.floor(tonumber(n) or 0))
    return n and (n & 0xFFFFFFFF) or 0
end

local function isActive(v)
    return v == true or v == 1
end

-- gear no banco: { categoria = { style, variant } }; só entra o que o config conhece
local function decodeGear(raw)
    local gear = {}
    if type(raw) ~= "string" or raw == "" then return gear end
    local ok, t = pcall(json.decode, raw)
    if not ok or type(t) ~= "table" then return gear end
    for cat, g in pairs(t) do
        local styles = TackStyle[cat]
        local style = styles and type(g) == "table" and styles[g.style]
        local variant = style and math.tointeger(tonumber(g.variant))
        if variant and variant >= 1 and variant <= #style.hashes then
            gear[cat] = { style = style.id, variant = variant }
        end
    end
    return gear
end

local function rowToRide(r)
    return {
        id = r.id, type = r.type, model = r.model, name = r.name, active = isActive(r.active),
        xp = r.xp or 0, health = r.health or 100, injured = r.injured_until or 0, gear = decodeGear(r.gear),
    }
end

local RIDE_COLUMNS = "id, type, model, name, active, xp, health, injured_until, gear"

local function bondOf(xp)
    local levels = Config.Bond.levels
    local level = 0
    for i, need in ipairs(levels) do
        if xp >= need then level = i end
    end
    return level, levels[level + 1] or levels[#levels]
end

local function charOf(src)
    local user = Core.getUser(src)
    local char = user and user.getUsedCharacter
    if not char or not char.charIdentifier then return nil end
    return char
end

local function fullName(char)
    return ("%s %s"):format(char.firstname or "", char.lastname or ""):match("^%s*(.-)%s*$")
end

local function fmtMoney(v)
    return ("$%.2f"):format(v)
end

local function fmtClock(secs)
    secs = math.max(0, math.floor(secs))
    return ("%d:%02d"):format(secs // 60, secs % 60)
end

-- Nome dado pelo jogador: sem caracteres de controle nem de marcação
local function cleanName(raw)
    if type(raw) ~= "string" then return nil, "Escolha um nome." end
    local name = raw:gsub("[%c<>\"`\\{}%[%]]", "")
    name = name:gsub("%s+", " ")
    name = name:match("^%s*(.-)%s*$")
    local len = utf8.len(name)
    if not len then return nil, "O nome tem caracteres inválidos." end
    if len < Config.Name.min or len > Config.Name.max then
        return nil, ("Use de %d a %d letras."):format(Config.Name.min, Config.Name.max)
    end
    return name
end

-- ── notificações (Notify do rsm_nuikit, com o do VORP de reserva) ───────────

local kitWarned = false

local function notify(src, kind, title, body)
    local kit = Config.NuiKit
    if kit ~= "" and GetResourceState(kit) == "started" then
        local ok, err = pcall(function()
            exports[kit]:Notify(src, kind, title, body, 4500)
        end)
        if ok then return end
        if not kitWarned then
            kitWarned = true
            print(("^3[rsm_stables] %s está rodando mas o export Notify(target, kind, title, body, duration) falhou: %s. Usando a notificação do VORP.^0"):format(kit, tostring(err)))
        end
    end
    Core.NotifyRightTip(src, body and (title .. " · " .. body) or title, 4500)
end

-- ── cache por personagem ────────────────────────────────────────────────────

local Chars = {}   -- charid → { rides = { [id] = ride }, tack = { [chave] = true } }
local Loading = {}
local CharOfSrc = {} -- src → charid carregado

local function load(charid)
    waitReady()
    if Chars[charid] then return Chars[charid] end
    while Loading[charid] do Wait(25) end
    if Chars[charid] then return Chars[charid] end
    Loading[charid] = true

    local data = { rides = {}, tack = {} }
    local rows = MySQL.query.await(("SELECT %s FROM rsm_stables_rides WHERE charid = ? ORDER BY id"):format(RIDE_COLUMNS), { charid }) or {}
    local seenActive = {}
    for _, row in ipairs(rows) do
        local r = rowToRide(row)
        -- um só ativo por tipo (dados antigos podem ter mais de um)
        if r.active and seenActive[r.type] then r.active = false end
        if r.active then seenActive[r.type] = true end
        data.rides[r.id] = r
    end
    local items = MySQL.query.await("SELECT item FROM rsm_stables_tack WHERE charid = ?", { charid }) or {}
    for _, t in ipairs(items) do data.tack[t.item] = true end

    Chars[charid] = data
    Loading[charid] = nil
    return data
end

local function countOf(mine, kind)
    local n = 0
    for _, r in pairs(mine.rides) do
        if r.type == kind then n = n + 1 end
    end
    return n
end

local function activeOf(mine, kind)
    for _, r in pairs(mine.rides) do
        if r.type == kind and r.active then return r end
    end
end

-- Sem ativo daquele tipo, o mais antigo passa a ser o ativo
local function promote(mine, kind, charid)
    if activeOf(mine, kind) then return end
    local pick
    for _, r in pairs(mine.rides) do
        if r.type == kind and (not pick or r.id < pick.id) then pick = r end
    end
    if not pick then return end
    pick.active = true
    MySQL.update.await("UPDATE rsm_stables_rides SET active = (id = ?) WHERE charid = ? AND type = ?", { pick.id, charid, kind })
end

local function saveGear(r)
    MySQL.update.await("UPDATE rsm_stables_rides SET gear = ? WHERE id = ?", { json.encode(r.gear), r.id })
end

-- ── formato que a interface consome (o mesmo do mock.js) ────────────────────

local function ridePayload(r, now)
    local p = {
        id = r.id, type = r.type, name = r.name, model = r.model, active = r.active,
        health = r.health, injured = math.max(0, r.injured - now), gear = r.gear,
    }
    if r.type == "horse" then
        local h = Horse[r.model]
        local level, nextXp = bondOf(r.xp)
        p.breed = h and h.breed.label or "Cavalo"
        p.coat = h and h.coat or ""
        p.stats = h and h.breed.stats or {}
        p.capacity = h and h.breed.capacity or 0
        p.bond, p.xp, p.xpNext = level, r.xp, nextXp
    else
        local c = Cart[r.model]
        p.label = c and c.label or r.model
        p.seats = c and c.seats or 0
        p.capacity = c and c.capacity or 0
        p.stats = c and c.stats or {}
    end
    return p
end

local function ridesPayload(mine)
    local now, list = os.time(), {}
    for _, r in pairs(mine.rides) do list[#list + 1] = ridePayload(r, now) end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function tackPayload(mine)
    local list = {}
    for key in pairs(mine.tack) do list[#list + 1] = key end
    return list
end

local function playerPayload(src)
    local char = charOf(src)
    if not char then return nil end
    return { cash = char.money or 0, gold = char.gold or 0, name = fullName(char) }
end

local function incomingFor(charid)
    local rows = MySQL.query.await([[
        SELECT o.id, o.price, o.from_name, r.type, r.model, r.name, r.xp
        FROM rsm_stables_offers o JOIN rsm_stables_rides r ON r.id = o.ride_id
        WHERE o.to_charid = ? ORDER BY o.id
    ]], { charid }) or {}
    local list = {}
    for _, o in ipairs(rows) do
        local item = { id = o.id, type = o.type, model = o.model, rideName = o.name, from = o.from_name, price = o.price }
        if o.type == "horse" then
            local h = Horse[o.model]
            local level = bondOf(o.xp or 0)
            item.breed = h and h.breed.label or "Cavalo"
            item.coat = h and h.coat or ""
            item.bond = level
        else
            local c = Cart[o.model]
            item.breed = c and c.label or o.model
            item.coat = c and ("%d lugares"):format(c.seats) or ""
        end
        list[#list + 1] = item
    end
    return list
end

local function onlineChars(selfCharid)
    local list = {}
    for _, id in ipairs(GetPlayers()) do
        local char = charOf(tonumber(id))
        if char and char.charIdentifier ~= selfCharid then
            list[#list + 1] = { id = char.charIdentifier, name = fullName(char), online = true }
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- ── sessão no balcão ────────────────────────────────────────────────────────

local Session = {} -- src → índice do estábulo aberto
local Out = {}     -- src → { horse = { id, net }, cart = { id, net } } animais fora do estábulo
local Busy, Last, Called, BondTick = {}, {}, {}, {}

local function nearStable(src, idx)
    local st = Config.Stables[idx]
    if not st or not st.enabled then return false end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - st.npc.xyz) <= Config.Keeper.promptDistance + 6.0
end

-- Toda ação responde com "update": é isso que tira a interface do "aguardando"
local function reply(src, patch, focus)
    TriggerClientEvent("rsm_stables:client:update", src, patch or {}, focus)
end

local function fail(src, title, body)
    notify(src, "error", title, body)
    reply(src)
end

local function statePatch(src, mine, extra)
    local patch = extra or {}
    patch.rides = ridesPayload(mine)
    patch.ownedTack = tackPayload(mine)
    patch.player = playerPayload(src)
    return patch
end

-- Quem está com o estábulo aberto recebe a mudança na hora (ex.: proposta nova)
local function refreshOpen(src, charid, withIncoming)
    if not Session[src] then return end
    local mine = Chars[charid]
    if not mine then return end
    local extra = withIncoming and { incoming = incomingFor(charid) } or nil
    reply(src, statePatch(src, mine, extra))
end

-- Avisa o cliente dono que um animal mudou (nome, arreios) ou sumiu (nil)
local function gearHashes(r)
    local map = {}
    for cat, g in pairs(r.gear) do
        local style = TackStyle[cat] and TackStyle[cat][g.style]
        if style and style.hashes[g.variant] then map[cat] = style.hashes[g.variant] end
    end
    return map
end

local function spawnInfo(r)
    local level = bondOf(r.xp)
    return { id = r.id, type = r.type, model = r.model, name = r.name, gear = gearHashes(r), bond = level }
end

local function rideChanged(src, r, gone)
    local out = Out[src] and Out[src][r.type]
    if not out or out.id ~= r.id then return end
    if gone then Out[src][r.type] = nil end
    TriggerClientEvent("rsm_stables:client:rideChanged", src, r.type, r.id, not gone and spawnInfo(r) or nil)
end

local function invId(rideId)
    return "rsm_stables_" .. rideId
end

local Registered = {}

local function dropInventory(rideId)
    local id = invId(rideId)
    Registered[id] = nil
    local ok, err = pcall(function()
        exports.vorp_inventory:deleteCustomInventory(id)
    end)
    if not ok then log("deleteCustomInventory falhou", id, err) end
end

-- Apaga o animal de vez (libertado, morto de vez)
local function destroyRide(src, charid, mine, r)
    MySQL.update.await("DELETE FROM rsm_stables_offers WHERE ride_id = ?", { r.id })
    MySQL.update.await("DELETE FROM rsm_stables_rides WHERE id = ? AND charid = ?", { r.id, charid })
    mine.rides[r.id] = nil
    if r.active then promote(mine, r.type, charid) end
    dropInventory(r.id)
    rideChanged(src, r, true)
end

-- ── ações da interface ──────────────────────────────────────────────────────

local Actions = {}

local function rideOf(mine, id)
    return mine.rides[math.tointeger(tonumber(id)) or -1]
end

local function tackOf(data)
    local cat = TackCat[data.cat]
    local style = cat and TackStyle[cat.id][data.style]
    local variant = style and math.tointeger(tonumber(data.variant))
    if not variant or variant < 1 or variant > #style.hashes then return nil end
    return cat, style, variant
end

function Actions.buy(src, char, mine, data, idx)
    local kind = (data.type == "horse" or data.type == "cart") and data.type or nil
    local model = tostring(data.model or "")
    if not kind or not Stock[idx][kind][model] then
        return fail(src, "Indisponível", "Este estábulo não vende esse animal.")
    end
    local name, why = cleanName(data.name)
    if not name then return fail(src, "Nome inválido", why) end
    if countOf(mine, kind) >= Config.Limits[kind] then
        return fail(src, "Estábulo cheio", "Liberte um animal antes de comprar outro.")
    end

    local currency, price
    if data.currency == "gold" then
        price = kind == "horse" and Horse[model].gold or nil
        if not price then return fail(src, "Só em dólar", "Este animal não é vendido por ouro.") end
        if (char.gold or 0) < price then
            return fail(src, "Ouro insuficiente", ("O preço é %s de ouro."):format(price))
        end
        currency = 1
    else
        price = kind == "horse" and Horse[model].price or Cart[model].price
        if (char.money or 0) < price then
            return fail(src, "Dinheiro insuficiente", ("Faltam %s."):format(fmtMoney(price - (char.money or 0))))
        end
        currency = 0
    end

    char.removeCurrency(currency, price)
    local active = activeOf(mine, kind) == nil
    local id = MySQL.insert.await(
        "INSERT INTO rsm_stables_rides (charid, type, model, name, active) VALUES (?, ?, ?, ?, ?)",
        { char.charIdentifier, kind, model, name, active and 1 or 0 }
    )
    if not id then
        char.addCurrency(currency, price)
        return fail(src, "Não foi possível", "A compra não foi salva e o valor voltou para você.")
    end
    mine.rides[id] = { id = id, type = kind, model = model, name = name, active = active, xp = 0, health = 100, injured = 0, gear = {} }
    notify(src, "success", "Compra concluída", ("%s agora está no seu estábulo."):format(name))
    reply(src, statePatch(src, mine), id)
end

function Actions.setActive(src, char, mine, data)
    local r = rideOf(mine, data.id)
    if not r then return reply(src) end
    MySQL.update.await("UPDATE rsm_stables_rides SET active = (id = ?) WHERE charid = ? AND type = ?", { r.id, char.charIdentifier, r.type })
    for _, o in pairs(mine.rides) do
        if o.type == r.type then
            -- o que estava fora volta para o estábulo
            if o.active and o.id ~= r.id then rideChanged(src, o, true) end
            o.active = o.id == r.id
        end
    end
    notify(src, "success", "Animal ativo", ("%s atende quando você chamar."):format(r.name))
    reply(src, statePatch(src, mine))
end

function Actions.rename(src, char, mine, data)
    local r = rideOf(mine, data.id)
    if not r then return reply(src) end
    local name, why = cleanName(data.name)
    if not name then return fail(src, "Nome inválido", why) end
    MySQL.update.await("UPDATE rsm_stables_rides SET name = ? WHERE id = ? AND charid = ?", { name, r.id, char.charIdentifier })
    r.name = name
    -- o inventário registrado guarda o nome; registra de novo no próximo uso
    local id = invId(r.id)
    if Registered[id] then
        Registered[id] = nil
        pcall(function() exports.vorp_inventory:removeInventory(id) end)
    end
    rideChanged(src, r)
    notify(src, "info", "Nome alterado", ("Agora ele se chama %s."):format(name))
    reply(src, statePatch(src, mine))
end

function Actions.release(src, char, mine, data)
    local r = rideOf(mine, data.id)
    if not r then return reply(src) end
    destroyRide(src, char.charIdentifier, mine, r)
    notify(src, "warning", "Animal libertado", ("%s não pertence mais a você."):format(r.name))
    reply(src, statePatch(src, mine))
end

local function equip(src, mine, r, cat, style, variant)
    r.gear[cat.id] = { style = style.id, variant = variant }
    saveGear(r)
    rideChanged(src, r)
end

function Actions.tackBuy(src, char, mine, data)
    local r = rideOf(mine, data.id)
    local cat, style, variant = tackOf(data)
    if not r or r.type ~= "horse" or not cat then return reply(src) end
    local key = ("%s:%s:%d"):format(cat.id, style.id, variant)
    if mine.tack[key] or style.price <= 0 then
        equip(src, mine, r, cat, style, variant)
        return reply(src, statePatch(src, mine))
    end
    if (char.money or 0) < style.price then
        return fail(src, "Dinheiro insuficiente", ("Faltam %s."):format(fmtMoney(style.price - (char.money or 0))))
    end
    char.removeCurrency(0, style.price)
    local saved = MySQL.update.await("INSERT IGNORE INTO rsm_stables_tack (charid, item) VALUES (?, ?)", { char.charIdentifier, key })
    if not saved then
        char.addCurrency(0, style.price)
        return fail(src, "Não foi possível", "A compra não foi salva e o valor voltou para você.")
    end
    mine.tack[key] = true
    equip(src, mine, r, cat, style, variant)
    notify(src, "success", "Arreio comprado", ("%s equipado em %s."):format(style.label, r.name))
    reply(src, statePatch(src, mine))
end

function Actions.tackEquip(src, char, mine, data)
    local r = rideOf(mine, data.id)
    local cat, style, variant = tackOf(data)
    if not r or r.type ~= "horse" or not cat then return reply(src) end
    if style.price > 0 and not mine.tack[("%s:%s:%d"):format(cat.id, style.id, variant)] then
        return fail(src, "Arreio não comprado", "Compre esta peça antes de equipar.")
    end
    equip(src, mine, r, cat, style, variant)
    notify(src, "info", "Arreio equipado", ("%s em %s."):format(style.label, r.name))
    reply(src, statePatch(src, mine))
end

function Actions.tackRemove(src, char, mine, data)
    local r = rideOf(mine, data.id)
    if not r or not TackCat[data.cat] or not r.gear[data.cat] then return reply(src) end
    r.gear[data.cat] = nil
    saveGear(r)
    rideChanged(src, r)
    reply(src, statePatch(src, mine))
end

function Actions.tackRemoveAll(src, char, mine, data)
    local r = rideOf(mine, data.id)
    if not r then return reply(src) end
    r.gear = {}
    saveGear(r)
    rideChanged(src, r)
    notify(src, "info", "Arreios removidos", ("%s está sem equipamento."):format(r.name))
    reply(src, statePatch(src, mine))
end

function Actions.transferSend(src, char, mine, data)
    local r = rideOf(mine, data.id)
    local target = math.tointeger(tonumber(data.target))
    local price = math.tointeger(tonumber(data.price))
    if not r or not target or not price or price < 0 or price > Config.Transfer.maxPrice then return reply(src) end
    if target == char.charIdentifier then return fail(src, "Transferência", "Escolha outra pessoa.") end

    local tuser = Core.getUserByCharId(target)
    local tchar = tuser and tuser.getUsedCharacter
    if not tchar or tchar.charIdentifier ~= target then
        return fail(src, "Indisponível", "Essa pessoa não está na cidade agora.")
    end
    if MySQL.scalar.await("SELECT id FROM rsm_stables_offers WHERE ride_id = ?", { r.id }) then
        return fail(src, "Proposta pendente", "Já existe uma proposta aberta para este animal.")
    end
    local id = MySQL.insert.await(
        "INSERT INTO rsm_stables_offers (ride_id, from_charid, from_name, to_charid, price) VALUES (?, ?, ?, ?, ?)",
        { r.id, char.charIdentifier, fullName(char), target, price }
    )
    if not id then return fail(src, "Não foi possível", "A proposta não foi salva.") end

    local priceText = price > 0 and fmtMoney(price) or "presente"
    notify(src, "success", "Proposta enviada", ("%s recebeu a proposta por %s."):format(fullName(tchar), r.name))
    notify(tuser.source, "info", "Proposta de transferência",
        ("%s quer lhe passar %s (%s). Responda em qualquer estábulo."):format(fullName(char), r.name, priceText))
    refreshOpen(tuser.source, target, true)
    reply(src)
end

-- Paga quem vendeu; se estiver fora do servidor, recebe ao entrar
local function pay(charid, amount, note)
    local user = Core.getUserByCharId(charid)
    local char = user and user.getUsedCharacter
    if char and char.charIdentifier == charid then
        char.addCurrency(0, amount)
        return user.source
    end
    MySQL.insert.await("INSERT INTO rsm_stables_payouts (charid, amount, note) VALUES (?, ?, ?)", { charid, amount, note })
end

function Actions.transferAnswer(src, char, mine, data)
    local charid = char.charIdentifier
    local id = math.tointeger(tonumber(data.id))
    local offer = id and MySQL.single.await(
        "SELECT id, ride_id, from_charid, from_name, price FROM rsm_stables_offers WHERE id = ? AND to_charid = ?",
        { id, charid }
    )
    if not offer then return reply(src, { incoming = incomingFor(charid) }) end

    local seller = Core.getUserByCharId(offer.from_charid)
    local sellerChar = seller and seller.getUsedCharacter
    local sellerSrc = sellerChar and sellerChar.charIdentifier == offer.from_charid and seller.source or nil

    if data.accept ~= true then
        MySQL.update.await("DELETE FROM rsm_stables_offers WHERE id = ?", { offer.id })
        notify(src, "info", "Proposta recusada", ("%s foi avisado."):format(offer.from_name))
        if sellerSrc then notify(sellerSrc, "warning", "Proposta recusada", ("%s recusou a sua proposta."):format(fullName(char))) end
        return reply(src, { incoming = incomingFor(charid) })
    end

    local ride = MySQL.single.await("SELECT type, name FROM rsm_stables_rides WHERE id = ? AND charid = ?", { offer.ride_id, offer.from_charid })
    if not ride then
        MySQL.update.await("DELETE FROM rsm_stables_offers WHERE id = ?", { offer.id })
        notify(src, "error", "Proposta expirada", "O animal não está mais com quem ofereceu.")
        return reply(src, { incoming = incomingFor(charid) })
    end
    if countOf(mine, ride.type) >= Config.Limits[ride.type] then
        return fail(src, "Estábulo cheio", "Não há vaga para receber este animal.")
    end
    if (char.money or 0) < offer.price then
        return fail(src, "Dinheiro insuficiente", ("A proposta pede %s."):format(fmtMoney(offer.price)))
    end

    -- cobra antes de mover; se o animal não mudar de dono, devolve
    if offer.price > 0 then char.removeCurrency(0, offer.price) end
    local active = activeOf(mine, ride.type) == nil
    local moved = MySQL.update.await(
        "UPDATE rsm_stables_rides SET charid = ?, active = ?, gear = NULL WHERE id = ? AND charid = ?",
        { charid, active and 1 or 0, offer.ride_id, offer.from_charid }
    )
    MySQL.update.await("DELETE FROM rsm_stables_offers WHERE id = ?", { offer.id })
    if moved ~= 1 then
        if offer.price > 0 then char.addCurrency(0, offer.price) end
        notify(src, "error", "Proposta expirada", "O animal não está mais com quem ofereceu.")
        return reply(src, { incoming = incomingFor(charid) })
    end
    if offer.price > 0 then
        pay(offer.from_charid, offer.price, ("Venda de %s para %s"):format(ride.name, fullName(char)))
    end

    -- quem vendeu: tira do cache e recolhe o animal se estiver fora
    local sellerData = Chars[offer.from_charid]
    if sellerData then
        local old = sellerData.rides[offer.ride_id]
        sellerData.rides[offer.ride_id] = nil
        if old then
            if old.active then promote(sellerData, old.type, offer.from_charid) end
            if sellerSrc then rideChanged(sellerSrc, old, true) end
        end
    end
    if sellerSrc then
        local body = offer.price > 0 and ("%s pagou %s por %s."):format(fullName(char), fmtMoney(offer.price), ride.name)
            or ("%s aceitou %s."):format(fullName(char), ride.name)
        notify(sellerSrc, "success", "Transferência concluída", body)
        refreshOpen(sellerSrc, offer.from_charid, false)
    end

    local row = MySQL.single.await(("SELECT %s FROM rsm_stables_rides WHERE id = ?"):format(RIDE_COLUMNS), { offer.ride_id })
    if row then mine.rides[row.id] = rowToRide(row) end
    notify(src, "success", "Transferência aceita", ("%s agora é seu."):format(ride.name))
    reply(src, statePatch(src, mine, { incoming = incomingFor(charid) }), offer.ride_id)
end

-- Uma entrada só para todas as ações: sessão, distância e ritmo checados aqui
RegisterNetEvent("rsm_stables:action", function(name, data)
    local src = source
    local fn = Actions[name]
    if not fn or type(data) ~= "table" then return end
    local idx = Session[src]
    local t = GetGameTimer()
    if not idx or Busy[src] or (Last[src] and t - Last[src] < 250) then return reply(src) end
    Busy[src], Last[src] = true, t

    local char = charOf(src)
    if char and nearStable(src, idx) then
        CharOfSrc[src] = char.charIdentifier
        local ok, err = pcall(fn, src, char, load(char.charIdentifier), data, idx)
        if not ok then
            print(("^1[rsm_stables] erro em '%s': %s^0"):format(name, tostring(err)))
            reply(src)
        end
    else
        Session[src] = nil
        reply(src)
    end
    Busy[src] = nil
end)

-- ── abrir / fechar o balcão ─────────────────────────────────────────────────

RegisterNetEvent("rsm_stables:open", function(idx)
    local src = source
    idx = math.tointeger(tonumber(idx))
    local char = charOf(src)
    if not idx or not char or not nearStable(src, idx) then
        return TriggerClientEvent("rsm_stables:client:denied", src)
    end
    local charid = char.charIdentifier
    CharOfSrc[src] = charid
    local mine = load(charid)
    local st = Config.Stables[idx]
    Session[src] = idx
    TriggerClientEvent("rsm_stables:client:open", src, idx, {
        stable = { id = st.id, name = st.name, region = st.region, keeper = st.keeper or "Cavalariço" },
        player = playerPayload(src),
        limits = Limits,
        shop = Shop[idx],
        tack = TackPayload,
        rides = ridesPayload(mine),
        ownedTack = tackPayload(mine),
        incoming = incomingFor(charid),
        characters = onlineChars(charid),
    })
end)

RegisterNetEvent("rsm_stables:close", function()
    Session[source] = nil
end)

-- ── o animal no mundo ───────────────────────────────────────────────────────

local function outOf(src)
    Out[src] = Out[src] or {}
    return Out[src]
end

local function deleteNet(net)
    if not net then return end
    local ent = NetworkGetEntityFromNetworkId(net)
    if ent and ent ~= 0 and DoesEntityExist(ent) then DeleteEntity(ent) end
end

-- Chamar (assobio / carroça): o servidor confere dono, ferimento e ritmo
RegisterNetEvent("rsm_stables:call", function(kind)
    local src = source
    if kind ~= "horse" and kind ~= "cart" then return end
    local char = charOf(src)
    if not char then return end
    local key = src .. kind
    local t = GetGameTimer()
    if Called[key] and t - Called[key] < Config.Call.cooldownSeconds * 1000 then return end
    Called[key] = t

    CharOfSrc[src] = char.charIdentifier
    local mine = load(char.charIdentifier)
    local r = activeOf(mine, kind)
    if not r then
        return notify(src, "warning", kind == "horse" and "Sem cavalo" or "Sem carroça",
            "Escolha um animal ativo no estábulo mais próximo.")
    end
    local left = r.injured - os.time()
    if left > 0 then
        return notify(src, "warning", ("%s está se recuperando"):format(r.name),
            ("Disponível em %s."):format(fmtClock(left)))
    end
    local out = outOf(src)
    if out[kind] and out[kind].id ~= r.id then deleteNet(out[kind].net) end
    out[kind] = { id = r.id }
    TriggerClientEvent("rsm_stables:client:spawn", src, spawnInfo(r))
end)

-- O cliente avisa o id de rede do que criou, para o servidor recolher na saída
RegisterNetEvent("rsm_stables:spawned", function(kind, id, net)
    local src = source
    local out = Out[src] and Out[src][kind]
    if out and out.id == id and type(net) == "number" then out.net = net end
end)

-- Guardou o animal (voltou ao estábulo pelo menu do jogo, trocou de personagem…)
RegisterNetEvent("rsm_stables:stored", function(kind)
    local src = source
    if Out[src] then Out[src][kind] = nil end
end)

RegisterNetEvent("rsm_stables:died", function(kind, id)
    local src = source
    local out = Out[src] and Out[src][kind]
    if not out or out.id ~= id then return end
    Out[src][kind] = nil
    local char = charOf(src)
    if not char then return end
    local mine = load(char.charIdentifier)
    local r = mine.rides[id]
    if not r or r.injured > os.time() then return end

    r.health = math.max(0, r.health - Config.Death.healthLoss)
    if r.health <= 0 and Config.Death.permanent then
        destroyRide(src, char.charIdentifier, mine, r)
        notify(src, "error", ("%s morreu"):format(r.name), "O animal não resistiu e não volta mais.")
        return refreshOpen(src, char.charIdentifier, false)
    end
    -- quanto mais gasta a saúde, mais demora para se recuperar (até o dobro)
    local wait = math.floor(Config.Death.recoverSeconds * (2 - r.health / 100))
    r.injured = os.time() + wait
    MySQL.update.await("UPDATE rsm_stables_rides SET health = ?, injured_until = ? WHERE id = ?", { r.health, r.injured, r.id })
    notify(src, "warning", ("%s está ferido"):format(r.name), ("Poderá chamar de novo em %s."):format(fmtClock(wait)))
end)

-- Vínculo: um tique por minuto montado no próprio cavalo
RegisterNetEvent("rsm_stables:bond", function(id)
    local src = source
    local out = Out[src] and Out[src].horse
    if not out or out.id ~= id then return end
    local t = GetGameTimer()
    if BondTick[src] and t - BondTick[src] < 55000 then return end
    BondTick[src] = t

    local char = charOf(src)
    if not char then return end
    local mine = load(char.charIdentifier)
    local r = mine.rides[id]
    if not r then return end
    local levels = Config.Bond.levels
    local cap = levels[#levels]
    if r.xp >= cap then return end
    local before = bondOf(r.xp)
    r.xp = math.min(cap, r.xp + Config.Bond.xpPerMinute)
    MySQL.update.await("UPDATE rsm_stables_rides SET xp = ? WHERE id = ?", { r.xp, r.id })
    local after = bondOf(r.xp)
    if after > before then
        notify(src, "success", "Vínculo mais forte", ("%s chegou ao vínculo %d."):format(r.name, after))
        TriggerClientEvent("rsm_stables:client:bond", src, r.id, after)
    end
end)

-- Alforje / carga: só o dono, só perto do animal que está fora
RegisterNetEvent("rsm_stables:saddlebag", function(kind)
    local src = source
    local out = Out[src] and Out[src][kind]
    if not out or not out.net then return end
    local ent = NetworkGetEntityFromNetworkId(out.net)
    if not ent or ent == 0 or not DoesEntityExist(ent) then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(ent)) > 4.0 then return end

    local char = charOf(src)
    if not char then return end
    local r = load(char.charIdentifier).rides[out.id]
    if not r then return end

    local id = invId(r.id)
    if not Registered[id] then
        local conf = Config.Inventory[r.type]
        local limit = r.type == "horse" and (Horse[r.model] and Horse[r.model].breed.capacity)
            or (Cart[r.model] and Cart[r.model].capacity) or 50
        local ok, err = pcall(function()
            if not exports.vorp_inventory:isCustomInventoryRegistered(id) then
                exports.vorp_inventory:registerInventory({
                    id = id,
                    name = r.name,
                    limit = limit,
                    acceptWeapons = conf.acceptWeapons,
                    shared = conf.shared,
                    ignoreItemStackLimit = conf.ignoreStackLimit,
                    whitelistItems = false,
                    UsePermissions = false,
                    UseBlackList = false,
                    whitelistWeapons = false,
                })
            end
        end)
        if not ok then
            print(("^1[rsm_stables] vorp_inventory recusou registrar %s: %s^0"):format(id, tostring(err)))
            return
        end
        Registered[id] = true
    end
    exports.vorp_inventory:openInventory(src, id)
end)

-- ── entrada, troca de personagem e saída ────────────────────────────────────

local function claimPayouts(src, charid)
    local rows = MySQL.query.await("SELECT id, amount, note FROM rsm_stables_payouts WHERE charid = ?", { charid }) or {}
    local total = 0
    for _, row in ipairs(rows) do
        if MySQL.update.await("DELETE FROM rsm_stables_payouts WHERE id = ?", { row.id }) == 1 then
            total = total + tonumber(row.amount)
        end
    end
    if total <= 0 then return end
    local char = charOf(src)
    if not char or char.charIdentifier ~= charid then
        -- trocou de personagem no meio: devolve para a fila
        MySQL.insert.await("INSERT INTO rsm_stables_payouts (charid, amount, note) VALUES (?, ?, ?)", { charid, total, "Pendente" })
        return
    end
    char.addCurrency(0, total)
    notify(src, "success", "Venda no estábulo", ("Você recebeu %s por animais vendidos enquanto estava fora."):format(fmtMoney(total)))
end

local function clearPlayer(src)
    local out = Out[src]
    if out then
        for _, o in pairs(out) do deleteNet(o.net) end
    end
    Out[src], Session[src], Busy[src], Last[src], BondTick[src] = nil, nil, nil, nil, nil
    Called[src .. "horse"], Called[src .. "cart"] = nil, nil
    local charid = CharOfSrc[src]
    CharOfSrc[src] = nil
    if charid then Chars[charid] = nil end
end

AddEventHandler("vorp:SelectedCharacter", function(src, character)
    clearPlayer(src)
    waitReady()
    local charid = character and character.charIdentifier
    if not charid then
        local char = charOf(src)
        charid = char and char.charIdentifier
    end
    if charid then claimPayouts(src, charid) end
end)

AddEventHandler("playerDropped", function()
    clearPlayer(source)
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    for src in pairs(Out) do
        for _, o in pairs(Out[src]) do deleteNet(o.net) end
    end
end)

-- ── migração do vorp_stables (console do servidor, uma vez) ─────────────────
-- Copia cavalos, carroças e arreios das tabelas `stables` e
-- `horse_complements`. Pode rodar de novo: o que já veio é pulado.

RegisterCommand("rsm_stables_migrate", function(src)
    if src ~= 0 then return end
    CreateThread(function()
        waitReady()
        local rides = MySQL.query.await("SELECT id, charidentifier, name, modelname, type, xp, gear, isDefault FROM stables")
        if not rides then return print("^1[rsm_stables] tabela `stables` não encontrada.^0") end
        local moved, skipped = 0, 0
        for _, row in ipairs(rides) do
            local kind = row.type == "cart" and "cart" or row.type == "horse" and "horse" or nil
            local known = kind == "horse" and Horse[row.modelname] or kind == "cart" and Cart[row.modelname]
            if known then
                local gear = {}
                local ok, old = pcall(json.decode, row.gear or "")
                if ok and type(old) == "table" then
                    for _, hash in pairs(old) do
                        local t = TackByHash[u32(hash)]
                        if t then gear[t.cat] = { style = t.style, variant = t.variant } end
                    end
                end
                -- nome antigo: limpo e cortado no tamanho máximo, nunca descartado
                local raw = tostring(row.name or ""):gsub("[%c<>\"`\\{}%[%]]", "")
                local name = cleanName(raw)
                if not name and utf8.len(raw) then
                    local cut = utf8.offset(raw, Config.Name.max + 1)
                    name = cleanName(cut and raw:sub(1, cut - 1) or raw)
                end
                name = name or "Sem nome"
                local done = MySQL.update.await([[
                    INSERT IGNORE INTO rsm_stables_rides (charid, type, model, name, active, xp, gear, legacy_id)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ]], { row.charidentifier, kind, row.modelname, name, isActive(row.isDefault) and 1 or 0, row.xp or 0, json.encode(gear), row.id })
                if done == 1 then moved = moved + 1 end
            else
                skipped = skipped + 1
            end
        end
        local owned = 0
        local comps = MySQL.query.await("SELECT charidentifier, complements FROM horse_complements") or {}
        for _, row in ipairs(comps) do
            local ok, list = pcall(json.decode, row.complements or "")
            if ok and type(list) == "table" then
                for _, hash in pairs(list) do
                    local t = TackByHash[u32(hash)]
                    if t then
                        local done = MySQL.update.await("INSERT IGNORE INTO rsm_stables_tack (charid, item) VALUES (?, ?)",
                            { row.charidentifier, ("%s:%s:%d"):format(t.cat, t.style, t.variant) })
                        if done == 1 then owned = owned + 1 end
                    end
                end
            end
        end
        Chars = {}
        print(("^2[rsm_stables] migração: %d animais copiados, %d pulados (modelo fora do config), %d arreios.^0"):format(moved, skipped, owned))
    end)
end, true)
