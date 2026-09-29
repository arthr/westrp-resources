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
            fullname = string.format("%s %s", char.firstname or "", char.lastname or ""):gsub("^%s*(.-)%s*$", "%1"),
            job = char.job or "unemployed",
            jobGrade = tonumber(char.jobGrade) or 0,
            jobLabel = char.jobLabel or char.job or "Desempregado",
            group = effectiveGroup,
            money = tonumber(char.money) or 0.0,
            gold = tonumber(char.gold) or 0.0,
            rol = tonumber(char.rol) or 0.0,
            isDead = char.isdead == true,
            isLoggedIn = true,
            raw = char
        }
    end

    ---Sincroniza o estado do jogador nos StateBags nativos do CitizenFX (Replicado para o client a 0.00ms)
    ---@param source number
    ---@return boolean
    function WestRP.Shared.Bridge.Player.SyncStateBag(source)
        if not source then return false end

        local playerState = Player(source).state
        if not playerState then return false end

        local char = WestRP.Shared.Bridge.Player.GetCharacter(source)
        if char then
            playerState:set('westrp:char', {
                identifier = char.identifier,
                charid = char.charid,
                firstname = char.firstname,
                lastname = char.lastname,
                fullname = char.fullname,
                job = char.job,
                jobGrade = char.jobGrade,
                jobLabel = char.jobLabel,
                group = char.group,
                money = char.money,
                gold = char.gold,
                rol = char.rol,
                isDead = char.isDead,
                isLoggedIn = true
            }, true)

            playerState:set('isLoggedIn', true, true)
            playerState:set('isDead', char.isDead, true)
            return true
        else
            playerState:set('westrp:char', nil, true)
            playerState:set('isLoggedIn', false, true)
            return false
        end
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

    ---Adiciona dinheiro/moeda ao personagem e sincroniza StateBag reativa
    ---@param source number
    ---@param currencyType "cash"|"gold"|"rol"|number
    ---@param amount number
    ---@return boolean
    function WestRP.Shared.Bridge.Player.AddMoney(source, currencyType, amount)
        local core = GetVorpCore()
        local numAmount = tonumber(amount)
        if not core or not numAmount or numAmount <= 0 then return false end

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

        char.addCurrency(cType, numAmount)
        WestRP.Shared.Bridge.Player.SyncStateBag(source)
        WestRP.Shared.Logger.Debug("BRIDGE", "Adicionado %s de moeda (%s) para source %s", numAmount, currencyType, source)
        return true
    end

    ---Remove dinheiro/moeda do personagem caso tenha saldo suficiente e sincroniza StateBag
    ---@param source number
    ---@param currencyType "cash"|"gold"|"rol"|number
    ---@param amount number
    ---@return boolean
    function WestRP.Shared.Bridge.Player.RemoveMoney(source, currencyType, amount)
        local core = GetVorpCore()
        local numAmount = tonumber(amount)
        if not core or not numAmount or numAmount <= 0 then return false end

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

        if (tonumber(balance) or 0) < numAmount then
            return false
        end

        char.removeCurrency(cType, numAmount)
        WestRP.Shared.Bridge.Player.SyncStateBag(source)
        WestRP.Shared.Logger.Debug("BRIDGE", "Removido %s de moeda (%s) de source %s", numAmount, currencyType, source)
        return true
    end

    ---Define o saldo exato de moeda do personagem e sincroniza StateBag
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
        local currentBalance = tonumber(char.money) or 0.0
        if currencyType == "gold" or currencyType == 1 then
            cType = 1
            currentBalance = tonumber(char.gold) or 0.0
        elseif currencyType == "rol" or currencyType == 2 then
            cType = 2
            currentBalance = tonumber(char.rol) or 0.0
        end

        local delta = targetVal - currentBalance
        if delta > 0 then
            char.addCurrency(cType, delta)
        elseif delta < 0 then
            char.removeCurrency(cType, math.abs(delta))
        end

        WestRP.Shared.Bridge.Player.SyncStateBag(source)
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
        Player(source).state:set('isDead', false, true)
    end

    ---Reanima o jogador caso esteja morto ou incapacitado
    ---@param source number
    function WestRP.Shared.Bridge.Player.Revive(source)
        local core = GetVorpCore()
        if core and core.Player and core.Player.Revive then
            core.Player.Revive(source)
        end
        Player(source).state:set('isDead', false, true)
    end

    ---Executa respawn do jogador
    ---@param source number
    function WestRP.Shared.Bridge.Player.Respawn(source)
        local core = GetVorpCore()
        if core and core.Player and core.Player.Respawn then
            core.Player.Respawn(source)
        end
        Player(source).state:set('isDead', false, true)
    end

    ---Define emprego e graduação do personagem e sincroniza StateBag
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

        WestRP.Shared.Bridge.Player.SyncStateBag(source)
        return true
    end

    ---Define grupo/permissão administrativa do jogador e sincroniza StateBag
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

        WestRP.Shared.Bridge.Player.SyncStateBag(source)
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

    -- ========================================================================
    -- EVENTOS DE SINCRONIZAÇÃO REATIVA DO SERVIDOR
    -- ========================================================================
    AddEventHandler('vorp:SelectedCharacter', function(source, _)
        local src = tonumber(source)
        if not src then return end
        SetTimeout(200, function()
            WestRP.Shared.Bridge.Player.SyncStateBag(src)
            local charData = WestRP.Shared.Bridge.Player.GetCharacter(src)
            WestRP.Shared.Logger.Info("BRIDGE", "Personagem carregado e StateBag sincronizada para source %s", src)
            if charData then
                TriggerClientEvent('westrp:client:playerLoaded', src, charData)
            end
        end)
    end)

    AddEventHandler('playerDropped', function()
        local src = source
        Player(src).state:set('westrp:char', nil, true)
        Player(src).state:set('isLoggedIn', false, true)
    end)

    -- Sincroniza jogadores que já estejam online se o resource reiniciar (Hot Reload)
    CreateThread(function()
        Wait(1000)
        local players = GetPlayers()
        for i = 1, #players do
            local src = tonumber(players[i])
            if src then
                WestRP.Shared.Bridge.Player.SyncStateBag(src)
            end
        end
    end)

