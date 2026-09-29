-- ═══════════════════════════════════════════════════════════════════════════
-- rsm_stables — configuração
-- Tudo o que o servidor cobra, limita ou oferece mora AQUI. A interface só
-- mostra o que o servidor manda, então mudar um preço aqui muda em todo lugar.
-- ═══════════════════════════════════════════════════════════════════════════

Config = {}

-- Mostra no console do servidor/cliente o que o script está fazendo (use para testar)
Config.Debug = false

-- Quantos animais cada personagem pode ter no estábulo
Config.Limits = { horse = 3, cart = 1 }

-- Teclas (hashes de controle do RDR2)
Config.Keys = {
    Open      = 0x760A9C6F, -- G  (segurar) falar com o cavalariço
    CallHorse = 0x24978A28, -- H  assobiar para o cavalo ativo
    CallCart  = 0xF3830D8E, -- J  chamar a carroça ativa
    Saddlebag = 0x5966D52A, -- B  (segurar) abrir o alforje / a carga, perto do animal
}

-- Cavalariço (ped parado no balcão de cada estábulo)
Config.Keeper = {
    model = "U_M_M_BwmStablehand_01",
    promptDistance = 2.2, -- metros até o prompt aparecer
    spawnDistance = 60.0, -- o ped só existe com o jogador por perto
}

-- Blip dos estábulos no mapa (blip_shop_horse)
Config.Blip = { sprite = 1938782895 }

-- Nome dos animais
Config.Name = { min = 2, max = 20 }

-- Chamar o animal: acima desta distância ele reaparece perto do jogador
Config.Call = { teleportDistance = 120.0, cooldownSeconds = 5 }

-- Morte do animal
--   recoverSeconds  tempo até poder chamar de novo (com saúde 100; cai para
--                   perto do dobro conforme a saúde a longo prazo se desgasta)
--   healthLoss      quanto a saúde a longo prazo cai a cada morte (0 desliga)
--   permanent       true = saúde a longo prazo em 0 faz o animal morrer de vez
Config.Death = { recoverSeconds = 120, healthLoss = 10, permanent = false }

-- Vínculo (só cavalos): XP para chegar a cada nível, e XP por minuto montado
Config.Bond = { levels = { 250, 1000, 2500, 5000 }, xpPerMinute = 10 }

-- Transferências entre personagens
--   maxPrice    valor máximo que dá para pedir
--   expireDays  propostas sem resposta somem depois disso
Config.Transfer = { maxPrice = 99999, expireDays = 7 }

-- Inventário do alforje (cavalo) e da carga (carroça) no vorp_inventory.
-- Só o dono abre, e só perto do animal. O limite de peso vem da raça
-- (Config.Breeds → capacity) ou da carroça (Config.Carts → capacity).
--   shared  = true deixa o inventário aberto por mais de uma sessão ao mesmo tempo
Config.Inventory = {
    horse = { shared = false, ignoreStackLimit = true, acceptWeapons = true },
    cart  = { shared = false, ignoreStackLimit = true, acceptWeapons = true },
}

-- Tema: com o rsm_nuikit rodando, o estábulo usa as cores publicadas no estúdio
-- dele e as notificações saem pelo Notify do kit. "" = nunca usar o kit.
Config.NuiKit = "rsm_nuikit"

