--[[
    WestRP UI Engine — Native DataBinding Scaleform HUD Layer
    0.00ms Resmon Idle • Renderizado diretamente pelo motor C++ do RDR2 (Scaleform)
]]

local NativeHUD = {}

-- ============================================================================
-- 1. SISTEMA DE HONRA / KARMA (CONEXÃO DINÂMICA COM SISTEMAS DE KARMA)
-- ============================================================================
-- Configuração padrão da escala de Karma/Honra.
-- Por padrão alinhado com o westrp_karma [-1000, +1000].
-- Pode ser dinamicamente reconfigurado em tempo de execução via:
-- exports['westrp_ui']:NativeHUD_ConfigureHonorScale(min, max, defaultDuration)
local HonorConfig = {
    min = -1000,
    max = 1000,
    defaultDuration = 4500,
    showOnWeaponWheel = true,     -- Opção 3: Exibir barra na Roda de Armas (ao segurar TAB / LB)
    showOnStatusOverlay = true,    -- Opção 3: Exibir barra na telemetria nativa (ao tocar/segurar Left Alt / D-Pad Baixo)
    overlayHoldDelay = 1500        -- Tempo em ms de permanência após soltar a tecla (padrão: 1500ms)
}

local currentCachedHonor = 0 -- Armazena em cache o valor de honra/karma atual do jogador
local rpgContainer = nil
local honorContainer = nil
local honorStateEntry = nil
local honorTimerId = 0
local HONOR_CTX_HASH = `HUD_CTX_HONOR_SHOW` -- 121713391 (forceHonor)

local function ShowHonorHUD()
    if DisableHudContext then
        DisableHudContext(HONOR_CTX_HASH)
    end
    pcall(function()
        Citizen.InvokeNative(0x9A48FC6836ED0B6A, HONOR_CTX_HASH)
    end)
    pcall(function()
        Citizen.InvokeNative(0x4CC5F2FC1332577F, HONOR_CTX_HASH)
    end)
end

local function HideHonorHUD()
    if EnableHudContext then
        EnableHudContext(HONOR_CTX_HASH)
    end
    pcall(function()
        Citizen.InvokeNative(0xBB7CB4FA30C28258, HONOR_CTX_HASH)
    end)
    pcall(function()
        Citizen.InvokeNative(0x8BC7C1F929D07BF3, HONOR_CTX_HASH)
    end)
end

---Permite reconfigurar dinamicamente a escala de honra/karma aceita pelo HUD Nativo
---@param minVal number Menor valor possível de karma (ex: -1000 ou 0)
---@param maxVal number Maior valor possível de karma (ex: 1000 ou 100)
---@param defaultDurationMs? number Duração padrão de exibição em ms (padrão: 4500)
---@return table Configuração atualizada { min, max, defaultDuration }
function NativeHUD.ConfigureHonorScale(minVal, maxVal, defaultDurationMs)
    if type(minVal) == 'number' and type(maxVal) == 'number' and minVal < maxVal then
        HonorConfig.min = minVal
        HonorConfig.max = maxVal
    end
    if type(defaultDurationMs) == 'number' and defaultDurationMs > 0 then
        HonorConfig.defaultDuration = math.floor(defaultDurationMs)
    end
    return {
        min = HonorConfig.min,
        max = HonorConfig.max,
        defaultDuration = HonorConfig.defaultDuration
    }
end

---Retorna a configuração atual da escala de honra
---@return table { min: number, max: number, defaultDuration: number }
function NativeHUD.GetHonorScale()
    return {
        min = HonorConfig.min,
        max = HonorConfig.max,
        defaultDuration = HonorConfig.defaultDuration
    }
end

