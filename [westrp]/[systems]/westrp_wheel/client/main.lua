--[[
    WestRP Wheel — Client Main Controller
    
    Controlador principal da roda nativa RDR2/RedM integrado ao WestRP.
    Utiliza TickManager adaptativo (100ms Idle -> 0ms na Roda), consome State Bags
    reativamente e gerencia a seleção das abas de Provisões e Cavalo.
]]

local NativeHashToVorp = {}

local WheelState = {
    isOpen = false,
    currentWheel = 0, -- 0: Armas, 1: Provisões/Itens, 2: Cavalo
    selectedItem = 0,
    lastSelectedItem = 0,
    currentUsableVorpItem = nil,
    lastUseAt = 0
}

local HASH_HUD_QUICK_SELECT = `HUD_QUICK_SELECT`
local HASH_ITEM_FOCUSED = `ITEM_FOCUSED`
local HASH_TAB_WEAPONS = 0x307DF156 -- Aba de Armas (813560150)
local HASH_TAB_ITEMS   = 0xE74EF76D -- Aba de Provisões (-414255251)
local HASH_TAB_HORSE   = 0xA8422FCB -- Aba de Cavalo (-1472057397)

---Converte valor int32 assinado para representação de 32-bit unsigned
---@param val number
---@return number
local function ToUnsigned32(val)
    if val < 0 then return val + 0x100000000 end
    return val
end

---Constrói o índice reverso de hashes nativos para nomes do banco
---Indexa tanto a versão signed quanto a versão unsigned para busca O(1) à prova de falhas
local function BuildIndex()
    NativeHashToVorp = {}
    for vorpItem, data in pairs(Config.WheelItems or {}) do
        local nativeHash = GetHashKey(data.nativeName)
        NativeHashToVorp[nativeHash] = vorpItem
        NativeHashToVorp[ToUnsigned32(nativeHash)] = vorpItem
    end
end

---Atualiza o item consumível atualmente em foco no cursor
---@param itemHash number
local function UpdateUsableItem(itemHash)
    WheelState.currentUsableVorpItem = nil

    if not itemHash or itemHash == 0 then return end

    local vorpItem = NativeHashToVorp[itemHash] or NativeHashToVorp[ToUnsigned32(itemHash)]
    if not vorpItem then return end

    -- Valida se o jogador realmente possui o item aplicado no inventário nativo
    local applied = NativeMirror.appliedCounts[vorpItem] or 0
    if applied > 0 then
        WheelState.currentUsableVorpItem = vorpItem
    end
end

---Drena e processa as mensagens de eventos pendentes da UI nativa
local function ProcessUIMessages()
    while EventsUiIsPending(HASH_HUD_QUICK_SELECT) do
        local msg = BufferPool.GetUIMessage()
        local ok = Citizen.InvokeNative(0xE24E957294241444, HASH_HUD_QUICK_SELECT, msg:Buffer())
        
        if ok ~= 0 then
            local msgType = msg:GetInt32(0) or 0
            local f1 = msg:GetInt32(8) or 0
            local f2 = ToUnsigned32(msg:GetInt32(16) or 0)

            if msgType == HASH_ITEM_FOCUSED then
                if f1 == 1 and f2 == HASH_TAB_WEAPONS then
                    WheelState.currentWheel = 0
                elseif f1 == 2 and f2 == HASH_TAB_ITEMS then
                    WheelState.currentWheel = 1
                elseif f1 == 3 and f2 == HASH_TAB_HORSE then
                    WheelState.currentWheel = 2
                end
            end
        end
    end
end

---Executado a cada frame enquanto o HUD_QUICK_SELECT estiver ativo
local function HandleWheelTick()
    if not WheelState.isOpen then
        WheelState.isOpen = true
        LocalPlayer.state:set('isWheelOpen', true, false)
    end

    ProcessUIMessages()

    -- Captura o item atualmente destacado na roda pelo cursor analógico/mouse
    local selected = Citizen.InvokeNative(0x9C409BBC492CB5B1, Citizen.ResultAsInteger())
    if selected ~= WheelState.lastSelectedItem then
        WheelState.lastSelectedItem = selected or 0
        WheelState.selectedItem = selected or 0

        if WheelState.currentWheel == 1 or WheelState.currentWheel == 2 then
            UpdateUsableItem(selected)
        else
            WheelState.currentUsableVorpItem = nil
        end
    end
