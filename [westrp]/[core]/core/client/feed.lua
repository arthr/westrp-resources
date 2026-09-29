--[[
    WestRP Framework — Native RDR3 Feeds Bridge
    Target: RedM (CitizenFX RDR3 - Game Build 1491+)
    Zero Dependência com VORP Core.
    Executa feeds e notificações diretamente através do motor nativo C++ da Rockstar (0.00ms resmon).
]]

WestRP = WestRP or {}
WestRP.Client = WestRP.Client or {}
WestRP.Client.Feed = {}

local Feed = WestRP.Client.Feed

---Helper para converter valores em ponteiro de 64 bits para structs nativas
---@param value any
---@return integer
local function BigInt(value)
    local buf = DataView.ArrayBuffer(16)
    buf:SetInt64(0, value)
    return buf:GetInt64(0)
end

---Carrega assincronamente um dicionário de texturas com timeout de segurança
---@param dict string
---@return boolean
local function LoadTextureDict(dict)
    if not dict or dict == "" then return false end
    if not HasStreamedTextureDictLoaded(dict) then
        RequestStreamedTextureDict(dict, false)
        local timeout = GetGameTimer() + 1500
        while not HasStreamedTextureDictLoaded(dict) and GetGameTimer() < timeout do
            Wait(10)
        end
    end
    return HasStreamedTextureDictLoaded(dict)
end

---Exibe um card nativo Rockstar de Item Recebido / Transação no canto superior direito
---@param title string Título do item ou quantidade (ex: "+1 Faca de Caça")
---@param subtitle string Subtítulo ou categoria (ex: "Equipamento")
---@param dict string Dicionário de textura nativo (ex: "inventory_items", "feeds")
---@param icon string Nome do ícone na textura (ex: "weapon_melee_knife")
---@param duration? number Duração em milissegundos (padrão: 3500)
---@param color? string Cor do texto nativo (padrão: "COLOR_WHITE")
function Feed.ItemReceived(title, subtitle, dict, icon, duration, color)
    title = tostring(title or "")
    subtitle = tostring(subtitle or "")
    dict = tostring(dict or "inventory_items")
    icon = tostring(icon or "generic_item")
    duration = tonumber(duration or 3500)
    color = tostring(color or "COLOR_WHITE")

    LoadTextureDict(dict)

    local structConfig = DataView.ArrayBuffer(8 * 7)
    structConfig:SetInt32(8 * 0, duration)

    local structData = DataView.ArrayBuffer(8 * 8)
    structData:SetInt64(8 * 1, BigInt(VarString(10, "LITERAL_STRING", title)))
    structData:SetInt64(8 * 2, BigInt(VarString(10, "LITERAL_STRING", subtitle)))
    structData:SetInt32(8 * 3, 0)
    structData:SetInt64(8 * 4, BigInt(joaat(dict)))
    structData:SetInt64(8 * 5, BigInt(joaat(icon)))
    structData:SetInt64(8 * 6, BigInt(joaat(color)))

    -- UI_FEED_POST_SAMPLE_NOTIFICATION
    Citizen.InvokeNative(0x26E87218390E6729, structConfig:Buffer(), structData:Buffer(), 1, 1)

    -- Libera dicionário de textura após registro do feed
    Citizen.InvokeNative(0x4ACA10A91F66F1E2, dict)
end

---Exibe uma dica contextual (Help Tip) no canto esquerdo da tela
---@param message string Mensagem a exibir
---@param duration? number Duração em ms (padrão: 3500)
function Feed.Tip(message, duration)
    message = tostring(message or "")
    duration = tonumber(duration or 3500)

    local structConfig = DataView.ArrayBuffer(8 * 7)
    structConfig:SetInt32(8 * 0, duration)
    structConfig:SetInt32(8 * 1, 0)
    structConfig:SetInt32(8 * 2, 0)
    structConfig:SetInt32(8 * 3, 0)

    local structData = DataView.ArrayBuffer(8 * 3)
    structData:SetUint64(8 * 1, BigInt(VarString(10, "LITERAL_STRING", message)))

    -- UI_FEED_POST_HELP_TEXT (Left Tip)
    Citizen.InvokeNative(0x049D5C615BD38BAD, structConfig:Buffer(), structData:Buffer(), 1)
end

---Exibe uma dica contextual no canto direito da tela
---@param message string Mensagem a exibir
---@param duration? number Duração em ms (padrão: 3500)
function Feed.RightTip(message, duration)
    message = tostring(message or "")
    duration = tonumber(duration or 3500)

    local structConfig = DataView.ArrayBuffer(8 * 7)
    structConfig:SetInt32(8 * 0, duration)

    local structData = DataView.ArrayBuffer(8 * 3)
    structData:SetInt64(8 * 1, BigInt(VarString(10, "LITERAL_STRING", message)))

    -- UI_FEED_POST_HELP_TEXT (Right Tip)
    Citizen.InvokeNative(0xB2920B9760F0F36B, structConfig:Buffer(), structData:Buffer(), 1)
