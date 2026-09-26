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

---Define o nível visual de honra/karma do jogador (1 = Mais baixo / Foragido, 16 = Mais alto / Honrado)
---@param level integer (1 a 16)
function NativeHUD.SetHonor(level)
    level = math.max(1, math.min(16, tonumber(level) or 8))

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
    end
end)

-- Exports do HUD Nativo
exports('NativeHUD_SetHonor', NativeHUD.SetHonor)
exports('NativeHUD_StartTimer', NativeHUD.StartTimer)
exports('NativeHUD_StopTimer', NativeHUD.StopTimer)
exports('NativeHUD_ShowCash', NativeHUD.ShowCash)
exports('NativeHUD_SetRank', NativeHUD.SetRank)
exports('NativeHUD_SetBounty', NativeHUD.SetBounty)

_G.NativeHUD = NativeHUD
