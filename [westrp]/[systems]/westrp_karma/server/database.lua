-- ====================================================================
-- WestRP Karma — Server: Database & Unit of Work (oxmysql)
-- Arquivo: server/database.lua
-- ====================================================================

---@class KarmaData
---@field charIdentifier integer Identificador imutável do personagem
---@field source integer ID da sessão de rede ativa do jogador
---@field karma integer Pontuação numérica atual [-1000, 1000]
---@field tier KarmaTier Objeto do patamar moral atual
---@field bountyPrice number Valor da recompensa
---@field isDirty boolean Flag de pendência para gravação em disco

---@class Database
Database = {
    entities = {},     ---@type table<integer, KarmaData> [charIdentifier] = entity
    sourceToChar = {}  ---@type table<integer, integer> [source] = charIdentifier
}

-- --------------------------------------------------------------------
-- HELPER DE ENTIDADE MORAL (EM MEMÓRIA)
-- --------------------------------------------------------------------

local function CreateKarmaEntity(charIdentifier, source, initialKarma, bountyPrice)
    local karma = TierEvaluator.Clamp(initialKarma or Config.DefaultKarma)
    local tier = TierEvaluator.Resolve(karma)

    local self = {
        charIdentifier = charIdentifier,
        source = source,
        karma = karma,
        tier = tier,
        bountyPrice = bountyPrice or 0.00,
        isDirty = false
    }

    function self:ApplyDelta(delta)
        if delta == 0 then return false, self.tier end
        local oldTier = self.tier
        self.karma = TierEvaluator.Clamp(self.karma + delta)
        self.tier = TierEvaluator.Resolve(self.karma)
        self.isDirty = true
        return (oldTier.id ~= self.tier.id), oldTier
    end

    function self:SetKarma(newKarma)
        local oldTier = self.tier
        self.karma = TierEvaluator.Clamp(newKarma)
        self.tier = TierEvaluator.Resolve(self.karma)
        self.isDirty = true
        return (oldTier.id ~= self.tier.id), oldTier
    end

    function self:MarkClean()
        self.isDirty = false
    end

    return self
end

-- --------------------------------------------------------------------
-- MIGRAÇÕES AUTOMÁTICAS E IDEMPOTENTES DO BANCO DE DADOS
-- --------------------------------------------------------------------

function Database.RunMigrations()
    CreateThread(function()
        repeat Wait(100) until GetResourceState('oxmysql') == 'started'

        local function ColumnExists(colName)
            local query = [[
                SELECT 1 FROM information_schema.COLUMNS 
                WHERE TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'characters' 
                AND COLUMN_NAME = ? 
                LIMIT 1
            ]]
            local res = MySQL.query.await(query, { colName })
            return res and #res > 0
        end

        local migrationsApplied = 0

        if not ColumnExists('karma') then
            MySQL.query.await('ALTER TABLE `characters` ADD COLUMN `karma` INT NOT NULL DEFAULT 0')
            migrationsApplied = migrationsApplied + 1
        end

        if not ColumnExists('karma_tier') then
            MySQL.query.await('ALTER TABLE `characters` ADD COLUMN `karma_tier` VARCHAR(32) NOT NULL DEFAULT "neutral"')
            migrationsApplied = migrationsApplied + 1
        end

        if not ColumnExists('bounty_price') then
            MySQL.query.await('ALTER TABLE `characters` ADD COLUMN `bounty_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00')
            migrationsApplied = migrationsApplied + 1
        end

        local checkIndexQuery = [[
            SELECT 1 FROM information_schema.STATISTICS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'characters' 
            AND INDEX_NAME = 'idx_character_karma' 
            LIMIT 1
        ]]
        local indexRes = MySQL.query.await(checkIndexQuery)
        if not (indexRes and #indexRes > 0) then
            pcall(function()
                MySQL.query.await('CREATE INDEX `idx_character_karma` ON `characters` (`charidentifier`, `karma`)')
                migrationsApplied = migrationsApplied + 1
            end)
        end

        if migrationsApplied > 0 then
            print(string.format("^2[westrp_karma] Auto-Migration: %d atualizações de schema aplicadas com sucesso na tabela `characters`.^0", migrationsApplied))
        elseif Config.Debug then
            print("^2[westrp_karma] Auto-Migration: Banco de dados íntegro e sincronizado.^0")
        end
    end)
end

Database.RunMigrations()

-- --------------------------------------------------------------------
-- OPERAÇÕES DE CARREGAMENTO E SESSÃO
-- --------------------------------------------------------------------

---Carrega ou inicializa a entidade moral de um personagem
---@param charIdentifier integer
---@param source integer
---@return KarmaData
function Database.Load(charIdentifier, source)
    if Database.entities[charIdentifier] then
        local entity = Database.entities[charIdentifier]
        entity.source = source
        Database.sourceToChar[source] = charIdentifier
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

    local entity = CreateKarmaEntity(charIdentifier, source, initialKarma, initialBounty)
    Database.entities[charIdentifier] = entity
    Database.sourceToChar[source] = charIdentifier

    if Config.Debug then
        print(string.format("[westrp_karma] Personagem %d carregado: Karma=%d, Tier=%s", charIdentifier, entity.karma, entity.tier.name))
    end

    return entity
end

---Obtém a entidade pelo ID da sessão de rede (source)
---@param source integer
---@return KarmaData?
function Database.GetBySource(source)
    local charIdentifier = Database.sourceToChar[source]
    if not charIdentifier then
        local resolvedCharId = Karma.GetCharIdentifier(source)
        if resolvedCharId then
            return Database.Load(resolvedCharId, source)
        end
        return nil
    end
    return Database.entities[charIdentifier]
end

---Descarrega o jogador ao desconectar e persiste dados pendentes
---@param source integer
function Database.Unload(source)
    local charIdentifier = Database.sourceToChar[source]
    if not charIdentifier then return end

    local entity = Database.entities[charIdentifier]
    if entity and entity.isDirty then
        local updateQuery = 'UPDATE `characters` SET `karma` = ?, `karma_tier` = ?, `bounty_price` = ? WHERE `charidentifier` = ?'
        MySQL.update.await(updateQuery, { entity.karma, entity.tier.id, entity.bountyPrice, entity.charIdentifier })
        entity:MarkClean()
    end

    Database.sourceToChar[source] = nil
    Database.entities[charIdentifier] = nil
end

---Consolidação síncrona de todas as entidades marcadas como 'dirty' (Unit of Work)
function Database.FlushSync()
    local dirtyQueries = {}
    local dirtyEntities = {}

    for _, entity in pairs(Database.entities) do
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

-- --------------------------------------------------------------------
-- THREAD PERIÓDICA DE PERSISTÊNCIA EM LOTE
-- --------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(Config.BatchInterval or 60000)
        Database.FlushSync()
    end
end)