---Configura a exibição automática da barra de honra nas teclas de Roda de Armas (TAB/LB) e Status (ALT/D-Pad Baixo)
---@param enableWeaponWheel? boolean Exibir ao segurar TAB / LB
---@param enableStatusOverlay? boolean Exibir ao tocar/segurar Left Alt / D-Pad Baixo
---@param holdDelayMs? number Tempo de permanência após soltar a tecla (padrão: 1500ms)
---@return table Configuração atualizada { showOnWeaponWheel, showOnStatusOverlay, overlayHoldDelay }
function NativeHUD.ConfigureHonorOverlays(enableWeaponWheel, enableStatusOverlay, holdDelayMs)
    if type(enableWeaponWheel) == 'boolean' then
        HonorConfig.showOnWeaponWheel = enableWeaponWheel
    end
    if type(enableStatusOverlay) == 'boolean' then
        HonorConfig.showOnStatusOverlay = enableStatusOverlay
    end
    if type(holdDelayMs) == 'number' and holdDelayMs >= 0 then
        HonorConfig.overlayHoldDelay = math.floor(holdDelayMs)
    end
    return {
        showOnWeaponWheel = HonorConfig.showOnWeaponWheel,
        showOnStatusOverlay = HonorConfig.showOnStatusOverlay,
        overlayHoldDelay = HonorConfig.overlayHoldDelay
    }
end

---Retorna a configuração atual de exibição automática de overlays
---@return table { showOnWeaponWheel: boolean, showOnStatusOverlay: boolean, overlayHoldDelay: number }
function NativeHUD.GetHonorOverlaysConfig()
    return {
        showOnWeaponWheel = HonorConfig.showOnWeaponWheel,
        showOnStatusOverlay = HonorConfig.showOnStatusOverlay,
        overlayHoldDelay = HonorConfig.overlayHoldDelay
    }
end

---Atualiza o valor de honra/karma armazenado em cache sem abrir a barra
---@param value number
---@return number
function NativeHUD.CacheHonor(value)
    if type(value) == 'number' then
        currentCachedHonor = value
        if honorStateEntry and DatabindingIsEntryValid(honorStateEntry) then
            local visualLevel = NativeHUD.NormalizeHonor(value)
            DatabindingWriteDataInt(honorStateEntry, visualLevel)
        end
    end
    return currentCachedHonor
end

---Retorna o valor de honra/karma atualmente em cache
---@return number
function NativeHUD.GetCachedHonor()
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.karma ~= nil then
        return tonumber(LocalPlayer.state.karma) or currentCachedHonor
    end
    return currentCachedHonor
end

---Normaliza qualquer valor de karma para o frame visual nativo do Scaleform do RDR2 (1 a 16)
---1..8 = Foragido / Vermelho, 9..16 = Honrado / Branco
---@param value number Valor bruto de karma/honra
---@param customMin? number (Opcional) Sobrescreve o valor mínimo da escala
---@param customMax? number (Opcional) Sobrescreve o valor máximo da escala
---@return integer visualLevel (1 a 16)
function NativeHUD.NormalizeHonor(value, customMin, customMax)
    local minVal = tonumber(customMin) or HonorConfig.min
    local maxVal = tonumber(customMax) or HonorConfig.max
    local val = tonumber(value) or ((minVal + maxVal) / 2)

    -- Se a escala for exatamente 1..16 (modo visual nativo direto), apenas clampamos
    if minVal == 1 and maxVal == 16 then
        return math.max(1, math.min(16, math.floor(val + 0.5)))
    end

    if maxVal <= minVal then
        return 8 -- Fallback neutro se configuração for inválida
    end

    -- Clampa o valor na escala configurada
    local clamped = math.max(minVal, math.min(maxVal, val))

    -- Mapeamento linear: ratio de 0.0 (mínimo/foragido) a 1.0 (máximo/honrado)
    local ratio = (clamped - minVal) / (maxVal - minVal)

    -- RDR2 Scaleform tem exatamente 16 estados visuais discretos (1 a 16).
    -- ratio * 15 produz [0..15] + 1 -> [1..16]
    local visualLevel = math.floor(ratio * 15 + 0.5) + 1

    return math.max(1, math.min(16, visualLevel))
end

---Oculta a barra de honra imediatamente da tela
function NativeHUD.HideHonor()
    honorTimerId = honorTimerId + 1
    HideHonorHUD()
end

