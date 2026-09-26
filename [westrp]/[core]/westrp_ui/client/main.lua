local isDockOpen = false
local currentActiveMenu = nil
local keepInputThreadActive = false

local isPanelOpen = false
local currentActivePanel = nil

local isDialogOpen = false
local currentActiveDialog = nil

local isConfirmOpen = false
local currentActiveConfirm = nil

local isProgressActive = false
local currentProgressTask = nil
local activeProgressProp = nil


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
            position = options.position,
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
            brand = options.brand,
            operator = options.operator,
            tabs = options.tabs
        }
    })
end

---Atualiza dados/abas do Panel enquanto aberto
---@param options table
function UpdatePanel(options)
    if not isPanelOpen then return end
    SendNUIMessage({
        action = 'westrp_ui:updatePanel',
        options = options
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

RegisterNetEvent('westrp_ui:client:showToast', function(title, message, type, duration)
    ShowToast(title, message, type, duration)
end)

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
-- 6. SISTEMA DE MODAL DE CONFIRMAÇÃO RÁPIDA (OPEN CONFIRM)
-- ============================================================================

---Abre uma caixa de diálogo de confirmação binária (Sim/Não) estilizada
---@param options { id?: string, title?: string, tag?: string, message: string, submessage?: string, confirmLabel?: string, cancelLabel?: string, danger?: boolean, onConfirm?: fun(), onCancel?: fun() }
function OpenConfirm(options)
    if not options then return end

    currentActiveConfirm = {
        id = options.id or 'default_confirm',
        onConfirm = options.onConfirm,
        onCancel = options.onCancel
    }

    isConfirmOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'westrp_ui:openConfirm',
        options = {
            id = options.id,
            tag = options.tag,
            title = options.title,
            message = options.message,
            submessage = options.submessage,
            confirmLabel = options.confirmLabel,
            cancelLabel = options.cancelLabel,
            danger = options.danger == true
        }
    })
end

---Fecha a caixa de diálogo de confirmação
function CloseConfirm()
    if not isConfirmOpen then return end
    isConfirmOpen = false

    if not isPanelOpen and not isDialogOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    SendNUIMessage({
        action = 'westrp_ui:closeConfirm'
    })

    if currentActiveConfirm and currentActiveConfirm.onCancel then
        currentActiveConfirm.onCancel()
    end
    currentActiveConfirm = nil
end

---Retorna se a confirmação está aberta
---@return boolean
function IsConfirmOpen()
    return isConfirmOpen
end

-- ============================================================================
-- 7. SISTEMA DE ACTION PROGRESS BAR (BARRA DE PROGRESSO PROCEDURAL)
-- ============================================================================

local function StopProgressAnimationAndProp()
    local ped = PlayerPedId()
    ClearPedTasks(ped)

    if activeProgressProp and DoesEntityExist(activeProgressProp) then
        DeleteEntity(activeProgressProp)
        activeProgressProp = nil
    end
end

---Inicia uma barra de progresso procedural para ações no mundo
---@param options { label: string, duration: number, icon?: string, canCancel?: boolean, useWhileDead?: boolean, disableControls?: { movement?: boolean, combat?: boolean }, animation?: { dict: string, name: string, flag?: number }, prop?: { model: string|number, bone: number, coords?: vector3, rotation?: vector3 }, onComplete?: fun(), onCancel?: fun(reason: string) }
function StartProgressBar(options)
    if not options then return end
    local ped = PlayerPedId()

    -- Se o jogador estiver morto ou morrendo e não for permitido
    if not options.useWhileDead and IsPedDeadOrDying(ped, true) then
        if options.onCancel then options.onCancel('dead') end
        return
    end

    -- Se já houver barra ativa, cancela a anterior
    if isProgressActive then
        CancelProgressBar('interrupted')
    end

    isProgressActive = true
    currentProgressTask = {
        canCancel = options.canCancel ~= false,
        useWhileDead = options.useWhileDead == true,
        disableControls = options.disableControls or {},
        startHealth = GetEntityHealth(ped),
        onComplete = options.onComplete,
        onCancel = options.onCancel
    }

    -- Toca animação se configurada
    if options.animation and options.animation.dict and options.animation.name then
        local dict = options.animation.dict
        RequestAnimDict(dict)
        local timeout = GetGameTimer() + 2000
        while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
            Wait(10)
        end
        if HasAnimDictLoaded(dict) then
            TaskPlayAnim(ped, dict, options.animation.name, 8.0, -8.0, -1, options.animation.flag or 1, 0, false, false, false)
        end
    end

    -- Anexa prop se configurado
    if options.prop and options.prop.model then
        local modelHash = type(options.prop.model) == 'string' and joaat(options.prop.model) or options.prop.model
        RequestModel(modelHash)
        local timeout = GetGameTimer() + 2000
        while not HasModelLoaded(modelHash) and GetGameTimer() < timeout do
            Wait(10)
        end
        if HasModelLoaded(modelHash) then
            local pCoords = GetEntityCoords(ped)
            local propObj = CreateObject(modelHash, pCoords.x, pCoords.y, pCoords.z, true, true, false)
            local bone = GetPedBoneIndex(ped, options.prop.bone or 0)
            local offset = options.prop.coords or vector3(0.0, 0.0, 0.0)
            local rot = options.prop.rotation or vector3(0.0, 0.0, 0.0)
            AttachEntityToEntity(propObj, ped, bone, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, true, true, false, true, 1, true)
            activeProgressProp = propObj
        end
    end

    SendNUIMessage({
        action = 'westrp_ui:startProgress',
        options = {
            label = options.label or "REALIZANDO AÇÃO...",
            duration = options.duration or 3000,
            icon = options.icon or "hammer",
            canCancel = currentProgressTask.canCancel
        }
    })

    -- Thread de observação de integridade (sono de 0ms enquanto ativa para desabilitar inputs com precisão)
    CreateThread(function()
        while isProgressActive and currentProgressTask do
            local currentPed = PlayerPedId()

            -- Se o jogador morreu
            if not currentProgressTask.useWhileDead and IsPedDeadOrDying(currentPed, true) then
                CancelProgressBar('dead')
                break
            end

            -- Se o jogador sofreu dano físico
            if GetEntityHealth(currentPed) < currentProgressTask.startHealth then
                CancelProgressBar('damaged')
                break
            end

            -- Desabilita combate se solicitado (padrão ativo)
            if currentProgressTask.disableControls.combat ~= false then
                DisableControlAction(0, 0x07CE1E0D, true) -- Attack 1
                DisableControlAction(0, 0xF84FA74F, true) -- Attack 2
                DisableControlAction(0, 0xF124618B, true) -- Aim
                DisableControlAction(0, 0x1E0474EB, true) -- Melee
                DisableControlAction(0, 0x4CC0E2FE, true) -- Weapon Wheel
                DisablePlayerFiring(currentPed, true)
            end

            -- Desabilita movimentação se solicitado
            if currentProgressTask.disableControls.movement then
                DisableControlAction(0, 0x8FD015D8, true) -- Move LR
                DisableControlAction(0, 0xD27782E3, true) -- Move UD
                DisableControlAction(0, 0xD9D0E1C0, true) -- Jump
                DisableControlAction(0, 0x8FF95D16, true) -- Sprint
            end

            Wait(0)
        end
    end)
