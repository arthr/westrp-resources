-- ============================================================================
-- WestRP UI Engine - Player Status HUD Native Collector
-- Target: RedM (CitizenFX Game Build 1491+)
-- Standards: .agent/skills/fivem-basics, lua-basics, fivem-security
-- ============================================================================

local UPDATE_INTERVAL_IDLE <const> = 350
local UPDATE_INTERVAL_ACTIVE <const> = 100
local DELTA_THRESHOLD <const> = 0.5
local TEMP_DELTA_THRESHOLD <const> = 1.0

-- ----------------------------------------------------------------------------
-- State Management (Local Snapshot for Delta Throttling)
-- ----------------------------------------------------------------------------
local isHudVisible = true
local isCinematicActive = false
local voiceProximityMode = 2
local isForcedTalking = false
local forcedTemperature = nil

local playerHudState = {
    health = -1.0,
    stamina = -1.0,
    hunger = 100.0,
    thirst = 100.0,
    temperature = -999.0,
    tempStatus = "normal",
    voiceLevel = 2,
    isTalking = false,
    mountActive = false,
    mountHealth = -1.0,
    mountStamina = -1.0,
    isUIMenuOpen = false,
    isCinematic = false
}

-- Metabolism buffer (updated via VORP events, sync thread, or public exports)
local currentMetabolism = {
    hunger = 100.0,
    thirst = 100.0
}

-- Override de teste para fixar valores durante simulações e testes
local forcedMetabolism = {
    hunger = nil,
    thirst = nil
}

-- ----------------------------------------------------------------------------
-- Native Extraction Helpers (Defensive with pcall guards)
-- ----------------------------------------------------------------------------

---Calcula o percentual de vida normalizado (0.0 a 100.0)
---@param ped integer
---@return number
local function getNormalizedHealth(ped)
    if not DoesEntityExist(ped) then
        return 0.0
    end

    local currentHealth = GetEntityHealth(ped)
    local maxHealth = GetPedMaxHealth(ped)

    if not maxHealth or maxHealth <= 0 then
        return 0.0
    end

    local pct = (currentHealth / maxHealth) * 100.0
    if pct < 0.0 then return 0.0 end
    if pct > 100.0 then return 100.0 end
    return pct
end

---Calcula o percentual de estamina normalizado (0.0 a 100.0)
---Utiliza native float RDR2 com fallback seguro para Attribute Core 1 (Stamina)
---@param playerId integer
---@param ped integer
---@return number
local function getNormalizedStamina(playerId, ped)
    local stamina = nil

    -- 1. Tentativa via export/native direta GetPlayerStamina
    if GetPlayerStamina then
        local ok, result = pcall(GetPlayerStamina, playerId)
        if ok and type(result) == "number" then
            stamina = result
        end
    end

    -- 2. Tentativa via hash RDR3 _GET_PLAYER_STAMINA (0x0FF421E467373FCF)
    if not stamina then
        local ok, result = pcall(Citizen.InvokeNative, 0x0FF421E467373FCF, playerId, Citizen.ResultAsFloat())
        if ok and type(result) == "number" then
            stamina = result
        end
    end

    if type(stamina) == "number" and stamina >= 0.0 then
        if stamina > 100.0 then return 100.0 end
        return stamina
    end

    -- 3. Fallback nativo: Core de Estamina do Ped (Attribute Core index 1)
    local okCore, coreValue = pcall(GetAttributeCoreValue, ped, 1)
    if okCore and type(coreValue) == "number" then
        local pct = coreValue + 0.0
        if pct < 0.0 then return 0.0 end
        if pct > 100.0 then return 100.0 end
        return pct
    end

    return 100.0
end

---Calcula temperatura e categoriza status térmico
---@param coords vector3
---@return number, string
local function getTemperatureData(coords)
    local temp = 22.0
    if forcedTemperature ~= nil then
        temp = forcedTemperature
    elseif GetTemperatureAtCoords then
        local ok, result = pcall(GetTemperatureAtCoords, coords.x, coords.y, coords.z)
        if ok and type(result) == "number" then
            temp = result
        end
    end

    local status = "normal"
    if temp < 2.0 then
        status = "freezing"
    elseif temp > 36.0 then
        status = "heat"
    end

    return temp, status