end

---Exibe notificação superior com localidade e mensagem (Top Notice)
---@param title string Título ou Mensagem principal
---@param location string Nome do local ou categoria secundária
---@param duration? number Duração em ms (padrão: 3500)
function Feed.Top(title, location, duration)
    title = tostring(title or "")
    location = tostring(location or "")
    duration = tonumber(duration or 3500)

    local structConfig = DataView.ArrayBuffer(8 * 7)
    structConfig:SetInt32(8 * 0, duration)

    local structData = DataView.ArrayBuffer(8 * 5)
    structData:SetInt64(8 * 1, BigInt(VarString(10, "LITERAL_STRING", location)))
    structData:SetInt64(8 * 2, BigInt(VarString(10, "LITERAL_STRING", title)))

    -- UI_FEED_POST_TOP
    Citizen.InvokeNative(0xD05590C1AB38F068, structConfig:Buffer(), structData:Buffer(), 0, 1)
end

---Exibe um texto amarelo de objetivo de missão na base central da tela
---@param message string Instrução da missão/ação
---@param duration? number Duração em ms (padrão: 4000)
function Feed.Objective(message, duration)
    message = tostring(message or "")
    duration = tonumber(duration or 4000)

    -- Limpa feed de objetivo anterior
    Citizen.InvokeNative(0xDD1232B332CBB9E7, 3, 1, 0)

    local structConfig = DataView.ArrayBuffer(8 * 7)
    structConfig:SetInt32(8 * 0, duration)

    local structData = DataView.ArrayBuffer(8 * 3)
    structData:SetInt64(8 * 1, BigInt(VarString(10, "LITERAL_STRING", message)))

    -- UI_FEED_POST_OBJECTIVE
    Citizen.InvokeNative(0xCEDBF17EFCC0E4A4, structConfig:Buffer(), structData:Buffer(), 1)
end

---Exibe um alerta de aviso com som nativo da Rockstar
---@param title string Título do aviso
---@param message string Mensagem descritiva
---@param audioRef? string Referência sonora nativa (padrão: "HUD_REWARD_SOUNDSET")
---@param audioName? string Nome do efeito sonoro (padrão: "REWARD_NEW_ITEM")
---@param duration? number Duração em ms (padrão: 4000)
function Feed.Warning(title, message, audioRef, audioName, duration)
    title = tostring(title or "AVISO")
    message = tostring(message or "")
    audioRef = tostring(audioRef or "HUD_REWARD_SOUNDSET")
    audioName = tostring(audioName or "REWARD_NEW_ITEM")
    duration = tonumber(duration or 4000)

    local structConfig = DataView.ArrayBuffer(8 * 7)
    structConfig:SetInt32(8 * 0, duration)

    local structData = DataView.ArrayBuffer(8 * 5)
    structData:SetInt64(8 * 1, BigInt(VarString(10, "LITERAL_STRING", title)))
    structData:SetInt64(8 * 2, BigInt(VarString(10, "LITERAL_STRING", message)))
    structData:SetInt64(8 * 3, BigInt(VarString(10, "LITERAL_STRING", audioRef)))
    structData:SetInt64(8 * 4, BigInt(VarString(10, "LITERAL_STRING", audioName)))

    Citizen.InvokeNative(0x26E87218390E6729, structConfig:Buffer(), structData:Buffer(), 1, 1)
end

-- ============================================================================
-- EVENTOS DE REDE RECEBIDOS DO SERVIDOR
-- ============================================================================

RegisterNetEvent('westrp:client:feedItem', function(title, subtitle, dict, icon, duration, color)
    Feed.ItemReceived(title, subtitle, dict, icon, duration, color)
end)

RegisterNetEvent('westrp:client:feedTip', function(message, duration)
    Feed.Tip(message, duration)
end)

RegisterNetEvent('westrp:client:feedRightTip', function(message, duration)
    Feed.RightTip(message, duration)
end)

RegisterNetEvent('westrp:client:feedTop', function(title, location, duration)
    Feed.Top(title, location, duration)
end)

RegisterNetEvent('westrp:client:feedObjective', function(message, duration)
    Feed.Objective(message, duration)
end)

RegisterNetEvent('westrp:client:feedWarning', function(title, message, audioRef, audioName, duration)
    Feed.Warning(title, message, audioRef, audioName, duration)
end)

-- Exports globais do westrp_core
exports('ShowFeedItem', function(...) Feed.ItemReceived(...) end)
exports('ShowFeedTip', function(...) Feed.Tip(...) end)
exports('ShowFeedRightTip', function(...) Feed.RightTip(...) end)
exports('ShowFeedTop', function(...) Feed.Top(...) end)
exports('ShowFeedObjective', function(...) Feed.Objective(...) end)
exports('ShowFeedWarning', function(...) Feed.Warning(...) end)
