-- ====================================================================
-- WestRP Karma — Database Migration Schema
-- Resource: westrp_karma
-- Framework: VORP Core (tabela: characters)
-- ====================================================================

-- Adiciona as colunas necessárias na tabela characters caso não existam
ALTER TABLE `characters` 
ADD COLUMN IF NOT EXISTS `karma` INT NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS `karma_tier` VARCHAR(32) NOT NULL DEFAULT 'neutral',
ADD COLUMN IF NOT EXISTS `bounty_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00;

-- Cria índice composto para leitura rápida de integridade e consultas em lote
SET @exist := (SELECT COUNT(*) FROM information_schema.statistics 
               WHERE table_schema = DATABASE() 
               AND table_name = 'characters' 
               AND index_name = 'idx_character_karma');
SET @sqlstmt := IF(@exist = 0, 'CREATE INDEX `idx_character_karma` ON `characters` (`charidentifier`, `karma`)', 'SELECT 1');
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