end

---Obtém dados do sistema de voz (PMA-Voice / Mumble)
---@param playerId integer
---@return integer, boolean
local function getVoiceData(playerId)
    local isTalking = isForcedTalking
    if not isTalking then
        if MumbleIsPlayerTalking then
            local ok, result = pcall(MumbleIsPlayerTalking, playerId)
            if ok and (result == 1 or result == true) then isTalking = true end
        elseif NetworkIsPlayerTalking then
            local ok, result = pcall(NetworkIsPlayerTalking, playerId)
            if ok and (result == 1 or result == true) then isTalking = true end
        end
    end

    local level = voiceProximityMode
    if MumbleGetTalkerProximity then
        local ok, proximity = pcall(MumbleGetTalkerProximity)
        if ok and type(proximity) == "number" and proximity > 0 then
            if proximity <= 1.8 then
                level = 1 -- Sussurro (1.5m)
            elseif proximity <= 4.0 then
                level = 2 -- Normal (3.0m)
            else
                level = 3 -- Grito (8.0m+)
            end
        end
    end

    return level, isTalking
end

---Lê dados da montaria caso o ped esteja montado
---@param ped integer
---@return boolean, number, number
local function getMountData(ped)
    if not IsPedOnMount(ped) then
        return false, 0.0, 0.0
    end

    local mount = GetMount(ped)
    if not mount or mount == 0 or not DoesEntityExist(mount) then
        return false, 0.0, 0.0
    end

    local currentHealth = GetEntityHealth(mount)
    local maxHealth = GetPedMaxHealth(mount)
    local healthPct = 0.0
    if maxHealth and maxHealth > 0 then
        healthPct = math.max(0.0, math.min(100.0, (currentHealth / maxHealth) * 100.0))
    end

    local okCore, staminaCore = pcall(GetAttributeCoreValue, mount, 1)
    local staminaPct = 100.0
    if okCore and type(staminaCore) == "number" then
        staminaPct = math.max(0.0, math.min(100.0, staminaCore + 0.0))
    end

    return true, healthPct, staminaPct
end

---Verifica se algum menu principal da engine de UI está aberto
---@return boolean
local function checkAnyMenuOpen()
    if IsDockOpen and IsDockOpen() then return true end
    if IsPanelOpen and IsPanelOpen() then return true end
    if IsDialogOpen and IsDialogOpen() then return true end
    if IsConfirmOpen and IsConfirmOpen() then return true end
    if IsModalOpen and IsModalOpen() then return true end
    if IsSliderPanelOpen and IsSliderPanelOpen() then return true end
    return false
end

---Avalia se o jogador está em ação física intensa para ditar a taxa de tick
---@param ped integer
---@param isMounted boolean
---@return boolean
local function isPedInActiveMovement(ped, isMounted)
    if IsPedSprinting(ped) or IsPedRunning(ped) or IsPedSwimming(ped) or IsPedInMeleeCombat(ped) then
        return true
    end

    if isMounted then
        local speed = GetEntitySpeed(ped)
        if speed > 3.0 then
            return true
        end
    end

    return false
end

