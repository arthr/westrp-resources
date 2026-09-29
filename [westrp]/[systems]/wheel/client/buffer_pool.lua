--[[
    WestRP Wheel — Buffer Pool (Zero Garbage Collection Architecture)
    
    Evita alocações e instanciações dinâmicas de buffers de memória binária (DataView)
    durante a execução dos ticks nativos da roda e operações de inventário.
    Todas as estruturas C++ utilizam buffers estáticos singleton pré-alocados.
]]

BufferPool = {}

-- Buffers singleton pré-alocados para Zero GC
local Guid1 = DataView.ArrayBuffer(32)
local Guid2 = DataView.ArrayBuffer(32)
local Guid3 = DataView.ArrayBuffer(32)
local PlayerInvGuid = DataView.ArrayBuffer(32)

local SlotParentGuid = DataView.ArrayBuffer(32)
local CurrentSlotId = 0

local ItemInfo = DataView.ArrayBuffer(104)
local UIMessage = DataView.ArrayBuffer(32)

---Limpa os bytes de um buffer de GUID (32 bytes)
---@param buf any
local function ZeroGuid(buf)
    buf:SetInt32(0, 0)
    buf:SetInt32(8, 0)
    buf:SetInt32(16, 0)
    buf:SetInt32(24, 0)
end

---Copia o conteúdo de 32 bytes de um GUID para outro
---@param src any
---@param dest any
function BufferPool.CopyGuid(src, dest)
    dest:SetInt32(0, src:GetInt32(0) or 0)
    dest:SetInt32(8, src:GetInt32(8) or 0)
    dest:SetInt32(16, src:GetInt32(16) or 0)
    dest:SetInt32(24, src:GetInt32(24) or 0)
end

---Retorna o primeiro buffer de GUID estático limpo
---@return any
function BufferPool.GetGuid1()
    ZeroGuid(Guid1)
    return Guid1
end

---Retorna o segundo buffer de GUID estático limpo
---@return any
function BufferPool.GetGuid2()
    ZeroGuid(Guid2)
    return Guid2
end

---Retorna o terceiro buffer de GUID estático limpo
---@return any
function BufferPool.GetGuid3()
    ZeroGuid(Guid3)
    return Guid3
end

---Retorna o buffer estático para o GUID raiz do inventário do jogador
---@return any
function BufferPool.GetPlayerInvGuid()
    return PlayerInvGuid
end

---Define o SlotInfo estático com o GUID parente e o Slot ID
---@param parentGuid any Buffer do GUID parente
---@param slotId number Hash do slot (ex: SLOTID_SATCHEL)
function BufferPool.SetSlot(parentGuid, slotId)
    if parentGuid then
        BufferPool.CopyGuid(parentGuid, SlotParentGuid)
    else
        ZeroGuid(SlotParentGuid)
    end
    CurrentSlotId = tonumber(slotId) or 0
end

---Retorna o buffer do GUID parente do slot atual
---@return any
function BufferPool.GetSlotParentGuid()
    return SlotParentGuid
end

---Retorna o Slot ID configurado
---@return number
function BufferPool.GetSlotId()
    return CurrentSlotId
end

---Retorna o buffer estático de ItemInfo (104 bytes) limpo
---@return any
function BufferPool.GetItemInfo()
    for i = 0, 96, 8 do
        ItemInfo:SetInt32(i, 0)
    end
    return ItemInfo
end

---Retorna o buffer estático de mensagem da UI (32 bytes) limpo
---@return any
function BufferPool.GetUIMessage()
    ZeroGuid(UIMessage)
    return UIMessage
end

---Converte número ou hash para representação hexadecimal segura
---@param v number
---@return string
function BufferPool.ToHex(v)
    if type(v) ~= 'number' then return tostring(v) end
    if v < 0 then v = 0x100000000 + v end
    return string.format('0x%08X', v)
end

---Formata um buffer de GUID em string legível para debug
---@param guid any
---@return string
function BufferPool.GuidToString(guid)
    if not guid then return '[nil-guid]' end
    return string.format(
        '[%s %s %s %s]',
        BufferPool.ToHex(guid:GetInt32(0) or 0),
        BufferPool.ToHex(guid:GetInt32(8) or 0),
        BufferPool.ToHex(guid:GetInt32(16) or 0),
        BufferPool.ToHex(guid:GetInt32(24) or 0)
    )
end
