WestRP = WestRP or {}
WestRP.Admin = WestRP.Admin or {}
WestRP.Admin.Boosters = {}

local state = {
    godmode     = false,
    noclip      = false,
    invis       = false,
    goldencores = false,
    infiammo    = false
}

local currentSpeedIndex = 3 -- 'Normal' por padrão
local promptGroup = GetRandomIntInRange(0, 0xffffff)
local prompts = {}

-- FUNÇÕES AUXILIARES DE PROMPTS
--------------------------------------------------------------------------------
local function InitializePrompts()
    if prompts.initialized then return end

    local function createPrompt(control1, control2, text)
        local p = UiPromptRegisterBegin()
        UiPromptSetControlAction(p, control1)
        if control2 then
            UiPromptSetControlAction(p, control2)
        end
        local str = VarString(10, 'LITERAL_STRING', text)
        UiPromptSetText(p, str)
        UiPromptSetEnabled(p, true)
        UiPromptSetVisible(p, true)
        UiPromptSetStandardMode(p, true)
        UiPromptSetGroup(p, promptGroup, 0)
        UiPromptRegisterEnd(p)
        return p
    end

    prompts.elevate = createPrompt(Config.NoClip.Controls.goDown, Config.NoClip.Controls.goUp, "Descer / Subir")
    prompts.speed   = createPrompt(Config.NoClip.Controls.changeSpeed, nil, "Velocidade")
    prompts.move    = createPrompt(Config.NoClip.Controls.goBackward, Config.NoClip.Controls.goForward, "Ré / Avançar")
    prompts.cancel  = createPrompt(Config.NoClip.Controls.Cancel, nil, "Desativar")
    prompts.initialized = true
end

local function CleanupPrompts()
    if not prompts.initialized then return end
    for k, p in pairs(prompts) do
        if k ~= "initialized" and p and p ~= 0 then
            UiPromptDelete(p)
        end
    end
    prompts = {}
end

--------------------------------------------------------------------------------
-- NOCLIP (0.00ms IDLE VIA TICKMANAGER)
--------------------------------------------------------------------------------
local function DisableControlsThisFrame()
    DisableControlAction(0, 0xB238FE0B, true) -- Parar controles padrão
    DisableControlAction(0, 0x3C0A40F2, true)
end

local function GetFallImpulse(height)
    local coefficient = 1.6428571428571428
    local intercept = 3.5714285714285836
    return coefficient * height + intercept
end

local function SoftLandingDamping()
    CreateThread(function()
        local ped = PlayerPedId()
        local pedHeight = GetEntityHeightAboveGround(ped)
        if not pedHeight or pedHeight < 3.0 then return end

        SetEntityInvincible(ped, true)
        SetRagdollBlockingFlags(ped, (1 << 9)) -- RBF_FALLING
        local downForce = GetFallImpulse(pedHeight)
        ApplyForceToEntity(ped, 3, 0.0, 0.0, -downForce, 0.0, 0.0, 0.0, 0, true, true, false, true, false)

        local elapsed = 0
        while not IsPedFalling(ped) and elapsed < 1000 do
            elapsed = elapsed + 25
            Wait(25)
        end

        repeat Wait(50) until not IsPedFalling(ped)
        Wait(500)
        SetEntityInvincible(ped, false)
        ClearRagdollBlockingFlags(ped, (1 << 9))
    end)
end

local function ResetNoclipEntity(ped)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    if not state.invis then
        SetEntityVisible(ped, true)
    end
    SetEveryoneIgnorePlayer(PlayerId(), false)
    SetPedCanBeTargetted(ped, true)
    SetGameplayCamInitialHeading(0.0)
    SetPlayerLockon(PlayerId(), true)
    ClearPedTasks(ped, true, true)
end

local function EnableNoclipEntity(ped)
    ClearPedTasks(ped, true, true)
    SetGameplayCamInitialHeading(0.0)
    SetPlayerLockon(PlayerId(), false)
    SetEntityCollision(ped, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false)
    SetEveryoneIgnorePlayer(PlayerId(), true)
    SetPedCanBeTargetted(ped, false)
end

