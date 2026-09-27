local isDockOpen = false
local currentActiveMenu = nil
local keepInputThreadActive = false

local isPanelOpen = false
local currentActivePanel = nil

local isDialogOpen = false
local currentActiveDialog = nil

local isConfirmOpen = false
local currentActiveConfirm = nil

local isModalOpen = false
local currentActiveModal = nil

local isSliderPanelOpen = false
local currentActiveSlider = nil

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
            width = options.width,
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

---Abre um prompt de entrada de campo único (substituto oficial e elegante do vorp_inputs)
---@param options { id?: string, title?: string, tag?: string, description?: string, type?: "currency"|"number"|"text"|"textarea"|"select", placeholder?: string, min?: number, max?: number, step?: number, options?: table[], value?: any, submitLabel?: string, cancelLabel?: string }
---@param callback fun(value: any)
function PromptInput(options, callback)
    if not options then return end
    local fieldId = 'input_val'
    OpenDialog({
        id = options.id or 'prompt_input',
        title = options.title or 'ENTRADA DE DADOS',
        tag = options.tag or 'PROMPT',
        subtitle = options.description or options.subtitle,
        submitLabel = options.submitLabel or 'CONFIRMAR',
        cancelLabel = options.cancelLabel or 'CANCELAR',
        fields = {
            {
                id = fieldId,
                label = options.label or '',
                type = options.type or 'text',
                placeholder = options.placeholder or '',
                min = options.min,
                max = options.max,
                step = options.step,
                value = options.value,
                options = options.options,
                description = options.fieldDesc
            }
        },
        onSubmit = function(values)
            if callback then
                callback(values[fieldId])
            end
        end,
        onCancel = function()
            if callback then
                callback(nil)
            end
        end
    })
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
-- 6.1 SISTEMA DE MODAL FLUTUANTE RDR2 (RDRMODAL ZOOM-IN)
-- ============================================================================

---Abre o modal nativo RDR2 com animação de zoom e backdrop
---@param options { id?: string, title?: string, subtitle?: string, content?: string, html?: string, width?: string, height?: string, closable?: boolean, closeOnOverlay?: boolean, buttons?: table[], onClose?: fun(), onAction?: fun(action: string, data: table) }
function OpenModal(options)
    if not options then return end

    currentActiveModal = {
        id = options.id or 'default_modal',
        onClose = options.onClose,
        onAction = options.onAction
    }

    isModalOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    local sanitizedButtons = nil
    if options.buttons and type(options.buttons) == 'table' then
        sanitizedButtons = {}
        for i, btn in ipairs(options.buttons) do
            sanitizedButtons[i] = {
                label = btn.label,
                variant = btn.variant,
                action = btn.action
            }
        end
    end

    SendNUIMessage({
        action = 'westrp_ui:openModal',
        options = {
            id = options.id,
            title = options.title,
            subtitle = options.subtitle,
            content = options.content,
            html = options.html,
            width = options.width,
            height = options.height,
            closable = options.closable ~= false,
            closeOnOverlay = options.closeOnOverlay ~= false,
            buttons = sanitizedButtons
        }
    })
end

---Fecha o modal nativo RDR2
function CloseModal()
    if not isModalOpen then return end
    isModalOpen = false

    if not isPanelOpen and not isDialogOpen and not isConfirmOpen and not isSliderPanelOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    SendNUIMessage({
        action = 'westrp_ui:closeModal'
    })

    if currentActiveModal and currentActiveModal.onClose then
        currentActiveModal.onClose()
    end
    currentActiveModal = nil
end

---Retorna se o modal RDR2 está aberto
---@return boolean
function IsModalOpen()
    return isModalOpen
end

-- ============================================================================
-- 6.2 SISTEMA DE GAVETA LATERAL RDR2 (RDRSLIDER SLIDE-IN)
-- ============================================================================

---Abre a gaveta lateral RDR2 deslizando pela borda da tela
---@param options { id?: string, side?: "right"|"left", width?: string, title?: string, content?: string, html?: string, closable?: boolean, closeOnOverlay?: boolean, onClose?: fun() }
function OpenSliderPanel(options)
    if not options then return end

    currentActiveSlider = {
        id = options.id or 'default_slider',
        onClose = options.onClose
    }

    isSliderPanelOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'westrp_ui:openSliderPanel',
        options = {
            id = options.id,
            side = options.side or 'right',
            width = options.width,
            title = options.title,
            content = options.content,
            html = options.html,
            closable = options.closable ~= false,
            closeOnOverlay = options.closeOnOverlay ~= false
        }
    })
end

---Fecha a gaveta lateral RDR2
function CloseSliderPanel()
    if not isSliderPanelOpen then return end
    isSliderPanelOpen = false

    if not isPanelOpen and not isDialogOpen and not isConfirmOpen and not isModalOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    SendNUIMessage({
        action = 'westrp_ui:closeSliderPanel'
    })

    if currentActiveSlider and currentActiveSlider.onClose then
        currentActiveSlider.onClose()
    end
    currentActiveSlider = nil
end

