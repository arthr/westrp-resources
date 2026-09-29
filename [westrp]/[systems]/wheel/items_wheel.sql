-- ============================================================================
-- WestRP Framework — Wheel Items Database Migration
-- Tabela: items (VORP Core / RedM)
--
-- ATENÇÃO:
-- 1. NÃO utilize IDs fixos para não colidir com o AUTO_INCREMENT da sua tabela items.
-- 2. Este script utiliza INSERT IGNORE INTO para não sobrescrever itens que você
--    já possui cadastrados no seu servidor (como maçã, pêssego, etc.).
-- ============================================================================

INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `useExpired`, `groupId`, `metadata`, `desc`, `degradation`, `weight`) VALUES
    -- FRUTAS, VEGETAIS & ENLATADOS
    ('consumable_apple', 'Maçã', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Fruta fresca e crocante', 0, 0.25),
    ('consumable_apricots_can', 'Damasco em Lata', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Damascos em conserva', 0, 0.25),
    ('consumable_baked_beans_can', 'Feijão Cozido em Lata', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Feijão cozido em lata', 0, 0.25),
    ('consumable_beets', 'Beterraba', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Beterraba fresca', 0, 0.25),
    ('consumable_carrot', 'Cenoura', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Cenoura crocante', 0, 0.25),
    ('consumable_celery', 'Aipo', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Talo de aipo fresco', 0, 0.25),
    ('consumable_corn', 'Milho', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Espiga de milho', 0, 0.25),
    ('consumable_cornedbeef_can', 'Carne Enlatada', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Carne bovina em lata', 0, 0.25),
    ('consumable_kidneybeans_can', 'Feijão Vermelho em Lata', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Feijões vermelhos cozidos', 0, 0.25),
    ('consumable_peach', 'Pêssego', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Pêssego doce e suculento', 0, 0.25),
    ('consumable_peaches_can', 'Pêssegos em Lata', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Pêssegos em calda', 0, 0.25),
    ('consumable_pear', 'Pera', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Pera fresca', 0, 0.25),
    ('consumable_peas_can', 'Ervilhas em Lata', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Ervilhas tenras em conserva', 0, 0.25),
    ('consumable_pineapples_can', 'Abacaxi em Lata', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Fatias de abacaxi em conserva', 0, 0.25),
    ('consumable_salmon_can', 'Salmão em Lata', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Salmão defumado em conserva', 0, 0.25),
    ('consumable_strawberries_can', 'Morangos em Lata', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Morangos doces em conserva', 0, 0.25),
    ('consumable_sweet_corn_can', 'Milho Doce em Lata', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Milho doce enlatado', 0, 0.25),

    -- PÃES, QUEIJOS & SNACKS
    ('consumable_biscuit_box', 'Caixa de Biscoitos', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Biscoitos crocantes sortidos', 0, 0.25),
    ('consumable_bread_chunk', 'Pedaço de Pão', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Pedaço de pão caseiro', 0, 0.25),
    ('consumable_bread_roll', 'Pãozinho', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Pão fresco redondo', 0, 0.25),
    ('consumable_candy_bag', 'Saco de Doces', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Bolsa cheia de confeitos', 0, 0.25),
    ('consumable_cheese_wedge', 'Fatia de Queijo', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Pedaço de queijo curado', 0, 0.25),
    ('consumable_chocolate_bar', 'Barra de Chocolate', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Barra de chocolate rica em cacau', 0, 0.25),
    ('consumable_crackers', 'Biscoitos Salgados', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Bolachas salgadas secas', 0, 0.25),
    ('consumable_jerky', 'Carne Seca Bovina', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Tiras de carne bovina curada', 0, 0.25),
    ('consumable_jerky_venison', 'Carne Seca de Cervo', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de cervo seca e temperada', 0, 0.25),
    ('consumable_oat_cakes', 'Bolos de Aveia', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Bolos nutritivos de aveia', 0, 0.25),
    ('consumable_offal', 'Miúdos Salgados', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Miúdos variados curados no sal', 0, 0.25),
    ('consumable_peppermint', 'Bala de Hortelã', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Bala refrescante de hortelã', 0, 0.25),
    ('consumable_sugarcube', 'Cubo de Açúcar', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Cubo de açúcar puro', 0, 0.25),

    -- CARNES E PEIXES COZIDOS COM ERVAS
    ('consumable_big_game_meat_oregano_cooked', 'Carne de Caça Grande com Orégano', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de caça grande temperada com orégano', 0, 0.25),
    ('consumable_big_game_meat_thyme_cooked', 'Carne de Caça Grande com Tomilho', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de caça grande temperada com tomilho', 0, 0.25),
    ('consumable_big_game_meat_wild_mint_cooked', 'Carne de Caça Grande com Menta', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de caça grande temperada com menta selvagem', 0, 0.25),
    ('consumable_crustacean_meat_mint_cooked', 'Carne de Crustáceo com Menta', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de crustáceo cozida com menta', 0, 0.25),
    ('consumable_crustacean_meat_oregano_cooked', 'Carne de Crustáceo com Orégano', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de crustáceo temperada com orégano', 0, 0.25),
    ('consumable_crustacean_meat_thyme_cooked', 'Carne de Crustáceo com Tomilho', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de crustáceo temperada com tomilho', 0, 0.25),
    ('consumable_exotic_bird_oregano_cooked', 'Ave Exótica com Orégano', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de ave exótica assada com orégano', 0, 0.25),
    ('consumable_exotic_bird_thyme_cooked', 'Ave Exótica com Tomilho', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de ave exótica temperada com tomilho', 0, 0.25),
    ('consumable_exotic_bird_wild_mint_cooked', 'Ave Exótica com Menta Selvagem', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de ave exótica com menta fresca', 0, 0.25),
    ('consumable_flakey_fish_oregano_cooked', 'Peixe Suave com Orégano', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Filé de peixe tenro com orégano', 0, 0.25),
    ('consumable_flakey_fish_thyme_cooked', 'Peixe Suave com Tomilho', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Filé de peixe tenro com tomilho', 0, 0.25),
    ('consumable_flakey_fish_wild_mint_cooked', 'Peixe Suave com Menta', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Filé de peixe temperado com menta selvagem', 0, 0.25),
    ('consumable_game_meat_oregano_cooked', 'Carne de Caça com Orégano', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de caça cozida com orégano', 0, 0.25),
    ('consumable_game_meat_thyme_cooked', 'Carne de Caça com Tomilho', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de caça assada com tomilho', 0, 0.25),
    ('consumable_game_meat_wild_mint_cooked', 'Carne de Caça com Menta', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de caça temperada com menta', 0, 0.25),
    ('consumable_gristly_mutton_oregano_cooked', 'Carne de Carneiro com Orégano', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carneiro cozido com orégano', 0, 0.25),
    ('consumable_gristly_mutton_thyme_cooked', 'Carne de Carneiro com Tomilho', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carneiro cozido com tomilho', 0, 0.25),
    ('consumable_gristly_mutton_wild_mint_cooked', 'Carne de Carneiro com Menta', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carneiro assado com menta', 0, 0.25),
    ('consumable_mature_venison_oregano_cooked', 'Carne de Cervo com Orégano', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de cervo adulto com orégano', 0, 0.25),
    ('consumable_mature_venison_thyme_cooked', 'Carne de Cervo com Tomilho', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de cervo adulto com tomilho', 0, 0.25),
    ('consumable_mature_venison_wild_mint_cooked', 'Carne de Cervo com Menta', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne de cervo adulto com menta selvagem', 0, 0.25),
    ('consumable_plump_bird_oregano_cooked', 'Carne de Ave com Orégano', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne macia de ave com orégano', 0, 0.25),
    ('consumable_plump_bird_thyme_cooked', 'Carne de Ave com Tomilho', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne macia de ave com tomilho', 0, 0.25),
    ('consumable_plump_bird_wild_mint_cooked', 'Carne de Ave com Menta', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Carne macia de ave com menta', 0, 0.25),
    ('consumable_prime_beef_oregano_cooked', 'Carne Bovina com Orégano', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Corte nobre bovino assado com orégano', 0, 0.25),
    ('consumable_prime_beef_thyme_cooked', 'Carne Bovina com Tomilho', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Corte nobre bovino temperado com tomilho', 0, 0.25),
    ('consumable_prime_beef_wild_mint_cooked', 'Carne Bovina com Menta', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Corte nobre bovino preparado com menta', 0, 0.25),
    ('consumable_succulent_fish_oregano_cooked', 'Peixe Suculento com Orégano', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Peixe suculento grelhado com orégano', 0, 0.25),
    ('consumable_succulent_fish_thyme_cooked', 'Peixe Suculento com Tomilho', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Peixe suculento grelhado com tomilho', 0, 0.25),
    ('consumable_succulent_fish_wild_mint_cooked', 'Peixe Suculento com Menta', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Peixe grelhado com menta refrescante', 0, 0.25),
    ('consumable_tender_pork_oregano_cooked', 'Carne Suína com Orégano', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Porco macio temperado com orégano', 0, 0.25),
    ('consumable_tender_pork_thyme_cooked', 'Carne Suína com Tomilho', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Porco macio temperado com tomilho', 0, 0.25),
    ('consumable_tender_pork_wild_mint_cooked', 'Carne Suína com Menta', 10, 1, 'item_standard', 1, 0, 1, '{}', 'Porco macio preparado com menta', 0, 0.25),

    -- BEBIDAS ALCOÓLICAS
    ('consumable_brandy', 'Conhaque', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Garrafa de conhaque envelhecido', 0, 0.25),
    ('consumable_brandy_used', 'Conhaque Aberto', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Garrafa de conhaque parcialmente consumida', 0, 0.25),
    ('consumable_gin', 'Gim', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Garrafa de gim destilado', 0, 0.25),
    ('consumable_gin_used', 'Gim Aberto', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Garrafa de gim aberta', 0, 0.25),
    ('consumable_moonshine', 'Moonshine', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Bebida destilada clandestina forte', 0, 0.25),
    ('consumable_rum', 'Rum', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Garrafa de rum tradicional de Guarma', 0, 0.25),
    ('consumable_rum_used', 'Rum Aberto', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Garrafa de rum aberta', 0, 0.25),
    ('consumable_whiskey', 'Uísque do Kentucky', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Garrafa de bom uísque do Kentucky', 0, 0.25),
    ('consumable_whiskey_used', 'Uísque Aberto', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Garrafa de uísque aberta', 0, 0.25),

    -- TABACO & ESTIMULANTES
    ('consumable_chewing_tobacco', 'Tabaco de Mascar', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Pacote de tabaco para mascar', 0, 0.25),
    ('consumable_chewing_tobacco_used', 'Tabaco de Mascar Aberto', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Tabaco de mascar parcialmente utilizado', 0, 0.25),
    ('consumable_cigar', 'Charuto', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Charuto enrolado de alta qualidade', 0, 0.25),
    ('consumable_cigarette_box', 'Maço de Cigarros Premium', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Maço de cigarros finos', 0, 0.25),
    ('consumable_cigarette_box_cheap', 'Maço de Cigarros Comuns', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Maço de cigarros populares baratos', 0, 0.25),
    ('consumable_cocaine_chewing_gum', 'Goma de Cocaína', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Chiclete estimulante de cocaína medicinal', 0, 0.25),
    ('consumable_cocaine_chewing_gum_used', 'Goma de Cocaína Aberta', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Goma de cocaína aberta', 0, 0.25),

    -- REMÉDIOS & TÔNICOS MEDICINAIS
    ('consumable_medicine', 'Remédio', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Frasco de remédio comum', 0, 0.25),
    ('consumable_medicine_used', 'Remédio Aberto', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Frasco de remédio aberto', 0, 0.25),
    ('consumable_potent_medicine', 'Remédio Potente', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Frasco de remédio de alta eficácia', 0, 0.25),
    ('consumable_potent_restorative', 'Restaurador Potente', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Tônico restaurador forte', 0, 0.25),
    ('consumable_potent_snake_oil', 'Óleo de Cobra Potente', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Óleo de cobra concentrado para olhos de águia', 0, 0.25),
    ('consumable_potent_tonic', 'Tônico Milagroso Potente', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Tônico milagroso potente', 0, 0.25),
    ('consumable_restorative', 'Restaurador', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Tônico restaurador suave', 0, 0.25),
    ('consumable_restorative_used', 'Restaurador Aberto', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Tônico restaurador aberto', 0, 0.25),
    ('consumable_snake_oil', 'Óleo de Cobra', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Frasco clássico de óleo de cobra', 0, 0.25),
    ('consumable_snake_oil_used', 'Óleo de Cobra Aberto', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Óleo de cobra aberto', 0, 0.25),
    ('consumable_tonic', 'Tônico Milagroso', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Tônico medicinal curativo', 0, 0.25),
    ('consumable_tonic_used', 'Tônico Milagroso Aberto', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Tônico curativo aberto', 0, 0.25),

    -- PROVISÕES E CUIDADOS DO CAVALO (ABA 2 DA RODA)
    ('consumable_haycube', 'Feno', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Bloco de feno prensado nutritivo', 0, 0.25),
    ('consumable_crafted_super_meal', 'Refeição Especial para Cavalo', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Mistura artesanal revigorante para cavalos', 0, 0.25),
    ('consumable_horse_medicine', 'Remédio para Cavalos', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Medicina veterinária para equinos', 0, 0.25),
    ('consumable_horse_medicine_used', 'Remédio para Cavalos Aberto', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Remédio para cavalos aberto', 0, 0.25),
    ('consumable_horse_reviver', 'Revigorante para Cavalos', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Dose de emergência para reanimar cavalo ferido', 0, 0.25),
    ('consumable_horse_stimulant', 'Estimulante para Cavalos', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Injeção estimulante para fôlego do cavalo', 0, 0.25),
    ('consumable_horse_stimulant_used', 'Estimulante para Cavalos Aberto', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Estimulante de cavalo aberto', 0, 0.25),
    ('consumable_potent_horse_medicine', 'Remédio Potente para Cavalos', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Medicina veterinária concentrada', 0, 0.25),
    ('consumable_potent_horse_stimulant', 'Estimulante Potente para Cavalos', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Estimulante forte para cavalo', 0, 0.25),
    ('consumable_special_horse_medicine', 'Remédio Especial para Cavalos', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Fórmula medicinal especial para cavalos', 0, 0.25),
    ('consumable_special_horse_reviver_crafted', 'Revitalizante Artesanal para Cavalos', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Remédio artesanal para reviver montaria', 0, 0.25),
    ('consumable_special_horse_stimulant_crafted', 'Estimulante Especial Artesanal', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Mistura estimulante artesanal para equinos', 0, 0.25),
    ('kit_horse_brush', 'Escova de Cavalo', 1, 1, 'item_standard', 1, 0, 1, '{}', 'Escova de cerdas duras para limpar o cavalo', 0, 0.25),

    -- ISCAS DE CAÇA & KITS
    ('consumable_herbivore_bait', 'Isca para Herbívoros', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Mistura aromática que atrai cervos e outros herbívoros', 0, 0.25),
    ('consumable_potent_herbivore_bait', 'Isca Potente para Herbívoros', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Isca concentrada para grandes herbívoros', 0, 0.25),
    ('consumable_predator_bait', 'Isca para Predadores', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Isca de carne e sangue para atrair predadores', 0, 0.25),
    ('consumable_potent_predator_bait', 'Isca Potente para Predadores', 20, 1, 'item_standard', 1, 0, 1, '{}', 'Isca potente que atrai lobos, ursos e pumas', 0, 0.25),
    ('kit_camp', 'Kit de Acampamento', 1, 1, 'item_standard', 1, 0, 1, '{}', 'Equipamento completo para montar acampamento no ermo', 0, 0.25),
    ('kit_camp_simple', 'Acampamento Simples', 1, 1, 'item_standard', 1, 0, 1, '{}', 'Mochila com cobertor e lenha básica', 0, 0.25),
    ('upgrade_upg_mortar_pestle', 'Almofariz e Pilão', 1, 1, 'item_standard', 1, 0, 1, '{}', 'Instrumento para moer ervas e fabricar remédios', 0, 0.25);
