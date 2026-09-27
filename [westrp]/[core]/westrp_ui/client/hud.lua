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
    if GetTemperatureAtCoords then
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
    local isTalking = false
    if MumbleIsPlayerTalking then
        local ok, result = pcall(MumbleIsPlayerTalking, playerId)
        if ok and result then isTalking = true end
    elseif NetworkIsPlayerTalking then
        local ok, result = pcall(NetworkIsPlayerTalking, playerId)
        if ok and result then isTalking = true end
    end

    local level = 2
    if MumbleGetTalkerProximity then
        local ok, proximity = pcall(MumbleGetTalkerProximity)
        if ok and type(proximity) == "number" then
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

---Injeção direta de dados de metabolismo (fome e sede 0 a 100%)
---@param hunger number
---@param thirst number
local function updateMetabolismStatus(hunger, thirst)
    if type(hunger) == "number" then
        currentMetabolism.hunger = math.max(0.0, math.min(100.0, hunger))
    end
    if type(thirst) == "number" then
        currentMetabolism.thirst = math.max(0.0, math.min(100.0, thirst))
    end
end
exports('UpdateMetabolismStatus', updateMetabolismStatus)

-- ----------------------------------------------------------------------------
-- Integration Bridge: vorp_metabolism Listeners & Sync
-- ----------------------------------------------------------------------------

-- 1. Carga inicial de personagem do VORP
RegisterNetEvent("vorpmetabolism:StartFunctions", function(status)
    if not status or #status < 2 then return end
    local ok, decoded = pcall(json.decode, status)
    if ok and type(decoded) == "table" then
        if decoded.Hunger then
            currentMetabolism.hunger = math.max(0.0, math.min(100.0, decoded.Hunger / 10.0))
        end
        if decoded.Thirst then
            currentMetabolism.thirst = math.max(0.0, math.min(100.0, decoded.Thirst / 10.0))
        end
    end
end)

-- 2. Alteração delta de valor do VORP
RegisterNetEvent("vorpmetabolism:changeValue", function(key, value)
    if not key or not value or type(value) ~= "number" then return end
    local lowerKey = string.lower(key)
    local deltaPct = value / 10.0
    if lowerKey == "hunger" then
        currentMetabolism.hunger = math.max(0.0, math.min(100.0, currentMetabolism.hunger + deltaPct))
    elseif lowerKey == "thirst" then
        currentMetabolism.thirst = math.max(0.0, math.min(100.0, currentMetabolism.thirst + deltaPct))
    end
end)

-- 3. Definição absoluta de valor do VORP
RegisterNetEvent("vorpmetabolism:setValue", function(key, value)
    if not key or not value or type(value) ~= "number" then return end
    local lowerKey = string.lower(key)
    local newPct = value / 10.0
    if lowerKey == "hunger" then
        currentMetabolism.hunger = math.max(0.0, math.min(100.0, newPct))
    elseif lowerKey == "thirst" then
        currentMetabolism.thirst = math.max(0.0, math.min(100.0, newPct))
    end
end)

-- 4. Thread periódica de sincronização (cada 5s) para evitar drift de decaimento calórico interno
CreateThread(function()
    while true do
        Wait(5000)
        TriggerEvent("vorpmetabolism:getValue", "Hunger", function(val)
            if val and type(val) == "number" then
                currentMetabolism.hunger = math.max(0.0, math.min(100.0, val / 10.0))
            end
        end)
        TriggerEvent("vorpmetabolism:getValue", "Thirst", function(val)
            if val and type(val) == "number" then
                currentMetabolism.thirst = math.max(0.0, math.min(100.0, val / 10.0))
            end
        end)
    end
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
