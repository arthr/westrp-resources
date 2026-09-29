-- ═══════════════════════════════════════════════════════════════════════════
-- rsm_stables — cliente
-- Cavalariço com prompt de segurar, câmera e animal de exibição no balcão,
-- chamar cavalo (H) e carroça (J), morte, vínculo e alforje (B).
-- O cliente só mostra e pede: preço, dono e estado quem decide é o servidor.
-- ═══════════════════════════════════════════════════════════════════════════

local Core = exports.vorp_core:GetCore()

local function log(...)
    if Config.Debug then print("[rsm_stables]", ...) end
end

-- ── catálogo local (só para exibir; nada aqui vale como regra) ──────────────

local KnownModel = { horse = {}, cart = {} }
for _, breed in ipairs(Config.Breeds) do
    for _, c in ipairs(breed.coats) do KnownModel.horse[c.model] = true end
end
for _, c in ipairs(Config.Carts) do KnownModel.cart[c.model] = true end

local TackCat, TackStyle = {}, {}
for _, cat in ipairs(Config.Tack) do
    TackCat[cat.id] = cat
    TackStyle[cat.id] = {}
    for _, s in ipairs(cat.styles) do TackStyle[cat.id][s.id] = s end
end

-- Crina e cauda fazem parte do corpo: tirar a peça comprada exige voltar ao
-- visual original do cavalo, não só remover a categoria.
local BODY_PART = { manes = true, tails = true }

-- Comportamento de montaria do jogador (mesmos flags do vorp_stables)
local HORSE_FLAGS = {
    [6] = true, [113] = false, [136] = false, [208] = true, [209] = true, [211] = true,
    [277] = true, [297] = true, [300] = false, [301] = false, [312] = false, [319] = true,
    [400] = true, [412] = false, [419] = false, [438] = false, [439] = false, [440] = false,
    [561] = true, [24] = false, [25] = false, [48] = false,
}

local BLIP_STYLE_COORDS = 1664425300
local BLIP_STYLE_ENTITY = -1230993421

-- ── estado ──────────────────────────────────────────────────────────────────

local State = {
    open = false,
    pending = false, -- pediu para abrir e espera o servidor
    idx = nil,       -- estábulo aberto
    cam = nil,
    camKind = nil,
    fov = 45.0,
    heading = 0.0,
    preview = nil,   -- { ent, kind, model, applied }
    stageToken = 0,
    stage = nil,
    rides = {},      -- id → animal (do último payload)
    offers = {},     -- id → proposta
    radarHidden = false,
}

local Out = {}       -- tipo → { id, ent, blip, info, applied, dead }
local Keepers = {}   -- índice do estábulo → ped do cavalariço
local Blips = {}
local Theme = nil
local themeAsked = false

local NearStable = nil -- estábulo com o prompt ao alcance
local NearRide = nil   -- tipo do animal próprio ao alcance do alforje
local mountedSeconds = 0

-- ── utilidades ──────────────────────────────────────────────────────────────

local function kitOn()
    return Config.NuiKit ~= "" and GetResourceState(Config.NuiKit) == "started"
end

local function notify(kind, title, body)
    if kitOn() then
        local ok = pcall(function()
            exports[Config.NuiKit]:Notify(kind, title, body, 4500)
        end)
        if ok then return end
    end
    Core.NotifyRightTip(body and (title .. " · " .. body) or title, 4500)
end

local function loadModel(hash)
    if not IsModelValid(hash) then return false end
    RequestModel(hash, false)
    local limit = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > limit then return false end
        Wait(10)
    end
    return true
end

local function nameBlip(blip, text)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, text)
end

local function deleteVehicleWithTeam(veh)
    for i = 0, 3 do
        local animal = GetPedInDraftHarness(veh, i)
        if animal and animal ~= 0 and DoesEntityExist(animal) then DeletePed(animal) end
    end
    DeleteVehicle(veh)
end

local function deleteEnt(ent, kind)
    if not ent or not DoesEntityExist(ent) then return end
    if kind == "cart" then deleteVehicleWithTeam(ent) else DeletePed(ent) end
end

