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
---@param tabId? string
---@param itemId string
---@param updates table
function WestRP.Client.UI.UpdateItem(tabId, itemId, updates)
    if GetResourceState('westrp_ui') ~= 'started' then return end
    exports['westrp_ui']:UpdateItem(tabId, itemId, updates)
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