-- ───────────────────────────────────────────────────────────────────────────
-- Estábulos
--   enabled  false = não aparece no mapa
--   npc      onde fica o cavalariço (x, y, z, direção)
--   horse / cart  onde o animal de exibição aparece e de onde a câmera olha
--   horses / carts  o que ESTE estábulo vende (modelos das pelagens de
--            Config.Breeds / de Config.Carts). nil = vende tudo.
-- ───────────────────────────────────────────────────────────────────────────
Config.Stables = {
    {
        id = "valentine",
        enabled = true,
        name = "Valentine",
        region = "Heartlands · New Hanover",
        npc = vector4(-365.15, 792.68, 115.18, 178.47),
        horse = { spawn = vector4(-366.07, 781.81, 115.14, 5.97), cam = vector3(-367.927, 783.024, 117.778) },
        cart = { spawn = vector4(-370.11, 786.99, 115.16, 274.18), cam = vector3(-363.583, 792.111, 118.042) },
        horses = {
            "A_C_Horse_AmericanStandardbred_Black", "A_C_Horse_AmericanStandardbred_Buckskin",
            "A_C_Horse_AmericanStandardbred_Lightbuckskin", "A_C_Horse_AmericanStandardbred_PalominoDapple",
            "A_C_Horse_AmericanStandardbred_SilverTailBuckskin", "A_C_Horse_Breton_GrulloDun",
            "A_C_Horse_Breton_RedRoan", "A_C_Horse_Breton_Sorrel", "A_C_Horse_Breton_SteelGrey",
            "A_C_Horse_Breton_SealBrown", "A_C_Horse_KentuckySaddle_Black",
            "A_C_Horse_KentuckySaddle_ButterMilkBuckskin_PC", "A_C_Horse_KentuckySaddle_ChestnutPinto",
            "A_C_Horse_KentuckySaddle_Grey", "A_C_Horse_KentuckySaddle_SilverBay",
            "A_C_Horse_Kladruber_Black", "A_C_Horse_Kladruber_Silver", "A_C_Horse_Kladruber_Cremello",
            "A_C_Horse_Morgan_FlaxenChestnut", "A_C_Horse_Morgan_LiverChestnut_PC",
            "A_C_Horse_NorfolkRoadster_RoseGrey", "A_C_Horse_NorfolkRoadster_SpeckledGrey",
            "A_C_Horse_NorfolkRoadster_SpottedTricolor", "A_C_Horse_Shire_DarkBay",
            "A_C_Horse_Shire_LightGrey", "A_C_Horse_Shire_RavenBlack",
            "A_C_Horse_TennesseeWalker_BlackRabicano", "A_C_Horse_TennesseeWalker_Chestnut",
            "A_C_Horse_TennesseeWalker_MahoganyBay", "A_C_Horse_TennesseeWalker_RedRoan",
            "A_C_Horse_Turkoman_DarkBay", "A_C_Horse_Turkoman_Gold", "A_C_Horse_Turkoman_Silver",
            "A_C_HorseMule_01",
        },
        carts = { "huntercart01", "cart01", "cart02", "cart05", "chuckwagon002x", "wagon02x", "wagon03x", "coach2", "stagecoach001x", "supplywagon" },
    },
    {
        id = "rhodes",
        enabled = true,
        name = "Rhodes",
        region = "Scarlett Meadows · Lemoyne",
        npc = vector4(1434.64, -1294.89, 76.82, 105.08),
        horse = { spawn = vector4(1431.56, -1288.21, 76.82, 87.28), cam = vector3(1431.58, -1292.27, 79) },
        cart = { spawn = vector4(1414.53, -1294.22, 77.95, 285.53), cam = vector3(1416.7, -1301.12, 81) },
        horses = {
            "A_C_Horse_Ardennes_BayRoan", "A_C_Horse_Ardennes_IronGreyRoan",
            "A_C_Horse_Ardennes_StrawberryRoan", "A_C_Horse_Belgian_BlondChestnut",
            "A_C_Horse_Belgian_MealyChestnut", "A_C_Horse_KentuckySaddle_Black",
            "A_C_Horse_KentuckySaddle_ButterMilkBuckskin_PC", "A_C_Horse_KentuckySaddle_ChestnutPinto",
            "A_C_Horse_KentuckySaddle_Grey", "A_C_Horse_KentuckySaddle_SilverBay", "A_C_Horse_Kladruber_Grey",
            "A_C_Horse_Kladruber_DappleRoseGrey", "A_C_Horse_Kladruber_White", "A_C_Horse_Morgan_Bay",
            "A_C_Horse_Morgan_BayRoan", "A_C_Horse_Morgan_Palomino", "A_C_Horse_NorfolkRoadster_Black",
            "A_C_Horse_NorfolkRoadster_DappledBuckskin", "A_C_Horse_NorfolkRoadster_PiebaldRoan",
            "A_C_Horse_SuffolkPunch_RedChestnut", "A_C_Horse_SuffolkPunch_Sorrel",
            "A_C_Horse_TennesseeWalker_DappleBay", "A_C_Horse_TennesseeWalker_FlaxenRoan",
            "A_C_Horse_TennesseeWalker_GoldPalomino_PC", "A_C_HorseMule_01", "A_C_Donkey_01",
        },
        carts = { "huntercart01", "cart03", "cart06", "chuckwagon000x", "wagon02x", "wagon03x", "stagecoach003x", "supplywagon" },
    },
    {
        id = "wapiti",
        enabled = true,
        name = "Wapiti",
        region = "Grizzlies East · Ambarino",
        npc = vector4(480.43, 2213.17, 245.9, -44.71),
        horse = { spawn = vector4(485.49, 2209, 245.7, -27.54), cam = vector3(483.39, 2211.93, 248) },
        cart = { spawn = vector4(489.04, 2212.9, 246.95, -67), cam = vector3(483.36, 2219.16, 250.76) },
        horses = {
            "A_C_Horse_AmericanPaint_Greyovero", "A_C_Horse_AmericanPaint_Overo",
            "A_C_Horse_AmericanPaint_SplashedWhite", "A_C_Horse_AmericanPaint_Tobiano",
            "A_C_Horse_Appaloosa_BlackSnowflake", "A_C_Horse_Appaloosa_Blanket",
            "A_C_Horse_Appaloosa_BrownLeopard", "A_C_Horse_Appaloosa_FewSpotted_PC",
            "A_C_Horse_Appaloosa_Leopard", "A_C_Horse_Appaloosa_LeopardBlanket",
            "A_C_Horse_Mustang_BlackOvero", "A_C_Horse_Mustang_GoldenDun", "A_C_Horse_Mustang_GrulloDun",
            "A_C_Horse_Mustang_TigerStripedBay", "A_C_Horse_Mustang_RedDunOvero", "A_C_Horse_Mustang_WildBay",
            "A_C_Horse_Mustang_Buckskin", "A_C_Horse_Mustang_ChestNuttOvero", "A_C_Horse_Nokota_BlueRoan",
            "A_C_Horse_Nokota_ReverseDappleRoan", "A_C_Horse_Nokota_WhiteRoan",
        },
        carts = { "huntercart01", "cart03", "chuckwagon002x", "wagon02x" },
    },
    {
        id = "saintdenis",
        enabled = false,
        name = "Saint Denis",
        region = "Bayou Nwa · Lemoyne",
        npc = vector4(2512.35, -1456.89, 45.2, 91.68),
        horse = { spawn = vector4(2508.59, -1449.96, 45.5, 90.09), cam = vector3(2506.81, -1452.29, 48.617) },
        cart = { spawn = vector4(2503.47, -1441.89, 46.31, 0.24), cam = vector3(2506.43, -1437.7, 50.5783) },
    },
    {
        id = "strawberry",
        enabled = false,
        name = "Strawberry",
        region = "Big Valley · West Elizabeth",
        npc = vector4(-1818.45, -564.83, 155.06, 347.22),
        horse = { spawn = vector4(-1820.26, -555.84, 155.16, 163.01), cam = vector3(-1819.51, -558.7, 157.677) },
        cart = { spawn = vector4(-1821.46, -561.41, 155.06, 256.24), cam = vector3(-1816.37, -560.202, 157.668) },
    },
    {
        id = "blackwater",
        enabled = false,
        name = "Blackwater",
        region = "Great Plains · West Elizabeth",
        npc = vector4(-878.35, -1364.81, 42.53, 266.28),
        horse = { spawn = vector4(-864.25, -1361.8, 42.7, 177.48), cam = vector3(-862.616, -1362.93, 45.5816) },
        cart = { spawn = vector4(-872.58, -1366.57, 42.53, 270.35), cam = vector3(-869.785, -1361.1, 45.2699) },
    },
    {
        id = "tumbleweed",
        enabled = false,
        name = "Tumbleweed",
        region = "Gaptooth Ridge · New Austin",
        npc = vector4(-5515.07, -3039.51, -3.39, 179.88),
        horse = { spawn = vector4(-5519.47, -3039.32, -3.31, 181.62), cam = vector3(-5517.65, -3041.11, -0.50949) },
        cart = { spawn = vector4(-5520.65, -3044.3, -3.39, 270.83), cam = vector3(-5514.19, -3040.63, -0.510857) },
    },
}