---Alterna o estado do NoClip
---@return boolean novoEstado
function WestRP.Admin.Boosters.ToggleNoClip()
    local ped = PlayerPedId()
    state.noclip = not state.noclip

    if state.noclip then
        InitializePrompts()
        EnableNoclipEntity(ped)

        -- Registra no TickManager para rodar a cada frame apenas quando ativo
        WestRP.Client.TickManager.RegisterTick("admin_noclip", function()
            local player = PlayerPedId()
            local yoff = 0.0
            local zoff = 0.0

            DisableControlsThisFrame()
            SetEntityVisible(player, false)

            local currentSpeedConfig = Config.NoClip.Speeds[currentSpeedIndex]
            local labelStr = VarString(10, 'LITERAL_STRING', "Velocidade: " .. currentSpeedConfig.label .. " (" .. currentSpeedConfig.speed .. "x)")
            UiPromptSetActiveGroupThisFrame(promptGroup, labelStr, 0, 0, 0, 0)

            -- Alternar velocidade (L-Shift)
            if IsDisabledControlJustPressed(1, Config.NoClip.Controls.changeSpeed) then
                currentSpeedIndex = currentSpeedIndex + 1
                if currentSpeedIndex > #Config.NoClip.Speeds then
                    currentSpeedIndex = 1
                end
            end

            -- Frente / Trás
            if IsDisabledControlPressed(0, Config.NoClip.Controls.goForward) then
                yoff = Config.NoClip.Offsets.y
                SetEntityRotation(player, 0.0, 0.0, 0.0, 2, false)
                local heading = GetGameplayCamRelativeHeading()
                SetEntityHeading(player, heading)
            elseif IsDisabledControlPressed(0, Config.NoClip.Controls.goBackward) then
                yoff = -Config.NoClip.Offsets.y
                SetEntityRotation(player, 0.0, 0.0, 0.0, 2, false)
                local heading = GetGameplayCamRelativeHeading()
                SetEntityHeading(player, heading)
            end

            -- Subir / Descer
            if IsDisabledControlPressed(0, Config.NoClip.Controls.goUp) then
                zoff = Config.NoClip.Offsets.z
            elseif IsDisabledControlPressed(0, Config.NoClip.Controls.goDown) then
                zoff = -Config.NoClip.Offsets.z
            end

            -- Cancelar (Delete)
            if IsDisabledControlPressed(0, Config.NoClip.Controls.Cancel) then
                WestRP.Admin.Boosters.ToggleNoClip()
                return
            end

            -- Movimentação física
            if yoff ~= 0.0 or zoff ~= 0.0 then
                local mult = currentSpeedConfig.speed + 0.3
                local newPos = GetOffsetFromEntityInWorldCoords(player, 0.0, yoff * mult, zoff * mult)
                SetEntityCoordsNoOffset(player, newPos.x, newPos.y, newPos.z, true, true, true)
            end
        end)

        WestRP.Client.UI.ShowToast("NOCLIP", "Modo voo ativado com sucesso", "success")
        TriggerServerEvent("westrp_admin:server:logBooster", "NoClip", "Ativou o NoClip")
    else
        WestRP.Client.TickManager.UnregisterTick("admin_noclip")
        ResetNoclipEntity(ped)
        SoftLandingDamping()
        CleanupPrompts()
        WestRP.Client.UI.ShowToast("NOCLIP", "Modo voo desativado", "info")
        TriggerServerEvent("westrp_admin:server:logBooster", "NoClip", "Desativou o NoClip")
    end

    return state.noclip
end

