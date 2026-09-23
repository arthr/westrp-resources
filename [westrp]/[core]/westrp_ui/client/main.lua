local isDockOpen = false
local currentActiveMenu = nil
local keepInputThreadActive = false

local isPanelOpen = false
local currentActivePanel = nil

local isDialogOpen = false
local currentActiveDialog = nil


-- ============================================================================
-- 1. CONTROLE DE FOCO E TECLAS (KEEP INPUT)
-- ============================================================================

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

-- ============================================================================
-- 2. DOCK LATERAL (ROCKSTAR 350px / TECLADO & CÂMERA LIVRE)
-- ============================================================================

---Abre o HUD Dock Lateral a partir de um schema de dados
---@param options DockOptions
function OpenDock(options)
    if not options then return end

    -- Fecha o Panel caso esteja aberto para evitar sobreposição
    if isPanelOpen then
        ClosePanel()
    end

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

---Retorna se o dock está atualmente aberto
---@return boolean
function IsDockOpen()
    return isDockOpen
end

---Atualiza dados de um item no dock aberto em tempo real
---@param itemId string
---@param updates table
---@param tabId? string
function UpdateItem(itemId, updates, tabId)
    if not isDockOpen then return end
    SendNUIMessage({
        action = 'westrp_ui:updateItem',
        tabId = tabId,
        itemId = itemId,
        updates = updates
    })
end

-- ============================================================================
-- 3. PANEL / WORKSPACE (CANVAS CENTRAL / MOUSE LIBERADO)
-- ============================================================================

local SCREEN_BLUR_FILTER = 'OJDominoBlur'

---Aplica o efeito nativo de desfoque de tela do RedM (Rockstar PostFX)
local function ApplyScreenBlur()
    if AnimpostfxIsRunning and AnimpostfxIsRunning(SCREEN_BLUR_FILTER) then
        AnimpostfxStop(SCREEN_BLUR_FILTER)
    end
    if AnimpostfxPlay then
        AnimpostfxPlay(SCREEN_BLUR_FILTER)
    end
end

---Remove o efeito nativo de desfoque de tela do RedM
local function ClearScreenBlur()
    if AnimpostfxStop then
        AnimpostfxStop(SCREEN_BLUR_FILTER)
    end
end

---Abre o Panel Centralizado com cursor do mouse liberado
---@param options PanelOptions
function OpenPanel(options)
    if not options then return end

    -- Fecha o Dock caso esteja aberto
    if isDockOpen then
        CloseDock()
    end

    currentActivePanel = {
        id = options.id or 'default_panel',
        onAction = options.onAction,
        onClose = options.onClose
    }

    isPanelOpen = true

    -- Foco com cursor visível e bloqueio de inputs do jogo
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    -- Ativa o desfoque de tela nativo no motor 3D do RedM
    ApplyScreenBlur()

    SendNUIMessage({
        action = 'westrp_ui:openPanel',
        options = {
            id = options.id,
            title = options.title,
            tag = options.tag,
            subtitle = options.subtitle,
            ctaLabel = options.ctaLabel,
            tabs = options.tabs
        }
    })
end

---Fecha o Panel Centralizado
function ClosePanel()
    if not isPanelOpen then return end
    isPanelOpen = false

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    -- Desativa o desfoque nativo de tela
    ClearScreenBlur()

    SendNUIMessage({
        action = 'westrp_ui:closePanel'
    })

    if currentActivePanel and currentActivePanel.onClose then
        currentActivePanel.onClose()
    end
    currentActivePanel = nil
end

---Retorna se o panel está atualmente aberto
---@return boolean
function IsPanelOpen()
    return isPanelOpen
end

-- ============================================================================
-- 4. SISTEMA DE TOASTS
-- ============================================================================

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
-- 5. SISTEMA DE DIALOG MODAL / FORMULÁRIO TIPADO
-- ============================================================================

---Abre um modal de diálogo tipado (prompt / formulário)
---@param options table { id: string, title: string, subtitle?: string, fields: table[], onSubmit: fun(values: table), onCancel?: fun() }
function OpenDialog(options)
    if not options then return end

    currentActiveDialog = {
        id = options.id or 'default_dialog',
        onSubmit = options.onSubmit,
        onCancel = options.onCancel
    }

    isDialogOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'westrp_ui:openDialog',
        options = {
            id = options.id,
            tag = options.tag,
            title = options.title,
            subtitle = options.subtitle,
            fields = options.fields,
            submitLabel = options.submitLabel,
            cancelLabel = options.cancelLabel
        }
    })
end

---Fecha o modal de diálogo tipado
function CloseDialog()
    if not isDialogOpen then return end
    isDialogOpen = false

    -- Se o Panel não estiver aberto por trás, remove o foco do NUI
    if not isPanelOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    SendNUIMessage({
        action = 'westrp_ui:closeDialog'
    })

    if currentActiveDialog and currentActiveDialog.onCancel then
        currentActiveDialog.onCancel()
    end
    currentActiveDialog = nil
end

---Retorna se o diálogo modal está aberto
---@return boolean
function IsDialogOpen()
    return isDialogOpen
end

-- ============================================================================
-- 6. NUI CALLBACKS RECEBIDOS DO JAVASCRIPT
-- ============================================================================

-- Callbacks do Dock
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

-- Callbacks do Panel
RegisterNUICallback('westrp_ui:panelAction', function(data, cb)
    if currentActivePanel and currentActivePanel.onAction then
        currentActivePanel.onAction(data.action, data.item, data.tabId, data.quantity)
    end
    cb({ ok = true })
end)

RegisterNUICallback('westrp_ui:panelClosed', function(data, cb)
    isPanelOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    ClearScreenBlur()

    if currentActivePanel and currentActivePanel.onClose then
        currentActivePanel.onClose()
    end
    currentActivePanel = nil
    cb({ ok = true })
end)

-- Callbacks do Dialog
RegisterNUICallback('westrp_ui:dialogSubmit', function(data, cb)
    isDialogOpen = false
    if not isPanelOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    if currentActiveDialog and currentActiveDialog.onSubmit then
        currentActiveDialog.onSubmit(data.values or {})
    end
    currentActiveDialog = nil
    cb({ ok = true })
end)

RegisterNUICallback('westrp_ui:dialogCancel', function(data, cb)
    isDialogOpen = false
    if not isPanelOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    if currentActiveDialog and currentActiveDialog.onCancel then
        currentActiveDialog.onCancel()
    end
    currentActiveDialog = nil
    cb({ ok = true })
end)

-- Limpeza ao parar o recurso
AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        if isDockOpen or isPanelOpen or isDialogOpen then
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
            ClearScreenBlur()
        end
    end
end)

-- Exports globais do westrp_ui
exports('OpenDock', OpenDock)
exports('CloseDock', CloseDock)
exports('IsDockOpen', IsDockOpen)
exports('UpdateItem', UpdateItem)
exports('ShowToast', ShowToast)

exports('OpenPanel', OpenPanel)
exports('ClosePanel', ClosePanel)
exports('IsPanelOpen', IsPanelOpen)

exports('OpenDialog', OpenDialog)
exports('CloseDialog', CloseDialog)
exports('IsDialogOpen', IsDialogOpen)

