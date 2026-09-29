WestRP = WestRP or {}
WestRP.Server = WestRP.Server or {}
WestRP.Server.Database = {}

---Executa uma query assíncrona com retorno de múltiplas linhas
---@param query string
---@param params? table
---@return table|nil
function WestRP.Server.Database.Query(query, params)
    local ok, result = pcall(function()
        return MySQL.query.await(query, params or {})
    end)
    if not ok then
        WestRP.Shared.Logger.Error("DATABASE", "Erro na query: %s | Params: %s", query, json.encode(params or {}))
        return nil
    end
    return result
end

---Executa uma query com retorno de uma única linha
---@param query string
---@param params? table
---@return table|nil
function WestRP.Server.Database.Single(query, params)
    local ok, result = pcall(function()
        return MySQL.single.await(query, params or {})
    end)
    if not ok then
        WestRP.Shared.Logger.Error("DATABASE", "Erro no single: %s", query)
        return nil
    end
    return result
end

---Executa uma query com retorno de um único valor escalar
---@param query string
---@param params? table
---@return any
function WestRP.Server.Database.Scalar(query, params)
    local ok, result = pcall(function()
        return MySQL.scalar.await(query, params or {})
    end)
    if not ok then
        WestRP.Shared.Logger.Error("DATABASE", "Erro no scalar: %s", query)
        return nil
    end
    return result
end

---Executa inserção e retorna o ID inserido
---@param query string
---@param params? table
---@return number|nil
function WestRP.Server.Database.Insert(query, params)
    local ok, result = pcall(function()
        return MySQL.insert.await(query, params or {})
    end)
    if not ok then
        WestRP.Shared.Logger.Error("DATABASE", "Erro no insert: %s", query)
        return nil
    end
    return result
end

---Executa um update e retorna o número de linhas afetadas
---@param query string
---@param params? table
---@return number
function WestRP.Server.Database.Update(query, params)
    local ok, result = pcall(function()
        return MySQL.update.await(query, params or {})
    end)
    if not ok then
        WestRP.Shared.Logger.Error("DATABASE", "Erro no update: %s", query)
        return 0
    end
    return result or 0
end

---Executa múltiplas queries em uma transação atômica
---@param queries table
---@param params? table
---@return boolean
function WestRP.Server.Database.Transaction(queries, params)
    local ok, result = pcall(function()
        return MySQL.transaction.await(queries, params)
    end)
    if not ok then
        WestRP.Shared.Logger.Error("DATABASE", "Erro na transação!")
        return false
    end
    return result == true
end
