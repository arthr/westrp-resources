-- rsm_nuikit (servidor): guarda a configuração publicada no estúdio, valida
-- tudo o que chega dos clientes e expõe o serviço para outros resources.

local RES = GetCurrentResourceName()

-- O que foi publicado no estúdio (layout, tema, módulos, estilo dos cores).
-- nil = nada publicado ainda; a interface usa os padrões dela.
local Studio = nil

-- ── validação ────────────────────────────────────────────────────────────────
-- A interface já limita os valores, mas o servidor não confia no cliente:
-- tudo é conferido de novo aqui antes de salvar ou repassar.

local WIDGETS = { "cores", "prompts", "toasts", "help", "money", "objective", "menus" }
local ANCHORS = { tl = true, tc = true, tr = true, ml = true, mc = true, mr = true, bl = true, bc = true, br = true }
local CORE_STYLES = { ring = true, half = true, segmented = true, barsH = true, barsV = true, numeric = true }

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

-- Devolve a configuração limpa, ou nil + motivo se algo estiver errado.
local function sanitize(data)
    if type(data) ~= "table" then return nil, "Settings were not sent." end
    local layout = type(data.layout) == "table" and data.layout or nil
    local theme = type(data.theme) == "table" and data.theme or nil
    if not layout or not theme then return nil, "Layout or theme is missing." end

    local out = {
        layout = { preset = label(layout.preset) or "custom", safeZone = num(layout.safeZone, 0, 10), widgets = {} },
        theme = {},
        modules = {},
        hud = { coreStyle = "ring" },
    }
    if not out.layout.safeZone then return nil, "Safe zone is not a number." end

    local widgets = type(layout.widgets) == "table" and layout.widgets or {}
    for _, id in ipairs(WIDGETS) do
        local w = widgets[id]
        if type(w) ~= "table" or not ANCHORS[w.anchor] then
            return nil, ("Widget %s has no valid anchor."):format(id)
        end
        local x, y, scale = num(w.x, -40, 40), num(w.y, -40, 40), num(w.scale, 60, 140)
        if not x or not y or not scale then
            return nil, ("Widget %s has an invalid offset or scale."):format(id)
        end
        out.layout.widgets[id] = { anchor = w.anchor, x = x, y = y, scale = scale }
    end

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
        layout = Studio and Studio.layout or nil,
        theme = Studio and Studio.theme or nil,
        hud = Studio and Studio.hud or nil,
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
        notify(src, "success", "Published", "Layout, theme and modules are now live for every player.")
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

-- exports.rsm_nuikit:IsModuleActive(id) -> boolean
exports("IsModuleActive", function(id)
    for _, m in ipairs(payload().modules) do
        if m.id == id then return m.active end
    end
    return false
end)
