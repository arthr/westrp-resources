--[[
    WestRP Wheel — Native Mirror Satchel Manager
    
    Gerencia a injeção e remoção de itens na Satchel C++ nativa do RDR2/RedM
    utilizando a engine de GUIDs de 128-bits e os buffers estáticos do BufferPool.
    Garante Zero Garbage Collection e sincronização delta precisa.
]]

NativeMirror = {
    appliedCounts = {},
    isInitialized = false
}

local HASH_CHARACTER = `CHARACTER`
local HASH_SLOTID_NONE = `SLOTID_NONE`
local HASH_SLOTID_SATCHEL = `SLOTID_SATCHEL`
local HASH_SLOTID_ACTIVE_HORSE = `SLOTID_ACTIVE_HORSE`
local HASH_ADD_REASON = `ADD_REASON_DEFAULT`
local HASH_REMOVE_REASON = `REMOVE_REASON_DEFAULT`

local function SafeHash(val)
    if type(val) == "number" then return val end
    return GetHashKey(tostring(val))
end

---Obtém ou atualiza o GUID raiz do inventário do jogador (CHARACTER)
---@return any, boolean
function NativeMirror:GetPlayerInventoryGUID()
    local playerInvGuid = BufferPool.GetPlayerInvGuid()
    
    -- Se já estiver válido em cache, retorna imediatamente
    if Citizen.InvokeNative(0xB881CA836CC4B6D4, playerInvGuid:Buffer()) then
        return playerInvGuid, true
    end

    local emptyGuid = BufferPool.GetGuid1()
    local ok = Citizen.InvokeNative(
        0x886DFD3E185C8A89,
        1,
        emptyGuid:Buffer(),
        HASH_CHARACTER,
        HASH_SLOTID_NONE,
        playerInvGuid:Buffer(),
        Citizen.ResultAsInteger()
    )

    local isValid = (ok == 1) and Citizen.InvokeNative(0xB881CA836CC4B6D4, playerInvGuid:Buffer())
    return playerInvGuid, isValid
end

---Resolve as informações de slot (Parent GUID e SlotID) para um determinado item
---@param itemHash number
---@param preferredSlot? string|number
---@return any, number
function NativeMirror:ResolveSlot(itemHash, preferredSlot)
    local playerInvGuid, ok = self:GetPlayerInventoryGUID()
    if not ok then
        return nil, 0
    end

    local slotId = HASH_SLOTID_SATCHEL
    if preferredSlot then
        slotId = SafeHash(preferredSlot)
    else
        -- Caso não haja slot configurado, consulta o ItemDatabase nativo
        local itemInfo = BufferPool.GetItemInfo()
        if Citizen.InvokeNative(0xFE90ABBCBFDC13B2, itemHash, itemInfo:Buffer()) then
            local group = itemInfo:GetInt32(16) or 0
            if group == `HORSE` then
                slotId = HASH_SLOTID_ACTIVE_HORSE
            end
        end
    end

    BufferPool.SetSlot(playerInvGuid, slotId)
    return BufferPool.GetSlotParentGuid(), BufferPool.GetSlotId()
end

---Localiza o GUID existente de um item na Satchel C++
---@param itemHash number
---@param preferredSlot? string|number
---@return any|nil, boolean
function NativeMirror:GetExistingItemGuid(itemHash, preferredSlot)
    local parentGuid, slotId = self:ResolveSlot(itemHash, preferredSlot)
    if not parentGuid then return nil, false end

    local outGuid = BufferPool.GetGuid1()
    local result = Citizen.InvokeNative(
        0x886DFD3E185C8A89,
        1,
        parentGuid:Buffer(),
        itemHash,
        slotId,
        outGuid:Buffer(),
        Citizen.ResultAsInteger()
    )

    local isValid = (result == 1) and Citizen.InvokeNative(0xB881CA836CC4B6D4, outGuid:Buffer())
    return outGuid, isValid
end

---Adiciona uma quantidade de item na Satchel C++ nativa
---@param itemHash number
---@param quantity number
---@param preferredSlot? string|number
---@return boolean
function NativeMirror:AddItem(itemHash, quantity, preferredSlot)
    local parentGuid, slotId = self:ResolveSlot(itemHash, preferredSlot)
    if not parentGuid then return false end

    local qty = math.max(1, math.floor(tonumber(quantity) or 1))
    local newItemGuid = BufferPool.GetGuid2()

    return Citizen.InvokeNative(
        0xCB5D11F9508A928D,
        1,
        newItemGuid:Buffer(),
        parentGuid:Buffer(),
        itemHash,
        slotId,
        qty,
        HASH_ADD_REASON
    )
end

---Remove uma quantidade de item da Satchel C++ nativa com suporte a stacks múltiplos
---@param itemHash number
---@param quantity number
---@param preferredSlot? string|number
---@return boolean
function NativeMirror:RemoveItem(itemHash, quantity, preferredSlot)
    local qty = math.max(1, math.floor(tonumber(quantity) or 1))
    local remaining = qty
    local attempts = 0

    while remaining > 0 and attempts < 10 do
        local existingGuid, isValid = self:GetExistingItemGuid(itemHash, preferredSlot)
        if not isValid or not existingGuid then break end

        local ok = Citizen.InvokeNative(
            0x3E4E811480B3AE79,
            1,
            existingGuid:Buffer(),
            remaining,
            HASH_REMOVE_REASON
        )

        if not ok then break end
        attempts = attempts + 1

        -- Se a remoção foi completa, o GUID deixa de ser válido
        local _, stillValid = self:GetExistingItemGuid(itemHash, preferredSlot)
        if not stillValid then break end
        remaining = remaining - 1
    end

    return true
end

---Aplica um snapshot completo de itens calculando o delta estritamente necessário
---@param snapshot table<string, number>
function NativeMirror:ApplySnapshot(snapshot)
    if not snapshot or type(snapshot) ~= "table" then return end

    local playerInvGuid, ok = self:GetPlayerInventoryGUID()
    if not ok then
        if Config.Debug then
            WestRP.Shared.Logger.Warn("WHEEL", "PlayerInventoryGUID inválido ao tentar aplicar snapshot!")
        end
        return
    end

    for vorpItem, data in pairs(Config.WheelItems or {}) do
        local desired = tonumber(snapshot[vorpItem] or 0) or 0
        local applied = tonumber(self.appliedCounts[vorpItem] or 0) or 0
        local diff = desired - applied
        local itemHash = SafeHash(data.nativeName)

        if diff > 0 then
            self:AddItem(itemHash, diff, data.slot)
        elseif diff < 0 then
            self:RemoveItem(itemHash, math.abs(diff), data.slot)
        end

        self.appliedCounts[vorpItem] = desired
    end

    self.isInitialized = true
end

---Limpa todos os itens gerenciados da Satchel C++ (usado no stop ou reconnect)
---Protegido contra congelamento de thread com limite máximo de 10 tentativas por item
function NativeMirror:ClearSatchel()
    for vorpItem, data in pairs(Config.WheelItems or {}) do
        local itemHash = SafeHash(data.nativeName)
        local attempts = 0
        
        while attempts < 10 do
            local _, isValid = self:GetExistingItemGuid(itemHash, data.slot)
            if not isValid then break end

            local removed = Citizen.InvokeNative(
                0x3E4E811480B3AE79,
                1,
                BufferPool.GetGuid1():Buffer(),
                1,
                HASH_REMOVE_REASON
            )
            if not removed then break end
            
            attempts = attempts + 1
        end

        self.appliedCounts[vorpItem] = 0
    end
end