-- ───────────────────────────────────────────────────────────────────────────
-- Cavalos à venda, por raça
--   class    elite | war | race | riding | draft | work (só o rótulo na loja)
--   price    em dólares; gold = preço alternativo em ouro (nil = só dólar)
--   capacity peso que o alforje aguenta no vorp_inventory
--   stats    0 a 100, o que a ficha mostra
--   coats    pelagens: { modelo, nome, preço próprio?, ouro próprio? }
-- ───────────────────────────────────────────────────────────────────────────
Config.Breeds = {
    {
        label = "Árabe", class = "elite", price = 1050, gold = 42, capacity = 110,
        stats = { health = 70, stamina = 74, speed = 92, accel = 90, handling = 95 },
        coats = {
            { model = "A_C_Horse_Arabian_Black", coat = "Preto" },
            { model = "A_C_Horse_Arabian_Grey", coat = "Tordilho" },
            { model = "A_C_Horse_Arabian_RedChestnut", coat = "Alazão Avermelhado" },
            { model = "A_C_Horse_Arabian_RoseGreyBay", coat = "Baio Tordilho Rosado" },
            { model = "A_C_Horse_Arabian_WarpedBrindle_PC", coat = "Tigrado Retorcido" },
            { model = "A_C_Horse_Arabian_White", coat = "Branco", price = 1250, gold = 50 },
        },
    },
    {
        label = "Missouri Fox Trotter", class = "elite", price = 950, gold = 38, capacity = 120,
        stats = { health = 82, stamina = 90, speed = 85, accel = 80, handling = 75 },
        coats = {
            { model = "A_C_Horse_MissouriFoxTrotter_AmberChampagne", coat = "Champanhe Âmbar" },
            { model = "A_C_Horse_MissouriFoxTrotter_SableChampagne", coat = "Champanhe Zibelina" },
            { model = "A_C_Horse_MissouriFoxTrotter_SilverDapplePinto", coat = "Pampa Tordilho Prateado", price = 1125, gold = 45 },
        },
    },
    {
        label = "Turcomano", class = "war", price = 925, gold = 37, capacity = 125,
        stats = { health = 88, stamina = 80, speed = 80, accel = 78, handling = 70 },
        coats = {
            { model = "A_C_Horse_Turkoman_DarkBay", coat = "Baio Escuro" },
            { model = "A_C_Horse_Turkoman_Gold", coat = "Dourado" },
            { model = "A_C_Horse_Turkoman_Silver", coat = "Prata", price = 950, gold = 38 },
        },
    },
    {
        label = "Kladruber", class = "war", price = 950, gold = 38, capacity = 130,
        stats = { health = 85, stamina = 80, speed = 74, accel = 72, handling = 70 },
        coats = {
            { model = "A_C_Horse_Kladruber_Black", coat = "Preto" },
            { model = "A_C_Horse_Kladruber_Silver", coat = "Prata" },
            { model = "A_C_Horse_Kladruber_Cremello", coat = "Cremelo" },
            { model = "A_C_Horse_Kladruber_Grey", coat = "Tordilho" },
            { model = "A_C_Horse_Kladruber_DappleRoseGrey", coat = "Tordilho Rosado Rodado" },
            { model = "A_C_Horse_Kladruber_White", coat = "Branco" },
        },
    },
    {
        label = "Andaluz", class = "war", price = 440, gold = nil, capacity = 130,
        stats = { health = 82, stamina = 70, speed = 58, accel = 56, handling = 62 },
        coats = {
            { model = "A_C_Horse_Andalusian_DarkBay", coat = "Baio Escuro" },
            { model = "A_C_Horse_Andalusian_Perlino", coat = "Perlino" },
            { model = "A_C_Horse_Andalusian_RoseGray", coat = "Tordilho Rosado" },
        },
    },
    {
        label = "Ardennes", class = "war", price = 140, gold = nil, capacity = 140,
        stats = { health = 90, stamina = 82, speed = 60, accel = 58, handling = 55 },
        coats = {
            { model = "A_C_Horse_Ardennes_BayRoan", coat = "Ruão Baio" },
            { model = "A_C_Horse_Ardennes_IronGreyRoan", coat = "Ruão Ferro", price = 150 },
            { model = "A_C_Horse_Ardennes_StrawberryRoan", coat = "Ruão Morango", price = 150 },
        },
    },
    {
        label = "Húngaro Meio-Sangue", class = "war", price = 130, gold = nil, capacity = 120,
        stats = { health = 78, stamina = 72, speed = 62, accel = 60, handling = 62 },
        coats = {
            { model = "A_C_Horse_HungarianHalfbred_DarkDappleGrey", coat = "Tordilho Rodado Escuro" },
            { model = "A_C_Horse_HungarianHalfbred_FlaxenChestnut", coat = "Alazão Crina Clara" },
            { model = "A_C_Horse_HungarianHalfbred_LiverChestnut", coat = "Alazão Fígado" },
            { model = "A_C_Horse_HungarianHalfbred_PiebaldTobiano", coat = "Tobiano Malhado" },
        },
    },
    {
        label = "Puro-Sangue", class = "race", price = 550, gold = nil, capacity = 105,
        stats = { health = 58, stamina = 68, speed = 86, accel = 84, handling = 72 },
        coats = {
            { model = "A_C_Horse_Thoroughbred_BlackChestnut", coat = "Alazão Preto" },
            { model = "A_C_Horse_Thoroughbred_BloodBay", coat = "Baio Sangue" },
            { model = "A_C_Horse_Thoroughbred_Brindle", coat = "Tigrado" },
            { model = "A_C_Horse_Thoroughbred_DappleGrey", coat = "Tordilho Rodado" },
            { model = "A_C_Horse_Thoroughbred_ReverseDappleBlack", coat = "Preto Rodado Reverso" },
        },
    },
    {
        label = "Holandês de Sangue Quente", class = "race", price = 450, gold = nil, capacity = 110,
        stats = { health = 60, stamina = 72, speed = 80, accel = 82, handling = 70 },
        coats = {
            { model = "A_C_Horse_DutchWarmblood_ChocolateRoan", coat = "Ruão Chocolate" },
            { model = "A_C_Horse_DutchWarmblood_SealBrown", coat = "Castanho Foca" },
            { model = "A_C_Horse_DutchWarmblood_SootyBuckskin", coat = "Camurça Fuligem" },
        },
    },
    {
        label = "American Standardbred", class = "race", price = 130, gold = nil, capacity = 100,
        stats = { health = 55, stamina = 70, speed = 78, accel = 82, handling = 60 },
        coats = {
            { model = "A_C_Horse_AmericanStandardbred_Black", coat = "Preto" },
            { model = "A_C_Horse_AmericanStandardbred_Buckskin", coat = "Camurça" },
            { model = "A_C_Horse_AmericanStandardbred_Lightbuckskin", coat = "Camurça Clara" },
            { model = "A_C_Horse_AmericanStandardbred_PalominoDapple", coat = "Palomino Tordilho", price = 150 },
            { model = "A_C_Horse_AmericanStandardbred_SilverTailBuckskin", coat = "Camurça Cauda Prateada", price = 150 },
        },
    },
    {
        label = "Norfolk Roadster", class = "race", price = 150, gold = nil, capacity = 105,
        stats = { health = 56, stamina = 66, speed = 74, accel = 76, handling = 68 },
        coats = {
            { model = "A_C_Horse_NorfolkRoadster_Black", coat = "Preto" },
            { model = "A_C_Horse_NorfolkRoadster_SpeckledGrey", coat = "Tordilho Salpicado" },
            { model = "A_C_Horse_NorfolkRoadster_PiebaldRoan", coat = "Ruão Malhado" },
            { model = "A_C_Horse_NorfolkRoadster_RoseGrey", coat = "Tordilho Rosado" },
            { model = "A_C_Horse_NorfolkRoadster_DappledBuckskin", coat = "Camurça Rodada" },
            { model = "A_C_Horse_NorfolkRoadster_SpottedTricolor", coat = "Tricolor Pintado" },
        },
    },
    {
        label = "Criollo", class = "riding", price = 550, gold = nil, capacity = 115,
        stats = { health = 70, stamina = 76, speed = 68, accel = 66, handling = 74 },
        coats = {
            { model = "A_C_Horse_Criollo_Dun", coat = "Lobuno" },
            { model = "A_C_Horse_Criollo_MarbleSabino", coat = "Sabino Marmorizado" },
            { model = "A_C_Horse_Criollo_BayFrameOvero", coat = "Overo Baio" },
            { model = "A_C_Horse_Criollo_BayBrindle", coat = "Baio Tigrado" },
            { model = "A_C_Horse_Criollo_SorrelOvero", coat = "Overo Alazão Claro" },
            { model = "A_C_Horse_Criollo_BlueRoanOvero", coat = "Overo Ruão Azul" },
        },
    },
    {
        label = "Mustang", class = "riding", price = 500, gold = nil, capacity = 115,
        stats = { health = 72, stamina = 70, speed = 68, accel = 66, handling = 70 },
        coats = {
            { model = "A_C_Horse_Mustang_GoldenDun", coat = "Lobuno Dourado" },
            { model = "A_C_Horse_Mustang_GrulloDun", coat = "Lobuno Grullo" },
            { model = "A_C_Horse_Mustang_TigerStripedBay", coat = "Baio Tigrado" },
            { model = "A_C_Horse_Mustang_WildBay", coat = "Baio Selvagem" },
            { model = "A_C_Horse_Mustang_RedDunOvero", coat = "Overo Lobuno Vermelho" },
            { model = "A_C_Horse_Mustang_BlackOvero", coat = "Overo Preto" },
            { model = "A_C_Horse_Mustang_Buckskin", coat = "Camurça" },
            { model = "A_C_Horse_Mustang_ChestNuttOvero", coat = "Overo Alazão" },
        },
    },
    {
        label = "Nokota", class = "riding", price = 450, gold = nil, capacity = 110,
        stats = { health = 64, stamina = 72, speed = 70, accel = 74, handling = 78 },
        coats = {
            { model = "A_C_Horse_Nokota_BlueRoan", coat = "Ruão Azul" },
            { model = "A_C_Horse_Nokota_ReverseDappleRoan", coat = "Ruão Rodado Reverso" },
            { model = "A_C_Horse_Nokota_WhiteRoan", coat = "Ruão Branco" },
        },
    },
    {
        label = "Appaloosa", class = "riding", price = 400, gold = nil, capacity = 110,
        stats = { health = 64, stamina = 64, speed = 66, accel = 64, handling = 72 },
        coats = {
            { model = "A_C_Horse_Appaloosa_BlackSnowflake", coat = "Floco de Neve Preto" },
            { model = "A_C_Horse_Appaloosa_Blanket", coat = "Manta" },
            { model = "A_C_Horse_Appaloosa_BrownLeopard", coat = "Leopardo Marrom" },
            { model = "A_C_Horse_Appaloosa_FewSpotted_PC", coat = "Pouco Pintado" },
            { model = "A_C_Horse_Appaloosa_Leopard", coat = "Leopardo" },
            { model = "A_C_Horse_Appaloosa_LeopardBlanket", coat = "Manta Leopardo" },
        },
    },
    {
        label = "Bretão", class = "riding", price = 150, gold = nil, capacity = 110,
        stats = { health = 62, stamina = 64, speed = 66, accel = 64, handling = 74 },
        coats = {
            { model = "A_C_Horse_Breton_SteelGrey", coat = "Cinza Aço" },
            { model = "A_C_Horse_Breton_MealyDapple", coat = "Rodado Farinhento" },
            { model = "A_C_Horse_Breton_SealBrown", coat = "Castanho Foca" },
            { model = "A_C_Horse_Breton_GrulloDun", coat = "Lobuno Grullo" },
            { model = "A_C_Horse_Breton_Sorrel", coat = "Alazão Claro" },
            { model = "A_C_Horse_Breton_RedRoan", coat = "Ruão Vermelho" },
        },
    },
    {
        label = "American Paint", class = "riding", price = 140, gold = nil, capacity = 110,
        stats = { health = 62, stamina = 62, speed = 64, accel = 62, handling = 72 },
        coats = {
            { model = "A_C_Horse_AmericanPaint_Greyovero", coat = "Tordilho Overo" },
            { model = "A_C_Horse_AmericanPaint_Overo", coat = "Overo" },
            { model = "A_C_Horse_AmericanPaint_SplashedWhite", coat = "Branco Respingado" },
            { model = "A_C_Horse_AmericanPaint_Tobiano", coat = "Tobiano" },
        },
    },
    {
        label = "Tennessee Walker", class = "riding", price = 60, gold = nil, capacity = 100,
        stats = { health = 50, stamina = 56, speed = 62, accel = 60, handling = 68 },
        coats = {
            { model = "A_C_Horse_TennesseeWalker_BlackRabicano", coat = "Rabicano Preto" },
            { model = "A_C_Horse_TennesseeWalker_Chestnut", coat = "Alazão" },
            { model = "A_C_Horse_TennesseeWalker_DappleBay", coat = "Baio Rodado" },
            { model = "A_C_Horse_TennesseeWalker_FlaxenRoan", coat = "Ruão Crina Clara" },
            { model = "A_C_Horse_TennesseeWalker_MahoganyBay", coat = "Baio Mogno" },
            { model = "A_C_Horse_TennesseeWalker_RedRoan", coat = "Ruão Vermelho" },
            { model = "A_C_Horse_TennesseeWalker_GoldPalomino_PC", coat = "Palomino Dourado" },
        },
    },
    {
        label = "Morgan", class = "riding", price = 55, gold = nil, capacity = 100,
        stats = { health = 50, stamina = 56, speed = 56, accel = 58, handling = 66 },
        coats = {
            { model = "A_C_Horse_Morgan_Bay", coat = "Baio" },
            { model = "A_C_Horse_Morgan_BayRoan", coat = "Ruão Baio" },
            { model = "A_C_Horse_Morgan_FlaxenChestnut", coat = "Alazão Crina Clara" },
            { model = "A_C_Horse_Morgan_LiverChestnut_PC", coat = "Alazão Fígado" },
            { model = "A_C_Horse_Morgan_Palomino", coat = "Palomino" },
        },
    },
    {
        label = "Kentucky Saddler", class = "riding", price = 50, gold = nil, capacity = 100,
        stats = { health = 48, stamina = 55, speed = 58, accel = 60, handling = 65 },
        coats = {
            { model = "A_C_Horse_KentuckySaddle_Black", coat = "Preto" },
            { model = "A_C_Horse_KentuckySaddle_ButterMilkBuckskin_PC", coat = "Camurça Leitosa" },
            { model = "A_C_Horse_KentuckySaddle_ChestnutPinto", coat = "Pampa Alazão" },
            { model = "A_C_Horse_KentuckySaddle_Grey", coat = "Tordilho" },
            { model = "A_C_Horse_KentuckySaddle_SilverBay", coat = "Baio Prateado" },
        },
    },
    {
        label = "Belga", class = "draft", price = 120, gold = nil, capacity = 160,
        stats = { health = 95, stamina = 85, speed = 38, accel = 34, handling = 38 },
        coats = {
            { model = "A_C_Horse_Belgian_BlondChestnut", coat = "Alazão Loiro" },
            { model = "A_C_Horse_Belgian_MealyChestnut", coat = "Alazão Farinhento" },
        },
    },
    {
        label = "Shire", class = "draft", price = 120, gold = nil, capacity = 160,
        stats = { health = 95, stamina = 85, speed = 40, accel = 35, handling = 40 },
        coats = {
            { model = "A_C_Horse_Shire_DarkBay", coat = "Baio Escuro" },
            { model = "A_C_Horse_Shire_LightGrey", coat = "Tordilho Claro" },
            { model = "A_C_Horse_Shire_RavenBlack", coat = "Preto Corvo", price = 130 },
        },
    },
    {
        label = "Suffolk Punch", class = "draft", price = 120, gold = nil, capacity = 160,
        stats = { health = 92, stamina = 84, speed = 42, accel = 38, handling = 42 },
        coats = {
            { model = "A_C_Horse_SuffolkPunch_RedChestnut", coat = "Alazão Avermelhado" },
            { model = "A_C_Horse_SuffolkPunch_Sorrel", coat = "Alazão Claro" },
        },
    },
    {
        label = "Mula Pintada", class = "work", price = 35, gold = nil, capacity = 150,
        stats = { health = 45, stamina = 78, speed = 32, accel = 30, handling = 52 },
        coats = {
            { model = "A_C_HorseMulePainted_01", coat = "Comum" },
        },
    },
    {
        label = "Mula", class = "work", price = 25, gold = nil, capacity = 150,
        stats = { health = 45, stamina = 78, speed = 32, accel = 30, handling = 52 },
        coats = {
            { model = "A_C_HorseMule_01", coat = "Comum" },
        },
    },
    {
        label = "Burro", class = "work", price = 20, gold = nil, capacity = 120,
        stats = { health = 40, stamina = 70, speed = 28, accel = 28, handling = 50 },
        coats = {
            { model = "A_C_Donkey_01", coat = "Comum" },
        },
    },
}

