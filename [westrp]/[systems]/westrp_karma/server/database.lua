-- ====================================================================
-- WestRP Karma — Server: Database & Unit of Work Layer
-- File: server/database.lua
-- ====================================================================

---@class Database
Database = {}

---@type table<integer, CharacterKarmaData> Cache indexado por source (SessionID)
local cacheBySource = {}

---@type table<integer, CharacterKarmaData> Cache indexado por charIdentifier
local cacheByCharId = {}

---Auto-migração segura executada na inicialização do servidor
local function RunAutoMigration()
    local checkQuery = [[
        SELECT COUNT(*) as count 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
          AND TABLE_NAME = 'characters' 
          AND COLUMN_NAME = 'karma'
    ]]
    
    MySQL.query(checkQuery, {}, function(result)
        local count = result and result[1] and result[1].count or 0
        if count == 0 then
            WestRP.Shared.Logger.Info("KARMA:DB", "Coluna 'karma' não encontrada em 'characters'. Criando automaticamente...")
            local alterQuery = [[
                ALTER TABLE characters 
                ADD COLUMN karma INT NOT NULL DEFAULT 0 
                COMMENT 'Pontuação moral dinâmica do personagem [-1000 a +1000]'
            ]]
            MySQL.query(alterQuery, {}, function()
                WestRP.Shared.Logger.Info("KARMA:DB", "Auto-migração concluída com sucesso: Coluna 'karma' adicionada.")
            end)
        else
            if Config.Debug then
                WestRP.Shared.Logger.Info("KARMA:DB", "Esquema do banco validado: Coluna 'characters.karma' operacional.")
            end
        end
    end)
end

CreateThread(function()
    Wait(500)
    RunAutoMigration()
end)

---Carrega ou inicializa os dados de moralidade de um personagem
---@param charIdentifier integer Identificador único do personagem no banco
---@param source integer Session ID do jogador
---@return CharacterKarmaData
function Database.Load(charIdentifier, source)
    if cacheByCharId[charIdentifier] then
        local entry = cacheByCharId[charIdentifier]
        entry.source = source
        cacheBySource[source] = entry
        return entry
    end

    local rawKarma = MySQL.scalar.await('SELECT karma FROM characters WHERE charidentifier = ?', { charIdentifier })
    local karmaValue = tonumber(rawKarma) or Config.DefaultKarma

    ---@type CharacterKarmaData
    local entity = {
        charIdentifier = charIdentifier,
        source = source,
        karma = karmaValue,
        tier = TierEvaluator.Resolve(karmaValue),
        isDirty = false,
        lastSaved = GetGameTimer()
    }

    cacheBySource[source] = entity
    cacheByCharId[charIdentifier] = entity

    return entity
end

---Obtém os dados morais do jogador a partir de seu Session ID
---@param source integer
---@return CharacterKarmaData?
function Database.GetBySource(source)
    return cacheBySource[source]
end

---Descarrega o jogador da memória após salvar alterações pendentes
---@param source integer
function Database.Unload(source)
    local entity = cacheBySource[source]
    if not entity then return end

    if entity.isDirty then
        local charId = entity.charIdentifier
        local karmaVal = entity.karma
        entity.isDirty = false
        MySQL.update('UPDATE characters SET karma = ? WHERE charidentifier = ?', {
            karmaVal,
            charId
        })
    end

    cacheBySource[source] = nil
    cacheByCharId[entity.charIdentifier] = nil
end

---Salva imediatamente todas as entidades alteradas (Unit of Work síncrono para shutdown)
function Database.FlushSync()
    for _, entity in pairs(cacheByCharId) do
        if entity.isDirty then
            MySQL.update.await('UPDATE characters SET karma = ? WHERE charidentifier = ?', {
                entity.karma,
                entity.charIdentifier
            })
            entity.isDirty = false
        end
    end
end

-- Thread periódica de consolidação em lote (Unit of Work a cada 60s)
CreateThread(function()
    while true do
        Wait(60000)
        for _, entity in pairs(cacheByCharId) do
            if entity.isDirty then
                MySQL.update('UPDATE characters SET karma = ? WHERE charidentifier = ?', {
                    entity.karma,
                    entity.charIdentifier
                })
                entity.isDirty = false
                entity.lastSaved = GetGameTimer()
            end
        end
    end
end)
