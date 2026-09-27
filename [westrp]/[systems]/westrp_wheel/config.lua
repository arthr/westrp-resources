Config = {}

Config.Debug = false

-- Configurações de Cooldown e Controle de Taxa
Config.CooldownMs = 450            -- Cooldown mínimo entre usos de itens da roda (ms)
Config.HoldThresholdMs = 180       -- Tempo mínimo segurando TAB para considerar abertura ativa (ms)

-- Notificações visuais de consumo
Config.Notify = {
    Enabled = true,
    Title = "Você usou:",
    Duration = 4000
}

-- Mapeamento oficial de itens da Roda (WestRP / VORP Database -> Hashes Nativos RDR3)
-- Chave: nome exato do item na tabela de inventário do servidor
-- nativeName: nome do item nativo do RDR2 (hasheado pelo motor C++)
-- label: nome em português exibido em logs e notificações
-- slot: slot de destino na engine (SLOTID_SATCHEL ou SLOTID_ACTIVE_HORSE)
Config.WheelItems = {
    -- ========================================================================
    -- FRUTAS, VEGETAIS & ENLATADOS
    -- ========================================================================
    consumable_apple = {
        nativeName = "consumable_apple",
        label = "Maçã",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_apricots_can = {
        nativeName = "consumable_apricots_can",
        label = "Damasco em Lata",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_baked_beans_can = {
        nativeName = "consumable_baked_beans_can",
        label = "Feijão Cozido em Lata",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_beets = {
        nativeName = "consumable_beets",
        label = "Beterraba",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_carrot = {
        nativeName = "consumable_carrot",
        label = "Cenoura",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_celery = {
        nativeName = "consumable_celery",
        label = "Aipo",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_corn = {
        nativeName = "consumable_corn",
        label = "Milho",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_cornedbeef_can = {
        nativeName = "consumable_cornedbeef_can",
        label = "Carne Enlatada",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_kidneybeans_can = {
        nativeName = "consumable_kidneybeans_can",
        label = "Feijão Vermelho em Lata",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_peach = {
        nativeName = "consumable_peach",
        label = "Pêssego",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_peaches_can = {
        nativeName = "consumable_peaches_can",
        label = "Pêssegos em Lata",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_pear = {
        nativeName = "consumable_pear",
        label = "Pera",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_peas_can = {
        nativeName = "consumable_peas_can",
        label = "Ervilhas em Lata",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_pineapples_can = {
        nativeName = "consumable_pineapples_can",
        label = "Abacaxi em Lata",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_salmon_can = {
        nativeName = "consumable_salmon_can",
        label = "Salmão em Lata",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_strawberries_can = {
        nativeName = "consumable_strawberries_can",
        label = "Morangos em Lata",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_sweet_corn_can = {
        nativeName = "consumable_sweet_corn_can",
        label = "Milho Doce em Lata",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },

    -- ========================================================================
    -- PÃES, QUEIJOS & SNACKS
    -- ========================================================================
    consumable_biscuit_box = {
        nativeName = "consumable_biscuit_box",
        label = "Caixa de Biscoitos",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_bread_chunk = {
        nativeName = "consumable_bread_chunk",
        label = "Pedaço de Pão",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_bread_roll = {
        nativeName = "consumable_bread_roll",
        label = "Pãozinho",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_candy_bag = {
        nativeName = "consumable_candy_bag",
        label = "Saco de Doces",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_cheese_wedge = {
        nativeName = "consumable_cheese_wedge",
        label = "Fatia de Queijo",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_chocolate_bar = {
        nativeName = "consumable_chocolate_bar",
        label = "Barra de Chocolate",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_crackers = {
        nativeName = "consumable_crackers",
        label = "Biscoitos Salgados",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_jerky = {
        nativeName = "consumable_jerky",
        label = "Carne Seca Bovina",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_jerky_venison = {
        nativeName = "consumable_jerky_venison",
        label = "Carne Seca de Cervo",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_oat_cakes = {
        nativeName = "consumable_oat_cakes",
        label = "Bolos de Aveia",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_offal = {
        nativeName = "consumable_offal",
        label = "Miúdos Salgados",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_peppermint = {
        nativeName = "consumable_peppermint",
        label = "Bala de Hortelã",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_sugarcube = {
        nativeName = "consumable_sugarcube",
        label = "Cubo de Açúcar",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },

    -- ========================================================================
    -- CARNES E PEIXES COZIDOS COM ERVAS
    -- ========================================================================
    consumable_big_game_meat_oregano_cooked = {
        nativeName = "consumable_big_game_meat_oregano_cooked",
        label = "Carne de Caça Grande com Orégano",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_big_game_meat_thyme_cooked = {
        nativeName = "consumable_big_game_meat_thyme_cooked",
        label = "Carne de Caça Grande com Tomilho",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_big_game_meat_wild_mint_cooked = {
        nativeName = "consumable_big_game_meat_wild_mint_cooked",
        label = "Carne de Caça Grande com Menta",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_crustacean_meat_mint_cooked = {
        nativeName = "consumable_crustacean_meat_mint_cooked",
        label = "Carne de Crustáceo com Menta",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_crustacean_meat_oregano_cooked = {
        nativeName = "consumable_crustacean_meat_oregano_cooked",
        label = "Carne de Crustáceo com Orégano",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_crustacean_meat_thyme_cooked = {
        nativeName = "consumable_crustacean_meat_thyme_cooked",
        label = "Carne de Crustáceo com Tomilho",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_exotic_bird_oregano_cooked = {
        nativeName = "consumable_exotic_bird_oregano_cooked",
        label = "Ave Exótica com Orégano",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_exotic_bird_thyme_cooked = {
        nativeName = "consumable_exotic_bird_thyme_cooked",
        label = "Ave Exótica com Tomilho",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_exotic_bird_wild_mint_cooked = {
        nativeName = "consumable_exotic_bird_wild_mint_cooked",
        label = "Ave Exótica com Menta Selvagem",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_flakey_fish_oregano_cooked = {
        nativeName = "consumable_flakey_fish_oregano_cooked",
        label = "Peixe Suave com Orégano",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_flakey_fish_thyme_cooked = {
        nativeName = "consumable_flakey_fish_thyme_cooked",
        label = "Peixe Suave com Tomilho",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_flakey_fish_wild_mint_cooked = {
        nativeName = "consumable_flakey_fish_wild_mint_cooked",
        label = "Peixe Suave com Menta",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_game_meat_oregano_cooked = {
        nativeName = "consumable_game_meat_oregano_cooked",
        label = "Carne de Caça com Orégano",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_game_meat_thyme_cooked = {
        nativeName = "consumable_game_meat_thyme_cooked",
        label = "Carne de Caça com Tomilho",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_game_meat_wild_mint_cooked = {
        nativeName = "consumable_game_meat_wild_mint_cooked",
        label = "Carne de Caça com Menta",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_gristly_mutton_oregano_cooked = {
        nativeName = "consumable_gristly_mutton_oregano_cooked",
        label = "Carne de Carneiro com Orégano",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_gristly_mutton_thyme_cooked = {
        nativeName = "consumable_gristly_mutton_thyme_cooked",
        label = "Carne de Carneiro com Tomilho",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_gristly_mutton_wild_mint_cooked = {
        nativeName = "consumable_gristly_mutton_wild_mint_cooked",
        label = "Carne de Carneiro com Menta",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_mature_venison_oregano_cooked = {
        nativeName = "consumable_mature_venison_oregano_cooked",
        label = "Carne de Cervo com Orégano",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_mature_venison_thyme_cooked = {
        nativeName = "consumable_mature_venison_thyme_cooked",
        label = "Carne de Cervo com Tomilho",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_mature_venison_wild_mint_cooked = {
        nativeName = "consumable_mature_venison_wild_mint_cooked",
        label = "Carne de Cervo com Menta",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_plump_bird_oregano_cooked = {
        nativeName = "consumable_plump_bird_oregano_cooked",
        label = "Carne de Ave com Orégano",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_plump_bird_thyme_cooked = {
        nativeName = "consumable_plump_bird_thyme_cooked",
        label = "Carne de Ave com Tomilho",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_plump_bird_wild_mint_cooked = {
        nativeName = "consumable_plump_bird_wild_mint_cooked",
        label = "Carne de Ave com Menta",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_prime_beef_oregano_cooked = {
        nativeName = "consumable_prime_beef_oregano_cooked",
        label = "Carne Bovina com Orégano",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_prime_beef_thyme_cooked = {
        nativeName = "consumable_prime_beef_thyme_cooked",
        label = "Carne Bovina com Tomilho",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_prime_beef_wild_mint_cooked = {
        nativeName = "consumable_prime_beef_wild_mint_cooked",
        label = "Carne Bovina com Menta",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_succulent_fish_oregano_cooked = {
        nativeName = "consumable_succulent_fish_oregano_cooked",
        label = "Peixe Suculento com Orégano",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_succulent_fish_thyme_cooked = {
        nativeName = "consumable_succulent_fish_thyme_cooked",
        label = "Peixe Suculento com Tomilho",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_succulent_fish_wild_mint_cooked = {
        nativeName = "consumable_succulent_fish_wild_mint_cooked",
        label = "Peixe Suculento com Menta",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_tender_pork_oregano_cooked = {
        nativeName = "consumable_tender_pork_oregano_cooked",
        label = "Carne Suína com Orégano",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_tender_pork_thyme_cooked = {
        nativeName = "consumable_tender_pork_thyme_cooked",
        label = "Carne Suína com Tomilho",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_tender_pork_wild_mint_cooked = {
        nativeName = "consumable_tender_pork_wild_mint_cooked",
        label = "Carne Suína com Menta",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },

    -- ========================================================================
    -- BEBIDAS ALCOÓLICAS
    -- ========================================================================
    consumable_brandy = {
        nativeName = "consumable_brandy",
        label = "Conhaque",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_brandy_used = {
        nativeName = "consumable_brandy_used",
        label = "Conhaque Aberto",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_gin = {
        nativeName = "consumable_gin",
        label = "Gim",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_gin_used = {
        nativeName = "consumable_gin_used",
        label = "Gim Aberto",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_moonshine = {
        nativeName = "consumable_moonshine",
        label = "Moonshine",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_rum = {
        nativeName = "consumable_rum",
        label = "Rum",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_rum_used = {
        nativeName = "consumable_rum_used",
        label = "Rum Aberto",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_whiskey = {
        nativeName = "consumable_whiskey",
        label = "Uísque do Kentucky",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_whiskey_used = {
        nativeName = "consumable_whiskey_used",
        label = "Uísque Aberto",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },

    -- ========================================================================
    -- TABACO & ESTIMULANTES
    -- ========================================================================
    consumable_chewing_tobacco = {
        nativeName = "consumable_chewing_tobacco",
        label = "Tabaco de Mascar",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_chewing_tobacco_used = {
        nativeName = "consumable_chewing_tobacco_used",
        label = "Tabaco de Mascar Aberto",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_cigar = {
        nativeName = "consumable_cigar",
        label = "Charuto",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_cigarette_box = {
        nativeName = "consumable_cigarette_box",
        label = "Maço de Cigarros Premium",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_cigarette_box_cheap = {
        nativeName = "consumable_cigarette_box_cheap",
        label = "Maço de Cigarros Comuns",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_cocaine_chewing_gum = {
        nativeName = "consumable_cocaine_chewing_gum",
        label = "Goma de Cocaína",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_cocaine_chewing_gum_used = {
        nativeName = "consumable_cocaine_chewing_gum_used",
        label = "Goma de Cocaína Aberta",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },

    -- ========================================================================
    -- REMÉDIOS & TÔNICOS MEDICINAIS
    -- ========================================================================
    consumable_medicine = {
        nativeName = "consumable_medicine",
        label = "Remédio",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_medicine_used = {
        nativeName = "consumable_medicine_used",
        label = "Remédio Aberto",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_potent_medicine = {
        nativeName = "consumable_potent_medicine",
        label = "Remédio Potente",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_potent_restorative = {
        nativeName = "consumable_potent_restorative",
        label = "Restaurador Potente",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_potent_snake_oil = {
        nativeName = "consumable_potent_snake_oil",
        label = "Óleo de Cobra Potente",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_potent_tonic = {
        nativeName = "consumable_potent_tonic",
        label = "Tônico Milagroso Potente",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_restorative = {
        nativeName = "consumable_restorative",
        label = "Restaurador",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_restorative_used = {
        nativeName = "consumable_restorative_used",
        label = "Restaurador Aberto",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_snake_oil = {
        nativeName = "consumable_snake_oil",
        label = "Óleo de Cobra",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_snake_oil_used = {
        nativeName = "consumable_snake_oil_used",
        label = "Óleo de Cobra Aberto",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_tonic = {
        nativeName = "consumable_tonic",
        label = "Tônico Milagroso",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_tonic_used = {
        nativeName = "consumable_tonic_used",
        label = "Tônico Milagroso Aberto",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },

    -- ========================================================================
    -- PROVISÕES E CUIDADOS DO CAVALO (ABA 2 DA RODA)
    -- ========================================================================
    consumable_haycube = {
        nativeName = "consumable_haycube",
        label = "Feno",
        slot = "SLOTID_ACTIVE_HORSE",
        useAmount = 1
    },
    consumable_crafted_super_meal = {
        nativeName = "consumable_crafted_super_meal",
        label = "Refeição Especial para Cavalo",
        slot = "SLOTID_ACTIVE_HORSE",
        useAmount = 1
    },
    consumable_horse_medicine = {
        nativeName = "consumable_horse_medicine",
        label = "Remédio para Cavalos",
        slot = "SLOTID_ACTIVE_HORSE",
        useAmount = 1
    },
    consumable_horse_medicine_used = {
        nativeName = "consumable_horse_medicine_used",
        label = "Remédio para Cavalos Aberto",
        slot = "SLOTID_ACTIVE_HORSE",
        useAmount = 1
    },
    consumable_horse_reviver = {
        nativeName = "consumable_horse_reviver",
        label = "Revigorante para Cavalos",
        slot = "SLOTID_ACTIVE_HORSE",
        useAmount = 1
    },
    consumable_horse_stimulant = {
        nativeName = "consumable_horse_stimulant",
        label = "Estimulante para Cavalos",
        slot = "SLOTID_ACTIVE_HORSE",
        useAmount = 1
    },
    consumable_horse_stimulant_used = {
        nativeName = "consumable_horse_stimulant_used",
        label = "Estimulante para Cavalos Aberto",
        slot = "SLOTID_ACTIVE_HORSE",
        useAmount = 1
    },
    consumable_potent_horse_medicine = {
        nativeName = "consumable_potent_horse_medicine",
        label = "Remédio Potente para Cavalos",
        slot = "SLOTID_ACTIVE_HORSE",
        useAmount = 1
    },
    consumable_potent_horse_stimulant = {
        nativeName = "consumable_potent_horse_stimulant",
        label = "Estimulante Potente para Cavalos",
        slot = "SLOTID_ACTIVE_HORSE",
        useAmount = 1
    },
    consumable_special_horse_medicine = {
        nativeName = "consumable_special_horse_medicine",
        label = "Remédio Especial para Cavalos",
        slot = "SLOTID_ACTIVE_HORSE",
        useAmount = 1
    },
    consumable_special_horse_reviver_crafted = {
        nativeName = "consumable_special_horse_reviver_crafted",
        label = "Revitalizante Artesanal para Cavalos",
        slot = "SLOTID_ACTIVE_HORSE",
        useAmount = 1
    },
    consumable_special_horse_stimulant_crafted = {
        nativeName = "consumable_special_horse_stimulant_crafted",
        label = "Estimulante Especial Artesanal",
        slot = "SLOTID_ACTIVE_HORSE",
        useAmount = 1
    },
    kit_horse_brush = {
        nativeName = "kit_horse_brush",
        label = "Escova de Cavalo",
        slot = "SLOTID_ACTIVE_HORSE",
        useAmount = 1
    },

    -- ========================================================================
    -- ISCAS DE CAÇA & KITS
    -- ========================================================================
    consumable_herbivore_bait = {
        nativeName = "consumable_herbivore_bait",
        label = "Isca para Herbívoros",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_potent_herbivore_bait = {
        nativeName = "consumable_potent_herbivore_bait",
        label = "Isca Potente para Herbívoros",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_predator_bait = {
        nativeName = "consumable_predator_bait",
        label = "Isca para Predadores",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    consumable_potent_predator_bait = {
        nativeName = "consumable_potent_predator_bait",
        label = "Isca Potente para Predadores",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    kit_camp = {
        nativeName = "kit_camp",
        label = "Kit de Acampamento",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    kit_camp_simple = {
        nativeName = "kit_camp_simple",
        label = "Acampamento Simples",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    },
    upgrade_upg_mortar_pestle = {
        nativeName = "upgrade_upg_mortar_pestle",
        label = "Almofariz e Pilão",
        slot = "SLOTID_SATCHEL",
        useAmount = 1
    }
}
