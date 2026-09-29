-- rsm_hud · client: leitura das natives do RDR2
-- Cores do jogador e do cavalo, arma e munição, voz, hora, clima, temperatura,
-- localização e os efeitos de status derivados deles.

local u32 = RSMHud.u32

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local function pct(value, max)
    value, max = tonumber(value) or 0, tonumber(max) or 0
    if max <= 0 then return 0 end
    return math.floor(clamp(value / max * 100, 0, 100) + 0.5)
end

-- Núcleo do core (0 vida, 1 vigor, 2 olho morto), já de 0 a 100.
local function coreOf(ped, index)
    return math.floor(clamp(tonumber(GetAttributeCoreValue(ped, index)) or 0, 0, 100) + 0.5)
end

-- BOOL das natives pode chegar como boolean ou 0/1.
local function isTrue(v)
    return v == true or v == 1
end

-- Golden Core: núcleo e atributo fortificados, lidos direto das natives de
-- overpower (o mesmo índice 0/1/2 serve para core e atributo). "ending" liga
-- nos últimos segundos, quando o jogo informa um tempo restante.
local function endingSoon(seconds)
    seconds = tonumber(seconds) or 0
    return seconds > 0 and seconds <= Config.GoldenCore.endingSeconds
end

local function goldOf(ped, index)
    local core = isTrue(IsAttributeCoreOverpowered(ped, index))
    local ring = isTrue(IsAttributeOverpowered(ped, index))
    return {
        goldCore = core,
        goldRing = ring,
        goldCoreEnding = core and endingSoon(GetAttributeCoreOverpowerSecondsLeft(ped, index)) or false,
        goldRingEnding = ring and endingSoon(GetAttributeOverpowerSecondsLeft(ped, index)) or false,
    }
end

-- Monta { core, ring } + os campos dourados de um core.
local function coreData(ped, index, ring)
    local data = goldOf(ped, index)
    data.core = coreOf(ped, index)
    data.ring = ring
    return data
end

-- Tabelas de busca com hashes normalizados (o config usa assinados e sem sinal).
local function normalized(map)
    local out = {}
    for hash, label in pairs(map) do out[u32(hash)] = label end
    return out
end
local weatherNames = normalized(Config.Weather)
local townNames = normalized(Config.Zones.towns)
local districtNames = normalized(Config.Zones.districts)
local stateNames = normalized(Config.Zones.states)

local weapons = {}
for name, info in pairs(Config.Weapons) do
    weapons[u32(GetHashKey(name))] = info
end
local UNARMED = u32(GetHashKey('WEAPON_UNARMED'))

-- Compartilhado entre os loops deste arquivo.
local state = {
    healthRing = 100,
    lastHealth = nil,
    staminaCore = 100,
    tempC = 20,
    armed = false,
    lastStress = { shooting = 0, damage = 0 },
}

local function reportStress(reason)
    local cfg = Config.Needs.stress
    if not cfg.enabled then return end
    local now = GetGameTimer()
    if now - state.lastStress[reason] < cfg.cooldown * 1000 then return end
    state.lastStress[reason] = now
    TriggerServerEvent('rsm_hud:server:stress', reason)
end

local function readCores(ped, player)
    local health = GetEntityHealth(ped)
    local cores = {
        health = coreData(ped, 0, pct(health, GetEntityMaxHealth(ped))),
        stamina = coreData(ped, 1, pct(GetPedStamina(ped), GetPedMaxStamina(ped))),
        deadeye = coreData(ped, 2, pct(GetPlayerDeadEye(player), GetPlayerMaxDeadEye(player, 0))),
    }
    RSMHud.push('cores', cores)

    state.healthRing = cores.health.ring
    state.staminaCore = cores.stamina.core
    if state.lastHealth and health < state.lastHealth - 5 and not IsPedDeadOrDying(ped, true) then
        reportStress('damage')
    end
    state.lastHealth = health
end

local function readHorse(ped)
    local horse = IsPedOnMount(ped) and GetMount(ped) or 0
    if horse ~= 0 and DoesEntityExist(horse) then
        RSMHud.push('horse', {
            mounted = true,
            name = RSMHud.horseName or '',
            bond = tonumber(GetAttributeRank(horse, 7)) or 0, -- 7 = vínculo (PA_BONDING)
            health = coreData(horse, 0, pct(GetEntityHealth(horse), GetEntityMaxHealth(horse))),
            stamina = coreData(horse, 1, pct(GetPedStamina(horse), GetPedMaxStamina(horse))),
        })
    else
        RSMHud.push('horse', { mounted = false, name = RSMHud.horseName or '', bond = 0 })
    end
end

