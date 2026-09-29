-- rsm_nuikit (cliente): leva os pedidos dos outros resources até a interface
-- e segura o foco do mouse/teclado só enquanto há algo clicável na tela.

local RES = GetCurrentResourceName()
local nuiReady = false
local outbox = {}          -- mensagens que chegaram antes da interface carregar
local studioOpen = false
local confirms = {}        -- id -> callback de cada Confirm aberto na tela
local confirmSeq = 0
local modules = {}         -- id -> ativo, conforme a configuração publicada
local configReceived = false
local clockShown = false   -- o relógio só é enviado enquanto o dinheiro está no HUD

local function send(msg)
    if nuiReady then
        SendNUIMessage(msg)
    else
        outbox[#outbox + 1] = msg
    end
end

-- Foco só enquanto houver algo clicável aberto (estúdio ou Confirm), e nunca
-- antes da interface existir: foco sem nada na tela trava o jogador.
local function updateFocus()
    local want = nuiReady and (studioOpen or next(confirms) ~= nil)
    SetNuiFocus(want, want)
end

-- ── integração com o rsm_hud ─────────────────────────────────────────────────
-- Com o HUD rodando, Notificações, Ajuda e Objetivo entram no /hudlayout dele:
-- o jogador arrasta as peças junto com o resto do HUD, o rsm_hud salva a posição
-- no personagem e manda cada mudança para cá. Cores e dinheiro ficam só com ele.

local HOST = Config.HostHud and Config.HostHud.resource or ""
local HOST_PIECES = { "toasts", "help", "objective" }
local HOST_OWNED = { cores = true, money = true }
local hostPresent = false
local footprints = nil -- área de cada peça em px (1920×1080), informada pela interface
local hostPolicy = nil -- padrões do rsm_hud publicados no estúdio (elementos, predefinição, medidores)
local hostTheme = nil  -- tema publicado no Color Manager, que o rsm_hud também segue
local warned = {}

-- Página do rsm_hud (o ui_page dele), que o estúdio abre no modo espelho para
-- mostrar o HUD de verdade na prévia.
local function hostPage()
    local page = GetResourceMetadata(HOST, "ui_page", 0)
    if type(page) ~= "string" or page == "" then return nil end
    return ("https://cfx-nui-%s/%s"):format(HOST, page)
end

local function setHostPresent(present)
    if hostPresent == present then return end
    hostPresent = present
    if present then clockShown = false end -- o relógio também é do HUD
    send({ action = "host", present = present, name = HOST, page = present and hostPage() or nil })
end

-- Padrões publicados no estúdio → rsm_hud deste jogador. `force` = o HUD
-- acabou de avisar que subiu.
local function sendPolicy(force)
    if not hostPolicy or HOST == "" then return end
    if not force and not hostPresent and GetResourceState(HOST) ~= "started" then return end
    TriggerEvent("rsm_hud:client:policy", hostPolicy)
end

-- Tema publicado → rsm_hud deste jogador. O Blood & Black (padrão do kit) é o
-- próprio tema do HUD: com ele, o HUD fica exatamente como sempre foi.
local function sendTheme(force)
    if not hostTheme or HOST == "" then return end
    if not force and not hostPresent and GetResourceState(HOST) ~= "started" then return end
    TriggerEvent("rsm_hud:client:theme", hostTheme)
end

-- Registra no HUD as peças ativas, com o tamanho real e a posição inicial do
-- config.lua. `force` = o próprio HUD avisou que subiu (o estado dele ainda
-- pode estar em "starting" nesse momento).
local function registerWithHost(force)
    if HOST == "" or not footprints then return end
    if not force and GetResourceState(HOST) ~= "started" then return end
    local specs = {}
    for _, id in ipairs(HOST_PIECES) do
        local c, f = Config.Layout[id], footprints[id]
        if c and type(f) == "table" and modules[id] ~= false then
            specs[#specs + 1] = {
                id = id,
                label = c.label,
                hint = c.hint,
                width = tonumber(f[1]),
                height = tonumber(f[2]),
                default = { x = c.x, y = c.y, scale = c.scale or 1 },
            }
        end
    end
    -- presente ANTES de registrar: o HUD responde na hora (posição, visibilidade,
    -- catálogo) e essas respostas seriam descartadas se chegassem antes disso
    setHostPresent(true)
    TriggerEvent("rsm_hud:client:registerWidgets", RES, specs)
end

-- O HUD subiu depois do kit (ou reiniciou)
AddEventHandler("rsm_hud:client:ready", function()
    registerWithHost(true)
    sendPolicy(true)
    sendTheme(true)
end)

-- O que o HUD tem (elementos, predefinições, estilos), para a seção HUD Pieces
AddEventHandler("rsm_hud:client:catalog", function(catalog)
    if type(catalog) ~= "table" then return end
    send({ action = "host:catalog", catalog = catalog })
end)

-- Posição das peças do kit: ao carregar o personagem, e ao vivo enquanto o
-- jogador arrasta no /hudlayout (editing = true mostra exemplos no lugar).
AddEventHandler("rsm_hud:client:layout", function(owner, widgets, editing)
    if owner ~= RES or not hostPresent or type(widgets) ~= "table" then return end
    send({ action = "host:layout", widgets = widgets, editing = editing == true })
end)

-- /hud, menu de pausa, tela de carregamento: as peças somem junto com o HUD
AddEventHandler("rsm_hud:client:visible", function(visible)
    if not hostPresent then return end
    send({ action = "host:visible", visible = visible == true })
end)

AddEventHandler("onClientResourceStop", function(resource)
    if resource == HOST then setHostPresent(false) end
end)

-- Com o HUD rodando, SetCores / SetMoney não desenham nada: avisa uma vez só.
local function ownedByHost(id, export)
    if not (hostPresent and HOST_OWNED[id]) then return false end
    if not warned[id] then
        warned[id] = true
        print(("[%s] %s is ignored while %s runs: it draws its own %s."):format(RES, export, HOST, id))
    end
    return true
end

-- Posições do config.lua para a interface (sem o HUD, são as definitivas)
local function placementDefaults()
    local out = {}
    for id, c in pairs(Config.Layout or {}) do
        out[id] = { x = c.x, y = c.y, scale = c.scale or 1 }
    end
    return out
end
send({ action = "placement", defaults = placementDefaults() })

-- ── interface pronta ─────────────────────────────────────────────────────────

RegisterNUICallback("ready", function(data, cb)
    nuiReady = true
    for _, msg in ipairs(outbox) do
        SendNUIMessage(msg)
    end
    outbox = {}
    updateFocus()
    footprints = type(data) == "table" and type(data.footprints) == "table" and data.footprints or nil
    registerWithHost()
    cb("ok")
end)

-- ── configuração publicada ───────────────────────────────────────────────────

RegisterNetEvent("rsm_nuikit:config", function(config)
    configReceived = true
    modules = {}
    for _, m in ipairs(config.modules or {}) do
        modules[m.id] = m.active
    end
    send({ action = "config", config = config })
    -- módulo desligado no estúdio = peça fora do /hudlayout
    registerWithHost()
    if type(config.hostHud) == "table" then
        hostPolicy = config.hostHud
        sendPolicy()
    end
    if type(config.theme) == "table" then
        local t = config.theme
        hostTheme = { accent = t.accent, surface = t.surface, text = t.text, surfaceAlpha = tonumber(t.surfaceAlpha) }
        sendTheme()
    end
end)

-- Pede a configuração ao subir; repete até o servidor responder
CreateThread(function()
    while not configReceived do
        TriggerServerEvent("rsm_nuikit:requestConfig")
        Wait(5000)
    end
end)

-- ── estúdio (só abre depois que o servidor confere a permissão) ──────────────

local function setStudio(open)
    studioOpen = open
    send({ action = open and "studio:open" or "studio:close" })
    updateFocus()
end

-- /nuikit de novo com o estúdio aberto fecha (saída de emergência pelo console F8)
RegisterNetEvent("rsm_nuikit:openStudio", function()
    setStudio(not studioOpen)
end)

local function onStudioClosed(_, cb)
    studioOpen = false
    updateFocus()
    cb("ok")
end
RegisterNUICallback("studio:close", onStudioClosed)
RegisterNUICallback("close", onStudioClosed)

RegisterNUICallback("studio:publish", function(data, cb)
    TriggerServerEvent("rsm_nuikit:publish", data)
    cb("ok")
end)

-- Preview Placement: o rsm_hud deste jogador mostra os exemplos dele, com o tema
-- e os padrões ainda não publicados, e depois volta sozinho ao que era.
RegisterNUICallback("host:preview", function(data, cb)
    if hostPresent and type(data) == "table" then
        TriggerEvent("rsm_hud:client:preview", tonumber(data.ms) or 8000, {
            theme = type(data.theme) == "table" and data.theme or nil,
            policy = type(data.policy) == "table" and data.policy or nil,
        })
    end
    cb("ok")
end)

-- Layout salvo do próprio jogador no rsm_hud, para a prévia "My Layout".
-- Um rsm_hud sem esse evento simplesmente não responde: fica false.
RegisterNUICallback("host:getLayout", function(_, cb)
    local layout = false
    if hostPresent then
        TriggerEvent("rsm_hud:client:getLayout", function(saved) layout = saved end)
    end
    cb({ layout = layout })
end)

-- ── serviço: notificações ────────────────────────────────────────────────────

local function Notify(kind, title, body, duration)
    send({
        action = "notify",
        kind = kind or "info",
        title = tostring(title or ""),
        body = tostring(body or ""),
        duration = tonumber(duration),
    })
end

-- ── serviço: Confirm ─────────────────────────────────────────────────────────

-- cb(accepted) é chamado uma única vez, com true (confirmou) ou false.
local function Confirm(opts, cb)
    confirmSeq = confirmSeq + 1
    local id = "c" .. confirmSeq
    confirms[id] = cb or false
    send({ action = "confirm", id = id, dialog = type(opts) == "table" and opts or { title = tostring(opts) } })
    updateFocus()
    return id
end

RegisterNUICallback("confirm:result", function(data, cb)
    local fn = confirms[data.id]
    if fn ~= nil then
        confirms[data.id] = nil
        updateFocus()
        if fn then
            local ok, err = pcall(fn, data.accepted == true)
            if not ok then
                print(("[%s] Confirm callback failed: %s"):format(GetCurrentResourceName(), err))
            end
        end
    end
    cb("ok")
end)

-- ── eventos vindos do servidor ───────────────────────────────────────────────

RegisterNetEvent("rsm_nuikit:notify", Notify)

RegisterNetEvent("rsm_nuikit:confirm", function(serverId, opts)
    Confirm(opts, function(accepted)
        TriggerServerEvent("rsm_nuikit:confirmResult", serverId, accepted)
    end)
end)

-- ── relógio do jogo para o widget Money & Clock ──────────────────────────────

CreateThread(function()
    local last = -1
    while true do
        Wait(1000)
        if clockShown and nuiReady then
            local h, m = GetClockHours(), GetClockMinutes()
            if h * 60 + m ~= last then
                last = h * 60 + m
                SendNUIMessage({ action = "clock", h = h, m = m })
            end
        end
    end
end)

-- ── exports para outros resources (lado do cliente) ──────────────────────────

-- exports.rsm_nuikit:Notify(kind, title, body, duration)
--   kind: "info" | "success" | "warning" | "error"; duration em ms (opcional)
exports("Notify", Notify)

-- exports.rsm_nuikit:Confirm(opts, cb) -> id
--   opts: { kicker, title, body, lines = { {label, value}, ... }, confirm, cancel, danger }
exports("Confirm", Confirm)

-- exports.rsm_nuikit:SetCores({ health = { ring = 0-100, core = 0-100 }, stamina = {...}, deadeye = {...} })
--   atualização parcial: só os cores enviados mudam. nil esconde os cores.
--   Ignorado com o rsm_hud rodando (ele desenha os cores).
exports("SetCores", function(cores)
    if ownedByHost("cores", "SetCores") then return end
    send({ action = "cores", cores = cores })
end)

-- exports.rsm_nuikit:SetMoney(cash, gold) — nil esconde o widget
--   Ignorado com o rsm_hud rodando (ele desenha dinheiro, ouro e relógio).
exports("SetMoney", function(cash, gold)
    if ownedByHost("money", "SetMoney") then return end
    clockShown = cash ~= nil
    send({ action = "money", cash = tonumber(cash), gold = tonumber(gold) })
end)

-- exports.rsm_nuikit:SetObjective(text) — nil esconde
exports("SetObjective", function(text)
    send({ action = "objective", text = text and tostring(text) or nil })
end)

-- exports.rsm_nuikit:ShowHelp(text, key) / HideHelp()
exports("ShowHelp", function(text, key)
    send({ action = "help", text = tostring(text or ""), key = key and tostring(key) or nil })
end)
exports("HideHelp", function()
    send({ action = "help" })
end)

-- exports.rsm_nuikit:SetHudHidden(true|false) — esconde o HUD do kit (cutscenes, fotos)
exports("SetHudHidden", function(hidden)
    send({ action = "hud:hidden", hidden = hidden == true })
end)

-- exports.rsm_nuikit:IsModuleActive(id) -> boolean
--   "cores" e "money" dão false enquanto o rsm_hud estiver rodando
exports("IsModuleActive", function(id)
    if hostPresent and HOST_OWNED[id] then return false end
    return modules[id] == true
end)

-- Nunca deixar o jogador preso com o foco se o resource parar com algo aberto
AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if studioOpen or next(confirms) ~= nil then
        SetNuiFocus(false, false)
    end
end)
