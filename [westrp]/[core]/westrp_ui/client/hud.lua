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
local isForcedTalking = nil     -- nil: automático via natives/pma-voice, boolean: override de teste
local isForcedVoiceLevel = nil  -- nil: automático via pma-voice/mumble, integer: override de teste
local isForcedRadio = nil       -- nil: automático via pma-voice, boolean: override de teste
local isRadioActive = false
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
    isRadio = false,
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

local forcedMountActive = nil -- nil: automático via IsPedOnMount, boolean: override de teste

-- Overrides de teste para fixar valores da montaria durante simulações e testes
local forcedMountVitals = {
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

---Verifica se o jogador local está falando no microfone de forma resiliente
---Combina detecção nativa Mumble (pma-voice) e RedM nativo (0xEF6F2A35FAAF2ED7)
---@param playerId integer
---@return boolean
local function isLocalPlayerTalking(playerId)
    if isForcedTalking ~= nil then
        return isForcedTalking
    end

    local radioOn = (isForcedRadio ~= nil) and isForcedRadio or isRadioActive
    if radioOn then
        return true
    end

    -- 1. Detecção Primária: Mumble (utilizado pelo PMA-Voice no FiveM/RedM)
    if MumbleIsPlayerTalking then
        local ok, result = pcall(MumbleIsPlayerTalking, playerId)
        if ok and (result == 1 or result == true) then
            return true
        end
    end

    -- 2. Detecção Secundária / Nativa RedM: NetworkIsPlayerTalking (0xEF6F2A35FAAF2ED7)
    if NetworkIsPlayerTalking then
        local ok, result = pcall(NetworkIsPlayerTalking, playerId)
        if ok and (result == 1 or result == true) then
            return true
        end
    end

    return false
end

---Obtém o nível de proximidade calibrado e verificado (1: Sussurro, 2: Normal, 3: Grito)
---@return integer
local function getProximityLevel()
    if isForcedVoiceLevel ~= nil then
        return isForcedVoiceLevel
    end

    -- 1. Se recebemos o índice do PMA-Voice (via state bag ou evento), respeita estritamente o índice
    if voiceProximityMode and voiceProximityMode >= 1 and voiceProximityMode <= 3 then
        return voiceProximityMode
    end

    -- 2. Fallback para MumbleGetTalkerProximity() caso PMA-Voice não tenha enviado o índice
    if MumbleGetTalkerProximity then
        local ok, proximity = pcall(MumbleGetTalkerProximity)
        if ok and type(proximity) == "number" and proximity > 0 then
            local isNativeAudio = GetConvar('voice_useNativeAudio', 'false') == 'true'
            if isNativeAudio then
                if proximity <= 2.0 then
                    return 1 -- Sussurro (1.5m)
                elseif proximity <= 4.5 then
                    return 2 -- Normal (3.0m)
                else
                    return 3 -- Grito (6.0m+)
                end
            else
                if proximity <= 4.0 then
                    return 1 -- Sussurro (3.0m)
                elseif proximity <= 9.0 then
                    return 2 -- Normal (7.0m)
                else
                    return 3 -- Grito (15.0m+)
                end
            end
        end
    end

    return 2
end

---Obtém dados completos do sistema de voz (PMA-Voice / Mumble / RedM Native)
---@param playerId integer
---@return integer, boolean, boolean
local function getVoiceData(playerId)
    local isTalking = isLocalPlayerTalking(playerId)
    local isRadio = (isForcedRadio ~= nil) and isForcedRadio or isRadioActive
    local level = getProximityLevel()
    return level, isTalking, isRadio
end

---Lê dados da montaria caso o ped esteja montado de forma sincronizada com as natives do RedM
---@param ped integer
---@return boolean, number, number, number, number, integer
local function getMountData(ped)
    local isMounted = false
    if forcedMountActive ~= nil then
        isMounted = forcedMountActive
    elseif DoesEntityExist(ped) and IsPedOnMount(ped) then
        isMounted = true
    end

    if not isMounted then
        return false, 0.0, 0.0, 0.0, 0.0, 0
    end

    local mount = 0
    if DoesEntityExist(ped) then
        mount = GetMount(ped)
        if not mount or mount == 0 then
            -- Fallback direto via native GET_MOUNT (0xE7E11B8DCBED1058)
            local okM, mNative = pcall(Citizen.InvokeNative, 0xE7E11B8DCBED1058, ped, Citizen.ResultAsInteger())
            if okM and mNative and mNative ~= 0 then
                mount = mNative
            end
        end
    end

    -- Se não houver entidade de montaria válida (ex: em teste forçado ou transição de montagem)
    if not mount or mount == 0 or not DoesEntityExist(mount) or IsEntityDead(mount) then
        if forcedMountActive then
            local hBar = forcedMountVitals.healthBar or 100.0
            local hCore = forcedMountVitals.healthCore or 100.0
            local sBar = forcedMountVitals.staminaBar or 100.0
            local sCore = forcedMountVitals.staminaCore or 100.0
            return true, hBar, hCore, sBar, sCore, 0
        end
        return false, 0.0, 0.0, 0.0, 0.0, 0
    end

    -- 1. Núcleo Interno de Vida do Cavalo (Core 0: 0.0 a 100.0)
    local healthCore = 100.0
    local okHealthCore, valHCore = pcall(GetAttributeCoreValue, mount, 0)
    if not okHealthCore or type(valHCore) ~= "number" then
        local okNative, valNative = pcall(Citizen.InvokeNative, 0x36731AC041289BB1, mount, 0, Citizen.ResultAsInteger())
        if okNative and type(valNative) == "number" then
            valHCore = valNative
        end
    end
    if type(valHCore) == "number" then
        healthCore = math.max(0.0, math.min(100.0, valHCore + 0.0))
    end

    -- 2. Barra Externa de Vida do Cavalo (0.0 a 100.0%)
    -- No RedM, GetEntityHealth do cavalo escala de 0 até GetEntityMaxHealth(mount)
    local healthBar = 100.0
    local currentHealth = GetEntityHealth(mount)
    local maxHealth = GetEntityMaxHealth(mount)
    if not maxHealth or maxHealth <= 0 then
        maxHealth = math.max(100, currentHealth)
    end
    if maxHealth > 0 then
        healthBar = math.max(0.0, math.min(100.0, (currentHealth / maxHealth) * 100.0))
    end

    -- 3. Núcleo Interno de Estamina do Cavalo (Core 1: 0.0 a 100.0)
    local staminaCore = 100.0
    local okStamCore, valSCore = pcall(GetAttributeCoreValue, mount, 1)
    if not okStamCore or type(valSCore) ~= "number" then
        local okNative, valNative = pcall(Citizen.InvokeNative, 0x36731AC041289BB1, mount, 1, Citizen.ResultAsInteger())
        if okNative and type(valNative) == "number" then
            valSCore = valNative
        end
    end
    if type(valSCore) == "number" then
        staminaCore = math.max(0.0, math.min(100.0, valSCore + 0.0))
    end

    -- 4. Barra Externa de Estamina do Cavalo (0.0 a 100.0%)
    -- Lê estamina atual e estamina máxima via natives RedM/RDR2
    local staminaBar = staminaCore
    local curStamina = -1.0
    local maxStamina = -1.0

    if GetPedStamina and GetPedMaxStamina then
        local okCur, valCur = pcall(GetPedStamina, mount)
        local okMax, valMax = pcall(GetPedMaxStamina, mount)
        if okCur and type(valCur) == "number" then curStamina = valCur end
        if okMax and type(valMax) == "number" then maxStamina = valMax end
    end

    -- 0x22F2A386D43048A9: _GET_PED_STAMINA (float)
    if curStamina < 0.0 then
        local okCurNat, valCurNat = pcall(Citizen.InvokeNative, 0x22F2A386D43048A9, mount, Citizen.ResultAsFloat())
        if okCurNat and type(valCurNat) == "number" then
            curStamina = valCurNat
        end
    end

    -- 0xCB42AFE2B613EE55: _GET_PED_MAX_STAMINA (float)
    if maxStamina <= 0.0 then
        local okMaxNat, valMaxNat = pcall(Citizen.InvokeNative, 0xCB42AFE2B613EE55, mount, Citizen.ResultAsFloat())
        if okMaxNat and type(valMaxNat) == "number" and valMaxNat > 0.0 then
            maxStamina = valMaxNat
        end
    end

    -- Normalização proporcional da estamina do cavalo
    if maxStamina > 0.0 and curStamina >= 0.0 then
        staminaBar = math.max(0.0, math.min(100.0, (curStamina / maxStamina) * 100.0))
    elseif curStamina >= 0.0 then
        if curStamina <= 1.0 then
            staminaBar = curStamina * 100.0
        elseif curStamina <= 100.0 then
            staminaBar = curStamina
        end
    end

    -- 5. Aplicação de overrides de simulação/teste
    if forcedMountVitals.healthBar ~= nil then healthBar = forcedMountVitals.healthBar end
    if forcedMountVitals.healthCore ~= nil then healthCore = forcedMountVitals.healthCore end
    if forcedMountVitals.staminaBar ~= nil then staminaBar = forcedMountVitals.staminaBar end
    if forcedMountVitals.staminaCore ~= nil then staminaCore = forcedMountVitals.staminaCore end

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

---Avalia se o jogador ou a montaria está em ação física intensa para ditar a taxa de tick
---@param ped integer
---@param isMounted boolean
---@param mountPed integer|nil
---@return boolean
local function isPedInActiveMovement(ped, isMounted, mountPed)
    if IsPedSprinting(ped) or IsPedRunning(ped) or IsPedSwimming(ped) or IsPedInMeleeCombat(ped) then
        return true
    end

    if isMounted then
        local checkEntity = (mountPed and mountPed ~= 0 and DoesEntityExist(mountPed)) and mountPed or ped
        local speed = GetEntitySpeed(checkEntity)
        if speed > 2.0 then
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
local function hasDelta(healthBar, healthCore, healthGolden, staminaBar, staminaCore, staminaGolden, hunger, thirst, temp, tempStatus, voiceLevel, isTalking, isRadio, mountActive, mountHealthBar, mountHealthCore, mountHealthGolden, mountStaminaBar, mountStaminaCore, mountStaminaGolden, isMenuOpen, isCinematic)
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
    if isRadio ~= playerHudState.isRadio then return true end
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
                isTalking = playerHudState.isTalking,
                isRadio = playerHudState.isRadio
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

---Define manualmente o nível de proximidade de voz (1: Sussurro, 2: Normal, 3: Grito, ou nil/'restore' para retornar ao automático)
---@param level integer|string|nil
local function setVoiceLevel(level)
    if level == nil or level == "restore" or level == "auto" then
        isForcedVoiceLevel = nil
    elseif type(level) == "number" and level >= 1 and level <= 3 then
        isForcedVoiceLevel = math.floor(level)
        voiceProximityMode = isForcedVoiceLevel
    end
end
exports('SetVoiceLevel', setVoiceLevel)

---Permite forçar ou simular estado de microfone ativo/falando (nil/'restore' para retornar à detecção nativa)
---@param talking boolean|string|nil
local function setVoiceTalking(talking)
    if talking == nil or talking == "restore" or talking == "auto" then
        isForcedTalking = nil
    else
        isForcedTalking = (talking == true)
    end
end
exports('SetVoiceTalking', setVoiceTalking)

---Permite forçar ou simular transmissão via rádio (nil/'restore' para retornar ao PMA-Voice)
---@param radioActive boolean|string|nil
local function setVoiceRadio(radioActive)
    if radioActive == nil or radioActive == "restore" or radioActive == "auto" then
        isForcedRadio = nil
    else
        isForcedRadio = (radioActive == true)
    end
end
exports('SetVoiceRadio', setVoiceRadio)

---Retorna o estado atual de voz (nível, se está falando e se está no rádio)
---@return table
local function getVoiceDataExport()
    return {
        level = playerHudState.voiceLevel,
        isTalking = playerHudState.isTalking,
        isRadio = playerHudState.isRadio
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

---Define override de teste para vida da montaria (barra e núcleo)
---@param bar number|string|nil
---@param core number|nil
local function setMountHealthOverride(bar, core)
    if bar == "restore" or bar == false then
        forcedMountVitals.healthBar = nil
        forcedMountVitals.healthCore = nil
    elseif type(bar) == "number" then
        forcedMountVitals.healthBar = math.max(0.0, math.min(100.0, bar))
        if type(core) == "number" then
            forcedMountVitals.healthCore = math.max(0.0, math.min(100.0, core))
        end
    end
end
exports('SetMountHealthOverride', setMountHealthOverride)

---Define override de teste para estamina da montaria (barra e núcleo)
---@param bar number|string|nil
---@param core number|nil
local function setMountStaminaOverride(bar, core)
    if bar == "restore" or bar == false then
        forcedMountVitals.staminaBar = nil
        forcedMountVitals.staminaCore = nil
    elseif type(bar) == "number" then
        forcedMountVitals.staminaBar = math.max(0.0, math.min(100.0, bar))
        if type(core) == "number" then
            forcedMountVitals.staminaCore = math.max(0.0, math.min(100.0, core))
        end
    end
end
exports('SetMountStaminaOverride', setMountStaminaOverride)

---Permite forçar ou simular o estado montado/desmontado (nil/'restore' para retornar à detecção nativa)
---@param active boolean|string|nil
local function setMountActiveOverride(active)
    if active == nil or active == "restore" or active == "auto" then
        forcedMountActive = nil
    else
        forcedMountActive = (active == true)
    end
end
exports('SetMountActiveOverride', setMountActiveOverride)

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

---Sincroniza o modo de proximidade e status de rádio iniciais a partir do StateBag do PMA-Voice
local function syncVoiceProximityFromStateBag()
    if isForcedVoiceLevel == nil then
        if LocalPlayer and LocalPlayer.state and LocalPlayer.state.proximity then
            local prox = LocalPlayer.state.proximity
            if type(prox) == "table" and prox.index and type(prox.index) == "number" then
                voiceProximityMode = math.floor(prox.index)
            end
        end
    end
    if isForcedRadio == nil then
        if LocalPlayer and LocalPlayer.state and LocalPlayer.state.radioActive ~= nil then
            isRadioActive = (LocalPlayer.state.radioActive == true)
        end
    end
end

-- 6. Escuta StateBag de proximidade e rádio do PMA-Voice (0ms de latência entre recursos)
AddStateBagChangeHandler('proximity', nil, function(bagName, key, value)
    if isForcedVoiceLevel ~= nil then return end
    if bagName == ('player:%s'):format(GetPlayerServerId(PlayerId())) or bagName == 'local' then
        if type(value) == 'table' and value.index and type(value.index) == 'number' then
            voiceProximityMode = math.floor(value.index)
        end
    end
end)

AddStateBagChangeHandler('radioActive', nil, function(bagName, key, value)
    if isForcedRadio ~= nil then return end
    if bagName == ('player:%s'):format(GetPlayerServerId(PlayerId())) or bagName == 'local' then
        isRadioActive = (value == true)
    end
end)

-- 7. Escuta eventos legados de modo de voz e transmissão de rádio (PMA-Voice)
RegisterNetEvent("pma-voice:setTalkingMode", function(mode)
    if isForcedVoiceLevel ~= nil then return end
    if type(mode) == "number" and mode >= 1 and mode <= 3 then
        voiceProximityMode = math.floor(mode)
    end
end)

RegisterNetEvent("pma-voice:radioActive", function(radioTalking)
    if isForcedRadio ~= nil then return end
    isRadioActive = (radioTalking == true)
end)

-- 8. Restauração graciosa da HUD do VORP se o recurso westrp_ui for reiniciado ou finalizado
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    TriggerEvent("vorpmetabolism:setHud", true)
end)

-- ----------------------------------------------------------------------------
-- Micro-Thread de Telemetria de Voz em Tempo Real (0.00ms resmon / Zero-Latency PTT)
-- ----------------------------------------------------------------------------
CreateThread(function()
    while not DoesEntityExist(PlayerPedId()) do
        Wait(500)
    end

    syncVoiceProximityFromStateBag()

    local lastTalking = nil
    local lastRadio = nil
    local lastLevel = nil

    while true do
        local playerId = PlayerId()
        local level, talking, radio = getVoiceData(playerId)

        if talking ~= lastTalking or radio ~= lastRadio or level ~= lastLevel then
            lastTalking = talking
            lastRadio = radio
            lastLevel = level

            playerHudState.voiceLevel = level
            playerHudState.isTalking = talking
            playerHudState.isRadio = radio

            if isHudVisible and not isCinematicActive then
                SendNUIMessage({
                    action = "westrp_ui:updateVoice",
                    data = {
                        level = level,
                        isTalking = talking,
                        isRadio = radio
                    }
                })
            end
        end

        -- Se estiver falando, taxa de amostragem mais rápida (50ms) para reação imediata ao PTT
        -- Em repouso (silêncio), 120ms para manter Resmon em 0.00ms absoluto
        Wait(talking and 50 or 120)
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
        local voiceLevel, isTalking, isRadio = getVoiceData(playerId)

        -- 4. Leitura de Montaria Contextual
        local isMounted, mountHealthBar, mountHealthCore, mountStaminaBar, mountStaminaCore, mountPed = getMountData(ped)
        local mHGold = (isMounted and mountPed ~= 0 and isCoreOverpowered(mountPed, 0)) or false
        if forcedGolden.mountHealth ~= nil then mHGold = forcedGolden.mountHealth end

        local mSGold = (isMounted and mountPed ~= 0 and isCoreOverpowered(mountPed, 1)) or false
        if forcedGolden.mountStamina ~= nil then mSGold = forcedGolden.mountStamina end

        -- 5. Leitura de Estado de Menus da Engine
        local isMenuOpen = checkAnyMenuOpen()

        -- 6. Throttling Delta: Avalia diretamente sem criar tabelas temporárias (Zero-GC no loop)
        if hasDelta(hBar, hCore, hGold, sBar, sCore, sGold, hungerPct, thirstPct, temp, tempStatus, voiceLevel, isTalking, isRadio, isMounted, mountHealthBar, mountHealthCore, mHGold, mountStaminaBar, mountStaminaCore, mSGold, isMenuOpen, isCinematicActive) then
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
            playerHudState.isRadio = isRadio
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
        if isPedInActiveMovement(ped, isMounted, mountPed) then
            Wait(UPDATE_INTERVAL_ACTIVE)
        else
            Wait(UPDATE_INTERVAL_IDLE)
        end
    end
end)