---Verifica se há variação significativa entre os valores atuais e o snapshot anterior
---Executado com parâmetros primitivos para ZERO alocação de tabelas no coletor
---@param health number
---@param stamina number
---@param hunger number
---@param thirst number
---@param temp number
---@param tempStatus string
---@param voiceLevel integer
---@param isTalking boolean
---@param mountActive boolean
---@param mountHealth number
---@param mountStamina number
---@param isMenuOpen boolean
---@param isCinematic boolean
---@return boolean
local function hasDelta(health, stamina, hunger, thirst, temp, tempStatus, voiceLevel, isTalking, mountActive, mountHealth, mountStamina, isMenuOpen, isCinematic)
    if math.abs(health - playerHudState.health) >= DELTA_THRESHOLD then return true end
    if math.abs(stamina - playerHudState.stamina) >= DELTA_THRESHOLD then return true end
    if math.abs(hunger - playerHudState.hunger) >= DELTA_THRESHOLD then return true end
    if math.abs(thirst - playerHudState.thirst) >= DELTA_THRESHOLD then return true end
    if math.abs(temp - playerHudState.temperature) >= TEMP_DELTA_THRESHOLD then return true end

    if tempStatus ~= playerHudState.tempStatus then return true end
    if voiceLevel ~= playerHudState.voiceLevel then return true end
    if isTalking ~= playerHudState.isTalking then return true end
    if mountActive ~= playerHudState.mountActive then return true end
    if isMenuOpen ~= playerHudState.isUIMenuOpen then return true end
    if isCinematic ~= playerHudState.isCinematic then return true end

    if mountActive then
        if math.abs(mountHealth - playerHudState.mountHealth) >= DELTA_THRESHOLD then return true end
        if math.abs(mountStamina - playerHudState.mountStamina) >= DELTA_THRESHOLD then return true end
    end

    return false
end

---Despacha o pacote consolidado de dados para o frontend Chromium CEF
local function dispatchHudUpdate()
    SendNUIMessage({
        action = "westrp_ui:updatePlayerHud",
        data = {
            visible = isHudVisible,
            health = playerHudState.health,
            stamina = playerHudState.stamina,
            hunger = playerHudState.hunger,
            thirst = playerHudState.thirst,
            temperature = playerHudState.temperature,
            tempStatus = playerHudState.tempStatus,
            voice = {
                level = playerHudState.voiceLevel,
                isTalking = playerHudState.isTalking
            },
            mount = {
                active = playerHudState.mountActive,
                health = playerHudState.mountHealth,
                stamina = playerHudState.mountStamina
            },
            isUIMenuOpen = playerHudState.isUIMenuOpen,
            isCinematic = playerHudState.isCinematic
        }
    })
end

-- ----------------------------------------------------------------------------
-- Public Exports & Interface
-- ----------------------------------------------------------------------------

---Controla a visibilidade global do HUD
---@param visible boolean
local function setHudVisible(visible)
    isHudVisible = (visible == true)
    SendNUIMessage({
        action = "westrp_ui:setHudVisible",
        data = { visible = isHudVisible }
    })
end
exports('SetHudVisible', setHudVisible)

---Retorna o estado de visibilidade do HUD
---@return boolean
local function getHudVisible()
    return isHudVisible
end
exports('IsHudVisible', getHudVisible)

---Controla o modo cinemático (ocultação / letterbox)
---@param active boolean
local function setCinematicMode(active)
    isCinematicActive = (active == true)
    SendNUIMessage({
        action = "westrp_ui:setCinematicMode",
        data = { active = isCinematicActive }
    })
end
exports('SetCinematicMode', setCinematicMode)

---Injeção direta ou override de teste de dados de metabolismo (fome e sede 0 a 100%)
---@param hunger number|string|boolean|nil
---@param thirst number|string|boolean|nil
---@param isOverride boolean|nil Se true, trava o valor impedindo que a thread do VORP sobrescreva durante testes
local function updateMetabolismStatus(hunger, thirst, isOverride)
    if hunger == "restore" or hunger == false then
        forcedMetabolism.hunger = nil
    elseif type(hunger) == "number" then
        local val = math.max(0.0, math.min(100.0, hunger))
        currentMetabolism.hunger = val
        if isOverride then
            forcedMetabolism.hunger = val
        end
    end

    if thirst == "restore" or thirst == false then
        forcedMetabolism.thirst = nil
    elseif type(thirst) == "number" then
        local val = math.max(0.0, math.min(100.0, thirst))
        currentMetabolism.thirst = val
        if isOverride then
            forcedMetabolism.thirst = val
        end
    end
end
exports('UpdateMetabolismStatus', updateMetabolismStatus)

---Retorna os dados de metabolismo atuais (fome e sede de 0 a 100%)
---@return table
local function getMetabolismStatus()
    return {
        hunger = currentMetabolism.hunger,
        thirst = currentMetabolism.thirst
    }
end
exports('GetMetabolismStatus', getMetabolismStatus)

