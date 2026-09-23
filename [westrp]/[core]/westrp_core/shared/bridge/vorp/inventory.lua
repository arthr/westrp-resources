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
        local countNum = tonumber(count) or 1
        if not source or not itemName or countNum <= 0 then return false end

        local okCarry, canCarry = pcall(function()
            return exports['vorp_inventory']:canCarryItem(source, tostring(itemName), countNum)
        end)
        if not okCarry or canCarry == false then
            return false
        end

        local okAdd, result = pcall(function()
            return exports['vorp_inventory']:addItem(source, tostring(itemName), countNum, metadata or {})
        end)

        return okAdd and (result ~= false)
    end

    ---Remove um item do inventário do jogador
    ---@param source number
    ---@param itemName string
    ---@param count number
    ---@param metadata? table
    ---@return boolean
    function WestRP.Shared.Bridge.Inventory.RemoveItem(source, itemName, count, metadata)
        local countNum = tonumber(count) or 1
        if not source or not itemName or countNum <= 0 then return false end

        local currentCount = WestRP.Shared.Bridge.Inventory.GetItemCount(source, itemName)
        if currentCount < countNum then
            return false
        end

        local okSub = pcall(function()
            exports['vorp_inventory']:subItem(source, tostring(itemName), countNum, metadata or {})
        end)
        return okSub == true
    end

    ---Retorna a quantidade de um item no inventário
    ---@param source number
    ---@param itemName string
    ---@return number
    function WestRP.Shared.Bridge.Inventory.GetItemCount(source, itemName)
        if not source or not itemName then return 0 end
        local ok, count = pcall(function()
            return exports['vorp_inventory']:getItemCount(source, tostring(itemName))
        end)
        return ok and (tonumber(count) or 0) or 0
    end

    ---Verifica se o jogador tem espaço para carregar a quantidade do item
    ---@param source number
    ---@param itemName string
    ---@param count number
    ---@return boolean
    function WestRP.Shared.Bridge.Inventory.CanCarryItem(source, itemName, count)
        local countNum = tonumber(count) or 1
        if not source or not itemName or countNum <= 0 then return false end

        local okCarry, canCarry = pcall(function()
            return exports['vorp_inventory']:canCarryItem(source, tostring(itemName), countNum)
        end)
        return okCarry and (canCarry == true)
    end

    ---Concede arma ao jogador via API de inventário
    ---@param source number
    ---@param weaponName string
    ---@return boolean
    function WestRP.Shared.Bridge.Inventory.GiveWeapon(source, weaponName)
        if not source or not weaponName then return false end

        local okCarry, canCarry = pcall(function()
            return exports['vorp_inventory']:canCarryWeapons(source, 1, nil, tostring(weaponName))
        end)
        if okCarry and canCarry == false then
            return false
        end

        local okCreate = pcall(function()
            exports['vorp_inventory']:createWeapon(source, tostring(string.upper(weaponName)))
        end)
        return okCreate == true
    end

    ---Limpa completamente o inventário de itens e armas do jogador
    ---@param source number
    ---@return boolean
    function WestRP.Shared.Bridge.Inventory.ClearInventory(source)
        if not source then return false end
        local ok = pcall(function()
            exports['vorp_inventory']:subAllItems(source)
            exports['vorp_inventory']:subAllWeapons(source)
        end)
        return ok == true
    end
end
