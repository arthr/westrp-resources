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

    ---Retorna todos os itens do inventário do jogador
    ---@param source number
    ---@return table
    function WestRP.Shared.Bridge.Inventory.GetUserInventory(source)
        if not source then return {} end
        local ok, rawItems = pcall(function()
            return exports['vorp_inventory']:getUserInventoryItems(source)
        end)
        if not ok or type(rawItems) ~= "table" then return {} end

        local formatted = {}
        for _, it in ipairs(rawItems) do
            formatted[#formatted + 1] = {
                id = it.name or it.id,
                uniqueId = it.id,
                name = it.name,
                label = it.label or it.name,
                count = tonumber(it.count) or 1,
                weight = tonumber(it.weight) or 0.1,
                type = it.type or (string.sub(it.name or "", 1, 4) == "ammo" and "Munições" or "Geral"),
                desc = it.desc or "",
                metadata = it.metadata or {}
            }
        end
        return formatted
    end

    ---Retorna todas as armas do inventário do jogador
    ---@param source number
    ---@return table
    function WestRP.Shared.Bridge.Inventory.GetUserWeapons(source)
        if not source then return {} end
        local ok, rawWeapons = pcall(function()
            return exports['vorp_inventory']:getUserInventoryWeapons(source)
        end)
        if not ok or type(rawWeapons) ~= "table" then return {} end

        local formatted = {}
        for _, wp in ipairs(rawWeapons) do
            local ammoTotal = 0
            if type(wp.ammo) == "table" then
                for _, count in pairs(wp.ammo) do
                    ammoTotal = ammoTotal + (tonumber(count) or 0)
                end
            elseif tonumber(wp.ammo) then
                ammoTotal = tonumber(wp.ammo)
            end

            formatted[#formatted + 1] = {
                id = wp.name,
                weaponId = wp.id,
                name = wp.name,
                label = wp.custom_label or wp.label or wp.name,
                serialNumber = wp.serial_number or tostring(wp.id),
                ammo = ammoTotal,
                weight = tonumber(wp.weight) or 1.0,
                desc = wp.custom_desc or wp.desc or ""
            }
        end
        return formatted
    end

    ---Remove/confisca uma arma específica do jogador
    ---@param source number
    ---@param weaponId number
    ---@return boolean
    function WestRP.Shared.Bridge.Inventory.ConfiscateWeapon(source, weaponId)
        local wId = tonumber(weaponId)
        if not source or not wId then return false end
        local ok, result = pcall(function()
            return exports['vorp_inventory']:subWeapon(source, wId)
        end)
        return ok and (result ~= false)
    end
end

