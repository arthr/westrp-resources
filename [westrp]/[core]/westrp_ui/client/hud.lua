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
    healthBar = -1.0,
    healthCore = -1.0,
    healthGolden = false,
    staminaBar = -1.0,
    staminaCore = -1.0,
    staminaGolden = false,
    hunger = 100.0,
    thirst = 100.0,
    temperature = -999.0,
    tempStatus = "normal",
    voiceLevel = 2,
    isTalking = false,
    mountActive = false,
    mountHealthBar = -1.0,
    mountHealthCore = -1.0,
    mountHealthGolden = false,
    mountStaminaBar = -1.0,
    mountStaminaCore = -1.0,
    mountStaminaGolden = false,
    isUIMenuOpen = false,
    isCinematic = false
}

-- Overrides de teste para fixar valores durante simulações e testes
local forcedVitals = {
    healthBar = nil,
    healthCore = nil,
    staminaBar = nil,
    staminaCore = nil
}

-- Estado de Núcleo Dourado / Fortificado (Golden Core) - overrides manuais de teste
-- Quando nil, o coletor lê em tempo real diretamente das natives do RedM
local forcedGolden = {
    health = nil,
    stamina = nil,
    mountHealth = nil,
    mountStamina = nil
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
-- Configurações parametrizáveis do HUD (comportamento de núcleos dinâmicos)
local hudConfig = {
    dynamicCores = {
        health = true,
        stamina = true,
        mountHealth = true,
        mountStamina = true,
        hunger = false, -- Por padrão, Fome sem efeito no ícone central (ícone estático / 100% visível)
        thirst = false  -- Por padrão, Sede sem efeito no ícone central (ícone estático / 100% visível)
    }
}

-- ----------------------------------------------------------------------------

---Calcula o percentual do Núcleo Interno de Vida (Core 0: 0.0 a 100.0)
---@param ped integer
---@return number
local function getNormalizedHealthCore(ped)
    if not DoesEntityExist(ped) then return 0.0 end
    local ok, coreVal = pcall(GetAttributeCoreValue, ped, 0)
    if ok and type(coreVal) == "number" then
        return math.max(0.0, math.min(100.0, coreVal + 0.0))
    end
    return 100.0
end

---Calcula o percentual da Barra Externa de Vida (Tank/Bar: 0.0 a 100.0)
---No RedM: GetEntityHealth = HealthOuter + HealthInner
---Quando a barra externa está vazia, GetEntityHealth <= healthCore
---@param ped integer
---@param healthCore number
---@return number
local function getNormalizedHealthBar(ped, healthCore)
    if not DoesEntityExist(ped) then return 0.0 end

    local currentHealth = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    if not maxHealth or maxHealth <= 0 then
        maxHealth = 600
    end

    -- Se a vida for <= ao núcleo, a barra externa está zerada
    local outerHealth = math.max(0.0, currentHealth - healthCore)
    -- Capacidade máxima da barra externa (MaxHealth menos a base do núcleo)
    local maxOuter = math.max(1.0, maxHealth - 100.0)

    local pct = (outerHealth / maxOuter) * 100.0
    return math.max(0.0, math.min(100.0, pct))
end

---Calcula o percentual do Núcleo Interno de Estamina (Core 1: 0.0 a 100.0)
---@param ped integer
---@return number
local function getNormalizedStaminaCore(ped)
    if not DoesEntityExist(ped) then return 0.0 end
    local ok, coreVal = pcall(GetAttributeCoreValue, ped, 1)
    if ok and type(coreVal) == "number" then
        return math.max(0.0, math.min(100.0, coreVal + 0.0))
    end
    return 100.0
end

---Calcula o percentual da Barra Externa de Estamina (0.0 a 100.0)
---Utiliza a native nativa RDR2 _GET_PED_STAMINA_NORMALIZED (0x22F2A386D43048A9)
---@param ped integer
---@return number
local function getNormalizedStaminaBar(ped)
    if not DoesEntityExist(ped) then return 0.0 end

    local ok, result = pcall(Citizen.InvokeNative, 0x22F2A386D43048A9, ped, Citizen.ResultAsFloat())
    if ok and type(result) == "number" then
        if result >= 0.0 and result <= 1.0 then
            return result * 100.0
        elseif result > 1.0 and result <= 100.0 then
            return result
        end
    end

    -- Fallback caso GetPedStamina e GetPedMaxStamina estejam disponíveis
    if GetPedStamina and GetPedMaxStamina then
        local cur = GetPedStamina(ped)
        local max = GetPedMaxStamina(ped)
        if max and max > 0 then
            return math.max(0.0, math.min(100.0, (cur / max) * 100.0))
        end
    end

    return 100.0
end

---Verifica se o atributo ou núcleo do ped está em estado overpower / dourado (Golden Core)
---Verifica tanto o núcleo interno (_IS_ATTRIBUTE_CORE_OVERPOWERED 0x200373A8DF081F22)
---quanto a barra externa (_IS_ATTRIBUTE_OVERPOWERED 0x103C2F885ABEB00B)
---@param ped integer
---@param attributeIndex integer 0: Vida, 1: Estamina, 2: DeadEye
---@return boolean
local function isCoreOverpowered(ped, attributeIndex)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end

    -- 1. RedM globals se exportados pelo runtime
    if IsAttributeCoreOverpowered then
        local ok, res = pcall(IsAttributeCoreOverpowered, ped, attributeIndex)
        if ok and (res == true or res == 1) then return true end
    end
    if IsAttributeOverpowered then
        local ok, res = pcall(IsAttributeOverpowered, ped, attributeIndex)
        if ok and (res == true or res == 1) then return true end
    end
    if _IS_ATTRIBUTE_CORE_OVERPOWERED then
        local ok, res = pcall(_IS_ATTRIBUTE_CORE_OVERPOWERED, ped, attributeIndex)
        if ok and (res == true or res == 1) then return true end
    end
    if _IS_ATTRIBUTE_OVERPOWERED then
        local ok, res = pcall(_IS_ATTRIBUTE_OVERPOWERED, ped, attributeIndex)
        if ok and (res == true or res == 1) then return true end
    end

    -- 2. Invocação nativa direta por Hash (RDR2 NativeDB)
    -- 0x200373A8DF081F22 = _IS_ATTRIBUTE_CORE_OVERPOWERED (núcleo interno dourado)
    local okCore, resCore = pcall(Citizen.InvokeNative, 0x200373A8DF081F22, ped, attributeIndex)
    if okCore and (resCore == true or resCore == 1) then return true end

    -- 0x103C2F885ABEB00B = _IS_ATTRIBUTE_OVERPOWERED (barra externa dourada)
    local okAttr, resAttr = pcall(Citizen.InvokeNative, 0x103C2F885ABEB00B, ped, attributeIndex)
    if okAttr and (resAttr == true or resAttr == 1) then return true end

    -- 3. Fallbacks com tipagem explícita Citizen.ResultAsInteger
    local okCoreInt, resCoreInt = pcall(Citizen.InvokeNative, 0x200373A8DF081F22, ped, attributeIndex, Citizen.ResultAsInteger())
    if okCoreInt and (resCoreInt == 1 or resCoreInt == true) then return true end

    local okAttrInt, resAttrInt = pcall(Citizen.InvokeNative, 0x103C2F885ABEB00B, ped, attributeIndex, Citizen.ResultAsInteger())
    if okAttrInt and (resAttrInt == 1 or resAttrInt == true) then return true end

    return false
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
---@return boolean, number, number, number, number, integer
local function getMountData(ped)
    if not IsPedOnMount(ped) then
        return false, 0.0, 0.0, 0.0, 0.0, 0
    end

    local mount = GetMount(ped)
    if not mount or mount == 0 or not DoesEntityExist(mount) then
        return false, 0.0, 0.0, 0.0, 0.0, 0
    end

    -- Health Core & Bar para o cavalo
    local healthCore = 100.0
    local okHealthCore, valHCore = pcall(GetAttributeCoreValue, mount, 0)
    if okHealthCore and type(valHCore) == "number" then
        healthCore = math.max(0.0, math.min(100.0, valHCore + 0.0))
    end

    local currentHealth = GetEntityHealth(mount)
    local maxHealth = GetPedMaxHealth(mount)
    if not maxHealth or maxHealth <= 0 then maxHealth = 600 end
    local outerHealth = math.max(0.0, currentHealth - healthCore)
    local maxOuter = math.max(1.0, maxHealth - 100.0)
    local healthBar = math.max(0.0, math.min(100.0, (outerHealth / maxOuter) * 100.0))

    -- Stamina Core & Bar para o cavalo
    local staminaCore = 100.0
    local okStamCore, valSCore = pcall(GetAttributeCoreValue, mount, 1)
    if okStamCore and type(valSCore) == "number" then
        staminaCore = math.max(0.0, math.min(100.0, valSCore + 0.0))
    end

    local staminaBar = 100.0
    local okStamBar, valSBar = pcall(Citizen.InvokeNative, 0x22F2A386D43048A9, mount, Citizen.ResultAsFloat())
    if okStamBar and type(valSBar) == "number" then
        if valSBar >= 0.0 and valSBar <= 1.0 then
            staminaBar = valSBar * 100.0
        elseif valSBar > 1.0 and valSBar <= 100.0 then
            staminaBar = valSBar
        end
    elseif GetPedStamina and GetPedMaxStamina then
        local curS = GetPedStamina(mount)
        local maxS = GetPedMaxStamina(mount)
        if maxS and maxS > 0 then
            staminaBar = math.max(0.0, math.min(100.0, (curS / maxS) * 100.0))
        end
    end

    return true, healthBar, healthCore, staminaBar, staminaCore, mount
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
---@param healthBar number
---@param healthCore number
---@param healthGolden boolean
---@param staminaBar number
---@param staminaCore number
---@param staminaGolden boolean
---@param hunger number
---@param thirst number
---@param temp number
---@param tempStatus string
---@param voiceLevel integer
---@param isTalking boolean
---@param mountActive boolean
---@param mountHealthBar number
---@param mountHealthCore number
---@param mountHealthGolden boolean
---@param mountStaminaBar number
---@param mountStaminaCore number
---@param mountStaminaGolden boolean
---@param isMenuOpen boolean
---@param isCinematic boolean
---@return boolean
local function hasDelta(healthBar, healthCore, healthGolden, staminaBar, staminaCore, staminaGolden, hunger, thirst, temp, tempStatus, voiceLevel, isTalking, mountActive, mountHealthBar, mountHealthCore, mountHealthGolden, mountStaminaBar, mountStaminaCore, mountStaminaGolden, isMenuOpen, isCinematic)
    if math.abs(healthBar - playerHudState.healthBar) >= DELTA_THRESHOLD then return true end
    if math.abs(healthCore - playerHudState.healthCore) >= DELTA_THRESHOLD then return true end
    if healthGolden ~= playerHudState.healthGolden then return true end
    if math.abs(staminaBar - playerHudState.staminaBar) >= DELTA_THRESHOLD then return true end
    if math.abs(staminaCore - playerHudState.staminaCore) >= DELTA_THRESHOLD then return true end
    if staminaGolden ~= playerHudState.staminaGolden then return true end
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
        if math.abs(mountHealthBar - playerHudState.mountHealthBar) >= DELTA_THRESHOLD then return true end
        if math.abs(mountHealthCore - playerHudState.mountHealthCore) >= DELTA_THRESHOLD then return true end
        if mountHealthGolden ~= playerHudState.mountHealthGolden then return true end
        if math.abs(mountStaminaBar - playerHudState.mountStaminaBar) >= DELTA_THRESHOLD then return true end
        if math.abs(mountStaminaCore - playerHudState.mountStaminaCore) >= DELTA_THRESHOLD then return true end
        if mountStaminaGolden ~= playerHudState.mountStaminaGolden then return true end
    end

    return false
end

---Despacha o pacote consolidado de dados para o frontend Chromium CEF
local function dispatchHudUpdate()
    SendNUIMessage({
        action = "westrp_ui:updatePlayerHud",
        data = {
            visible = isHudVisible,
            health = {
                bar = playerHudState.healthBar,
                core = playerHudState.healthCore,
                golden = playerHudState.healthGolden
            },
            stamina = {
                bar = playerHudState.staminaBar,
                core = playerHudState.staminaCore,
                golden = playerHudState.staminaGolden
            },
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
                health = {
                    bar = playerHudState.mountHealthBar,
                    core = playerHudState.mountHealthCore,
                    golden = playerHudState.mountHealthGolden
                },
                stamina = {
                    bar = playerHudState.mountStaminaBar,
                    core = playerHudState.mountStaminaCore,
                    golden = playerHudState.mountStaminaGolden
                }
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

---Define override de teste para vida (barra e núcleo)
---@param bar number|string|nil
---@param core number|nil
local function setHealthOverride(bar, core)
    if bar == "restore" or bar == false then
        forcedVitals.healthBar = nil
        forcedVitals.healthCore = nil
    elseif type(bar) == "number" then
        forcedVitals.healthBar = math.max(0.0, math.min(100.0, bar))
        if type(core) == "number" then
            forcedVitals.healthCore = math.max(0.0, math.min(100.0, core))
        end
    end
end
exports('SetHealthOverride', setHealthOverride)

---Define override de teste para estamina (barra e núcleo)
---@param bar number|string|nil
---@param core number|nil
local function setStaminaOverride(bar, core)
    if bar == "restore" or bar == false then
        forcedVitals.staminaBar = nil
        forcedVitals.staminaCore = nil
    elseif type(bar) == "number" then
        forcedVitals.staminaBar = math.max(0.0, math.min(100.0, bar))
        if type(core) == "number" then
            forcedVitals.staminaCore = math.max(0.0, math.min(100.0, core))
        end
    end
end
exports('SetStaminaOverride', setStaminaOverride)

---Permite parametrizar dinamicamente os efeitos e configurações do HUD
---@param settings table
local function configureHudSettings(settings)
    if type(settings) ~= "table" then return end

    if settings.dynamicCores and type(settings.dynamicCores) == "table" then
        for k, v in pairs(settings.dynamicCores) do
            if hudConfig.dynamicCores[k] ~= nil then
                hudConfig.dynamicCores[k] = (v == true)
            end
        end
    end

    SendNUIMessage({
        action = "westrp_ui:configureHud",
        data = hudConfig
    })
end
exports('ConfigureHudSettings', configureHudSettings)

---Retorna a configuração atual do HUD
---@return table
local function getHudConfig()
    return hudConfig
end
exports('GetHudConfig', getHudConfig)

---Define o estado de Núcleo Dourado / Fortificado (Golden Core)
---@param attribute string 'health' | 'stamina' | 'mountHealth' | 'mountStamina' | 'all'
---@param isGolden boolean|string|number|nil true para ativar, false para desativar, "restore" ou nil para restaurar leitura nativa
local function setGoldenCore(attribute, isGolden)
    if type(attribute) ~= "string" then return end
    local lower = string.lower(attribute)
    local state = nil
    if isGolden == "restore" or isGolden == "auto" or isGolden == "reset" or isGolden == nil then
        state = nil
    else
        state = (isGolden == true or isGolden == "true" or isGolden == 1 or isGolden == "on")
    end

    if lower == "health" then
        forcedGolden.health = state
    elseif lower == "stamina" then
        forcedGolden.stamina = state
    elseif lower == "mounthealth" or lower == "mount_health" then
        forcedGolden.mountHealth = state
    elseif lower == "mountstamina" or lower == "mount_stamina" then
        forcedGolden.mountStamina = state
    elseif lower == "all" then
        forcedGolden.health = state
        forcedGolden.stamina = state
        forcedGolden.mountHealth = state
        forcedGolden.mountStamina = state
    end
end
exports('SetGoldenCore', setGoldenCore)

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

    -- Envia parametrização inicial para a NUI
    SendNUIMessage({
        action = "westrp_ui:configureHud",
        data = hudConfig
    })

    while true do
        local ped = PlayerPedId()
        local playerId = PlayerId()
        local coords = GetEntityCoords(ped)

        -- 1. Leitura de Vitals do Ped (com suporte a overrides de simulação)
        local hCore = getNormalizedHealthCore(ped)
        local hBar = getNormalizedHealthBar(ped, hCore)
        if forcedVitals.healthBar ~= nil then hBar = forcedVitals.healthBar end
        if forcedVitals.healthCore ~= nil then hCore = forcedVitals.healthCore end

        local sCore = getNormalizedStaminaCore(ped)
        local sBar = getNormalizedStaminaBar(ped)
        if forcedVitals.staminaBar ~= nil then sBar = forcedVitals.staminaBar end
        if forcedVitals.staminaCore ~= nil then sCore = forcedVitals.staminaCore end

        local hGold = isCoreOverpowered(ped, 0)
        if forcedGolden.health ~= nil then hGold = forcedGolden.health end

        local sGold = isCoreOverpowered(ped, 1)
        if forcedGolden.stamina ~= nil then sGold = forcedGolden.stamina end

        -- 2. Leitura de Fome e Sede
        local hungerPct = currentMetabolism.hunger
        local thirstPct = currentMetabolism.thirst

        -- 3. Leitura de Ambiente e Voz
        local temp, tempStatus = getTemperatureData(coords)
        local voiceLevel, isTalking = getVoiceData(playerId)

        -- 4. Leitura de Montaria Contextual
        local isMounted, mountHealthBar, mountHealthCore, mountStaminaBar, mountStaminaCore, mountPed = getMountData(ped)
        local mHGold = (isMounted and mountPed ~= 0 and isCoreOverpowered(mountPed, 0)) or false
        if forcedGolden.mountHealth ~= nil then mHGold = forcedGolden.mountHealth end

        local mSGold = (isMounted and mountPed ~= 0 and isCoreOverpowered(mountPed, 1)) or false
        if forcedGolden.mountStamina ~= nil then mSGold = forcedGolden.mountStamina end

        -- 5. Leitura de Estado de Menus da Engine
        local isMenuOpen = checkAnyMenuOpen()

        -- 6. Throttling Delta: Avalia diretamente sem criar tabelas temporárias (Zero-GC no loop)
        if hasDelta(hBar, hCore, hGold, sBar, sCore, sGold, hungerPct, thirstPct, temp, tempStatus, voiceLevel, isTalking, isMounted, mountHealthBar, mountHealthCore, mHGold, mountStaminaBar, mountStaminaCore, mSGold, isMenuOpen, isCinematicActive) then
            playerHudState.healthBar = hBar
            playerHudState.healthCore = hCore
            playerHudState.healthGolden = hGold
            playerHudState.staminaBar = sBar
            playerHudState.staminaCore = sCore
            playerHudState.staminaGolden = sGold
            playerHudState.hunger = hungerPct
            playerHudState.thirst = thirstPct
            playerHudState.temperature = temp
            playerHudState.tempStatus = tempStatus
            playerHudState.voiceLevel = voiceLevel
            playerHudState.isTalking = isTalking
            playerHudState.mountActive = isMounted
            playerHudState.mountHealthBar = mountHealthBar
            playerHudState.mountHealthCore = mountHealthCore
            playerHudState.mountHealthGolden = mHGold
            playerHudState.mountStaminaBar = mountStaminaBar
            playerHudState.mountStaminaCore = mountStaminaCore
            playerHudState.mountStaminaGolden = mSGold
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
