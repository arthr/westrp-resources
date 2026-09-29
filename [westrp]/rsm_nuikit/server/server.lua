-- rsm_nuikit (servidor): guarda a configuração publicada no estúdio, valida
-- tudo o que chega dos clientes e expõe o serviço para outros resources.

local RES = GetCurrentResourceName()

-- O que foi publicado no estúdio (tema, módulos, estilo dos cores e padrões do
-- rsm_hud). A posição
-- das peças do HUD não passa por aqui: vem do config.lua ou, com o rsm_hud
-- rodando, do /hudlayout de cada jogador.
-- nil = nada publicado ainda; a interface usa os padrões dela.
local Studio = nil

-- ── validação ────────────────────────────────────────────────────────────────
-- A interface já limita os valores, mas o servidor não confia no cliente:
-- tudo é conferido de novo aqui antes de salvar ou repassar.

local CORE_STYLES = { ring = true, half = true, segmented = true, barsH = true, barsV = true, numeric = true }
-- estilos dos medidores do rsm_hud (mesmos seis, com os nomes dele)
local HOST_STYLES = { ring = true, half = true, segmented = true, ["bars-h"] = true, ["bars-v"] = true, numeric = true }

local MODULE_BY_ID = {}
for _, m in ipairs(Config.Modules) do
    MODULE_BY_ID[m.id] = m
end

local function num(v, lo, hi)
    if type(v) ~= "number" or v ~= v then return nil end
    return math.min(hi, math.max(lo, v))
end

local function hex(v)
    if type(v) == "string" and v:match("^#%x%x%x%x%x%x$") then return v:upper() end
    return nil
end

local function label(v)
    if type(v) ~= "string" then return nil end
    return v:sub(1, 32)
end

-- id de elemento/predefinição do rsm_hud; qual existe de fato quem confere é o HUD
local function hostId(v)
    if type(v) ~= "string" or #v > 32 or not v:match("^[%w_%-]+$") then return nil end
    return v
end