--------------------------------------------------------------------------------
-- MODO DEUS (GODMODE 511 PROOFS)
--------------------------------------------------------------------------------
---Alterna o estado do GodMode
---@return boolean novoEstado
function WestRP.Admin.Boosters.ToggleGodMode()
    state.godmode = not state.godmode
    local ped = PlayerPedId()
    local playerId = PlayerId()

    if state.godmode then
        -- Ativação no TickManager
        WestRP.Client.TickManager.RegisterTick("admin_godmode", function()
            local p = PlayerPedId()
            local pId = PlayerId()

            SetPlayerInvincible(pId, true)
            SetEntityInvincible(p, true)
            SetEntityCanBeDamaged(p, false)
            SetEntityProofs(p, 511, true) -- Proofs totais

            SetPedConfigFlag(p, 2, true) -- Sem headshots
            SetPedCanRagdoll(p, false)
            SetPedCanBeTargetted(p, false)
            Citizen.InvokeNative(0x5240864E847C691C, p, false)  -- Não incapacita
            Citizen.InvokeNative(0xFD6943B6DF77E449, p, false)  -- Não pode ser laçado
            Citizen.InvokeNative(0xC3D4B754C0E86B9E, p, 1000.0) -- Estamina externa
            Citizen.InvokeNative(0xC6258F41D86676E0, p, 1, 100) -- Núcleo interno de estamina 100%
            Citizen.InvokeNative(0xC6258F41D86676E0, p, 0, 100) -- Núcleo interno de vida 100%

            ClearPedBloodDamage(p)
            if IsEntityOnFire(p) then
                StopEntityFire(p)
            end

            local maxHealth = GetEntityMaxHealth(p)
            if GetEntityHealth(p) < maxHealth then
                SetEntityHealth(p, maxHealth, 0)
            end

            -- Proteção repassada para cavalo se montado
            local mount = GetMount(p)
            if DoesEntityExist(mount) and not IsEntityDead(mount) then
                SetEntityInvincible(mount, true)
                SetEntityCanBeDamaged(mount, false)
                SetEntityProofs(mount, 511, true)
                if IsEntityOnFire(mount) then
                    StopEntityFire(mount)
                end
            end
        end)

        WestRP.Client.UI.ShowToast("MODO DEUS", "Invulnerabilidade total ativada (Proofs 511)", "success")
        TriggerServerEvent("westrp_admin:server:logBooster", "GodMode", "Ativou o Modo Deus")
    else
        WestRP.Client.TickManager.UnregisterTick("admin_godmode")

        SetPlayerInvincible(playerId, false)
        SetEntityInvincible(ped, false)
        SetEntityCanBeDamaged(ped, true)
        SetEntityProofs(ped, 0, false)
        SetPedConfigFlag(ped, 2, false)
        SetPedCanRagdoll(ped, true)
        SetPedCanBeTargetted(ped, true)
        Citizen.InvokeNative(0x5240864E847C691C, ped, true)
        Citizen.InvokeNative(0xFD6943B6DF77E449, ped, true)

        local mount = GetMount(ped)
        if DoesEntityExist(mount) and not IsEntityDead(mount) then
            SetEntityInvincible(mount, false)
            SetEntityCanBeDamaged(mount, true)
            SetEntityProofs(mount, 0, false)
        end

        WestRP.Client.UI.ShowToast("MODO DEUS", "Invulnerabilidade desativada", "info")
        TriggerServerEvent("westrp_admin:server:logBooster", "GodMode", "Desativou o Modo Deus")
    end

    return state.godmode
end

--------------------------------------------------------------------------------
-- INVISIBILIDADE
--------------------------------------------------------------------------------
---Alterna a visibilidade do operador
---@return boolean novoEstado
function WestRP.Admin.Boosters.ToggleInvis()
    local ped = PlayerPedId()
    state.invis = not state.invis

    SetEntityVisible(ped, not state.invis)

    local msg = state.invis and "Operador agora está invisível" or "Operador agora está visível"
    WestRP.Client.UI.ShowToast("INVISIBILIDADE", msg, state.invis and "success" or "info")
    TriggerServerEvent("westrp_admin:server:logBooster", "Invisibilidade", msg)
    return state.invis
end

--------------------------------------------------------------------------------
-- NÚCLEOS DOURADOS & MUNIÇÃO INFINITA
--------------------------------------------------------------------------------
---Alterna núcleos dourados e cheios
---@return boolean novoEstado
function WestRP.Admin.Boosters.ToggleGoldenCores()
    state.goldencores = not state.goldencores
    local ped = PlayerPedId()

    if state.goldencores then
        -- Núcleos internos em 100%
        Citizen.InvokeNative(0xC6258F41D86676E0, ped, 0, 100)
        Citizen.InvokeNative(0xC6258F41D86676E0, ped, 1, 100)
        Citizen.InvokeNative(0xC6258F41D86676E0, ped, 2, 100)

        -- Barras externas douradas maximizadas
        Citizen.InvokeNative(0x4AF5A4C7B9157D14, ped, 0, 5000.0)
        Citizen.InvokeNative(0x4AF5A4C7B9157D14, ped, 1, 5000.0)
        Citizen.InvokeNative(0x4AF5A4C7B9157D14, ped, 2, 5000.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, ped, 0, 5000.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, ped, 1, 5000.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, ped, 2, 5000.0)

        WestRP.Client.UI.ShowToast("NÚCLEOS DOURADOS", "Núcleos fortalecidos no nível máximo", "success")
        TriggerServerEvent("westrp_admin:server:logBooster", "GoldenCores", "Ativou Núcleos Dourados")
    else
        Citizen.InvokeNative(0x4AF5A4C7B9157D14, ped, 0, 0.0)
        Citizen.InvokeNative(0x4AF5A4C7B9157D14, ped, 1, 0.0)
        Citizen.InvokeNative(0x4AF5A4C7B9157D14, ped, 2, 0.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, ped, 0, 0.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, ped, 1, 0.0)
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, ped, 2, 0.0)

        WestRP.Client.UI.ShowToast("NÚCLEOS DOURADOS", "Efeito dourado removido", "info")
    end

    return state.goldencores
end