---Retorna se a gaveta lateral está aberta
---@return boolean
function IsSliderPanelOpen()
    return isSliderPanelOpen
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

local function RegisterUnifiedCallback(names, handler)
    if type(names) == 'string' then names = { names } end
    for _, name in ipairs(names) do
        RegisterNUICallback(name, handler)
        RegisterNUICallback('westrp_ui:' .. name, handler)
    end
end

-- Callbacks do Dock
RegisterUnifiedCallback({'selectItem', 'itemSelect'}, function(data, cb)
    cb({ ok = true })
    if currentActiveMenu and currentActiveMenu.onSelect then
        local onSelect = currentActiveMenu.onSelect
        CreateThread(function()
            onSelect(data.item, data.tabId)
        end)
    end
end)

RegisterUnifiedCallback({'changeValue', 'itemChange'}, function(data, cb)
    cb({ ok = true })
    if currentActiveMenu and currentActiveMenu.onChange then
        local onChange = currentActiveMenu.onChange
        CreateThread(function()
            onChange(data.item, data.value or data.newValue, data.tabId)
        end)
    end
end)

RegisterUnifiedCallback({'tabChanged'}, function(data, cb)
    cb({ ok = true })
end)

RegisterUnifiedCallback({'closed', 'close'}, function(data, cb)
    cb({ ok = true })
    isDockOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if currentActiveMenu and currentActiveMenu.onClose then
        local onClose = currentActiveMenu.onClose
        CreateThread(function()
            onClose()
        end)
    end
    currentActiveMenu = nil
end)

-- Callbacks do Panel
RegisterUnifiedCallback({'panelAction'}, function(data, cb)
    cb({ ok = true })
    if currentActivePanel and currentActivePanel.onAction then
        local onAction = currentActivePanel.onAction
        CreateThread(function()
            onAction(data.action or 'select', data.item or data.tileData, data.tabId, data.quantity, data)
        end)
    end
end)

RegisterUnifiedCallback({'panelClosed', 'closePanel'}, function(data, cb)
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
RegisterUnifiedCallback({'dialogSubmit'}, function(data, cb)
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

RegisterUnifiedCallback({'dialogCancel'}, function(data, cb)
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
RegisterUnifiedCallback({'confirmResult', 'confirmSubmit'}, function(data, cb)
    isConfirmOpen = false
    if not isPanelOpen and not isDialogOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    if currentActiveConfirm and currentActiveConfirm.onConfirm then
        currentActiveConfirm.onConfirm()
    end
    currentActiveConfirm = nil
    cb({ ok = true })
end)

RegisterUnifiedCallback({'confirmCancel'}, function(data, cb)
    isConfirmOpen = false
    if not isPanelOpen and not isDialogOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    if currentActiveConfirm and currentActiveConfirm.onCancel then
        currentActiveConfirm.onCancel()
    end
    currentActiveConfirm = nil
    cb({ ok = true })
end)

-- Callbacks do Progress Bar
RegisterUnifiedCallback({'progressComplete'}, function(data, cb)
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

RegisterUnifiedCallback({'progressCancel'}, function(data, cb)
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

-- Callbacks do Modal e Slider Panel
RegisterUnifiedCallback({'modalClosed', 'closeModal'}, function(data, cb)
    isModalOpen = false
    if not isPanelOpen and not isDialogOpen and not isConfirmOpen and not isSliderPanelOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    if currentActiveModal and currentActiveModal.onClose then
        currentActiveModal.onClose()
    end
    currentActiveModal = nil
    cb({ ok = true })
end)

RegisterUnifiedCallback({'modalAction'}, function(data, cb)
    if currentActiveModal and currentActiveModal.onAction then
        currentActiveModal.onAction(data.action, data)
    end
    cb({ ok = true })
end)

RegisterUnifiedCallback({'sliderPanelClosed', 'closeSliderPanel'}, function(data, cb)
    isSliderPanelOpen = false
    if not isPanelOpen and not isDialogOpen and not isConfirmOpen and not isModalOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    if currentActiveSlider and currentActiveSlider.onClose then
        currentActiveSlider.onClose()
    end
    currentActiveSlider = nil
    cb({ ok = true })
end)

-- Limpeza ao parar o recurso
AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        if isDockOpen or isPanelOpen or isDialogOpen or isConfirmOpen or isModalOpen or isSliderPanelOpen then
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
exports('PromptInput', PromptInput)

exports('OpenConfirm', OpenConfirm)
exports('CloseConfirm', CloseConfirm)
exports('IsConfirmOpen', IsConfirmOpen)

exports('OpenModal', OpenModal)
exports('CloseModal', CloseModal)
exports('IsModalOpen', IsModalOpen)

exports('OpenSliderPanel', OpenSliderPanel)
exports('CloseSliderPanel', CloseSliderPanel)
exports('IsSliderPanelOpen', IsSliderPanelOpen)

exports('StartProgressBar', StartProgressBar)
exports('CancelProgressBar', CancelProgressBar)
exports('IsProgressBarActive', IsProgressBarActive)


