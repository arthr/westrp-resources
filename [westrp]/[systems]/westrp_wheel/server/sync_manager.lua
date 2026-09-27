--[[
    WestRP Wheel — Server Sync Manager (100% Event-Driven & Zero Polling)
    
    Gerencia a sincronização de itens da roda para os State Bags dos jogadores.
    Substitui completamente o loop ineficiente de polling do script original por
    uma arquitetura orientada a eventos da Bridge com fila debounced e triagem
    inteligente de itens degradáveis (FIFO por durabilidade).
]]

SyncManager = {
    lastSignature = {},
    lastUseEntries = {},
    pendingSync = {},
    pendingUses = {}
}

---Verifica se um determinado item faz parte da whitelist da roda
---@param itemName string
---@return table|nil
function SyncManager:IsWheelItem(itemName)
    return itemName and Config.WheelItems and Config.WheelItems[itemName]
end

---Gera uma assinatura de hash dos itens para checagem rápida de alteração (Dirty Check)
---@param snapshot table<string, number>
---@return string
function SyncManager:BuildSignature(snapshot)
    local keys = {}
    for itemName, _ in pairs(Config.WheelItems or {}) do
        keys[#keys + 1] = itemName
    end
    table.sort(keys)

    local parts = {}
    for i = 1, #keys do
        local itemName = keys[i]
        local count = tonumber(snapshot[itemName] or 0) or 0
        if count > 0 then
            parts[#parts + 1] = string.format("%s:%d", itemName, count)
        end
    end
    return table.concat(parts, "|")
end

---Verifica se o item é elegível para uso a partir da roda
---@param item table
---@return boolean
local function CanBeUsedFromWheel(item)
    if not item or not item.id or not item.name then return false end
    if item.canUse == false then return false end

    if item.isDegradable then
        local percentage = tonumber(item.percentage or 100) or 100
        if percentage <= 0 then
            local metadata = item.metadata or {}
            if metadata.useExpired ~= true then
                return false
            end
        end
    end
    return true
end

---Triagem Inteligente (Task 3.4): Seleciona o melhor item para consumo
---Se degradável, prioriza o item com MENOR porcentagem (prestes a estragar)
---Se não for degradável, prioriza o stack com maior quantidade
---@param currentEntry table|nil
---@param newItem table
---@return boolean
local function ChooseBetterUseEntry(currentEntry, newItem)
    if not currentEntry then return true end

    local newIsDegradable = (newItem.isDegradable == true)
    local curIsDegradable = (currentEntry.isDegradable == true)

    if newIsDegradable and curIsDegradable then
        local curPct = tonumber(currentEntry.percentage or 100) or 100
        local newPct = tonumber(newItem.percentage or 100) or 100
        if newPct < curPct then
            return true
        elseif newPct > curPct then
            return false
        end
    end

    local currentCount = tonumber(currentEntry.count or 0) or 0
    local newCount = tonumber(newItem.count or newItem.amount or 0) or 0
    return newCount > currentCount
end

---Constrói o snapshot compacto e as entradas de uso do inventário do jogador
---@param items table
---@return table, table
function SyncManager:BuildStateFromInventory(items)
    local snapshot = {}
    local useEntries = {}

    for vorpItemName, _ in pairs(Config.WheelItems or {}) do
        snapshot[vorpItemName] = 0
    end

    for _, item in pairs(items or {}) do
        local itemName = item.name
        local count = tonumber(item.count or item.amount or 0) or 0

        if self:IsWheelItem(itemName) and count > 0 then
            snapshot[itemName] = (snapshot[itemName] or 0) + count

            if CanBeUsedFromWheel(item) then
                if ChooseBetterUseEntry(useEntries[itemName], item) then
                    useEntries[itemName] = {
                        id = item.id,
                        name = item.name,
                        type = item.type or 'item_standard',
                        count = count,
                        metadata = item.metadata or {},
                        percentage = item.percentage,
                        isDegradable = item.isDegradable == true
                    }
                end
            end
        end
    end

    return snapshot, useEntries
end

---Sincroniza o inventário do jogador e publica na State Bag se houver alterações
---@param source number
---@param force? boolean
function SyncManager:SyncPlayer(source, force)
    local src = tonumber(source)
    if not src or not GetPlayerName(src) then return end

    exports.vorp_inventory:getUserInventoryItems(src, function(items)
        if not GetPlayerName(src) then return end

        local snapshot, useEntries = self:BuildStateFromInventory(items)
        local signature = self:BuildSignature(snapshot)

        self.lastUseEntries[src] = useEntries or {}

        if force or self.lastSignature[src] ~= signature then
            self.lastSignature[src] = signature
            
            -- Publica na State Bag nativa do CitizenFX com replicação para o cliente
            local playerState = Player(src).state
            if playerState then
                playerState:set('wheel:items', snapshot, true)
            end

            if Config.Debug then
                WestRP.Shared.Logger.Debug("WHEEL", "Sincronização aplicada para player %s (Sig: %s)", src, signature)
            end
        end
    end)
end

---Enfileira uma sincronização com debounce de 150ms para evitar rajadas de pacotes
---@param source number
function SyncManager:QueueSync(source)
    local src = tonumber(source)
    if not src or self.pendingSync[src] then return end

    self.pendingSync[src] = true
    SetTimeout(150, function()
        if self.pendingSync[src] then
            self.pendingSync[src] = nil
            self:SyncPlayer(src, false)
        end
    end)
end

---Retorna a melhor entrada de uso para o item solicitado
---@param source number
---@param itemName string
---@return table|nil
function SyncManager:GetBestUseEntry(source, itemName)
    local entries = self.lastUseEntries[source]
    if entries and entries[itemName] then
        return entries[itemName]
    end
    return nil
end

---Registra uma intenção de consumo pela roda para validação
---@param source number
---@param itemId any
---@param itemName string
function SyncManager:RegisterPendingUse(source, itemId, itemName)
    self.pendingUses[source] = {
        itemId = itemId,
        itemName = itemName,
        timestamp = GetGameTimer()
    }
end

---Finaliza o consumo do item após confirmação do evento OnItemRemoved do inventário
---@param source number
---@param data table
---@return boolean
function SyncManager:CheckAndFinishUse(source, data)
    local pending = self.pendingUses[source]
    if not pending or not data or not data.name then return false end

    if pending.itemName == data.name then
        self.pendingUses[source] = nil
        TriggerClientEvent('westrp:wheel:client:onItemUsed', source, data.name)
        self:QueueSync(source)
        return true
    end

    return false
end

-- ============================================================================
-- GANCHOS ORIENTADOS A EVENTOS (Zero Polling)
-- ============================================================================

-- Disparado quando o jogador seleciona o personagem
AddEventHandler('vorp:SelectedCharacter', function(source, _)
    local src = tonumber(source)
    if src then
        SetTimeout(1000, function()
            SyncManager:SyncPlayer(src, true)
        end)
    end
end)

-- Ganchos de alteração de inventário nativos do VORP
AddEventHandler('vorp_inventory:Server:OnItemCreated', function(data, source)
    if source and data and SyncManager:IsWheelItem(data.name) then
        SyncManager:QueueSync(source)
    end
end)

AddEventHandler('vorp_inventory:Server:OnItemRemoved', function(data, source)
    if not source or not data then return end

    -- Verifica se a remoção foi resultado do uso disparado pela roda
    if SyncManager:CheckAndFinishUse(source, data) then
        return
    end

    if SyncManager:IsWheelItem(data.name) then
        SyncManager:QueueSync(source)
    end
end)

AddEventHandler('vorp_inventory:Server:OnItemTakenFromCustomInventory', function(item, _, source)
    if source and item and SyncManager:IsWheelItem(item.name) then
        SyncManager:QueueSync(source)
    end
end)

AddEventHandler('vorp_inventory:Server:OnItemMovedToCustomInventory', function(item, _, source)
    if source and item and SyncManager:IsWheelItem(item.name) then
        SyncManager:QueueSync(source)
    end
end)

-- Limpeza de memória ao desconectar
AddEventHandler('playerDropped', function()
    local src = source
    SyncManager.lastSignature[src] = nil
    SyncManager.lastUseEntries[src] = nil
    SyncManager.pendingSync[src] = nil
    SyncManager.pendingUses[src] = nil
end)