---Define e exibe a barra de honra/karma nativa do RDR2.
---Aceita valores em qualquer escala arbitrária (ex: -1000 a 1000, 0 a 100 ou 1 a 16).
---Exibe a barra de honra imediatamente e a oculta suavemente após o tempo especificado.
---@param value number Valor de honra/karma (ou nível visual 1..16 se customMin=1 e customMax=16)
---@param durationMs? integer Tempo em ms para manter a barra visível (padrão: HonorConfig.defaultDuration)
---@param customMin? number (Opcional) Escala mínima customizada
---@param customMax? number (Opcional) Escala máxima customizada
---@return integer visualLevel O nível visual (1..16) que foi renderizado no HUD nativo
function NativeHUD.SetHonor(value, durationMs, customMin, customMax)
    currentCachedHonor = tonumber(value) or currentCachedHonor
    local visualLevel = NativeHUD.NormalizeHonor(value, customMin, customMax)
    durationMs = tonumber(durationMs) or HonorConfig.defaultDuration

    if not rpgContainer or not DatabindingIsEntryValid(rpgContainer) then
        rpgContainer = DatabindingAddDataContainerFromPath("", "RPGStatusIcons")
    end

    if not honorContainer or not DatabindingIsEntryValid(honorContainer) then
        honorContainer = DatabindingAddDataContainer(rpgContainer, "HonorIcon")
    end

    if not honorStateEntry or not DatabindingIsEntryValid(honorStateEntry) then
        honorStateEntry = DatabindingAddDataInt(honorContainer, "State", visualLevel)
    else
        DatabindingWriteDataInt(honorStateEntry, visualLevel)
    end

    -- Exibe a barra de honra na tela imediatamente
    ShowHonorHUD()

    -- Controle de tempo para ocultação suave (Debounce com reset caso chamado novamente)
    honorTimerId = honorTimerId + 1
    local currentTimerId = honorTimerId

    if durationMs > 0 then
        CreateThread(function()
            Wait(durationMs)
            if honorTimerId == currentTimerId then
                HideHonorHUD()
            end
        end)
    end

    return visualLevel
end

---Executa a animação de transição da barra de honra de um valor inicial para um valor final.
---Aceita valores em qualquer escala arbitrária ou níveis visuais diretos.
---@param fromValue number Valor ou nível inicial
---@param toValue number Valor ou nível final
---@param stepDelayMs? integer Atraso entre cada nível na transição (padrão: 140ms)
---@param holdDurationMs? integer Tempo para manter a barra aberta após concluir (padrão: 3500ms)
---@param customMin? number (Opcional) Escala mínima customizada
---@param customMax? number (Opcional) Escala máxima customizada
---@return integer fromLevel, integer toLevel Níveis visuais de início e fim
function NativeHUD.AnimateHonor(fromValue, toValue, stepDelayMs, holdDurationMs, customMin, customMax)
    local fromLevel = NativeHUD.NormalizeHonor(fromValue, customMin, customMax)
    local toLevel = NativeHUD.NormalizeHonor(toValue, customMin, customMax)
    stepDelayMs = tonumber(stepDelayMs) or 140
    holdDurationMs = tonumber(holdDurationMs) or 3500

    local steps = math.abs(toLevel - fromLevel)
    local totalDisplayTime = 600 + (steps * stepDelayMs) + holdDurationMs

    -- 1. Exibe a barra na posição visual inicial (1..16 direto)
    NativeHUD.SetHonor(fromLevel, totalDisplayTime, 1, 16)

    if fromLevel == toLevel then
        return fromLevel, toLevel
    end

    -- 2. Thread de interpolação fluida do ponteiro
    CreateThread(function()
        Wait(600)
        local stepDir = fromLevel < toLevel and 1 or -1
        local current = fromLevel

        while current ~= toLevel do
            current = current + stepDir
            if honorStateEntry and DatabindingIsEntryValid(honorStateEntry) then
                DatabindingWriteDataInt(honorStateEntry, current)
            end
            Wait(stepDelayMs)
        end
    end)

    return fromLevel, toLevel
end

