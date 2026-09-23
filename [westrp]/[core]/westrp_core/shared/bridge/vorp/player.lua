WestRP = WestRP or {}
WestRP.Shared = WestRP.Shared or {}
WestRP.Shared.Bridge = WestRP.Shared.Bridge or {}
WestRP.Shared.Bridge.Player = {}

local isServer = IsDuplicityVersion()

if isServer then
    local VorpCore = nil

    local function GetVorpCore()
        if not VorpCore then
            local ok, core = pcall(function()
                return exports['vorp_core']:GetCore()
            end)
            if ok and core then
                VorpCore = core
            else
                WestRP.Shared.Logger.Error("BRIDGE", "Falha ao conectar com exports['vorp_core']:GetCore()")
            end
        end
        return VorpCore
    end

    ---Retorna os dados unificados do personagem do jogador
    ---@param source number
    ---@return table|nil
    function WestRP.Shared.Bridge.Player.GetCharacter(source)
        local core = GetVorpCore()
        if not core then return nil end

        local user = core.getUser(source)
        if not user then return nil end

        local char = user.getUsedCharacter
        if not char then return nil end

        return {
            source = source,
            identifier = char.identifier,
            charid = char.charIdentifier,
            firstname = char.firstname or "Sem Nome",
            lastname = char.lastname or "",
            job = char.job or "unemployed",
            jobGrade = char.jobGrade or 0,
            group = char.group or "user",
            money = char.money or 0.0,
            gold = char.gold or 0.0,
            rol = char.rol or 0.0,
            raw = char
        }
    end

    ---Adiciona dinheiro/moeda ao personagem
    ---@param source number
    ---@param currencyType "cash"|"gold"|"rol"|number
    ---@param amount number
    ---@return boolean
    function WestRP.Shared.Bridge.Player.AddMoney(source, currencyType, amount)
        local core = GetVorpCore()
        if not core or not amount or amount <= 0 then return false end

        local user = core.getUser(source)
        if not user then return false end

        local char = user.getUsedCharacter
        if not char then return false end

        local cType = 0
        if currencyType == "gold" or currencyType == 1 then
            cType = 1
        elseif currencyType == "rol" or currencyType == 2 then
            cType = 2
        end

        char.addCurrency(cType, amount)
        WestRP.Shared.Logger.Debug("BRIDGE", "Adicionado %s de moeda (%s) para source %s", amount, currencyType, source)
        return true
    end

    ---Remove dinheiro/moeda do personagem caso tenha saldo suficiente
    ---@param source number
    ---@param currencyType "cash"|"gold"|"rol"|number
    ---@param amount number
    ---@return boolean
    function WestRP.Shared.Bridge.Player.RemoveMoney(source, currencyType, amount)
        local core = GetVorpCore()
        if not core or not amount or amount <= 0 then return false end

        local user = core.getUser(source)
        if not user then return false end

        local char = user.getUsedCharacter
        if not char then return false end

        local cType = 0
        local balance = char.money
        if currencyType == "gold" or currencyType == 1 then
            cType = 1
            balance = char.gold
        elseif currencyType == "rol" or currencyType == 2 then
            cType = 2
            balance = char.rol
        end

        if balance < amount then
            return false
        end

        char.removeCurrency(cType, amount)
        WestRP.Shared.Logger.Debug("BRIDGE", "Removido %s de moeda (%s) de source %s", amount, currencyType, source)
        return true
    end

    ---Envia notificação nativa ao jogador a partir do servidor
    ---@param source number
    ---@param text string
    ---@param duration? number
    function WestRP.Shared.Bridge.Player.Notify(source, text, duration)
        local core = GetVorpCore()
        if core and core.NotifyTip then
            core.NotifyTip(source, text, duration or 4000)
        else
            TriggerClientEvent('vorp:Tip', source, text, duration or 4000)
        end
    end

else
    ---Exibe notificação no client
    ---@param text string
    ---@param duration? number
    function WestRP.Shared.Bridge.Player.Notify(text, duration)
        TriggerEvent('vorp:Tip', text, duration or 4000)
    end
end