-- ───────────────────────────────────────────────────────────────────────────
-- Carroças à venda
--   class     work | light | passenger;  seats = assentos;  capacity = carga
--   stats     0 a 100 (velocidade e resistência) para a ficha
-- ───────────────────────────────────────────────────────────────────────────
Config.Carts = {
    { model = "huntercart01", label = "Carroça de Caçador", class = "work", price = 50, seats = 2, capacity = 50, stats = { speed = 62, durability = 55 } },
    { model = "cart01", label = "Carroça Simples", class = "work", price = 30, seats = 2, capacity = 50, stats = { speed = 58, durability = 50 } },
    { model = "cart02", label = "Carroça Pequena", class = "work", price = 23, seats = 2, capacity = 23, stats = { speed = 64, durability = 40 } },
    { model = "cart03", label = "Carroça de Fazenda", class = "work", price = 40, seats = 2, capacity = 40, stats = { speed = 56, durability = 55 } },
    { model = "cart05", label = "Carroça de Feno", class = "work", price = 28, seats = 2, capacity = 28, stats = { speed = 55, durability = 50 } },
    { model = "cart06", label = "Carroça Coberta", class = "work", price = 55, seats = 2, capacity = 55, stats = { speed = 54, durability = 60 } },
    { model = "buggy01", label = "Charrete", class = "light", price = 250, seats = 2, capacity = 15, stats = { speed = 88, durability = 40 } },
    { model = "chuckwagon000x", label = "Carroça de Cozinha", class = "work", price = 105, seats = 2, capacity = 105, stats = { speed = 40, durability = 70 } },
    { model = "chuckwagon002x", label = "Carroça de Cozinha Coberta", class = "work", price = 110, seats = 2, capacity = 110, stats = { speed = 40, durability = 72 } },
    { model = "wagon02x", label = "Carroção", class = "work", price = 100, seats = 2, capacity = 100, stats = { speed = 45, durability = 72 } },
    { model = "wagon03x", label = "Carroção Leve", class = "work", price = 65, seats = 2, capacity = 65, stats = { speed = 52, durability = 62 } },
    { model = "supplywagon", label = "Carroção de Suprimentos", class = "work", price = 105, seats = 2, capacity = 105, stats = { speed = 42, durability = 78 } },
    { model = "coach2", label = "Coche Particular", class = "passenger", price = 120, seats = 4, capacity = 120, stats = { speed = 60, durability = 64 } },
    { model = "stagecoach001x", label = "Diligência", class = "passenger", price = 80, seats = 6, capacity = 80, stats = { speed = 55, durability = 80 } },
    { model = "stagecoach003x", label = "Diligência de Carga", class = "passenger", price = 250, seats = 6, capacity = 250, stats = { speed = 50, durability = 85 } },
}