-- ============================================================================
-- SINCRONIZAÇÃO AUTOMÁTICA COM westrp_karma (SE PRESENTE NO SERVIDOR)
-- ============================================================================
RegisterNetEvent('westrp_karma:client:onKarmaUpdated', function(payload)
    if payload and payload.currentKarma ~= nil then
        NativeHUD.CacheHonor(payload.currentKarma)
    end
end)

-- ============================================================================
-- MONITORAMENTO REATIVO DAS TECLAS TAB (WEAPON WHEEL) E ALT (STATUS OVERLAY)
-- 0.00ms Resmon Idle • Intervalo adaptativo de 200ms -> 0ms durante ativação
-- ============================================================================
local isOverlayVisible = false
local wheelHoldStart = 0

CreateThread(function()
    while true do
        local sleep = 200
        local cfgWheel = HonorConfig.showOnWeaponWheel
        local cfgStatus = HonorConfig.showOnStatusOverlay

        if cfgWheel or cfgStatus then
            local isWheelInputActive = cfgWheel and (
                LocalPlayer.state.isWheelOpen == true or
                IsUiappRunning("hud_quick_select") or
                IsControlPressed(0, `INPUT_TOGGLE_HOLSTER`) or
                IsControlPressed(0, `INPUT_SELECT_WEAPON`) or
                IsDisabledControlPressed(0, `INPUT_TOGGLE_HOLSTER`) or
                IsDisabledControlPressed(0, `INPUT_SELECT_WEAPON`)
            )

            local isStatusInputActive = cfgStatus and (
                IsControlPressed(0, `INPUT_REVEAL_HUD`) or
                IsControlPressed(0, `INPUT_RADAR_EXPAND`) or
                IsControlPressed(0, `INPUT_PC_FREE_LOOK`) or
                IsDisabledControlPressed(0, `INPUT_REVEAL_HUD`) or
                IsDisabledControlPressed(0, `INPUT_RADAR_EXPAND`) or
                IsDisabledControlPressed(0, `INPUT_PC_FREE_LOOK`)
            )

            if isWheelInputActive then
                sleep = 0
                if LocalPlayer.state.isWheelOpen or IsUiappRunning("hud_quick_select") then
                    if not isOverlayVisible then
                        isOverlayVisible = true
                        local val = NativeHUD.GetCachedHonor()
                        NativeHUD.SetHonor(val, 0)
                    end
                elseif wheelHoldStart == 0 then
                    wheelHoldStart = GetGameTimer()
                elseif (GetGameTimer() - wheelHoldStart) >= 180 then
                    -- Jogador segurando TAB há mais de 180ms (Roda de Armas aberta)
                    if not isOverlayVisible then
                        isOverlayVisible = true
                        local val = NativeHUD.GetCachedHonor()
                        NativeHUD.SetHonor(val, 0)
                    end
                end
            elseif isStatusInputActive then
                sleep = 0
                wheelHoldStart = 0
                if not isOverlayVisible then
                    isOverlayVisible = true
                    local val = NativeHUD.GetCachedHonor()
                    NativeHUD.SetHonor(val, 0)
                end
            else
                wheelHoldStart = 0
                if isOverlayVisible then
                    isOverlayVisible = false
                    sleep = 0
                    local holdDelay = HonorConfig.overlayHoldDelay or 1500
                    honorTimerId = honorTimerId + 1
                    local currentTimer = honorTimerId
                    CreateThread(function()
                        Wait(holdDelay)
                        if honorTimerId == currentTimer and not isOverlayVisible then
                            HideHonorHUD()
                        end
                    end)
                end
            end
        else
            sleep = 1000
        end

        Wait(sleep)
    end
end)

-- ============================================================================
-- 2. CRONÔMETRO CENTRAL SUPERIOR (TOP-CENTER TIMER / ASSALTOS E EVENTOS)
-- ============================================================================
local activeTimerData = nil

