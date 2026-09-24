-- ====================================================================
-- WestRP Karma — Infrastructure: DatabaseAdapter (Unit of Work)
-- File: server/infrastructure/database_adapter.lua
-- ====================================================================

---@class DatabaseAdapter
---@field private entities table<integer, KarmaEntity> Chave: charIdentifier
---@field private sourceToChar table<integer, integer> Chave: source, Valor: charIdentifier
DatabaseAdapter = {
    entities = {},
    sourceToChar = {}
}

---Carrega ou inicializa a entidade moral de um personagem a partir do banco de dados
---@param charIdentifier integer
---@param source integer
---@return KarmaEntity
function DatabaseAdapter.Load(charIdentifier, source)
    -- Verifica se já está em memória
    if DatabaseAdapter.entities[charIdentifier] then
        local entity = DatabaseAdapter.entities[charIdentifier]
        entity:UpdateSource(source)
        DatabaseAdapter.sourceToChar[source] = charIdentifier
        return entity
    end

    local query = 'SELECT `karma`, `bounty_price` FROM `characters` WHERE `charidentifier` = ? LIMIT 1'
    local result = MySQL.query.await(query, { charIdentifier })

    local initialKarma = Config.DefaultKarma
    local initialBounty = 0.00

    if result and result[1] then
        initialKarma = result[1].karma or Config.DefaultKarma
        initialBounty = tonumber(result[1].bounty_price) or 0.00
    end

    local entity = KarmaEntity.New(charIdentifier, source, initialKarma, initialBounty)
    DatabaseAdapter.entities[charIdentifier] = entity
    DatabaseAdapter.sourceToChar[source] = charIdentifier

    if Config.Debug then
        print(string.format("[westrp_karma] Personagem %d carregado: Karma=%d, Tier=%s", charIdentifier, entity.karma, entity.tier.name))
    end

    return entity
end

---Recupera a entidade ativa pela sessão de rede (source)
---@param source integer
---@return KarmaEntity?
function DatabaseAdapter.GetBySource(source)
    local charIdentifier = DatabaseAdapter.sourceToChar[source]
    if not charIdentifier then return nil end
    return DatabaseAdapter.entities[charIdentifier]
end

---Remove o mapeamento de sessão quando o jogador desconecta e força persistência imediata
---@param source integer
function DatabaseAdapter.Unload(source)
    local charIdentifier = DatabaseAdapter.sourceToChar[source]
    if not charIdentifier then return end

    local entity = DatabaseAdapter.entities[charIdentifier]
    if entity and entity.isDirty then
        local updateQuery = 'UPDATE `characters` SET `karma` = ?, `karma_tier` = ?, `bounty_price` = ? WHERE `charidentifier` = ?'
        MySQL.update.await(updateQuery, { entity.karma, entity.tier.id, entity.bountyPrice, entity.charIdentifier })
        entity:MarkClean()
    end

    DatabaseAdapter.sourceToChar[source] = nil
    -- Mantém a entidade em cache temporário ou descarta
    DatabaseAdapter.entities[charIdentifier] = nil
end

---Consolida todas as entidades marcadas como 'dirty' em uma única transação no MySQL
function DatabaseAdapter.FlushSync()
    local dirtyQueries = {}
    local dirtyEntities = {}

    for _, entity in pairs(DatabaseAdapter.entities) do
        if entity.isDirty then
            table.insert(dirtyQueries, {
                query = 'UPDATE `characters` SET `karma` = ?, `karma_tier` = ?, `bounty_price` = ? WHERE `charidentifier` = ?',
                values = { entity.karma, entity.tier.id, entity.bountyPrice, entity.charIdentifier }
            })
            table.insert(dirtyEntities, entity)
        end
    end

    if #dirtyQueries > 0 then
        local success = MySQL.transaction.await(dirtyQueries)
        if success then
            for _, entity in ipairs(dirtyEntities) do
                entity:MarkClean()
            end
            if Config.Debug then
                print(string.format("[westrp_karma] Batch Write: %d entidades consolidadas no banco de dados.", #dirtyQueries))
            end
        else
            print("^1[westrp_karma] ERRO: Falha ao executar transação em lote no oxmysql!^0")
        end
    end
end

---Thread periódica para consolidação em lote (Batching)
CreateThread(function()
    while true do
        Wait(Config.BatchInterval or 60000)
        DatabaseAdapter.FlushSync()
        SelfDefensePool.PurgeExpired()
    end
end)