-- ───────────────────────────────────────────────────────────────────────────
-- Arreios (os mesmos hashes do vorp_stables)
--   category  hash da categoria no ped do cavalo (usado para tirar a peça)
--   art       ícone do item na interface (web/public/tex/items/<art>.png)
--   styles    { id, label, price, hashes = { variação 1, variação 2, ... } }
--   O id do estilo é o que fica salvo no banco: não troque depois de usar.
-- ───────────────────────────────────────────────────────────────────────────
Config.Tack = {
    {
        id = "saddles", label = "Selas", art = "generic_horse_equip_saddle", category = 0xBAA7E618,
        styles = {
            { id = "lumley_mcclelland", label = "Lumley McClelland", price = 26.9, hashes = {
                 0x106961A8, 0x150D0DAA, 0x17153A45, 0x1C14443F, 0x1F7C4C5, 0x2E4668A3, 0x2ECD9E70, 0x3D0C3AED,
                 0x3F9F62CE, 0x4B372288, 0x5D717C9, 0x78F07DFA, 0xC04FE429, 0xD97573C1, 0xDE47F51, 0xEB1139AB,
                 0xF3BEA853, 0xF94D5623,
            } },
            { id = "kneller_mother_hubbard", label = "Kneller Mother Hubbard", price = 24, hashes = {
                 0x14168240, 0x2844E292, 0x3E949A74, 0x5B6390D9, 0x5BBC54C3, 0x6D403492, 0x70BB7EC1, 0x7FD859C2,
                 0x87F421F7, 0x8D163776, 0x8D9D754C, 0x9CD94BC1, 0xBA6A921E, 0xBB335077, 0xC1AF1568, 0xCE8C2F22,
                 0xD11CBF82, 0xF36A78DE,
            } },
            { id = "kneller_dakota", label = "Kneller Dakota", price = 22, hashes = {
                 0x15FB6791, 0x3827D232, 0x40C53D24, 0x47D2CB3F, 0x9533FA8E, 0xA7AC9F7B, 0xB7B33F88, 0xB9BE555D,
                 0xC7FC601A, 0xDA36048D, 0xE039FC0F, 0xE36C8274, 0xE52BAC3F, 0xEC882931, 0xF2F0045, 0xF4B14B4A,
                 0xF687A8AA,
            } },
            { id = "gerden_vaquero", label = "Gerden Vaquero", price = 21.5, hashes = {
                 0x189F7005, 0x1D0BF8F2, 0x1EC65C0, 0x219D85E2, 0x4C1A5ADB, 0x522CCED, 0x5546EB7A, 0x5B45F932,
                 0x7092A211, 0x7DBB3E1C, 0x8E64DDB5, 0x8FFCF06B, 0xA39D34E, 0xAD4A6355, 0xBE703DF7, 0xBFD09512,
                 0xC0C04297, 0xD2FA64BC, 0xE5510BB8, 0xE6488B58, 0xF1BAA60D, 0xF7682D97,
            } },
            { id = "gerden_trail_saddle", label = "Gerden Trail", price = 21, hashes = {
                 0x1EE21489, 0x20359E53, 0x24F24446, 0x2E3F3A62, 0x306806F, 0x335DC49F, 0x534A7D59, 0x660B29F9,
                 0x6C622F8C, 0x70C65BED, 0x8E22730C, 0x93B7057, 0xC454830C, 0xD6BF27E1, 0xD7FC86BF, 0xE9B7AA35,
                 0xF4118E4, 0xFCE1D7A4,
            } },
            { id = "stenger_roping", label = "Stenger Roping", price = 25, hashes = {
                 0x21E8DDFA, 0x2E216DBC, 0x2F8C7941, 0x5A9E4F6C, 0x60DE5335, 0x6384D886, 0x64CEC6DF, 0x694DE418,
                 0x76887E89, 0x8DABACD7, 0x90489DD2, 0x9E0C3959, 0xB61F0668, 0xBC52F5E6, 0xC7D58D0B, 0xD61B2996,
                 0xDA84CF33, 0xFD4E14C5,
            } },
            { id = "lumley_ranch_cutter", label = "Lumley Ranch Cutter", price = 23, hashes = {
                 0x6FEABF89, 0x7A23C686, 0x7C19770A, 0x7C2C580C, 0x88C363C5, 0x8DD09A7C, 0x93DA8768, 0x9B1C95F8,
                 0x9FF23EBF, 0xA1154105, 0xA21923E5, 0xA8DB3175, 0xB357E58A, 0xC10B5450, 0xD2C8F7CB, 0xE5B31D9F,
                 0xF373B920, 0xFC6AF7AF,
            } },
            { id = "beaver_roping_castor", label = "Beaver Roping Castor", price = 120, hashes = {
                 0x2BEA8ED4,
            } },
            { id = "cougar_mcclelland", label = "Cougar McClelland", price = 110, hashes = {
                 0x353FC03C,
            } },
            { id = "rattlesnake_vaquero", label = "Rattlesnake Vaquero", price = 115, hashes = {
                 0x7D795D72,
            } },
            { id = "alligator_ranch_cutter", label = "Alligator Ranch Cutter", price = 140, hashes = {
                 0xB5802A5F,
            } },
            { id = "panther_trail", label = "Panther Trail", price = 150, hashes = {
                 0xC76C46D9,
            } },
            { id = "boar_mother_hubbard", label = "Boar Mother Hubbard", price = 125, hashes = {
                 0xD225CCA0,
            } },
            { id = "bear_dakota", label = "Bear Dakota", price = 140, hashes = {
                 0xDE5A2905,
            } },
        },
    },
    {
        id = "blankets", label = "Mantas", art = "generic_horse_equip_blanket", category = 0x17CEB41A,
        styles = {
            { id = "siltwater", label = "Siltwater", price = 10, hashes = {
                 0x127E0412, 0x20D4A0BF, 0x2A6D33E8, 0xDC87A9F, 0xFFB1DE72,
            } },
            { id = "roanoke_ridge", label = "Roanoke Ridge", price = 10, hashes = {
                 0x19C5E80C, 0x3278996D, 0x3D34F3, 0x64BE7DF8, 0xEC040C89,
            } },
            { id = "rio_bravo", label = "Rio Bravo", price = 10, hashes = {
                 0x269583CA, 0x3973A986, 0x4A294AF1, 0x97EBE669, 0xED0190A3,
            } },
            { id = "cholla_springs", label = "Cholla Springs", price = 10, hashes = {
                 0x342916F3, 0x6B2084E5, 0x78FB209A, 0x8FAD4DFE, 0x9DE0EA65,
            } },
            { id = "nekoti_rock", label = "Nekoti Rock", price = 10, hashes = {
                 0x3BA0D76D, 0x4BF1F80F, 0x5F0F9E4A, 0x71DFC3EA, 0xF506CA32,
            } },
            { id = "manzanita", label = "Manzanita", price = 10, hashes = {
                 0x4655E362, 0xAD283105, 0xC2EF5C93, 0xC8A467FD, 0xDBEF0E96,
            } },
            { id = "cotorra", label = "Cotorra", price = 11, hashes = {
                 0x508B80B9, 0x67CAAF37, 0xEBB4B70D,
            } },
            { id = "bayou", label = "Bayou", price = 10, hashes = {
                 0x533A022A, 0x823A602A, 0xB0F7BDA4, 0xBBF05395, 0xFDC3D6D3,
            } },
            { id = "owanjila", label = "Owanjila", price = 14, hashes = {
                 0x53B325B7, 0x7D637917, 0x90A31F96, 0x9AD633FC, 0xB19B4519, 0xC073E2CA, 0xC7688D20,
            } },
            { id = "millesani", label = "Millesani", price = 17.5, hashes = {
                 0x5894FB24, 0x9E468686, 0xAB302059, 0xD9E17DBB, 0xE32A1050,
            } },
            { id = "diablo", label = "Diablo", price = 20, hashes = {
                 0x7951D487, 0xA3D5298D, 0xEDCB3D78,
            } },
            { id = "iron_cloud", label = "Iron Cloud", price = 10.5, hashes = {
                 0xC097E12C, 0xCDD2FB96, 0xD333865B, 0xE409A807, 0xF6484C84,
            } },
        },
    },
    {
        id = "horns", label = "Cabeças de Sela", art = "generic_horse_equip_horn", category = 0x05447332,
        styles = {
            { id = "birch_dally", label = "Birch Dally", price = 20, hashes = {
                 0x107D9598, 0x2A28C8BE,
            } },
            { id = "maple_torquemada", label = "Maple Torquemada", price = 21.2, hashes = {
                 0x333CDC06,
            } },
            { id = "brass_eagle", label = "Brass Eagle", price = 26.4, hashes = {
                 0x34135CC3,
            } },
            { id = "aspen_duck_bill", label = "Aspen Duck Bill", price = 19.9, hashes = {
                 0x3E40711D,
            } },
            { id = "steel_diablo", label = "Steel Diablo", price = 30, hashes = {
                 0x9AD2AA40,
            } },
            { id = "maple_duck_bill", label = "Maple Duck Bill", price = 21.2, hashes = {
                 0xC6C381F5,
            } },
            { id = "pine_dally", label = "Pine Dally", price = 25.5, hashes = {
                 0xDBE6AC3B,
            } },
            { id = "redemption_sindewinder", label = "Redemption Sindewinder", price = 25, hashes = {
                 0xE1B1B8F1,
            } },
            { id = "steel_dally", label = "Steel Dally", price = 23, hashes = {
                 0xE1DC3856,
            } },
            { id = "steel_diez_corona", label = "Steel Diez Corona", price = 29, hashes = {
                 0xED0BCEB5,
            } },
            { id = "birch_wide_belly", label = "Birch Wide Belly", price = 15, hashes = {
                 0xF09C56EE,
            } },
            { id = "aspen_thick_neck", label = "Aspen Thick Neck", price = 20.3, hashes = {
                 0xF826E4EB,
            } },
            { id = "birch_torquemada", label = "Birch Torquemada", price = 26.9, hashes = {
                 0xF8CAE723,
            } },
        },
    },
    {
        id = "bags", label = "Alforjes", art = "generic_horse_equip_saddlebag", category = 0x80451C25,
        styles = {
            { id = "standard", label = "Alforje de Couro", price = 10, hashes = {
                 0x1D4EDB88, 0x20AA8620, 0x293E17B3, 0x2AEFF6CA, 0x5277E9BA, 0x577EF434, 0x8BE10F93, 0x9D593283,
                 0xAE110017, 0xB4F40DD9, 0xC019F804, 0xC05AA4AA, 0xD048C482, 0xE2ADE94C, 0xE4108D59, 0xE57042B4,
                 0xE893DFD, 0xEEC77E72, 0xF0C30271, 0xF8FB69CA,
            } },
        },
    },
    {
        id = "stirrups", label = "Estribos", art = "generic_horse_equip_stirrup", category = 0xDA6DADCA,
        styles = {
            { id = "safety", label = "Segurança", price = 10, hashes = {
                 0x3B3AB08,
            } },
            { id = "belled_oxbow", label = "Oxbow com Sino", price = 5, hashes = {
                 0x587DD49F,
            } },
            { id = "deep_roper", label = "Roper Fundo", price = 6, hashes = {
                 0x67AF7302,
            } },
            { id = "slim_line", label = "Fino", price = 9.9, hashes = {
                 0x75178DD2,
            } },
            { id = "fillies", label = "Fillies", price = 12, hashes = {
                 0x8246282F,
            } },
            { id = "bell", label = "Sino", price = 6.9, hashes = {
                 0x8D0BC7DA,
            } },
            { id = "oxbow", label = "Oxbow", price = 8, hashes = {
                 0x9EE8E174,
            } },
            { id = "tapaderos", label = "Tapaderos", price = 15, hashes = {
                 0xBDF19F85,
            } },
            { id = "barroque", label = "Barroco", price = 13, hashes = {
                 0xCB9A3AD6,
            } },
            { id = "hooded", label = "Encapuzado", price = 10, hashes = {
                 0xD8AE54FE,
            } },
            { id = "slim_line_iron", label = "Fino de Ferro", price = 11.5, hashes = {
                 0xE73FF221,
            } },
        },
    },
    {
        id = "bedrolls", label = "Rolos de Dormir", art = "generic_horse_equip_bedroll", category = 0xEFB31921,
        styles = {
            { id = "wool", label = "Lã", price = 5, hashes = {
                 0x12F0DF9F, 0x18BB6B30, 0x1B43F045, 0x55A0E4FE, 0x69B21ADD, 0x7B55D476, 0x8C9F7709, 0x9FD99D7D,
                 0xAC1F34C, 0xD8258E14, 0xFFB0391E,
            } },
            { id = "canvas", label = "Lona", price = 3, hashes = {
                 0x27543EBB, 0x36BEDD90, 0x4B7E0712, 0x73D157B4, 0x841C784A, 0xA1FD8B43, 0xB4532FEE, 0xBC664014,
                 0xD020E789,
            } },
            { id = "padded_wool", label = "Lã Acolchoada", price = 7.7, hashes = {
                 0x45FEA6D8, 0x69B29DC5, 0x72FCB059, 0x7C8A149A, 0x84E5AFA, 0x8DD7B735, 0x98214B1C, 0x9D868568,
                 0xA643680C, 0xD258EF10,
            } },
        },
    },
    {
        id = "manes", label = "Crinas", art = "generic_horse_equip_mane", category = 0xAA0217AB,
        styles = {
            { id = "mane_dreads", label = "Dreads", price = 2, hashes = {
                 0x1FDC6D0F, 0x241D7FBD, 0x3A7C2C86, 0x483AC803, 0x512377B, 0x6038F7FF, 0x6D9412B5, 0x83563E39,
                 0x96FE6589, 0x9A640A3, 0xB2FB934B, 0xC929BFA7, 0xCDC9C8E7, 0xDCF5321, 0xE02377D6, 0xFF17AB82,
                 0xFFF3B76A,
            } },
            { id = "mane_trancada", label = "Trançada", price = 2, hashes = {
                 0x25627B98, 0x2E378E8A, 0x3BFE2A17, 0x4FCC51B3, 0x54A3CB0, 0x5D596CCD, 0x6F4510C4, 0x7D902D5A,
                 0x92B2579E, 0x97105EF6, 0xA0F4F423, 0xA64BFD6D, 0xB13D134B, 0xCF434F57, 0xD4E65BE5, 0xDC62E996,
                 0xE9FE04D0,
            } },
            { id = "mane_curta", label = "Curta", price = 2, hashes = {
                 0x18199F48, 0x354F6B7, 0x3F1FEE4C, 0x4F148D45, 0x52DC15C8, 0x5DE62AE8, 0x648A3924, 0x7098D141,
                 0x86457C9A, 0x960C1B33, 0x99F5A3FA, 0xA4E1B8DE, 0xABA8475F, 0xB288D42C, 0xBD7B6B05, 0xC15371C1,
                 0xF2E555D8,
            } },
            { id = "mane_comum", label = "Comum", price = 2, hashes = {
                 0x130E341A, 0x16923E26, 0x1A5A45B6, 0x2FCAF0CB, 0x419D9470, 0x41EA9196, 0x5445B9C0, 0x5ED14B9F,
                 0x66215D77, 0x817B10F6, 0xA7A4DD49, 0xB5F379E6, 0xD894BF28, 0xE1435081, 0xEA46E28C, 0xFF020F3A,
            } },
            { id = "mane_longa", label = "Longa", price = 2, hashes = {
                 0x235DBF1, 0x446A6F01, 0x5F0395A3, 0x5FE29755, 0x632F2B7, 0x6CB9310E, 0x838E5EB8, 0x94F58186,
                 0x97D095F4, 0xA193A97A, 0xAA3FAC1A, 0xAFB7C24, 0xB881489D, 0xC8646863, 0xC9D16B31, 0xE0BC27A6,
                 0xFC74DF3B,
            } },
        },
    },
    {
        id = "tails", label = "Caudas", art = "generic_horse_equip_tail", category = 0xA63CAE10,
        styles = {
            { id = "tail_dreads", label = "Dreads", price = 2, hashes = {
                 0x12DBBBAF, 0x3B8A8D0C, 0x4951F22, 0x49CD2991, 0x607956E9, 0x6DB6F164, 0x7522834F, 0x84269E43,
                 0x876B27E0, 0x88A2AA53, 0x96EDC3D1, 0x972AC447, 0xA8A4673A, 0xBCD412B1, 0xCE62B5CE, 0xDD9F5447,
                 0xEFA67855,
            } },
            { id = "tail_trancada", label = "Trançada", price = 2, hashes = {
                 0x17EB79D3, 0x1A3B721B, 0x25B51566, 0x33E7B1CB, 0x4124CC49, 0x4F5268A4, 0xA3DA055A, 0xA62C9657,
                 0xA7438C29, 0xB4AB3354, 0xC2FA4FF2, 0xC74FCC45, 0xD143E02D, 0xEBC7218B, 0xED0397AC, 0xF6B0AB06,
            } },
            { id = "tail_curta", label = "Curta", price = 2, hashes = {
                 0x1BB5EAA1, 0x1E9A18C2, 0x2E753874, 0x3B27D1DD, 0x3D212D77, 0x5062FC53, 0x508AD44A, 0x543203ED,
                 0x5F4871C5, 0x695B2E3F, 0x75C4C716, 0x82DB38EE, 0x84ADE4E4, 0xAFB492C, 0xC0AF3489, 0xDCE41557,
                 0xDDB48566, 0xEAEAB164,
            } },
            { id = "tail_comum", label = "Comum", price = 2, hashes = {
                 0x383E86F3, 0x3D1F13D4, 0x4B51B039, 0x574BC82D, 0x66C266F, 0x69756C80, 0x740701A3, 0x7A248ABE,
                 0x84D6B90, 0x894C290D, 0x9CB1CFD8, 0xA0775A83, 0xA4F0E056, 0xB244FE1E, 0xCDFF359A, 0xE38F5D96,
                 0xEAA5EEE7, 0xED787168,
            } },
            { id = "tail_longa", label = "Longa", price = 2, hashes = {
                 0x1F7A99EA, 0x30603BB5, 0x3AE050B5, 0x5D7FA043, 0x607E6DD, 0x73073A2, 0x810A5CE0, 0xB4374DB1,
                 0xC304EB4C, 0xD7D68A7B, 0xD9288D47, 0xD9EA1916, 0xEABBBAB9, 0xF4294320, 0xF4A3443C, 0xF867D611,
            } },
        },
    },
    {
        id = "masks", label = "Máscaras", art = "generic_horse_equip_mask", category = 0xD3500E5D,
        styles = {
            { id = "all", label = "Máscara de Guerra", price = 45, hashes = {
                 0xFA5B72BB, 0xF606EC4A, 0xEEF65F11, 0xEC10D626, 0xE3278C28, 0xDDCDB9A0, 0xD70C73EA, 0xC907FCA9,
                 0xC70D8F40, 0xBD887906, 0xB567EBF5, 0xB395D1C5, 0xB0395F88, 0xA45049C6, 0x9DB125FC, 0x9A11B219,
                 0x9946F874, 0x90A62272, 0x8DCC1CBE, 0x8DB38601, 0x8C471684, 0x872A0C5A, 0x7BFA791B, 0x7A773AC1,
                 0x702A4AF3, 0x6B355791, 0x69CD996E, 0x68FB97DE, 0x68DB4FAD, 0x62C5B02A, 0x61BEAE08, 0x4E22622C,
                 0x4C8C83A4, 0x406FC6C7, 0x30044BAC, 0x226B2F76, 0x13AC6E51, 0x08A78F53, 0xF0ED62FF, 0xF17728C7,
            } },
        },
    },
    {
        id = "lanterns", label = "Lanternas", art = "generic_horse_equip_lantern", category = 0x1530BE1C,
        styles = {
            { id = "normal", label = "Lanterna de Sela", price = 35, hashes = {
                 0x635E387C,
            } },
        },
    },
}
