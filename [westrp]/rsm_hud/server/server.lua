-- rsm_hud · servidor
-- Estresse, higiene e embriaguez de cada personagem (o VORP não tem esses
-- valores), recompensa e efeitos de status. O servidor é o dono desses
-- números: o client só pede e exibe. Tudo é salvo por personagem no KVP do
-- servidor, então sobrevive a desconexões e reinícios.
--
-- Exports para outros scripts (todos do lado do servidor):
--   exports.rsm_hud:setNeed(source, 'hygiene', 100)       -- define (0-100)
--   exports.rsm_hud:addNeed(source, 'alcohol', 15)        -- soma (negativo subtrai)
--   exports.rsm_hud:getNeed(source, 'stress')             -- lê (ou nil)
--   exports.rsm_hud:setBounty(source, 25.0, 'New Hanover') -- mostra o cartaz de procurado
--   exports.rsm_hud:clearBounty(source)
--   exports.rsm_hud:setEffect(source, 'sick', true)       -- 'sick' | 'venom' | 'overfed'

local NEEDS = { 'stress', 'hygiene', 'alcohol' }
local SERVER_EFFECTS = { sick = true, venom = true, overfed = true }

local players = {}  -- [source] = { charId, values = { stress, hygiene, alcohol }, dirty }
local bounties = {} -- [source] = { amount, region }
local effects = {}  -- [source] = { sick = true, ... }
local lastStress = {} -- [source] = { shooting = os.time(), damage = os.time() }

local function clamp(v)
    return math.max(0, math.min(100, v))
end

local Core = exports.vorp_core:GetCore()

local function charIdOf(src)
    local user = Core.getUser(src)
    if not user then return nil end -- jogador ainda sem personagem em sessão
    local character = user.getUsedCharacter
    return character and character.charIdentifier
end

local function kvpKey(charId)
    return ('needs:%s'):format(charId)
end

local function save(src)
    local entry = players[src]
    if not entry or not entry.dirty then return end
    SetResourceKvp(kvpKey(entry.charId), json.encode(entry.values))
    entry.dirty = false
end

-- Envia os três valores; os desativados no config vão como false e somem do HUD.
local function pushNeeds(src)
    local entry = players[src]
    if not entry then return end
    local payload = {}
    for _, key in ipairs(NEEDS) do
        payload[key] = Config.Needs[key].enabled and math.floor(entry.values[key] + 0.5) or false
    end
    TriggerClientEvent('rsm_hud:client:needs', src, payload)
end

local function pushBounty(src)
    local b = bounties[src]
    TriggerClientEvent('rsm_hud:client:bounty', src, b and b.amount or 0, b and b.region or '')
end

local function pushEffects(src)
    local list = {}
    for name in pairs(effects[src] or {}) do list[#list + 1] = name end
    TriggerClientEvent('rsm_hud:client:effects', src, list)
end

local function load(src, charId)
    charId = charId or charIdOf(src)
    if not charId then return false end
    charId = tostring(charId) -- o evento e o statebag podem trazer número ou texto

    local current = players[src]
    if current and current.charId == charId then return true end
    if current then
        current.dirty = true
        save(src) -- troca de personagem: grava o anterior
    end

    local saved
    local raw = GetResourceKvpString(kvpKey(charId))
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then saved = data end
    end

    local values = {}
    for _, key in ipairs(NEEDS) do
        values[key] = clamp(tonumber(saved and saved[key]) or Config.Needs[key].start)
    end
    players[src] = { charId = charId, values = values, dirty = false }
    return true
end

local function pushAll(src)
    pushNeeds(src)
    pushBounty(src)
    pushEffects(src)
end

AddEventHandler('vorp:SelectedCharacter', function(source, character)
    local src = source
    if load(src, character and character.charIdentifier) then pushAll(src) end
end)

-- O client pede o estado quando o personagem fica pronto (inclusive após reiniciar o recurso).
RegisterNetEvent('rsm_hud:server:requestState', function()
    local src = source
    if load(src) then pushAll(src) end
end)

-- Disparos e dano sobem o estresse. Com limite de frequência por jogador, o
-- client não consegue acelerar nada além do previsto no config.
RegisterNetEvent('rsm_hud:server:stress', function(reason)
    local src = source
    local cfg = Config.Needs.stress
    local entry = players[src]
    if not cfg.enabled or not entry then return end
    if reason ~= 'shooting' and reason ~= 'damage' then return end

    lastStress[src] = lastStress[src] or {}
    local now = os.time()
    if now - (lastStress[src][reason] or 0) < cfg.cooldown then return end
    lastStress[src][reason] = now

    entry.values.stress = clamp(entry.values.stress + cfg[reason])
    entry.dirty = true
    pushNeeds(src)
end)

-- Variação automática por minuto e gravação periódica.
CreateThread(function()
    local ticks = 0
    while true do
        Wait(Config.Needs.tickSeconds * 1000)
        ticks = ticks + 1
        local factor = Config.Needs.tickSeconds / 60
        for src, entry in pairs(players) do
            local changed = false
            for _, key in ipairs(NEEDS) do
                local cfg = Config.Needs[key]
                if cfg.enabled and cfg.perMinute ~= 0 then
                    local before = entry.values[key]
                    entry.values[key] = clamp(before + cfg.perMinute * factor)
                    if entry.values[key] ~= before then changed = true end
                end
            end
            if changed then
                entry.dirty = true
                pushNeeds(src)
            end
            if ticks % Config.Needs.saveEveryTicks == 0 then save(src) end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    save(src)
    players[src], bounties[src], effects[src], lastStress[src] = nil, nil, nil, nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for src in pairs(players) do save(src) end
end)

-- ── exports ─────────────────────────────────────────────────────────────────

local function validNeed(key)
    return key == 'stress' or key == 'hygiene' or key == 'alcohol'
end

exports('setNeed', function(src, key, value)
    src = tonumber(src)
    if not src or not validNeed(key) or not load(src) then return false end
    local entry = players[src]
    entry.values[key] = clamp(tonumber(value) or entry.values[key])
    entry.dirty = true
    pushNeeds(src)
    return true
end)

exports('addNeed', function(src, key, amount)
    src = tonumber(src)
    if not src or not validNeed(key) or not load(src) then return false end
    local entry = players[src]
    entry.values[key] = clamp(entry.values[key] + (tonumber(amount) or 0))
    entry.dirty = true
    pushNeeds(src)
    return true
end)

exports('getNeed', function(src, key)
    src = tonumber(src)
    if not src or not validNeed(key) or not players[src] then return nil end
    return players[src].values[key]
end)

exports('setBounty', function(src, amount, region)
    src = tonumber(src)
    if not src then return false end
    amount = math.max(0, tonumber(amount) or 0)
    bounties[src] = amount > 0 and { amount = amount, region = tostring(region or '') } or nil
    pushBounty(src)
    return true
end)

exports('clearBounty', function(src)
    src = tonumber(src)
    if not src then return false end
    bounties[src] = nil
    pushBounty(src)
    return true
end)

exports('setEffect', function(src, name, active)
    src = tonumber(src)
    if not src or not SERVER_EFFECTS[name] then return false end
    effects[src] = effects[src] or {}
    effects[src][name] = active and true or nil
    pushEffects(src)
    return true
end)
