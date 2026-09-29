--[[
    WestRP Framework — Server Feed Bridge
    Dispara notificações nativas do RedM para um cliente específico ou para todos os jogadores.
]]

WestRP = WestRP or {}
WestRP.Server = WestRP.Server or {}
WestRP.Server.Feed = {}

local ServerFeed = WestRP.Server.Feed

---Envia um feed nativo de Item Recebido para um jogador
---@param source integer Player Source ID (-1 para todos)
---@param title string Título do item ou quantidade
---@param subtitle string Subtítulo
---@param dict string Dicionário de textura
---@param icon string Nome do ícone
---@param duration? number Duração em ms
---@param color? string Cor do texto
function ServerFeed.ItemReceived(source, title, subtitle, dict, icon, duration, color)
    TriggerClientEvent('westrp:client:feedItem', source, title, subtitle, dict, icon, duration, color)
end

---Envia uma dica contextual (Help Tip) para um jogador
---@param source integer Player Source ID (-1 para todos)
---@param message string Mensagem a exibir
---@param duration? number Duração em ms
function ServerFeed.Tip(source, message, duration)
    TriggerClientEvent('westrp:client:feedTip', source, message, duration)
end

---Envia uma dica contextual no canto direito para um jogador
---@param source integer Player Source ID (-1 para todos)
---@param message string Mensagem a exibir
---@param duration? number Duração em ms
function ServerFeed.RightTip(source, message, duration)
    TriggerClientEvent('westrp:client:feedRightTip', source, message, duration)
end

---Envia um aviso superior com localidade para um jogador
---@param source integer Player Source ID (-1 para todos)
---@param title string Título da notificação
---@param location string Localidade ou categoria
---@param duration? number Duração em ms
function ServerFeed.Top(source, title, location, duration)
    TriggerClientEvent('westrp:client:feedTop', source, title, location, duration)
end

---Envia um objetivo de missão para um jogador
---@param source integer Player Source ID (-1 para todos)
---@param message string Texto do objetivo
---@param duration? number Duração em ms
function ServerFeed.Objective(source, message, duration)
    TriggerClientEvent('westrp:client:feedObjective', source, message, duration)
end

---Envia um aviso de alerta sonoro para um jogador
---@param source integer Player Source ID (-1 para todos)
---@param title string Título do aviso
---@param message string Mensagem
---@param audioRef? string Referência sonora nativa
---@param audioName? string Nome do efeito sonoro
---@param duration? number Duração em ms
function ServerFeed.Warning(source, title, message, audioRef, audioName, duration)
    TriggerClientEvent('westrp:client:feedWarning', source, title, message, audioRef, audioName, duration)
end