---Define manualmente o nível de proximidade de voz (1: Sussurro, 2: Normal, 3: Grito)
---@param level integer
local function setVoiceLevel(level)
    if type(level) == "number" and level >= 1 and level <= 3 then
        voiceProximityMode = math.floor(level)
    end
end
exports('SetVoiceLevel', setVoiceLevel)

---Permite forçar ou simular estado de microfone ativo/falando
---@param talking boolean
local function setVoiceTalking(talking)
    isForcedTalking = (talking == true)
end
exports('SetVoiceTalking', setVoiceTalking)

---Retorna o estado atual de voz (nível e se está falando)
---@return table
local function getVoiceDataExport()
    return {
        level = playerHudState.voiceLevel,
        isTalking = playerHudState.isTalking
    }
end
exports('GetVoiceData', getVoiceDataExport)

---Define override manual de temperatura (nil para retornar à leitura nativa)
---@param temp number|nil
local function setTemperatureOverride(temp)
    if temp == nil or type(temp) == "number" then
        forcedTemperature = temp
    end
end
exports('SetTemperatureOverride', setTemperatureOverride)

-- ----------------------------------------------------------------------------
-- Integration Bridge: vorp_metabolism Listeners & Sync
-- ----------------------------------------------------------------------------

local function requestVorpSync()
    TriggerEvent("vorpmetabolism:getValue", "Hunger", function(val)
        if val and type(val) == "number" and forcedMetabolism.hunger == nil then
            currentMetabolism.hunger = math.max(0.0, math.min(100.0, val / 10.0))
        end
    end)
    TriggerEvent("vorpmetabolism:getValue", "Thirst", function(val)
        if val and type(val) == "number" and forcedMetabolism.thirst == nil then
            currentMetabolism.thirst = math.max(0.0, math.min(100.0, val / 10.0))
        end
    end)
    -- Desativa a HUD legada do VORP para manter apenas a HUD elegante da WestRP
    TriggerEvent("vorpmetabolism:setHud", false)
end

-- 1. Carga inicial de personagem do VORP
RegisterNetEvent("vorpmetabolism:StartFunctions", function(status)
    if not status then return end
    local decoded = nil
    if type(status) == "table" then
        decoded = status
    elseif type(status) == "string" and #status >= 2 then
        local ok, res = pcall(json.decode, status)
        if ok and type(res) == "table" then
            decoded = res
        end
    end

    if decoded then
        if decoded.Hunger ~= nil and forcedMetabolism.hunger == nil then
            currentMetabolism.hunger = math.max(0.0, math.min(100.0, (tonumber(decoded.Hunger) or 1000) / 10.0))
        end
        if decoded.Thirst ~= nil and forcedMetabolism.thirst == nil then
            currentMetabolism.thirst = math.max(0.0, math.min(100.0, (tonumber(decoded.Thirst) or 1000) / 10.0))
        end
    end
    TriggerEvent("vorpmetabolism:setHud", false)
end)

-- 2. Alteração delta de valor do VORP
RegisterNetEvent("vorpmetabolism:changeValue", function(key, value)
    if not key or not value or type(value) ~= "number" then return end
    local lowerKey = string.lower(key)
    local deltaPct = value / 10.0
    if lowerKey == "hunger" and forcedMetabolism.hunger == nil then
        currentMetabolism.hunger = math.max(0.0, math.min(100.0, currentMetabolism.hunger + deltaPct))
    elseif lowerKey == "thirst" and forcedMetabolism.thirst == nil then
        currentMetabolism.thirst = math.max(0.0, math.min(100.0, currentMetabolism.thirst + deltaPct))
    end
end)

-- 3. Definição absoluta de valor do VORP
RegisterNetEvent("vorpmetabolism:setValue", function(key, value)
    if not key or not value or type(value) ~= "number" then return end
    local lowerKey = string.lower(key)
    local newPct = value / 10.0
    if lowerKey == "hunger" and forcedMetabolism.hunger == nil then
        currentMetabolism.hunger = math.max(0.0, math.min(100.0, newPct))
    elseif lowerKey == "thirst" and forcedMetabolism.thirst == nil then
        currentMetabolism.thirst = math.max(0.0, math.min(100.0, newPct))
    end
end)