end

---Cancela a barra de progresso ativa
---@param reason? string Motivo do cancelamento (ex: 'moved', 'damaged', 'dead', 'cancelled')
function CancelProgressBar(reason)
    if not isProgressActive then return end
    isProgressActive = false

    StopProgressAnimationAndProp()

    SendNUIMessage({
        action = 'westrp_ui:cancelProgress',
        reason = reason or 'cancelled'
    })

    if currentProgressTask and currentProgressTask.onCancel then
        currentProgressTask.onCancel(reason or 'cancelled')
    end
    currentProgressTask = nil
end

---Retorna se há uma barra de progresso ativa no momento
---@return boolean
function IsProgressBarActive()
    return isProgressActive
end

-- ============================================================================
-- 8. NUI CALLBACKS RECEBIDOS DO JAVASCRIPT
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
        currentActivePanel.onAction(data.action, data.item or data.tileData, data.tabId, data.quantity, data)
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
    if not isPanelOpen and not isConfirmOpen then
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
    if not isPanelOpen and not isConfirmOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    if currentActiveDialog and currentActiveDialog.onCancel then
        currentActiveDialog.onCancel()
    end
    currentActiveDialog = nil
    cb({ ok = true })
end)

-- Callbacks do Confirm
RegisterNUICallback('westrp_ui:confirmResult', function(data, cb)
    isConfirmOpen = false
    if not isPanelOpen and not isDialogOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    if currentActiveConfirm then
        if data.confirmed and currentActiveConfirm.onConfirm then
            currentActiveConfirm.onConfirm()
        elseif not data.confirmed and currentActiveConfirm.onCancel then
            currentActiveConfirm.onCancel()
        end
    end
    currentActiveConfirm = nil
    cb({ ok = true })
end)

-- Callbacks do Progress Bar
RegisterNUICallback('westrp_ui:progressComplete', function(data, cb)
    if isProgressActive then
        isProgressActive = false
        StopProgressAnimationAndProp()

        if currentProgressTask and currentProgressTask.onComplete then
            currentProgressTask.onComplete()
        end
        currentProgressTask = nil
    end
    cb({ ok = true })
end)

RegisterNUICallback('westrp_ui:progressCancel', function(data, cb)
    if isProgressActive then
        isProgressActive = false
        StopProgressAnimationAndProp()

        if currentProgressTask and currentProgressTask.onCancel then
            currentProgressTask.onCancel(data.reason or 'user_cancelled')
        end
        currentProgressTask = nil
    end
    cb({ ok = true })
end)

-- Limpeza ao parar o recurso
AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        if isDockOpen or isPanelOpen or isDialogOpen or isConfirmOpen then
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
            ClearScreenBlur()
        end
        if isProgressActive then
            StopProgressAnimationAndProp()
            isProgressActive = false
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
exports('UpdatePanel', UpdatePanel)
exports('ClosePanel', ClosePanel)
exports('IsPanelOpen', IsPanelOpen)

exports('OpenDialog', OpenDialog)
exports('CloseDialog', CloseDialog)
exports('IsDialogOpen', IsDialogOpen)

exports('OpenConfirm', OpenConfirm)
exports('CloseConfirm', CloseConfirm)
exports('IsConfirmOpen', IsConfirmOpen)

exports('StartProgressBar', StartProgressBar)
exports('CancelProgressBar', CancelProgressBar)
exports('IsProgressBarActive', IsProgressBarActive)