local function FormatTimerString(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

---Inicia o cronômetro central no HUD do RDR2
---@param durationInSeconds integer
---@param alertSeconds? integer Segundos restantes nos quais a cor muda para vermelho
function NativeHUD.StartTimer(durationInSeconds, alertSeconds)
    NativeHUD.StopTimer()

    local flowblock = Citizen.InvokeNative(0xC0081B34E395CE48, -119209833) -- RequestUiFlowBlock
    if not flowblock then return end

    local loadTimeout = 0
    while not UiflowblockIsLoaded(flowblock) and loadTimeout < 100 do
        loadTimeout = loadTimeout + 1
        Wait(10)
    end

    local container = DatabindingAddDataContainerFromPath("", "centralInfoDatastore")
    DatabindingAddDataString(container, "timerMessageString", "")
    local timerEntry = DatabindingAddDataString(container, "timerString", FormatTimerString(durationInSeconds))
    local visibleEntry = DatabindingAddDataBool(container, "isVisible", true)

    UiflowblockEnter(flowblock, `cTimer`)

    local stateMachine = nil
    if UiStateMachineExists(1546991729) == 0 then
        stateMachine = UiStateMachineCreate(1546991729, flowblock)
    end

    activeTimerData = {
        seconds = durationInSeconds,
        alertSeconds = alertSeconds or 10,
        flowblock = flowblock,
        container = container,
        timerEntry = timerEntry,
        visibleEntry = visibleEntry,
        stateMachine = stateMachine,
        isLow = false
    }

    CreateThread(function()
        local data = activeTimerData
        while data and data == activeTimerData and data.seconds > 0 do
            Wait(1000)
            if not activeTimerData or activeTimerData ~= data then break end

            data.seconds = data.seconds - 1
            if DatabindingIsEntryValid(data.timerEntry) then
                DatabindingWriteDataString(data.timerEntry, FormatTimerString(data.seconds))
            end

            if not data.isLow and data.seconds <= data.alertSeconds then
                data.isLow = true
                DatabindingAddDataBool(data.container, "isTimerLow", true)
            end

            if data.seconds <= 0 then
                NativeHUD.StopTimer()
                break
            end
        end
    end)
end

---Interrompe o cronômetro central
function NativeHUD.StopTimer()
    if not activeTimerData then return end

    if UiStateMachineExists(1546991729) ~= 0 then
        UiStateMachineDestroy(1546991729)
    end

    if DatabindingIsEntryValid(activeTimerData.visibleEntry) then
        DatabindingWriteDataBool(activeTimerData.visibleEntry, false)
        DatabindingRemoveDataEntry(activeTimerData.visibleEntry)
    end
    if DatabindingIsEntryValid(activeTimerData.timerEntry) then
        DatabindingRemoveDataEntry(activeTimerData.timerEntry)
    end
    if DatabindingIsEntryValid(activeTimerData.container) then
        DatabindingRemoveDataEntry(activeTimerData.container)
    end

    activeTimerData = nil
end

-- ============================================================================
-- 3. HUD DE CARTEIRA / COFRE (TITHING HUD)
-- ============================================================================
local tithingContainer = nil
local playerCashContainer = nil
local playerDollarsEntry = nil
local playerCentsEntry = nil

---Exibe os fundos da carteira do jogador na fonte e estilo nativo do RDR2
---@param dollars integer
---@param cents integer
function NativeHUD.ShowCash(dollars, cents)
    if not tithingContainer or not DatabindingIsEntryValid(tithingContainer) then
        tithingContainer = DatabindingAddDataContainerFromPath("", "Tithing")
    end

    if not playerCashContainer or not DatabindingIsEntryValid(playerCashContainer) then
        playerCashContainer = DatabindingAddDataContainer(tithingContainer, "PlayerCash")
        playerDollarsEntry = DatabindingAddDataInt(playerCashContainer, "dollars", math.floor(dollars or 0))
        playerCentsEntry = DatabindingAddDataInt(playerCashContainer, "cents", math.floor(cents or 0))
    else
        DatabindingWriteDataInt(playerDollarsEntry, math.floor(dollars or 0))
        DatabindingWriteDataInt(playerCentsEntry, math.floor(cents or 0))
    end

    -- Contexto nativo para ativar o HUD temporariamente
    EnableHudContext(1670279562)
end

-- ============================================================================
-- 4. BARRA DE PROGRESSÃO DE RANK / XP
-- ============================================================================
local mpRankBar = nil
local rankHeaderEntry = nil
local rankTextEntry = nil
local xpValueEntry = nil

---Atualiza a barra de XP e Rank multiplayer nativa
---@param headerText string Nome ou Título (ex: "PESCADOR")
---@param rankNumber integer/string Nível atual
---@param xpPercentage number 0.0 a 100.0
function NativeHUD.SetRank(headerText, rankNumber, xpPercentage)
    if not mpRankBar or not DatabindingIsEntryValid(mpRankBar) then
        mpRankBar = DatabindingGetDataContainerFromPath("mp_rank_bar")
        if mpRankBar == 0 then
            mpRankBar = DatabindingAddDataContainerFromPath("", "mp_rank_bar")
        end
        rankHeaderEntry = DatabindingAddDataString(mpRankBar, "rank_header_text", tostring(headerText or ""))
        rankTextEntry = DatabindingAddDataString(mpRankBar, "rank_text", tostring(rankNumber or "1"))
        DatabindingAddDataFloat(mpRankBar, "xp_bar_minimum", 0.0)
        DatabindingAddDataFloat(mpRankBar, "xp_bar_maximum", 100.0)
        xpValueEntry = DatabindingAddDataFloat(mpRankBar, "xp_bar_value", tonumber(xpPercentage) or 0.0)
    else
        DatabindingWriteDataString(rankHeaderEntry, tostring(headerText or ""))
        DatabindingWriteDataString(rankTextEntry, tostring(rankNumber or "1"))
        DatabindingWriteDataFloat(xpValueEntry, tonumber(xpPercentage) or 0.0)
    end
end

-- ============================================================================
-- 5. RECOMPENSA / BOUNTY TOP RIGHT
-- ============================================================================
local bountyContainer = nil
local bountyTextEntry = nil
local bountyStateEntry = nil

---Exibe ou esconde o display de recompensa pela cabeça no canto superior direito
---@param text string Ex: "Bounty: $ 15.00"
---@param visible boolean
function NativeHUD.SetBounty(text, visible)
    if not bountyContainer or not DatabindingIsEntryValid(bountyContainer) then
        bountyContainer = DatabindingAddDataContainerFromPath("", "BountyCash")
        bountyTextEntry = DatabindingAddDataString(bountyContainer, "Text", text or "")
        bountyStateEntry = DatabindingAddDataBool(bountyContainer, "State", visible == true)
    else
        DatabindingWriteDataString(bountyTextEntry, text or "")
        DatabindingWriteDataBool(bountyStateEntry, visible == true)
    end
end

-- ============================================================================
-- LIMPEZA AO PARAR O RECURSO
-- ============================================================================
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        NativeHUD.StopTimer()
        HideHonorHUD()
    end
end)

