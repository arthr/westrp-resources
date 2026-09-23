local isDockOpen = false
local currentActiveMenu = nil
local keepInputThreadActive = false

---Desabilita controles de combate quando o menu está aberto em modo Câmera Livre (KeepInput)
local function StartKeepInputControlLoop()
    if keepInputThreadActive then return end
    keepInputThreadActive = true

    CreateThread(function()
        while isDockOpen and currentActiveMenu and currentActiveMenu.keepInput do
            -- Desabilita disparo, mira, coronhada, socos e troca de armas
            DisableControlAction(0, 0x07CE1E0D, true) -- Attack 1
            DisableControlAction(0, 0xF84FA74F, true) -- Attack 2
            DisableControlAction(0, 0xF124618B, true) -- Aim
            DisableControlAction(0, 0x1E0474EB, true) -- Melee Attack
            DisableControlAction(0, 0xD9D0E1C0, true) -- Jump
            DisableControlAction(0, 0x4CC0E2FE, true) -- Weapon Wheel
            DisableControlAction(0, 0x580C4473, true) -- HUD Weapon Wheel
            DisablePlayerFiring(PlayerPedId(), true)
            Wait(0)
        end
        keepInputThreadActive = false
    end)
end

---Abre o HUD Dock Lateral a partir de um schema de dados
---@param options DockOptions
function OpenDock(options)
    if not options then return end

    currentActiveMenu = {
        id = options.id or 'default_menu',
        keepInput = options.keepInput ~= false, -- Default: câmera livre
        onSelect = options.onSelect,
        onChange = options.onChange,
        onClose = options.onClose
    }

    isDockOpen = true

    -- Configura foco no NUI
    if currentActiveMenu.keepInput then
        SetNuiFocus(true, false)
        SetNuiFocusKeepInput(true)
        StartKeepInputControlLoop()
    else
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    end

    SendNUIMessage({
        action = 'westrp_ui:open',
        options = {
            id = options.id,
            title = options.title,
            tag = options.tag,
            tabs = options.tabs,
            items = options.items
        }
    })
end

---Fecha o HUD Dock Lateral
function CloseDock()
    if not isDockOpen then return end
    isDockOpen = false

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'westrp_ui:close'
    })

    if currentActiveMenu and currentActiveMenu.onClose then
        currentActiveMenu.onClose()
    end
    currentActiveMenu = nil
end

---Retorna se o menu está atualmente aberto
---@return boolean
function IsDockOpen()
    return isDockOpen
end

---Atualiza dados de um item no menu aberto em tempo real
---@param tabId? string
---@param itemId string
---@param updates table
function UpdateItem(tabId, itemId, updates)
    if not isDockOpen then return end
    SendNUIMessage({
        action = 'westrp_ui:updateItem',
        tabId = tabId,
        itemId = itemId,
        updates = updates
    })
end

---Exibe um toast elegante de notificação
---@param title string
---@param message string
---@param type? "info"|"success"|"alert"|"error"
---@param duration? number
function ShowToast(title, message, type, duration)
    SendNUIMessage({
        action = 'westrp_ui:toast',
        title = title or "NOTIFICAÇÃO",
        message = message or "",
        type = type or "info",
        duration = duration or 3500
    })
end

-- ============================================================================
-- NUI CALLBACKS RECEBIDOS DO JAVASCRIPT
-- ============================================================================

RegisterNUICallback('westrp_ui:selectItem', function(data, cb)
    if currentActiveMenu and currentActiveMenu.onSelect then
        currentActiveMenu.onSelect(data.item, data.tabId)
    end
    cb({ ok = true })
end)

RegisterNUICallback('westrp_ui:changeValue', function(data, cb)
    if currentActiveMenu and currentActiveMenu.onChange then
        currentActiveMenu.onChange(data.item, data.newValue, data.tabId)
    end
    cb({ ok = true })
end)

RegisterNUICallback('westrp_ui:tabChanged', function(data, cb)
    cb({ ok = true })
end)

RegisterNUICallback('westrp_ui:closed', function(data, cb)
    isDockOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if currentActiveMenu and currentActiveMenu.onClose then
        currentActiveMenu.onClose()
    end
    currentActiveMenu = nil
    cb({ ok = true })
end)

-- Limpeza ao parar o recurso
AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        if isDockOpen then
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
        end
    end
end)

-- Exports globais do westrp_ui
exports('OpenDock', OpenDock)
exports('CloseDock', CloseDock)
exports('IsDockOpen', IsDockOpen)
exports('UpdateItem', UpdateItem)
exports('ShowToast', ShowToast)