local function readWeapon(ped)
    local ok, hash = GetCurrentPedWeapon(ped, true, 0, true)
    local drawn = ok and hash and u32(hash) ~= UNARMED and IsWeaponValid(hash)
        and (IsWeaponAGun(hash) or IsWeaponBow(hash))
    state.armed = drawn and true or false

    if not drawn then
        RSMHud.push('weapon', { drawn = false })
        return
    end

    local clipOk, clip = GetAmmoInClip(ped, hash)
    clip = clipOk and (tonumber(clip) or 0) or 0 -- a flag decide: sem flag, sem valor
    local total = tonumber(GetAmmoInPedWeapon(ped, hash)) or 0
    local info = weapons[u32(hash)]
    RSMHud.push('weapon', {
        drawn = true,
        name = info and info.label or Config.Text.unknownWeapon,
        icon = info and info.icon or '',
        clip = clip,
        clipSize = tonumber(GetMaxAmmoInClip(ped, hash, true)) or 0,
        reserve = math.max(0, total - clip),
    })
end

local function readVoice(player)
    local range
    local proximity = LocalPlayer.state.proximity -- publicado pelo pma-voice
    if type(proximity) == 'table' and tonumber(proximity.index) then
        range = clamp(math.floor(tonumber(proximity.index)), 1, 3)
    else
        local distance = tonumber(MumbleGetTalkerProximity()) or 0
        range = distance <= Config.Voice.whisperUpTo and 1 or (distance <= Config.Voice.normalUpTo and 2 or 3)
    end
    RSMHud.push('voice', { range = range, talking = isTrue(MumbleIsPlayerTalking(player)) })
end

-- Efeitos: os calculados aqui + os que o servidor ligou.
local EFFECT_ORDER = { 'cold', 'hot', 'wounded', 'sick', 'venom', 'drained', 'disoriented', 'overfed' }
local function pushEffects()
    local fx = Config.Effects
    local on = {
        cold = state.tempC <= fx.coldBelow,
        hot = state.tempC >= fx.hotAbove,
        wounded = state.healthRing <= fx.woundedBelow,
        drained = state.staminaCore <= fx.drainedBelow,
        disoriented = (RSMHud.alcohol or 0) >= fx.dizzyAlcoholAbove,
    }
    local list = {}
    for _, name in ipairs(EFFECT_ORDER) do
        if on[name] or RSMHud.serverEffects[name] then list[#list + 1] = name end
    end
    RSMHud.push('effects', list)
end

-- Loop rápido: cores, cavalo, arma, voz.
CreateThread(function()
    while true do
        if RSMHud.active then
            local ped = PlayerPedId()
            local player = PlayerId()
            readCores(ped, player)
            readHorse(ped)
            readWeapon(ped)
            readVoice(player)
            pushEffects()
        end
        Wait(Config.Tick.status)
    end
end)

-- Disparos só existem no frame do tiro: checa a cada frame, mas só com arma em mãos.
CreateThread(function()
    while true do
        if RSMHud.active and state.armed and Config.Needs.stress.enabled then
            if IsPedShooting(PlayerPedId()) then reportStress('shooting') end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

local function zoneName(x, y, z, zoneType, names)
    local hash = GetMapZoneAtCoords(x, y, z, zoneType)
    if not hash or hash == 0 then return nil end
    return names[u32(hash)]
end

-- Loop lento: hora, clima, temperatura, localização.
CreateThread(function()
    while true do
        if RSMHud.active then
            local coords = GetEntityCoords(PlayerPedId())
            local x, y, z = coords.x, coords.y, coords.z

            local tempC = tonumber(GetTemperatureAtCoords(x, y, z)) or 20
            state.tempC = tempC
            local unit = Config.Temperature.unit == 'F' and 'F' or 'C'
            local shownTemp = unit == 'F' and (tempC * 9 / 5 + 32) or tempC

            RSMHud.push('world', {
                time = ('%02d:%02d'):format(GetClockHours(), GetClockMinutes()),
                day = Config.Days[(tonumber(GetClockDayOfWeek()) or 0) + 1] or '',
                weather = weatherNames[u32(GetPrevWeatherTypeHashName())] or '',
                temperature = math.floor(shownTemp + 0.5),
                unit = unit,
            })

            local town = zoneName(x, y, z, 1, townNames)
            local district = zoneName(x, y, z, 10, districtNames)
            local stateName = zoneName(x, y, z, 0, stateNames)
            local title = town or district or stateName or Config.Zones.wilderness
            local region = (town and (stateName or district)) or (district and stateName) or ''
            RSMHud.push('location', { town = title, region = region })
        end
        Wait(Config.Tick.world)
    end
end)

-- Scripts de estábulo podem informar o nome do cavalo montado.
AddEventHandler('rsm_hud:client:setHorseName', function(name)
    RSMHud.horseName = type(name) == 'string' and name or ''
end)