-- Devolve a configuração limpa, ou nil + motivo se algo estiver errado.
local function sanitize(data)
    if type(data) ~= "table" then return nil, "Settings were not sent." end
    -- um studio.json antigo ainda traz "layout": é ignorado, o resto continua valendo
    local theme = type(data.theme) == "table" and data.theme or nil
    if not theme then return nil, "Theme is missing." end

    local out = {
        theme = {},
        modules = {},
        hud = { coreStyle = "ring" },
        hostHud = { preset = "frontier", meterStyle = "ring", values = false, disabled = {} },
    }

    out.theme.preset = label(theme.preset) or "custom"
    out.theme.accent = hex(theme.accent)
    out.theme.surface = hex(theme.surface)
    out.theme.text = hex(theme.text)
    out.theme.surfaceAlpha = num(theme.surfaceAlpha, 70, 100)
    if not out.theme.accent or not out.theme.surface or not out.theme.text or not out.theme.surfaceAlpha then
        return nil, "Theme colours must be six-digit hex values."
    end

    -- só módulos que existem no config.lua; os travados ficam sempre ligados
    local modules = type(data.modules) == "table" and data.modules or {}
    for _, m in ipairs(modules) do
        local def = type(m) == "table" and MODULE_BY_ID[m.id]
        if def then
            out.modules[#out.modules + 1] = { id = def.id, active = def.locked or m.active == true }
        end
    end

    local hud = type(data.hud) == "table" and data.hud or {}
    if CORE_STYLES[hud.coreStyle] then out.hud.coreStyle = hud.coreStyle end

    -- padrões do rsm_hud (um studio.json antigo não tem: fica tudo no padrão)
    local hh = type(data.hostHud) == "table" and data.hostHud or {}
    out.hostHud.preset = hostId(hh.preset) or "frontier"
    if HOST_STYLES[hh.meterStyle] then out.hostHud.meterStyle = hh.meterStyle end
    out.hostHud.values = hh.values == true
    for _, id in ipairs(type(hh.disabled) == "table" and hh.disabled or {}) do
        if hostId(id) and #out.hostHud.disabled < 32 then
            out.hostHud.disabled[#out.hostHud.disabled + 1] = id
        end
    end

    return out
end

-- O que cada cliente recebe: a lista final de módulos (padrões do config.lua
-- com o que foi publicado por cima) e o resto da configuração publicada.
local function payload()
    local published = {}
    if Studio then
        for _, m in ipairs(Studio.modules) do published[m.id] = m.active end
    end
    local modules = {}
    for _, m in ipairs(Config.Modules) do
        local active = m.active
        if published[m.id] ~= nil then active = published[m.id] end
        modules[#modules + 1] = { id = m.id, active = m.locked or active, locked = m.locked }
    end
    return {
        modules = modules,
        notifyDuration = Config.NotifyDuration,
        theme = Studio and Studio.theme or nil,
        hud = Studio and Studio.hud or nil,
        hostHud = Studio and Studio.hostHud or nil,
    }
end

-- ── carregar / salvar ────────────────────────────────────────────────────────

local function load()
    local raw = LoadResourceFile(RES, Config.SaveFile)
    if not raw or raw == "" then return end
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= "table" or next(data) == nil then return end
    local clean, err = sanitize(data)
    if clean then
        Studio = clean
    else
        print(("[%s] %s is invalid (%s); using the defaults until the next publish."):format(RES, Config.SaveFile, err))
    end
end

load()

-- ── estúdio ──────────────────────────────────────────────────────────────────

local function isAdmin(src)
    return IsPlayerAceAllowed(tostring(src), Config.AdminAce)
end

local function notify(target, kind, title, body, duration)
    TriggerClientEvent("rsm_nuikit:notify", target, kind, title, body, duration)
end

RegisterCommand(Config.Command, function(src)
    if src == 0 then
        print(("[%s] /%s opens the studio in game; it can't be used from the console."):format(RES, Config.Command))
        return
    end
    if not isAdmin(src) then
        notify(src, "error", "No Permission", "Only server staff can open the NUI studio.")
        return
    end
    TriggerClientEvent("rsm_nuikit:openStudio", src)
end, false)

-- Cada cliente pede a configuração assim que o script dele sobe
RegisterNetEvent("rsm_nuikit:requestConfig", function()
    TriggerClientEvent("rsm_nuikit:config", source, payload())
end)

RegisterNetEvent("rsm_nuikit:publish", function(data)
    local src = source
    if not isAdmin(src) then
        notify(src, "error", "No Permission", "Only server staff can publish studio settings.")
        return
    end
    local clean, err = sanitize(data)
    if not clean then
        notify(src, "error", "Not Published", err)
        return
    end
    Studio = clean
    if not SaveResourceFile(RES, Config.SaveFile, json.encode(clean), -1) then
        print(("[%s] could not write %s; the change is live but will be lost on restart."):format(RES, Config.SaveFile))
        notify(src, "warning", "Published, Not Saved", ("Live for everyone now, but %s could not be written."):format(Config.SaveFile))
    else
        notify(src, "success", "Published", "Theme, modules and HUD defaults are now live for every player.")
    end
    print(("[%s] studio settings published by %s"):format(RES, GetPlayerName(src) or src))
    TriggerClientEvent("rsm_nuikit:config", -1, payload())
end)

-- ── Confirm aberto pelo servidor ─────────────────────────────────────────────

local confirms = {}
local confirmSeq = 0

local function resolve(id, accepted)
    local p = confirms[id]
    if not p then return end
    confirms[id] = nil
    if p.cb then
        local ok, err = pcall(p.cb, accepted)
        if not ok then print(("[%s] Confirm callback failed: %s"):format(RES, err)) end
    end
end

RegisterNetEvent("rsm_nuikit:confirmResult", function(id, accepted)
    local p = confirms[id]
    -- só quem recebeu a pergunta pode responder
    if not p or p.src ~= source then return end
    resolve(id, accepted == true)
end)

-- Jogador saiu ou demorou demais: a resposta vira "não"
AddEventHandler("playerDropped", function()
    local src = source
    for id, p in pairs(confirms) do
        if p.src == src then resolve(id, false) end
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        local now = os.time()
        for id, p in pairs(confirms) do
            if now - p.at >= Config.ConfirmTimeout then resolve(id, false) end
        end
    end
end)

-- ── exports para outros resources (lado do servidor) ─────────────────────────

-- exports.rsm_nuikit:Notify(target, kind, title, body, duration)
--   target: id do jogador, ou -1 para todos
exports("Notify", function(target, kind, title, body, duration)
    notify(target, kind, title, body, duration)
end)

-- exports.rsm_nuikit:Confirm(target, opts, cb) -> id
--   cb(accepted) recebe true/false; false também se o jogador sair ou não responder
exports("Confirm", function(target, opts, cb)
    confirmSeq = confirmSeq + 1
    local id = confirmSeq
    confirms[id] = { src = target, cb = cb, at = os.time() }
    TriggerClientEvent("rsm_nuikit:confirm", target, id, opts)
    return id
end)

-- Cores e dinheiro: com o rsm_hud rodando, quem desenha é ele.
local HOST_OWNED = { cores = true, money = true }

local function hostRunning()
    local host = Config.HostHud and Config.HostHud.resource or ""
    return host ~= "" and GetResourceState(host) == "started"
end

-- exports.rsm_nuikit:IsModuleActive(id) -> boolean
--   "cores" e "money" dão false enquanto o rsm_hud estiver rodando
exports("IsModuleActive", function(id)
    if HOST_OWNED[id] and hostRunning() then return false end
    for _, m in ipairs(payload().modules) do
        if m.id == id then return m.active end
    end
    return false
end)