end

---Executado imediatamente no frame em que a roda é liberada (jogador soltou a tecla)
local function HandleWheelRelease()
    local wheelBeforeClose = WheelState.currentWheel
    local usableVorp = WheelState.currentUsableVorpItem
    local now = GetGameTimer()
    local cooldown = Config.CooldownMs or 450

    WheelState.isOpen = false
    WheelState.currentWheel = 0
    WheelState.selectedItem = 0
    WheelState.lastSelectedItem = 0
    WheelState.currentUsableVorpItem = nil
    LocalPlayer.state:set('isWheelOpen', false, false)

    -- Apenas abas de Provisões (1) e Cavalo (2) disparam consumo de consumíveis
    if (wheelBeforeClose == 1 or wheelBeforeClose == 2) and usableVorp then
        if (now - WheelState.lastUseAt) >= cooldown then
            local ped = PlayerPedId()
            if not IsPedDeadOrDying(ped, true) then
                WheelState.lastUseAt = now
                TriggerServerEvent('westrp:wheel:server:useItem', usableVorp)
            end
        end
    end
end

---Exibe notificação amigável de item consumido no padrão WestRP
---@param itemName string
local function NotifyItemUsed(itemName)
    if not Config.Notify or Config.Notify.Enabled == false then return end

    local cfg = Config.WheelItems and Config.WheelItems[itemName]
    local label = cfg and cfg.label or itemName
    local title = Config.Notify.Title or "Você usou:"
    local msg = string.format("%s ~t6~%s~q~", title, label)

    -- Tenta usar o sistema unificado de UI do WestRP
    if WestRP.Client and WestRP.Client.UI and WestRP.Client.UI.ShowToast then
        WestRP.Client.UI.ShowToast("info", string.format("%s %s", title, label))
    else
        -- Fallback nativo limpo
        local str = CreateVarString(10, 'LITERAL_STRING', msg)
        Citizen.InvokeNative(0xFA233F333E58AC82, str)
    end
end

-- ============================================================================
-- INICIALIZAÇÃO & CICLO DE VIDA
-- ============================================================================
local function InitWheelModule()
    BuildIndex()

    -- Sincroniza estado inicial caso a State Bag do jogador já tenha dados
    local initialItems = LocalPlayer.state['wheel:items']
    if initialItems and type(initialItems) == "table" then
        NativeMirror:ApplySnapshot(initialItems)
    end

    -- Tarefa de alta performance via TickManager: 100ms em Idle -> 0ms na Roda
    WestRP.Client.TickManager.CreateTask('westrp_wheel_main', function(task)
        if LocalPlayer.state['wheel:disabled'] then
            task:SetInterval(500)
            return
        end

        local isRunning = IsUiappRunning("hud_quick_select")
        if isRunning then
            task:SetInterval(0)
            HandleWheelTick()
        else
            if WheelState.isOpen then
                HandleWheelRelease()
            end
            task:SetInterval(100)
        end
    end, 100)

    WestRP.Shared.Logger.Info("WHEEL", "Módulo de InputWheel nativa inicializado com sucesso!")
end

local function CleanupWheelModule()
    WestRP.Client.TickManager.RemoveTask('westrp_wheel_main')
    NativeMirror:ClearSatchel()
    LocalPlayer.state:set('isWheelOpen', false, false)
end

-- Ouvinte reativo da State Bag oficial (Disparado quando o servidor altera os itens)
AddStateBagChangeHandler('wheel:items', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(_, _, newSnapshot)
    if newSnapshot and type(newSnapshot) == "table" then
        NativeMirror:ApplySnapshot(newSnapshot)
    end
end)

-- Notificação enviada pelo servidor após consumo seguro
RegisterNetEvent('westrp:wheel:client:onItemUsed', function(itemName)
    NotifyItemUsed(itemName)
end)

-- Gatilhos de Ciclo de Vida do RedM
AddEventHandler('onResourceStart', function(resName)
    if resName == GetCurrentResourceName() then
        InitWheelModule()
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        CleanupWheelModule()
    end
end)

CreateThread(function()
    InitWheelModule()
end)