-- 4. Eventos de ciclo de vida do personagem no VORP
RegisterNetEvent("vorp:PlayerForceRespawn", function()
    forcedMetabolism.hunger = nil
    forcedMetabolism.thirst = nil
    currentMetabolism.hunger = 100.0
    currentMetabolism.thirst = 100.0
    TriggerEvent("vorpmetabolism:setHud", false)
end)

RegisterNetEvent("vorp:SelectedCharacter", function()
    Wait(1000)
    requestVorpSync()
end)

RegisterNetEvent("vorp_core:Client:OnPlayerSpawned", function()
    Wait(1000)
    requestVorpSync()
end)

-- 5. Thread periódica de sincronização (cada 5s) para evitar drift de decaimento calórico interno
CreateThread(function()
    -- Sincronização inicial imediata
    requestVorpSync()

    while true do
        Wait(5000)
        requestVorpSync()
    end
end)

-- 6. Escuta redefinição de modo de voz (PMA-Voice)
RegisterNetEvent("pma-voice:setTalkingMode", function(mode)
    if type(mode) == "number" and mode >= 1 and mode <= 3 then
        voiceProximityMode = math.floor(mode)
    end
end)

RegisterNetEvent("pma-voice:radioActive", function(radioTalking)
    isForcedTalking = (radioTalking == true)
end)

-- 7. Restauração graciosa da HUD do VORP se o recurso westrp_ui for reiniciado ou finalizado
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    TriggerEvent("vorpmetabolism:setHud", true)
end)

-- ----------------------------------------------------------------------------
-- Adaptive Collector Thread (Resmon 0.00ms idle / <= 0.01ms active)
-- ----------------------------------------------------------------------------

CreateThread(function()
    -- Aguarda inicialização do ped do jogador
    while not DoesEntityExist(PlayerPedId()) do
        Wait(500)
    end

    while true do
        local ped = PlayerPedId()
        local playerId = PlayerId()
        local coords = GetEntityCoords(ped)

        -- 1. Leitura de Vitals do Ped
        local healthPct = getNormalizedHealth(ped)
        local staminaPct = getNormalizedStamina(playerId, ped)

        -- 2. Leitura de Fome e Sede
        local hungerPct = currentMetabolism.hunger
        local thirstPct = currentMetabolism.thirst

        -- 3. Leitura de Ambiente e Voz
        local temp, tempStatus = getTemperatureData(coords)
        local voiceLevel, isTalking = getVoiceData(playerId)

        -- 4. Leitura de Montaria Contextual
        local isMounted, mountHealth, mountStamina = getMountData(ped)

        -- 5. Leitura de Estado de Menus da Engine
        local isMenuOpen = checkAnyMenuOpen()

        -- 6. Throttling Delta: Avalia diretamente sem criar tabelas temporárias (Zero-GC no loop)
        if hasDelta(healthPct, staminaPct, hungerPct, thirstPct, temp, tempStatus, voiceLevel, isTalking, isMounted, mountHealth, mountStamina, isMenuOpen, isCinematicActive) then
            playerHudState.health = healthPct
            playerHudState.stamina = staminaPct
            playerHudState.hunger = hungerPct
            playerHudState.thirst = thirstPct
            playerHudState.temperature = temp
            playerHudState.tempStatus = tempStatus
            playerHudState.voiceLevel = voiceLevel
            playerHudState.isTalking = isTalking
            playerHudState.mountActive = isMounted
            playerHudState.mountHealth = mountHealth
            playerHudState.mountStamina = mountStamina
            playerHudState.isUIMenuOpen = isMenuOpen
            playerHudState.isCinematic = isCinematicActive

            dispatchHudUpdate()
        end

        -- 7. Tick Adaptativo
        if isPedInActiveMovement(ped, isMounted) then
            Wait(UPDATE_INTERVAL_ACTIVE)
        else
            Wait(UPDATE_INTERVAL_IDLE)
        end
    end
end)
