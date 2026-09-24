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

    ---Retorna o grupo ativo do jogador (prioriza grupo da conta user.getGroup e fallback em char.group)
    ---@param source number
    ---@return string
    function WestRP.Shared.Bridge.Player.GetGroup(source)
        local core = GetVorpCore()
        if not core then return "user" end

        local user = core.getUser(source)
        if not user then return "user" end

        local userGroup = user.getGroup
        if userGroup and userGroup ~= "" and userGroup ~= "user" then
            return tostring(userGroup)
        end

        local char = user.getUsedCharacter
        if char and char.group and char.group ~= "" and char.group ~= "user" then
            return tostring(char.group)
        end

        return (userGroup and userGroup ~= "") and tostring(userGroup) or ((char and char.group) and tostring(char.group) or "user")
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

        local userGroup = user.getGroup
        local charGroup = char.group or "user"
        local effectiveGroup = (userGroup and userGroup ~= "" and userGroup ~= "user") and userGroup or charGroup

        return {
            source = source,
            identifier = char.identifier,
            charid = char.charIdentifier,
            firstname = char.firstname or "Sem Nome",
            lastname = char.lastname or "",
            job = char.job or "unemployed",
            jobGrade = char.jobGrade or 0,
            group = effectiveGroup,
            money = char.money or 0.0,
            gold = char.gold or 0.0,
            rol = char.rol or 0.0,
            isDead = char.isdead == true,
            raw = char
        }
    end

    ---Verifica se o jogador está morto
    ---@param source number
    ---@return boolean
    function WestRP.Shared.Bridge.Player.IsDead(source)
        local core = GetVorpCore()
        if core then
            local user = core.getUser(source)
            if user and user.getUsedCharacter then
                return user.getUsedCharacter.isdead == true
            end
        end
        return Player(source).state.isDead == true
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

    ---Define o saldo exato de moeda do personagem
    ---@param source number
    ---@param currencyType "cash"|"gold"|"rol"|number
    ---@param targetAmount number
    ---@return boolean
    function WestRP.Shared.Bridge.Player.SetMoney(source, currencyType, targetAmount)
        local core = GetVorpCore()
        local targetVal = tonumber(targetAmount)
        if not core or not targetVal or targetVal < 0 then return false end

        local user = core.getUser(source)
        if not user then return false end

        local char = user.getUsedCharacter
        if not char then return false end

        local cType = 0
        local currentBalance = char.money or 0.0
        if currencyType == "gold" or currencyType == 1 then
            cType = 1
            currentBalance = char.gold or 0.0
        elseif currencyType == "rol" or currencyType == 2 then
            cType = 2
            currentBalance = char.rol or 0.0
        end

        local delta = targetVal - currentBalance
        if delta > 0 then
            char.addCurrency(cType, delta)
        elseif delta < 0 then
            char.removeCurrency(cType, math.abs(delta))
        end

        WestRP.Shared.Logger.Debug("BRIDGE", "Definido saldo de moeda (%s) para %s em source %s", currencyType, targetVal, source)
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

    ---Restaura vida e estamina do jogador via Core
    ---@param source number
    function WestRP.Shared.Bridge.Player.Heal(source)
        local core = GetVorpCore()
        if core and core.Player and core.Player.Heal then
            core.Player.Heal(source)
        end
    end

    ---Reanima o jogador caso esteja morto ou incapacitado
    ---@param source number
    function WestRP.Shared.Bridge.Player.Revive(source)
        local core = GetVorpCore()
        if core and core.Player and core.Player.Revive then
            core.Player.Revive(source)
        end
    end

    ---Executa respawn do jogador
    ---@param source number
    function WestRP.Shared.Bridge.Player.Respawn(source)
        local core = GetVorpCore()
        if core and core.Player and core.Player.Respawn then
            core.Player.Respawn(source)
        end
    end

    ---Define emprego e graduação do personagem
    ---@param source number
    ---@param job string
    ---@param grade number
    ---@param label? string
    ---@return boolean
    function WestRP.Shared.Bridge.Player.SetJob(source, job, grade, label)
        local core = GetVorpCore()
        if not core then return false end
        local user = core.getUser(source)
        if not user then return false end
        local char = user.getUsedCharacter
        if not char then return false end

        char.setJob(job)
        char.setJobGrade(tonumber(grade) or 0)
        char.setJobLabel(label or job)
        return true
    end

    ---Define grupo/permissão administrativa do jogador
    ---@param source number
    ---@param group string
    ---@return boolean
    function WestRP.Shared.Bridge.Player.SetGroup(source, group)
        local core = GetVorpCore()
        if not core then return false end
        local user = core.getUser(source)
        if not user then return false end
        local char = user.getUsedCharacter
        if char then
            char.setGroup(group)
        end
        user.setGroup(group)
        return true
    end

    ---Adiciona usuário à whitelist
    ---@param identifier string
    function WestRP.Shared.Bridge.Player.WhitelistUser(identifier)
        local core = GetVorpCore()
        if core and core.Whitelist and core.Whitelist.whitelistUser then
            core.Whitelist.whitelistUser(identifier)
        end
    end

    ---Remove usuário da whitelist
    ---@param identifier string
    function WestRP.Shared.Bridge.Player.UnwhitelistUser(identifier)
        local core = GetVorpCore()
        if core and core.Whitelist and core.Whitelist.unWhitelistUser then
            core.Whitelist.unWhitelistUser(identifier)
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