-- Exports do HUD Nativo
exports('NativeHUD_ConfigureHonorScale', NativeHUD.ConfigureHonorScale)
exports('NativeHUD_GetHonorScale', NativeHUD.GetHonorScale)
exports('NativeHUD_ConfigureHonorOverlays', NativeHUD.ConfigureHonorOverlays)
exports('NativeHUD_GetHonorOverlaysConfig', NativeHUD.GetHonorOverlaysConfig)
exports('NativeHUD_CacheHonor', NativeHUD.CacheHonor)
exports('NativeHUD_GetCachedHonor', NativeHUD.GetCachedHonor)
exports('NativeHUD_NormalizeHonor', NativeHUD.NormalizeHonor)
exports('NativeHUD_SetHonor', NativeHUD.SetHonor)
exports('NativeHUD_AnimateHonor', NativeHUD.AnimateHonor)
exports('NativeHUD_HideHonor', NativeHUD.HideHonor)
exports('NativeHUD_StartTimer', NativeHUD.StartTimer)
exports('NativeHUD_StopTimer', NativeHUD.StopTimer)
exports('NativeHUD_ShowCash', NativeHUD.ShowCash)
exports('NativeHUD_SetRank', NativeHUD.SetRank)
exports('NativeHUD_SetBounty', NativeHUD.SetBounty)

_G.NativeHUD = NativeHUD
