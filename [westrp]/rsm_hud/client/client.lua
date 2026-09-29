-- rsm_hud · client: ponte com a interface (NUI)
-- Controla quando o HUD aparece, abre o Editor de Layout e guarda o layout de
-- cada personagem. Os outros arquivos do client só chamam RSMHud.push().
--
-- Comandos:
--   /hud        liga/desliga o HUD (sobreposição transparente, nunca pega o foco)
--   /hudlayout  abre o Editor de Layout (pega o mouse até Salvar / Cancelar)

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

local function sendSavedLayout()
    local raw = GetResourceKvpString(layoutKey())
    if not raw or raw == '' then return end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' then
        SendNUIMessage({ action = 'hud:setLayout', layout = data })
    end
end

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
    sendSavedLayout()
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
        if layoutOpen then show = true end

        if show ~= shown then
            shown = show
            SendNUIMessage({ action = show and 'hud:show' or 'hud:hide' })
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
