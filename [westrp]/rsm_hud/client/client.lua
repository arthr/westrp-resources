-- rsm_hud · client: ponte com a interface (NUI)
-- Controla quando o HUD aparece, abre o Editor de Layout e guarda o layout de
-- cada personagem. Os outros arquivos do client só chamam RSMHud.push().
--
-- Comandos:
--   /hud        liga/desliga o HUD (sobreposição transparente, nunca pega o foco)
--   /hudlayout  abre o Editor de Layout (pega o mouse até Salvar / Cancelar)
--
-- Peças de outros resources (ex.: rsm_nuikit) entram no mesmo Editor de Layout.
-- O HUD não desenha essas peças: mostra só a moldura delas no editor, salva a
-- posição junto com o layout do personagem e devolve cada mudança ao dono.
--   TriggerEvent('rsm_hud:client:registerWidgets', GetCurrentResourceName(), {
--       { id = 'toasts', label = 'Notificações', hint = 'Texto curto',
--         width = 380, height = 332,                  -- px em 1920×1080
--         default = { x = 0.99, y = 0.58, scale = 1 } },
--   })
-- Eventos locais que o HUD dispara para os donos:
--   rsm_hud:client:ready                    o HUD subiu: registre as peças de novo
--   rsm_hud:client:layout (owner, widgets, editing)
--       widgets = { [id] = { x, y, scale, opacity, visible } } só do `owner`;
--       editing = true enquanto o Editor de Layout está aberto
--   rsm_hud:client:visible (visible)        o HUD apareceu / sumiu (/hud, pausa, carregamento)
--   rsm_hud:client:catalog (catalog)        elementos, predefinições e estilos que este HUD tem
--
-- Padrões do servidor (ex.: publicados no estúdio do rsm_nuikit):
--   TriggerEvent('rsm_hud:client:policy', {
--       preset = 'frontier',      -- predefinição de quem ainda não salvou layout (e do "Restaurar")
--       meterStyle = 'ring',      -- estilo dos medidores de quem ainda não salvou layout
--       values = false,           -- números nos medidores, idem
--       disabled = { 'voice' },   -- elementos desligados para todos (somem até do editor)
--   })
--
-- Tema (ex.: o Color Manager do rsm_nuikit). false volta às cores próprias do HUD:
--   TriggerEvent('rsm_hud:client:theme', { accent = '#CB0101', surface = '#0D0D0D',
--       text = '#F5F3EE', surfaceAlpha = 93 })
-- Prévia: todos os elementos com dados de exemplo por `ms`, opcionalmente com um
-- tema e padrões ainda não publicados; depois tudo volta ao que era:
--   TriggerEvent('rsm_hud:client:preview', 8000, { theme = {...} ou false, policy = {...} })
-- Layout salvo deste personagem (false = ainda não salvou), para mostrar prévias:
--   TriggerEvent('rsm_hud:client:getLayout', function(layout) ... end)

RSMHud = {
    active = false,     -- true depois que o personagem foi escolhido: os módulos começam a enviar
    serverEffects = {}, -- efeitos que o servidor ligou (doente, envenenado…)
    alcohol = 0,        -- última embriaguez recebida (usada no efeito "Tonto")
    horseName = Config.Text.defaultHorseName,
}

local lastSent = {}
local characterReady = false
local playerWantsHud = true
local layoutOpen = false
local shown = nil

-- ── peças de outros resources ────────────────────────────────────────────────

local external = {}        -- dono -> lista de peças já validadas
local externalLayout = nil -- última posição que a interface mandou: { widgets, editing }
local catalog = nil        -- o que este HUD tem, informado pela interface ao carregar
local policy = nil         -- padrões do servidor (rsm_hud:client:policy)
local theme = false        -- tema de fora (rsm_hud:client:theme); false = cores próprias
local previewUntil = 0     -- GetGameTimer() até onde a prévia com exemplos vai
local previewSeq = 0

local function number(v, fallback)
    v = tonumber(v)
    if not v or v ~= v then return fallback end
    return v
end

-- Só o formato é conferido aqui; os limites de posição e tamanho a interface aplica.
local function cleanSpec(owner, s)
    if type(s) ~= 'table' or type(s.id) ~= 'string' or #s.id > 32 or not s.id:match('^[%w_%-]+$') then return nil end
    local width, height = number(s.width), number(s.height)
    if not width or not height or width < 8 or height < 8 or width > 1920 or height > 1080 then return nil end
    local d = type(s.default) == 'table' and s.default or {}
    return {
        id = owner .. ':' .. s.id, -- o prefixo do dono evita colisão com os elementos do HUD
        owner = owner,
        label = tostring(s.label or s.id):sub(1, 40),
        hint = s.hint and tostring(s.hint):sub(1, 80) or '',
        width = width,
        height = height,
        default = {
            x = number(d.x, 0.5),
            y = number(d.y, 0.5),
            scale = number(d.scale, 1),
            opacity = number(d.opacity, 1),
            visible = d.visible ~= false,
        },
    }
