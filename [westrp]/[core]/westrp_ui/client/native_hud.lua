--[[
    WestRP UI Engine — Native DataBinding Scaleform HUD Layer
    0.00ms Resmon Idle • Renderizado diretamente pelo motor C++ do RDR2 (Scaleform)
]]

local NativeHUD = {}

-- ============================================================================
-- 1. SISTEMA DE HONRA / KARMA (CONEXÃO DIRETA COM westrp_karma)
-- ============================================================================
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

---Oculta a barra de honra imediatamente da tela
function NativeHUD.HideHonor()
    honorTimerId = honorTimerId + 1
    HideHonorHUD()
end

---Define o nível visual de honra/karma do jogador (1 = Mais baixo / Foragido, 16 = Mais alto / Honrado)
---Exibe a barra de honra imediatamente e a oculta suavemente após o tempo especificado.
---@param level integer (1 a 16)
---@param durationMs? integer Tempo em ms para manter a barra visível (padrão: 4500)
function NativeHUD.SetHonor(level, durationMs)
    level = math.max(1, math.min(16, tonumber(level) or 8))
    durationMs = tonumber(durationMs) or 4500

    if not rpgContainer or not DatabindingIsEntryValid(rpgContainer) then
        rpgContainer = DatabindingAddDataContainerFromPath("", "RPGStatusIcons")
    end

    if not honorContainer or not DatabindingIsEntryValid(honorContainer) then
        honorContainer = DatabindingAddDataContainer(rpgContainer, "HonorIcon")
    end

    if not honorStateEntry or not DatabindingIsEntryValid(honorStateEntry) then
        honorStateEntry = DatabindingAddDataInt(honorContainer, "State", level)
    else
        DatabindingWriteDataInt(honorStateEntry, level)
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
end

---Executa a animação de transição da barra de honra de um nível inicial para um nível final
---@param fromLevel integer Nível inicial (1 a 16)
---@param toLevel integer Nível final (1 a 16)
---@param stepDelayMs? integer Atraso entre cada nível na transição (padrão: 140ms)
---@param holdDurationMs? integer Tempo para manter a barra aberta após concluir (padrão: 3500ms)
function NativeHUD.AnimateHonor(fromLevel, toLevel, stepDelayMs, holdDurationMs)
    fromLevel = math.max(1, math.min(16, tonumber(fromLevel) or 1))
    toLevel = math.max(1, math.min(16, tonumber(toLevel) or 16))
    stepDelayMs = tonumber(stepDelayMs) or 140
    holdDurationMs = tonumber(holdDurationMs) or 3500

    local steps = math.abs(toLevel - fromLevel)
    local totalDisplayTime = 600 + (steps * stepDelayMs) + holdDurationMs

    -- 1. Exibe a barra na posição inicial
    NativeHUD.SetHonor(fromLevel, totalDisplayTime)

    if fromLevel == toLevel then return end

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
end

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
exports('NativeHUD_SetHonor', NativeHUD.SetHonor)
exports('NativeHUD_AnimateHonor', NativeHUD.AnimateHonor)
exports('NativeHUD_HideHonor', NativeHUD.HideHonor)
exports('NativeHUD_StartTimer', NativeHUD.StartTimer)
exports('NativeHUD_StopTimer', NativeHUD.StopTimer)
exports('NativeHUD_ShowCash', NativeHUD.ShowCash)
exports('NativeHUD_SetRank', NativeHUD.SetRank)
exports('NativeHUD_SetBounty', NativeHUD.SetBounty)

_G.NativeHUD = NativeHUD