-- Arreios num cavalo: tira o que saiu, põe o que entrou, uma atualização só
local function applyGear(ent, holder, gear)
    local applied = holder.applied or {}
    local reset = false
    for cat in pairs(applied) do
        if not gear[cat] and BODY_PART[cat] then reset = true end
    end
    if reset then
        Citizen.InvokeNative(0x283978A15512B2FE, ent, true)
        applied = {}
    else
        for cat in pairs(applied) do
            if not gear[cat] and TackCat[cat] then RemoveTagFromMetaPed(ent, TackCat[cat].category, 0) end
        end
    end
    for cat, hash in pairs(gear) do
        if applied[cat] ~= hash then ApplyShopItemToPed(ent, hash, true, true, true) end
    end
    UpdatePedVariation(ent, false, true, true, true, false)
    local copy = {}
    for cat, hash in pairs(gear) do copy[cat] = hash end
    holder.applied = copy
end

-- gear salvo { cat = { style, variant } } (+ a peça em prova) → { cat = hash }
local function gearHashes(saved, trying)
    local map = {}
    for cat, g in pairs(saved or {}) do
        local style = TackStyle[cat] and TackStyle[cat][g.style]
        if style and style.hashes[g.variant] then map[cat] = style.hashes[g.variant] end
    end
    if type(trying) == "table" then
        local style = TackStyle[trying.cat] and TackStyle[trying.cat][trying.style]
        local hash = style and style.hashes[math.tointeger(tonumber(trying.variant)) or 0]
        if hash then map[trying.cat] = hash end
    end
    return map
end

-- ── câmera e animal de exibição ─────────────────────────────────────────────

local function spot(kind)
    local st = Config.Stables[State.idx]
    return kind == "cart" and st.cart or st.horse
end

local function aimCamera(kind, ent)
    local cam = spot(kind).cam
    if State.camKind ~= kind then
        SetCamCoord(State.cam, cam.x, cam.y, cam.z)
        State.camKind = kind
    end
    if ent then
        PointCamAtEntity(State.cam, ent, 0.0, 0.0, 0.0, true)
    else
        local sp = spot(kind).spawn
        PointCamAtCoord(State.cam, sp.x, sp.y, sp.z)
    end
end

local function startCamera()
    local cam = spot("horse").cam
    State.fov = 45.0
    State.camKind = "horse"
    State.cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", cam.x, cam.y, cam.z, 0.0, 0.0, 0.0, State.fov, false, 0)
    aimCamera("horse", nil)
    SetCamActive(State.cam, true)
    RenderScriptCams(true, true, 600, true, true, 0)
end

local function stopCamera()
    if not State.cam then return end
    RenderScriptCams(false, true, 500, true, true, 0)
    SetCamActive(State.cam, false)
    DestroyCam(State.cam, false)
    State.cam, State.camKind = nil, nil
end

local function clearPreview()
    if State.preview then deleteEnt(State.preview.ent, State.preview.kind) end
    State.preview = nil
end

-- stage vindo da interface → (tipo, modelo, arreios)
local function resolveStage(stage)
    if type(stage) ~= "table" then return nil end
    if stage.kind == "shop" then
        local kind = stage.type == "cart" and "cart" or "horse"
        if not KnownModel[kind][stage.model] then return nil end
        return kind, stage.model, {}
    end
    if stage.kind == "ride" then
        local r = State.rides[stage.id]
        if not r or not KnownModel[r.type][r.model] then return nil end
        local gear = r.type == "horse" and gearHashes(r.gear, stage.tack) or {}
        return r.type, r.model, gear
    end
    if stage.kind == "offer" then
        local o = State.offers[stage.id]
        if not o or not KnownModel[o.type] or not KnownModel[o.type][o.model] then return nil end
        return o.type, o.model, {}
    end
end