---Alterna munição infinita na arma em mãos
---@return boolean novoEstado
function WestRP.Admin.Boosters.ToggleInfiniteAmmo()
    local ped = PlayerPedId()
    local hasWeapon, weaponHash = GetCurrentPedWeapon(ped, false, 0, false)

    if not hasWeapon or weaponHash == -1569615261 then
        WestRP.Client.UI.ShowToast("MUNIÇÃO", "Você precisa estar com uma arma em mãos", "danger")
        return false
    end

    state.infiammo = not state.infiammo
    SetPedInfiniteAmmo(ped, state.infiammo, weaponHash)

    local msg = state.infiammo and "Munição infinita travada para a arma atual" or "Munição infinita desativada"
    WestRP.Client.UI.ShowToast("MUNIÇÃO INFINITA", msg, state.infiammo and "success" or "info")
    TriggerServerEvent("westrp_admin:server:logBooster", "MuniçãoInfinita", msg)
    return state.infiammo
end

--------------------------------------------------------------------------------
-- CURA & REVIVER PRÓPRIO
--------------------------------------------------------------------------------
function WestRP.Admin.Boosters.SelfHeal()
    local ped = PlayerPedId()
    local maxHealth = GetEntityMaxHealth(ped)
    SetEntityHealth(ped, maxHealth, 0)
    Citizen.InvokeNative(0xC6258F41D86676E0, ped, 0, 100) -- Vida
    Citizen.InvokeNative(0xC6258F41D86676E0, ped, 1, 100) -- Estamina

    -- Tratar montaria se existente
    local mount = GetMount(ped)
    if DoesEntityExist(mount) and not IsEntityDead(mount) then
        local maxHorseHealth = GetEntityMaxHealth(mount)
        SetEntityHealth(mount, maxHorseHealth, 0)
        Citizen.InvokeNative(0xC6258F41D86676E0, mount, 0, 600)
        Citizen.InvokeNative(0xC6258F41D86676E0, mount, 1, 600)
    end

    -- Disparar evento de metabolismo se ativo
    if GetResourceState("vorp_metabolism") == "started" then
        TriggerEvent("vorpmetabolism:changeValue", "Thirst", 1000)
        TriggerEvent("vorpmetabolism:changeValue", "Hunger", 1000)
    end

    WestRP.Client.UI.ShowToast("AUTO CURA", "Vida, estamina e metabolismo restaurados", "success")
    TriggerServerEvent("westrp_admin:server:selfHeal")
end

function WestRP.Admin.Boosters.SelfRevive()
    TriggerServerEvent("westrp_admin:server:selfRevive")
    WestRP.Client.UI.ShowToast("AUTO REVIVER", "Operador reanimado com sucesso", "success")
end

---Limpa sangue, danos e lama do ped
function WestRP.Admin.Boosters.CleanPed()
    local ped = PlayerPedId()
    ClearPedEnvDirt(ped)
    ClearPedDamageDecalByZone(ped, 10, "ALL")
    ClearPedBloodDamage(ped)
    ClearPedWetness(ped)
    WestRP.Client.UI.ShowToast("LIMPEZA", "Personagem limpo de sangue e sujeira", "success")
end

---Limpa entidades mortas, veículos e projéteis da área
---@param radius? number
function WestRP.Admin.Boosters.ClearArea(radius)
    local r = radius or 50.0
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    ClearAreaOfPeds(coords.x, coords.y, coords.z, r, 0)
    ClearAreaOfVehicles(coords.x, coords.y, coords.z, r, false, false, false, false, false)
    ClearAreaOfProjectiles(coords.x, coords.y, coords.z, r, false)
    WestRP.Client.UI.ShowToast("LIMPEZA DE ÁREA", string.format("Área de %.0fm limpa de entidades", r), "success")
end

---Retorna o estado consolidado de todos os boosters
---@return table
function WestRP.Admin.Boosters.GetStates()
    return {
        godmode     = state.godmode,
        noclip      = state.noclip,
        invis       = state.invis,
        goldencores = state.goldencores,
        infiammo    = state.infiammo
    }
end

--------------------------------------------------------------------------------
-- LIMPEZA AO PARAR RESOURCE
--------------------------------------------------------------------------------
AddEventHandler("onResourceStop", function(resName)
    if resName ~= GetCurrentResourceName() then return end
    local ped = PlayerPedId()

    if state.noclip then
        WestRP.Client.TickManager.UnregisterTick("admin_noclip")
        ResetNoclipEntity(ped)
        CleanupPrompts()
    end

    if state.godmode then
        WestRP.Client.TickManager.UnregisterTick("admin_godmode")
        SetPlayerInvincible(PlayerId(), false)
        SetEntityInvincible(ped, false)
        SetEntityCanBeDamaged(ped, true)
        SetEntityProofs(ped, 0, false)
    end

    if state.invis then
        SetEntityVisible(ped, true)
    end
end)
