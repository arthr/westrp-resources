WestRP = WestRP or {}
WestRP.Admin = WestRP.Admin or {}
WestRP.Admin.Permissions = {}

---Retorna a tabela de configuração de um cargo
---@param role string
---@return table|nil
function WestRP.Admin.Permissions.GetRoleConfig(role)
    if not role or type(role) ~= "string" then return nil end
    local cleanRole = string.lower(role)
    return Config.Roles[cleanRole]
end

---Verifica se um determinado cargo possui permissão para executar uma ação
---@param role string
---@param action string
---@return boolean
function WestRP.Admin.Permissions.CanRoleExecute(role, action)
    if not role or not action then return false end
    local roleData = WestRP.Admin.Permissions.GetRoleConfig(role)
    if not roleData then return false end

    -- Se o cargo possui permissão global
    if roleData.actions and roleData.actions.all then
        return true
    end

    -- Se a ação específica está habilitada
    return roleData.actions and roleData.actions[action] == true
end

---Retorna o peso hierárquico do cargo para proteção contra abuso
---@param role string
---@return number
function WestRP.Admin.Permissions.GetHierarchy(role)
    local roleData = WestRP.Admin.Permissions.GetRoleConfig(role)
    if not roleData then return 0 end
    return roleData.hierarchy or 0
end

---Valida se o operador tem nível hierárquico superior ao alvo para aplicar punição
---@param operatorRole string
---@param targetRole string
---@return boolean
function WestRP.Admin.Permissions.CanTargetPlayer(operatorRole, targetRole)
    local opHierarchy = WestRP.Admin.Permissions.GetHierarchy(operatorRole)
    local targetHierarchy = WestRP.Admin.Permissions.GetHierarchy(targetRole)

    -- Se o alvo for usuário comum, qualquer staff autorizado pode agir
    if targetHierarchy == 0 then
        return true
    end

    -- Um staff só pode punir outro staff se tiver hierarquia ESTRITAMENTE maior
    return opHierarchy > targetHierarchy
end
