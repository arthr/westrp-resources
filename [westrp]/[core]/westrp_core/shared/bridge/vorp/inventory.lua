WestRP = WestRP or {}
WestRP.Shared = WestRP.Shared or {}
WestRP.Shared.Bridge = WestRP.Shared.Bridge or {}
WestRP.Shared.Bridge.Inventory = {}

local isServer = IsDuplicityVersion()

if isServer then
    local VorpInv = nil

    local function GetVorpInventory()
        if not VorpInv then
            local ok, inv = pcall(function()
                return exports['vorp_inventory']:vorp_inventoryApi()
            end)
            if ok and inv then
                VorpInv = inv
            else
                WestRP.Shared.Logger.Error("BRIDGE", "Falha ao conectar com exports['vorp_inventory']:vorp_inventoryApi()")
            end
        end
        return VorpInv
    end

    ---Adiciona um item ao inventário do jogador
    ---@param source number
    ---@param itemName string
    ---@param count number
    ---@param metadata? table
    ---@return boolean
    function WestRP.Shared.Bridge.Inventory.AddItem(source, itemName, count, metadata)
        local inv = GetVorpInventory()
        if not inv or not itemName or not count or count <= 0 then return false end

        local p = promise.new()
        TriggerEvent("vorpCore:canCarryItem", source, count, function(canCarry)
            if not canCarry then
                p:resolve(false)
                return
            end
            inv.addItem(source, tostring(itemName), tonumber(count), metadata or {})
            p:resolve(true)
        end, tostring(itemName))

        return Citizen.Await(p)
    end

    ---Remove um item do inventário do jogador
    ---@param source number
    ---@param itemName string
    ---@param count number
    ---@param metadata? table
    ---@return boolean
    function WestRP.Shared.Bridge.Inventory.RemoveItem(source, itemName, count, metadata)
        local inv = GetVorpInventory()
        if not inv or not itemName or not count or count <= 0 then return false end

        local currentCount = WestRP.Shared.Bridge.Inventory.GetItemCount(source, itemName)
        if currentCount < count then
            return false
        end

        inv.subItem(source, tostring(itemName), tonumber(count), metadata)
        return true
    end

    ---Retorna a quantidade de um item no inventário
    ---@param source number
    ---@param itemName string
    ---@return number
    function WestRP.Shared.Bridge.Inventory.GetItemCount(source, itemName)
        local inv = GetVorpInventory()
        if not inv or not itemName then return 0 end

        local item = inv.getItemByName(source, tostring(itemName))
        if item and item.count then
            return tonumber(item.count) or 0
        end
        return 0
    end

    ---Verifica se o jogador tem espaço para carregar a quantidade do item
    ---@param source number
    ---@param itemName string
    ---@param count number
    ---@return boolean
    function WestRP.Shared.Bridge.Inventory.CanCarryItem(source, itemName, count)
        local p = promise.new()
        TriggerEvent("vorpCore:canCarryItem", source, tonumber(count), function(canCarry)
            p:resolve(canCarry == true)
        end, tostring(itemName))
        return Citizen.Await(p)
    end
end
