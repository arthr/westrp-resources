WestRP = WestRP or {}
WestRP.Client = WestRP.Client or {}
WestRP.Client.UI = {}

---Abre o HUD Dock Lateral unificado do WestRP
---@param options DockOptions
function WestRP.Client.UI.OpenDock(options)
    if GetResourceState('westrp_ui') ~= 'started' then
        WestRP.Shared.Logger.Error("UI", "O recurso 'westrp_ui' não está iniciado!")
        return
    end
    exports['westrp_ui']:OpenDock(options)
end

---Fecha o HUD Dock Lateral se estiver aberto
function WestRP.Client.UI.CloseDock()
    if GetResourceState('westrp_ui') ~= 'started' then return end
    exports['westrp_ui']:CloseDock()
end

---Retorna se o HUD Dock Lateral está aberto
---@return boolean
function WestRP.Client.UI.IsDockOpen()
    if GetResourceState('westrp_ui') ~= 'started' then return false end
    return exports['westrp_ui']:IsDockOpen()
end

---Atualiza dados de um item no menu aberto em tempo real
---@param itemId string
---@param updates table
---@param tabId? string
function WestRP.Client.UI.UpdateItem(itemId, updates, tabId)
    if GetResourceState('westrp_ui') ~= 'started' then return end
    exports['westrp_ui']:UpdateItem(itemId, updates, tabId)
end

---Dispara notificação Toast elegante padrão Rockstar no canto da tela
---@param title string
---@param message string
---@param type? "info"|"success"|"alert"|"error"
---@param duration? number
function WestRP.Client.UI.ShowToast(title, message, type, duration)
    if GetResourceState('westrp_ui') ~= 'started' then
        WestRP.Shared.Bridge.Player.Notify(title .. ": " .. message)
        return
    end
    exports['westrp_ui']:ShowToast(title, message, type, duration)
end

---Abre o Panel Centralizado (Workspace / Modal de Alta Interatividade com mouse liberado)
---@param options PanelOptions
function WestRP.Client.UI.OpenPanel(options)
    if GetResourceState('westrp_ui') ~= 'started' then
        WestRP.Shared.Logger.Error("UI", "O recurso 'westrp_ui' não está iniciado!")
        return
    end
    exports['westrp_ui']:OpenPanel(options)
end

---Fecha o Panel Centralizado
function WestRP.Client.UI.ClosePanel()
    if GetResourceState('westrp_ui') ~= 'started' then return end
    exports['westrp_ui']:ClosePanel()
end

---Retorna se o Panel Centralizado está aberto
---@return boolean
function WestRP.Client.UI.IsPanelOpen()
    if GetResourceState('westrp_ui') ~= 'started' then return false end
    return exports['westrp_ui']:IsPanelOpen()
end

---Abre um Diálogo Modal com campos de formulário tipados
---@param options table
function WestRP.Client.UI.OpenDialog(options)
    if GetResourceState('westrp_ui') ~= 'started' then
        WestRP.Shared.Logger.Error("UI", "O recurso 'westrp_ui' não está iniciado!")
        return
    end
    exports['westrp_ui']:OpenDialog(options)
end

---Fecha o Diálogo Modal
function WestRP.Client.UI.CloseDialog()
    if GetResourceState('westrp_ui') ~= 'started' then return end
    exports['westrp_ui']:CloseDialog()
end

---Retorna se o Diálogo Modal está aberto
---@return boolean
function WestRP.Client.UI.IsDialogOpen()
    if GetResourceState('westrp_ui') ~= 'started' then return false end
    return exports['westrp_ui']:IsDialogOpen()
end