end

local function sendExternal()
    local list = {}
    for _, specs in pairs(external) do
        for _, s in ipairs(specs) do list[#list + 1] = s end
    end
    SendNUIMessage({ action = 'hud:external', widgets = list })
end

-- Repassa ao dono só a posição das peças dele, já sem o prefixo.
local function emitLayout(owner)
    if not externalLayout or not external[owner] then return end
    local prefix = owner .. ':'
    local mine = {}
    for key, w in pairs(externalLayout.widgets) do
        if type(key) == 'string' and type(w) == 'table' and key:sub(1, #prefix) == prefix then
            mine[key:sub(#prefix + 1)] = w
        end
    end
    TriggerEvent('rsm_hud:client:layout', owner, mine, externalLayout.editing)
end

AddEventHandler('rsm_hud:client:registerWidgets', function(owner, specs)
    if type(owner) ~= 'string' or owner == '' then return end
    local list = {}
    if type(specs) == 'table' then
        for _, s in ipairs(specs) do
            local clean = cleanSpec(owner, s)
            if clean and #list < 16 then list[#list + 1] = clean end
        end
    end
    external[owner] = #list > 0 and list or nil
    sendExternal()
    -- o dono pode ter subido depois do HUD: recebe a posição, a visibilidade e o catálogo atuais
    emitLayout(owner)
    TriggerEvent('rsm_hud:client:visible', shown == true)
    if catalog then TriggerEvent('rsm_hud:client:catalog', catalog) end
end)

-- Padrões do servidor. A interface confere cada valor; aqui só o formato geral.
AddEventHandler('rsm_hud:client:policy', function(data)
    if type(data) ~= 'table' then return end
    policy = data
    SendNUIMessage({ action = 'hud:policy', policy = policy })
end)

-- Tema. A interface confere cada cor; aqui só o formato geral.
AddEventHandler('rsm_hud:client:theme', function(data)
    theme = type(data) == 'table' and data or false
    SendNUIMessage({ action = 'hud:theme', theme = theme })
end)

-- Prévia com exemplos (ex.: "Preview Placement" do estúdio do rsm_nuikit). O HUD
-- aparece mesmo desligado pelo /hud e, no fim, volta aos dados, ao tema e aos
-- padrões de antes. Uma prévia nova substitui a anterior.
AddEventHandler('rsm_hud:client:preview', function(ms, draft)
    ms = math.floor(math.min(30000, math.max(1000, number(ms, 8000))))
    draft = type(draft) == 'table' and draft or {}
    previewSeq = previewSeq + 1
    local seq = previewSeq
    previewUntil = GetGameTimer() + ms
    -- sem tema na prévia (nil) = fica o publicado; false = cores próprias do HUD
    local draftTheme = nil
    if type(draft.theme) == 'table' or draft.theme == false then draftTheme = draft.theme end
    SendNUIMessage({
        action = 'hud:preview',
        on = true,
        theme = draftTheme,
        policy = type(draft.policy) == 'table' and draft.policy or nil,
    })
    SetTimeout(ms, function()
        if seq ~= previewSeq then return end
        previewUntil = 0
        SendNUIMessage({ action = 'hud:preview', on = false })
    end)
end)

-- Dono parou: a moldura sai do editor, mas a posição continua no layout salvo.
AddEventHandler('onClientResourceStop', function(resource)
    if external[resource] then
        external[resource] = nil
        sendExternal()
    end
end)

-- Envia uma seção para a interface, e só quando ela mudou de verdade.
-- `key` separa fontes diferentes da mesma seção (ex.: necessidades do client e do servidor).
function RSMHud.push(section, data, key)
    local id = key or section
    local encoded = json.encode(data)
    if lastSent[id] == encoded then return end
    lastSent[id] = encoded
    SendNUIMessage({ action = 'hud:update', data = { [section] = data } })
end

-- Hashes vêm assinados de algumas natives e sem sinal de outras: normaliza para comparar.
function RSMHud.u32(hash)
    return (tonumber(hash) or 0) & 0xFFFFFFFF
end

local function layoutKey()
    local character = LocalPlayer.state.Character
    local charId = RSMHud.charId or (character and character.CharId)
    return charId and ('layout:%s'):format(charId) or 'layout:default'
end

-- Layout salvo do personagem atual, ou false se ele ainda não salvou nenhum.
local function readSavedLayout()
    local raw = GetResourceKvpString(layoutKey())
    local ok, data = false, nil
    if raw and raw ~= '' then ok, data = pcall(json.decode, raw) end
    return (ok and type(data) == 'table') and data or false
end

-- Sem layout salvo, manda false: a interface usa os padrões do servidor.
local function sendSavedLayout()
    SendNUIMessage({ action = 'hud:setLayout', layout = readSavedLayout() })
end

AddEventHandler('rsm_hud:client:getLayout', function(cb)
    if cb then cb(readSavedLayout()) end
end)

local function setNativeCoresHidden(hidden)
    if not Config.Hud.hideNativeCores then return end
    local state = hidden and Config.Hud.nativeCoreHiddenState or 0
    for _, icon in ipairs(Config.Hud.nativeCoreIcons) do
        UitutorialSetRpgIconVisibility(icon, state)
    end
end

local function hideMetabolismHud()
    if Config.Metabolism.hideItsHud and GetResourceState(Config.Metabolism.resource) == 'started' then
        TriggerEvent('vorpmetabolism:setHud', false)
    end
end

-- Chamado quando o jogador escolhe o personagem (ou quando o recurso reinicia
-- com o personagem já em jogo). Os dados reais chegam antes do HUD aparecer,
-- para nunca mostrar valores de exemplo.
local function onCharacterReady()
    if RSMHud.active then return end
    lastSent = {}
    RSMHud.active = true
    if policy then SendNUIMessage({ action = 'hud:policy', policy = policy }) end
    if theme then SendNUIMessage({ action = 'hud:theme', theme = theme }) end
    sendSavedLayout()
    sendExternal()
    hideMetabolismHud()
    TriggerServerEvent('rsm_hud:server:requestState')
    Wait(800)
    characterReady = true
end

RegisterNetEvent('vorp:SelectedCharacter', function(charid)
    -- troca de personagem: recomeça do zero
    RSMHud.charId = charid
    RSMHud.active = false
    characterReady = false
    CreateThread(onCharacterReady)
end)

CreateThread(function()
    Wait(1000)
    if LocalPlayer.state.IsInSession then onCharacterReady() end
end)

-- Visibilidade: personagem pronto, jogador quer o HUD, sem pausa nem tela de carregamento.
CreateThread(function()
    local lastCoreHide = 0
    while true do
        local show = characterReady and playerWantsHud
            and not (Config.Hud.hideOnPause and IsPauseMenuActive())
            and not IsLoadingScreenVisible()
        if layoutOpen or (characterReady and GetGameTimer() < previewUntil) then show = true end

        if show ~= shown then
            shown = show
            SendNUIMessage({ action = show and 'hud:show' or 'hud:hide' })
            TriggerEvent('rsm_hud:client:visible', show)
        end

        -- o jogo restaura os cores nativos em alguns momentos (respawn, cutscene):
        -- reaplica de tempos em tempos enquanto o personagem estiver em jogo
        if characterReady and GetGameTimer() - lastCoreHide > 5000 then
            lastCoreHide = GetGameTimer()
            setNativeCoresHidden(true)
        end
        Wait(250)
    end
end)

RegisterCommand(Config.Hud.command, function()
    playerWantsHud = not playerWantsHud
end, false)

RegisterCommand(Config.Hud.layoutCommand, function()
    if layoutOpen or not characterReady then return end
    layoutOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'hud:layout' })
end, false)

local function releaseFocus()
    layoutOpen = false
    SetNuiFocus(false, false)
end

-- O layout é salvo por personagem no KVP deste client.
RegisterNUICallback('layoutSave', function(data, cb)
    if type(data) == 'table' and type(data.widgets) == 'table' then
        SetResourceKvp(layoutKey(), json.encode(data))
    end
    cb({ ok = true })
end)

-- Posição das peças de outros resources, a cada mudança (inclusive durante o
-- arraste no editor, para o dono acompanhar ao vivo).
RegisterNUICallback('layoutExternal', function(data, cb)
    if type(data) == 'table' and type(data.widgets) == 'table' then
        externalLayout = { widgets = data.widgets, editing = data.editing == true }
        for owner in pairs(external) do emitLayout(owner) end
    end
    cb({ ok = true })
end)

-- Catálogo do HUD (nomes já traduzidos), para quem quiser apresentar ou configurar.
RegisterNUICallback('catalog', function(data, cb)
    if type(data) == 'table' and type(data.widgets) == 'table' then
        catalog = data
        TriggerEvent('rsm_hud:client:catalog', catalog)
    end
    cb({ ok = true })
end)

RegisterNUICallback('layoutClose', function(_, cb)
    releaseFocus()
    cb({ ok = true })
end)

-- Callback genérico de fechar, mantido para o foco nunca ficar preso.
RegisterNUICallback('close', function(_, cb)
    releaseFocus()
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if layoutOpen then SetNuiFocus(false, false) end
    setNativeCoresHidden(false)
end)

-- Todos os handlers acima já existem: quem subiu antes do HUD registra de novo.
TriggerEvent('rsm_hud:client:ready')
