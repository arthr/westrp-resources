-- rsm_hud · client: dados do VORP
-- Nome, emprego, dinheiro e ouro vêm do statebag que o vorp_core publica
-- (LocalPlayer.state.Character); fome e sede vêm do vorp_metabolism; estresse,
-- higiene, embriaguez, recompensa e efeitos vêm do servidor deste recurso.

local function number(v)
    return tonumber(v) or 0
end

-- Personagem e dinheiro. O vorp_core é quem altera esses valores; aqui só se lê.
CreateThread(function()
    while true do
        if RSMHud.active then
            local c = LocalPlayer.state.Character
            if type(c) == 'table' then
                local name = ('%s %s'):format(c.FirstName or '', c.LastName or ''):gsub('^%s+', ''):gsub('%s+$', '')
                RSMHud.push('player', {
                    id = GetPlayerServerId(PlayerId()),
                    name = name,
                    job = c.JobLabel or c.Job or '',
                    employer = c.Grade and Config.Text.grade:format(c.Grade) or '',
                })
                RSMHud.push('money', { cash = number(c.Money), gold = number(c.Gold) })
            end
        end
        Wait(Config.Tick.character)
    end
end)

-- Fome e sede (0-1000 no vorp_metabolism → 0-100 no HUD). Sem o recurso, os
-- dois medidores são enviados como false e somem da interface.
local function readMetabolism(key)
    local p = promise.new()
    local done = false
    local function finish(value)
        if done then return end
        done = true
        p:resolve(value)
    end
    TriggerEvent('vorpmetabolism:getValue', key, function(value)
        finish(tonumber(value))
    end)
    -- se ninguém responder, não trava o loop
    SetTimeout(1000, function() finish(nil) end)
    return Citizen.Await(p)
end

CreateThread(function()
    while true do
        if RSMHud.active then
            local running = GetResourceState(Config.Metabolism.resource) == 'started'
            local needs = { hunger = false, thirst = false }
            if running and Config.Needs.hunger.enabled then
                local v = readMetabolism('Hunger')
                needs.hunger = v and math.floor(math.max(0, math.min(1000, v)) / 10 + 0.5) or false
            end
            if running and Config.Needs.thirst.enabled then
                local v = readMetabolism('Thirst')
                needs.thirst = v and math.floor(math.max(0, math.min(1000, v)) / 10 + 0.5) or false
            end
            RSMHud.push('needs', needs, 'needs:metabolism')
        end
        Wait(Config.Tick.metabolism)
    end
end)

-- Valores que o servidor mantém: { stress = n|false, hygiene = n|false, alcohol = n|false }
RegisterNetEvent('rsm_hud:client:needs', function(values)
    if type(values) ~= 'table' then return end
    RSMHud.alcohol = tonumber(values.alcohol) or 0
    RSMHud.push('needs', {
        stress = values.stress,
        hygiene = values.hygiene,
        alcohol = values.alcohol,
    }, 'needs:server')
end)

RegisterNetEvent('rsm_hud:client:bounty', function(amount, region)
    RSMHud.push('wanted', { bounty = tonumber(amount) or 0, region = type(region) == 'string' and region or '' })
end)

RegisterNetEvent('rsm_hud:client:effects', function(list)
    local active = {}
    if type(list) == 'table' then
        for _, name in ipairs(list) do active[name] = true end
    end
    RSMHud.serverEffects = active
end)
