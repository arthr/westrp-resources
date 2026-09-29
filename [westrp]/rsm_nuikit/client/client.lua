-- rsm_nuikit (cliente): leva os pedidos dos outros resources até a interface
-- e segura o foco do mouse/teclado só enquanto há algo clicável na tela.

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

-- ── interface pronta ─────────────────────────────────────────────────────────

RegisterNUICallback("ready", function(_, cb)
    nuiReady = true
    for _, msg in ipairs(outbox) do
        SendNUIMessage(msg)
    end
    outbox = {}
    updateFocus()
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
exports("SetCores", function(cores)
    send({ action = "cores", cores = cores })
end)

-- exports.rsm_nuikit:SetMoney(cash, gold) — nil esconde o widget
exports("SetMoney", function(cash, gold)
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
exports("IsModuleActive", function(id)
    return modules[id] == true
end)

-- Nunca deixar o jogador preso com o foco se o resource parar com algo aberto
AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if studioOpen or next(confirms) ~= nil then
        SetNuiFocus(false, false)
    end
end)