local function showPreview(stage)
    State.stageToken = State.stageToken + 1
    local token = State.stageToken
    local kind, model, gear = resolveStage(stage)
    if not kind then return end

    local p = State.preview
    if p and p.kind == kind and p.model == model and DoesEntityExist(p.ent) then
        if kind == "horse" then applyGear(p.ent, p, gear) end
        return
    end

    local hash = GetHashKey(model)
    if not loadModel(hash) then return log("modelo não carregou", model) end
    if token ~= State.stageToken or not State.open then return end

    clearPreview()
    local sp = spot(kind).spawn
    local ent
    if kind == "horse" then
        ent = CreatePed(hash, sp.x, sp.y, sp.z, sp.w, false, false, false, false)
        Citizen.InvokeNative(0x283978A15512B2FE, ent, true)
        PlaceEntityOnGroundProperly(ent, true)
        SetBlockingOfNonTemporaryEvents(ent, true)
    else
        ent = CreateVehicle(hash, sp.x, sp.y, sp.z, sp.w, false, false, false, false)
        SetVehicleOnGroundProperly(ent, true)
    end
    SetModelAsNoLongerNeeded(hash)
    SetEntityInvincible(ent, true)
    SetEntityCanBeDamaged(ent, false)
    FreezeEntityPosition(ent, true)

    State.preview = { ent = ent, kind = kind, model = model, applied = {} }
    State.heading = sp.w
    if kind == "horse" then applyGear(ent, State.preview, gear) end
    aimCamera(kind, ent)
end

-- ── abrir / fechar ──────────────────────────────────────────────────────────

local function cacheData(data)
    if type(data) ~= "table" then return end
    if data.rides then
        State.rides = {}
        for _, r in ipairs(data.rides) do State.rides[r.id] = r end
    end
    if data.incoming then
        State.offers = {}
        for _, o in ipairs(data.incoming) do State.offers[o.id] = o end
    end
end

local function closeStable()
    SetNuiFocus(false, false)
    if not State.open then return end
    State.open = false
    State.stage = nil
    State.stageToken = State.stageToken + 1
    SendNUIMessage({ action = "close" })
    clearPreview()
    stopCamera()
    FreezeEntityPosition(PlayerPedId(), false)
    if State.radarHidden then
        DisplayRadar(true)
        State.radarHidden = false
    end
    TriggerServerEvent("rsm_stables:close")
end

local function requestOpen(idx)
    if State.open or State.pending then return end
    State.pending = GetGameTimer()
    TriggerServerEvent("rsm_stables:open", idx)
end

RegisterNetEvent("rsm_stables:client:denied", function()
    State.pending = false
end)

RegisterNetEvent("rsm_stables:client:open", function(idx, data)
    State.pending = false
    if State.open or not Config.Stables[idx] then return end
    State.idx = idx
    cacheData(data)
    State.open = true
    startCamera()
    FreezeEntityPosition(PlayerPedId(), true)
    DisplayRadar(false)
    State.radarHidden = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open", data = data, theme = Theme })
    if not Theme and not themeAsked and kitOn() then
        themeAsked = true
        TriggerServerEvent("rsm_nuikit:requestConfig")
    end
end)

-- Resposta de cada ação: repassa à interface e atualiza o que está em cena
RegisterNetEvent("rsm_stables:client:update", function(patch, focus)
    cacheData(patch)
    SendNUIMessage({ action = "update", data = patch, focus = focus })
    if State.open and patch and patch.rides and State.stage and State.stage.kind == "ride" then
        CreateThread(function() showPreview(State.stage) end)
    end
end)

-- Tema publicado no estúdio do rsm_nuikit
RegisterNetEvent("rsm_nuikit:config", function(cfg)
    if Config.NuiKit == "" or type(cfg) ~= "table" or type(cfg.theme) ~= "table" then return end
    local t = cfg.theme
    Theme = { accent = t.accent, surface = t.surface, text = t.text, surfaceAlpha = tonumber(t.surfaceAlpha) }
    if State.open then SendNUIMessage({ action = "theme", theme = Theme }) end
end)

-- ── callbacks da interface ──────────────────────────────────────────────────

RegisterNUICallback("close", function(_, cb)
    closeStable()
    cb("ok")
end)

RegisterNUICallback("preview", function(stage, cb)
    cb("ok")
    if not State.open then return end
    State.stage = stage
    CreateThread(function() showPreview(stage) end)
end)

RegisterNUICallback("rotate", function(data, cb)
    cb("ok")
    local p = State.preview
    local delta = tonumber(data and data.delta)
    if not p or not delta or not DoesEntityExist(p.ent) then return end
    State.heading = (State.heading + math.max(-30.0, math.min(30.0, delta))) % 360.0
    SetEntityHeading(p.ent, State.heading)
end)

