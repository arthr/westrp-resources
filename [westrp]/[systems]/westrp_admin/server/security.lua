WestRP = WestRP or {}
WestRP.Server = WestRP.Server or {}
WestRP.Server.Admin = WestRP.Server.Admin or {}
WestRP.Server.Admin.Security = {}

local VorpCore = nil
local function GetVorpCore()
    if not VorpCore then
        pcall(function()
            VorpCore = exports['vorp_core']:GetCore()
        end)
    end
    return VorpCore
end

---Obtém o cargo administrativo ativo do jogador (a partir do personagem ou da conta)
---@param source number
---@return string
function WestRP.Server.Admin.Security.GetPlayerRole(source)
    if not source or source <= 0 then return "user" end

    -- 1. Verifica permissão ACE nativa
    if IsPlayerAceAllowed(tostring(source), "command") or IsPlayerAceAllowed(tostring(source), "westrp.admin") then
        return "root"
    end

    -- 2. Verifica grupo do personagem via Bridge do WestRP
    local char = WestRP.Shared.Bridge.Player.GetCharacter(source)
    if char and char.group and Config.Roles[string.lower(char.group)] then
        return string.lower(char.group)
    end

    -- 3. Fallback no VORP Core direto
    local core = GetVorpCore()
    if core then
        local user = core.getUser(source)
        if user then
            local uGroup = user.getGroup
            if uGroup and Config.Roles[string.lower(uGroup)] then
                return string.lower(uGroup)
            end
        end
    end

    return "user"
end

---Middleware de segurança Zero-Trust para validar se a ação pode ser executada
---@param source number Operador
---@param action string Nome da ação pretendida
---@param targetSource? number Jogador alvo (se houver)
---@return boolean autorizado
function WestRP.Server.Admin.Security.CanExecute(source, action, targetSource)
    if not source or not action then return false end

    -- Rate Limit anti-spam (máximo 1 comando a cada 400ms por padrão)
    if not WestRP.Server.Security.CheckRateLimit(source, "admin_" .. action, 400) then
        WestRP.Shared.Bridge.Player.Notify(source, "Aguarde um instante antes de executar outra ação", 3000)
        return false
    end

    local operatorRole = WestRP.Server.Admin.Security.GetPlayerRole(source)
    if not WestRP.Admin.Permissions.CanRoleExecute(operatorRole, action) then
        WestRP.Shared.Logger.Warn("ADMIN_SECURITY", "Jogador %s (Cargo: %s) tentou ação não autorizada: '%s'", source, operatorRole, action)
        WestRP.Shared.Bridge.Player.Notify(source, "Você não tem permissão para esta ação!", 4000)
        return false
    end

    -- Validação de hierarquia sobre o alvo
    if targetSource and targetSource > 0 and targetSource ~= source then
        local targetRole = WestRP.Server.Admin.Security.GetPlayerRole(targetSource)
        if not WestRP.Admin.Permissions.CanTargetPlayer(operatorRole, targetRole) then
            WestRP.Shared.Logger.Warn("ADMIN_SECURITY", "Jogador %s tentou agir sobre staff de hierarquia superior ou igual (%s)", source, targetSource)
            WestRP.Shared.Bridge.Player.Notify(source, "Você não pode executar esta ação em um membro da staff de cargo igual ou superior!", 5000)
            return false
        end
    end

    return true
end