else
    -- ========================================================================
    -- CLIENT SIDE API (Leitura Instantânea em Memória via StateBags a 0.00ms)
    -- ========================================================================

    ---Retorna os dados completos do personagem atual a partir da StateBag local (0.00ms)
    ---@return table
    function WestRP.Shared.Bridge.Player.GetPlayerData()
        return LocalPlayer.state['westrp:char'] or {}
    end

    ---Verifica se o personagem atual está devidamente carregado e autenticado
    ---@return boolean
    function WestRP.Shared.Bridge.Player.IsLoggedIn()
        local char = LocalPlayer.state['westrp:char']
        return (char ~= nil and char.isLoggedIn == true) or (LocalPlayer.state.isLoggedIn == true)
    end

    ---Retorna o emprego e a graduação atual do personagem local (0.00ms)
    ---@return string job, number grade, string label
    function WestRP.Shared.Bridge.Player.GetJob()
        local char = LocalPlayer.state['westrp:char']
        if not char then return "unemployed", 0, "Desempregado" end
        return char.job or "unemployed", char.jobGrade or 0, char.jobLabel or char.job or "Desempregado"
    end

    ---Retorna o grupo de permissão do jogador local (0.00ms)
    ---@return string
    function WestRP.Shared.Bridge.Player.GetGroup()
        local char = LocalPlayer.state['westrp:char']
        return char and char.group or "user"
    end

    ---Retorna o saldo de moeda do personagem local sem requisição de rede (0.00ms)
    ---@param currencyType? "cash"|"gold"|"rol"|number
    ---@return number
    function WestRP.Shared.Bridge.Player.GetMoney(currencyType)
        local char = LocalPlayer.state['westrp:char']
        if not char then return 0.0 end

        if currencyType == "gold" or currencyType == 1 then
            return tonumber(char.gold) or 0.0
        elseif currencyType == "rol" or currencyType == 2 then
            return tonumber(char.rol) or 0.0
        end

        return tonumber(char.money) or 0.0
    end

    ---Verifica se o jogador local está morto
    ---@return boolean
    function WestRP.Shared.Bridge.Player.IsDead()
        local char = LocalPlayer.state['westrp:char']
        if char and char.isDead ~= nil then
            return char.isDead == true
        end
        return LocalPlayer.state.isDead == true or IsEntityDead(PlayerPedId())
    end

    ---Exibe notificação na tela do cliente
    ---@param text string
    ---@param duration? number
    function WestRP.Shared.Bridge.Player.Notify(text, duration)
        TriggerEvent('vorp:Tip', text, duration or 4000)
    end

    ---Registra um callback a ser disparado assim que o personagem for carregado
    ---@param cb fun(playerData: table)
    function WestRP.Shared.Bridge.Player.OnPlayerLoaded(cb)
        if not cb then return end
        if WestRP.Shared.Bridge.Player.IsLoggedIn() then
            cb(WestRP.Shared.Bridge.Player.GetPlayerData())
            return
        end

        local handler
        handler = AddStateBagChangeHandler('westrp:char', nil, function(bagName, _, value)
            if bagName == ('player:%s'):format(GetPlayerServerId(PlayerId())) and value and value.isLoggedIn then
                RemoveStateBagChangeHandler(handler)
                cb(value)
            end
        end)
    end

    RegisterNetEvent('westrp:client:playerLoaded', function(playerData)
        WestRP.Shared.Logger.Info("BRIDGE", "Personagem autenticado: %s (Job: %s)", playerData and playerData.fullname or "Desconhecido", playerData and playerData.job or "none")
    end)
end