RegisterNUICallback("zoom", function(data, cb)
    cb("ok")
    local delta = tonumber(data and data.delta)
    if not State.cam or not delta then return end
    State.fov = math.max(22.0, math.min(65.0, State.fov + (delta > 0 and 3.0 or -3.0)))
    SetCamFov(State.cam, State.fov)
end)

for _, name in ipairs({
    "buy", "setActive", "rename", "release", "tackBuy", "tackEquip", "tackRemove", "tackRemoveAll",
    "transferSend", "transferAnswer",
}) do
    RegisterNUICallback(name, function(data, cb)
        cb("ok")
        if not State.open then return end
        TriggerServerEvent("rsm_stables:action", name, type(data) == "table" and data or {})
    end)
end

-- ── o animal no mundo ───────────────────────────────────────────────────────

local function dropOut(kind)
    local out = Out[kind]
    if not out then return end
    if out.blip then RemoveBlip(out.blip) end
    deleteEnt(out.ent, kind)
    Out[kind] = nil
end

local function setupHorse(ent, info)
    Citizen.InvokeNative(0xADB3F206518799E8, ent, GetHashKey("PLAYER"))
    SetPedPersonality(ent, GetHashKey("PLAYER_HORSE"))
    SetAnimalIsWild(ent, false)
    for flag, value in pairs(HORSE_FLAGS) do SetPedConfigFlag(ent, flag, value) end
    Citizen.InvokeNative(0xA691C10054275290, ent, PlayerId(), 431)
    Citizen.InvokeNative(0x6734F0A6A52C371C, PlayerId(), 431)
    Citizen.InvokeNative(0x024EC9B649111915, ent, true)
    SetMountBondingLevel(ent, math.max(1, info.bond or 1))
end

-- Ponto de chegada: na estrada mais próxima atrás do jogador, ou no chão atrás dele
local function arrivalPoint(kind)
    local ped = PlayerPedId()
    local me = GetEntityCoords(ped)
    local back = GetOffsetFromEntityInWorldCoords(ped, 0.0, kind == "cart" and -18.0 or -25.0, 0.0)
    local found, node, heading = GetClosestVehicleNodeWithHeading(back.x, back.y, back.z, 1, 3.0, 0)
    if found and #(node - me) <= 60.0 then
        return vector4(node.x, node.y, node.z, heading)
    end
    local ok, groundZ = GetGroundZFor_3dCoord(back.x, back.y, back.z + 25.0, false)
    local z = ok and groundZ or me.z
    return vector4(back.x, back.y, z, GetEntityHeading(ped))
end

RegisterNetEvent("rsm_stables:client:spawn", function(info)
    local kind = info and info.type
    if kind ~= "horse" and kind ~= "cart" then return end
    local hash = GetHashKey(info.model)
    if not loadModel(hash) then
        notify("error", "Não foi possível chamar", "O modelo deste animal não carregou.")
        return TriggerServerEvent("rsm_stables:stored", kind)
    end

    dropOut(kind)
    local at = arrivalPoint(kind)
    local ent
    if kind == "horse" then
        ent = CreatePed(hash, at.x, at.y, at.z, at.w, true, true, true, true)
        Citizen.InvokeNative(0x283978A15512B2FE, ent, true)
        PlaceEntityOnGroundProperly(ent, true)
    else
        ent = CreateVehicle(hash, at.x, at.y, at.z, at.w, true, true, false, true)
        SetVehicleOnGroundProperly(ent, true)
    end
    SetModelAsNoLongerNeeded(hash)
    if not ent or ent == 0 then return TriggerServerEvent("rsm_stables:stored", kind) end
    SetEntityAsMissionEntity(ent, true, true)

    local out = { id = info.id, ent = ent, info = info, applied = {}, dead = false }
    out.blip = BlipAddForEntity(BLIP_STYLE_ENTITY, ent)
    nameBlip(out.blip, info.name)
    Out[kind] = out

    if kind == "horse" then
        SetPedPromptName(ent, info.name)
        setupHorse(ent, info)
        applyGear(ent, out, info.gear or {})
        TaskGoToEntity(ent, PlayerPedId(), -1, 3.0, 3.0, 0, 0)
    end

    -- o servidor guarda o id de rede para recolher o animal se o jogador sair
    CreateThread(function()
        local limit = GetGameTimer() + 3000
        while DoesEntityExist(ent) and not NetworkGetEntityIsNetworked(ent) and GetGameTimer() < limit do Wait(50) end
        if DoesEntityExist(ent) and NetworkGetEntityIsNetworked(ent) then
            TriggerServerEvent("rsm_stables:spawned", kind, info.id, NetworkGetNetworkIdFromEntity(ent))
        end
    end)
end)

