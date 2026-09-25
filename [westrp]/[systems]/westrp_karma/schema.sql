-- ====================================================================
-- WestRP Karma — Database Schema & Auto-Migration
-- File: schema.sql
-- ====================================================================

-- Adiciona a coluna 'karma' na tabela 'characters' se ainda não existir
SET @dbname = DATABASE();
SET @tablename = "characters";
SET @columnname = "karma";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 1",
  "ALTER TABLE characters ADD COLUMN karma INT NOT NULL DEFAULT 0 COMMENT 'Pontuação moral dinâmica do personagem [-1000 a +1000]';"
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;