-- Nome/arreios mudaram no balcão, ou o animal deixou de ser seu (info = nil)
RegisterNetEvent("rsm_stables:client:rideChanged", function(kind, id, info)
    local out = Out[kind]
    if not out or out.id ~= id then return end
    if not info then return dropOut(kind) end
    out.info = info
    if out.blip then nameBlip(out.blip, info.name) end
    if kind == "horse" and DoesEntityExist(out.ent) then
        SetPedPromptName(out.ent, info.name)
        applyGear(out.ent, out, info.gear or {})
    end
end)

RegisterNetEvent("rsm_stables:client:bond", function(id, level)
    local out = Out.horse
    if out and out.id == id and DoesEntityExist(out.ent) then
        SetMountBondingLevel(out.ent, math.max(1, tonumber(level) or 1))
    end
end)

local lastCall = 0

local function callRide(kind)
    local t = GetGameTimer()
    if t - lastCall < 1000 then return end
    lastCall = t
    local out = Out[kind]
    if out and not out.dead and DoesEntityExist(out.ent) then
        local ped = PlayerPedId()
        local dist = #(GetEntityCoords(ped) - GetEntityCoords(out.ent))
        if dist <= Config.Call.teleportDistance then
            if kind == "horse" then
                if GetMount(ped) ~= out.ent then
                    ClearPedTasks(out.ent, true, true)
                    TaskGoToEntity(out.ent, ped, -1, 3.0, 3.0, 0, 0)
                end
            else
                notify("info", out.info.name, ("Está a %d metros daqui."):format(math.floor(dist)))
            end
            return
        end
    end
    -- longe demais (ou guardado): o servidor confere e manda aparecer por perto
    TriggerServerEvent("rsm_stables:call", kind)
end

-- ── prompts ─────────────────────────────────────────────────────────────────

local function makePrompt(key, text, group)
    local p = UiPromptRegisterBegin()
    UiPromptSetControlAction(p, key)
    UiPromptSetText(p, VarString(10, "LITERAL_STRING", text))
    UiPromptSetEnabled(p, true)
    UiPromptSetVisible(p, true)
    UiPromptSetHoldMode(p, 1000)
    UiPromptSetGroup(p, group, 0)
    UiPromptRegisterEnd(p)
    return p
end

local StableGroup = GetRandomIntInRange(0, 0xFFFFFF)
local BagGroup = GetRandomIntInRange(0, 0xFFFFFF)
local OpenPrompt = makePrompt(Config.Keys.Open, "Falar com o cavalariço", StableGroup)
local BagPrompt = makePrompt(Config.Keys.Saddlebag, "Abrir", BagGroup)

local function rearm(p)
    UiPromptSetEnabled(p, false)
    UiPromptSetEnabled(p, true)
end

-- ── mundo: blips, cavalariços, alcance, morte e vínculo (a cada 500 ms) ─────

CreateThread(function()
    for idx, st in ipairs(Config.Stables) do
        if st.enabled then
            local blip = BlipAddForCoords(BLIP_STYLE_COORDS, st.npc.x, st.npc.y, st.npc.z)
            SetBlipSprite(blip, Config.Blip.sprite, true)
            nameBlip(blip, "Estábulo · " .. st.name)
            Blips[idx] = blip
        end
    end
end)

local function spawnKeeper(idx, st)
    local hash = GetHashKey(Config.Keeper.model)
    if not loadModel(hash) then return end
    local ped = CreatePed(hash, st.npc.x, st.npc.y, st.npc.z, st.npc.w, false, false, false, false)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
    PlaceEntityOnGroundProperly(ped, true)
    SetEntityCanBeDamaged(ped, false)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(hash)
    Keepers[idx] = ped
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local me = GetEntityCoords(ped)
        local alive = not IsEntityDead(ped)

        -- cavalariços: só existem com o jogador por perto
        local near = nil
        for idx, st in ipairs(Config.Stables) do
            if st.enabled then
                local dist = #(me - st.npc.xyz)
                if dist <= Config.Keeper.spawnDistance and not Keepers[idx] then
                    spawnKeeper(idx, st)
                elseif dist > Config.Keeper.spawnDistance + 10.0 and Keepers[idx] then
                    DeletePed(Keepers[idx])
                    Keepers[idx] = nil
                end
                if dist <= Config.Keeper.promptDistance then near = idx end
            end
        end
        NearStable = alive and near or nil

        -- animais fora: sumiram, morreram, ou estão ao alcance do alforje
        local bag = nil
        for kind, out in pairs(Out) do
            if not DoesEntityExist(out.ent) then
                if out.blip then RemoveBlip(out.blip) end
                Out[kind] = nil
                TriggerServerEvent("rsm_stables:stored", kind)
            elseif not out.dead and IsEntityDead(out.ent) then
                out.dead = GetGameTimer()
                TriggerServerEvent("rsm_stables:died", kind, out.id)
            elseif out.dead and GetGameTimer() - out.dead > 20000 then
                dropOut(kind)
            elseif not out.dead and alive then
                local reach = kind == "cart" and 4.0 or 2.2
                local onFoot = not IsPedOnMount(ped) and not IsPedInAnyVehicle(ped, false)
                if onFoot and #(me - GetEntityCoords(out.ent)) <= reach then bag = kind end
            end
        end
        NearRide = bag

        -- vínculo: um tique por minuto montado no próprio cavalo
        local horse = Out.horse
        if horse and not horse.dead and GetMount(ped) == horse.ent then
            mountedSeconds = mountedSeconds + 0.5
            if mountedSeconds >= 60 then
                mountedSeconds = 0
                TriggerServerEvent("rsm_stables:bond", horse.id)
            end
        end

        -- morreu com o balcão aberto: devolve o jogo
        if State.open and not alive then closeStable() end
        if State.pending and GetGameTimer() - State.pending > 6000 then State.pending = false end

        Wait(500)
    end
end)

-- ── teclas e prompts (a cada frame; o trabalho pesado fica no laço acima) ───

CreateThread(function()
    while true do
        if State.open or IsNuiFocused() or IsPauseMenuActive() then
            Wait(250)
        else
            if IsControlJustPressed(0, Config.Keys.CallHorse) then callRide("horse") end
            if IsControlJustPressed(0, Config.Keys.CallCart) then callRide("cart") end

            if NearStable then
                local st = Config.Stables[NearStable]
                UiPromptSetActiveGroupThisFrame(StableGroup, VarString(10, "LITERAL_STRING", "Estábulo de " .. st.name), 0, 0, 0, 0)
                if UiPromptHasHoldModeCompleted(OpenPrompt) then
                    rearm(OpenPrompt)
                    requestOpen(NearStable)
                end
            elseif NearRide and Out[NearRide] then
                local out = Out[NearRide]
                local title = NearRide == "horse" and "Alforje de " or "Carga de "
                UiPromptSetActiveGroupThisFrame(BagGroup, VarString(10, "LITERAL_STRING", title .. out.info.name), 0, 0, 0, 0)
                if UiPromptHasHoldModeCompleted(BagPrompt) then
                    rearm(BagPrompt)
                    TriggerServerEvent("rsm_stables:saddlebag", NearRide)
                end
            end
            Wait(0)
        end
    end
end)

-- ── troca de personagem e parada do resource ────────────────────────────────

RegisterNetEvent("vorp:SelectedCharacter", function()
    closeStable()
    dropOut("horse")
    dropOut("cart")
    mountedSeconds = 0
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    clearPreview()
    stopCamera()
    if State.open then FreezeEntityPosition(PlayerPedId(), false) end
    if State.radarHidden then DisplayRadar(true) end
    dropOut("horse")
    dropOut("cart")
    for _, ped in pairs(Keepers) do DeletePed(ped) end
    for _, blip in pairs(Blips) do RemoveBlip(blip) end
    UiPromptDelete(OpenPrompt)
    UiPromptDelete(BagPrompt)
end)
