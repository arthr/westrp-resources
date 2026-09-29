Config = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Recursos necessários
--   vorp_core        obrigatório (nome, emprego, dinheiro e ouro vêm do statebag do personagem)
--   vorp_character   obrigatório (dispara vorp:SelectedCharacter)
--   vorp_metabolism  opcional   (fome e sede; sem ele os dois medidores somem)
-- ─────────────────────────────────────────────────────────────────────────────

-- Intervalos de leitura, em milissegundos. A interface só recebe o que mudou.
Config.Tick = {
    status = 250,     -- cores, cavalo, arma, voz
    world = 2000,     -- hora, clima, temperatura, localização
    character = 1000, -- dinheiro, ouro, emprego (statebag do VORP)
    metabolism = 2000 -- fome e sede (vorp_metabolism)
}

Config.Hud = {
    command = 'hud',             -- liga/desliga o HUD para o jogador
    layoutCommand = 'hudlayout', -- abre o Editor de Layout
    hideOnPause = true,          -- esconde o HUD com o menu de pausa / mapa aberto

    -- Esconde os cores nativos do RDR2 para não aparecerem duplicados.
    -- Ícones 0-9 são os mesmos que o próprio jogo restaura com o valor 0.
    -- Se os cores nativos continuarem aparecendo no seu build, troque o valor
    -- em nativeCoreHiddenState; o valor 0 volta ao padrão do jogo.
    hideNativeCores = true,
    nativeCoreIcons = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
    nativeCoreHiddenState = 2,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Necessidades
--   fome / sede: lidas do vorp_metabolism (0-1000, convertidas para 0-100)
--   estresse / higiene / embriaguez: mantidas por este recurso NO SERVIDOR e
--   salvas por personagem. Outros scripts alteram pelos exports (veja server.lua).
--   perMinute: variação automática por minuto (negativo = diminui com o tempo)
-- ─────────────────────────────────────────────────────────────────────────────
Config.Needs = {
    hunger = { enabled = true },
    thirst = { enabled = true },
    stress = {
        enabled = true,
        start = 0,
        perMinute = -2.0, -- o estresse baixa sozinho com o tempo
        shooting = 1.0,   -- somado por disparo
        damage = 3.0,     -- somado ao levar dano
        cooldown = 2,     -- segundos mínimos entre dois aumentos do mesmo tipo
    },
    hygiene = { enabled = true, start = 100, perMinute = -0.5 }, -- banho: exports.rsm_hud:setNeed(src, 'hygiene', 100)
    alcohol = { enabled = true, start = 0, perMinute = -3.0 },   -- bebida: exports.rsm_hud:addNeed(src, 'alcohol', 15)
    tickSeconds = 30,   -- de quanto em quanto tempo o servidor aplica perMinute
    saveEveryTicks = 4, -- grava no KVP do servidor a cada N ticks (e sempre ao desconectar)
}

Config.Metabolism = {
    resource = 'vorp_metabolism',
    hideItsHud = true, -- esconde o HUD do próprio vorp_metabolism (este HUD já mostra fome e sede)
}

-- Golden Core: núcleo ou atributo fortificado pelo próprio jogo (tônicos,
-- itens ou qualquer script que use as natives de overpower). O HUD só lê o
-- estado nativo; abaixo deste tempo restante o brilho pulsa mais rápido.
Config.GoldenCore = {
    endingSeconds = 10,
}

-- Efeitos de status calculados no client. Doente e envenenado vêm do servidor
-- pelo export setEffect.
Config.Effects = {
    coldBelow = 5,      -- °C: abaixo disso mostra "Frio"
    hotAbove = 32,      -- °C: acima disso mostra "Calor"
    woundedBelow = 25,  -- % do anel de vida
    drainedBelow = 10,  -- % do núcleo de vigor
    dizzyAlcoholAbove = 60,
}

Config.Temperature = { unit = 'C' } -- 'C' ou 'F'

-- Voz: se o recurso de voz publicar LocalPlayer.state.proximity (pma-voice),
-- o índice dele é usado. Senão, o alcance vem da distância de fala do mumble.
Config.Voice = {
    whisperUpTo = 3.0, -- metros
    normalUpTo = 8.0,  -- acima disso conta como grito
}

-- GET_CLOCK_DAY_OF_WEEK: 0 = domingo
Config.Days = { 'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado' }

-- Hash do clima → nome exibido
Config.Weather = {
    [0x27EA2814] = 'Nevasca',
    [0x30FDAF5C] = 'Nublado',
    [0x995C7F44] = 'Garoa',
    [0xD61BDE01] = 'Neblina',
    [0x7F622122] = 'Nevasca Rasteira',
    [0x75A9E268] = 'Granizo',
    [0xF5A87B65] = 'Céu Limpo',
    [0x320D0951] = 'Furacão',
    [0x5974E8E5] = 'Névoa',
    [0xBB898D2D] = 'Encoberto',
    [0x19D4F1D9] = 'Encoberto',
    [0x54A69840] = 'Chuva',
    [0xB17F6111] = 'Tempestade de Areia',
    [0xE72679D5] = 'Pancada de Chuva',
    [0x0CA71D7C] = 'Chuva com Neve',
    [0xEFB6EFF6] = 'Neve',
    [0x23FB812B] = 'Neve Fraca',
    [0x614A1F91] = 'Ensolarado',
    [0xB677829F] = 'Trovoada',
    [0x7C1C4A13] = 'Tempestade',
    [0x2B402288] = 'Nevasca Branca',
}

-- Zonas do mapa (hash de GetMapZoneAtCoords → nome exibido)
Config.Zones = {
    -- tipo 1: cidades
    towns = {
        [1654810713] = 'Fazenda Aguasdulces',
        [201158410] = 'Ruínas de Aguasdulces',
        [-1207133769] = 'Vila Aguasdulces',
        [7359335] = 'Annesburg',
        [-744494798] = 'Armadillo',
        [-1708386982] = "Beecher's Hope",
        [1053078005] = 'Blackwater',
        [1778899666] = 'Braithwaite',
        [-1947415645] = 'Butcher Creek',
        [1862420670] = 'Caliga Hall',
        [-1851305682] = 'Cornwall Kerosene',
        [-473051294] = 'Emerald Ranch',
        [406627834] = 'Lagras',
        [1299204683] = 'Manicato',
        [1463094051] = 'Manzanita Post',
        [2046780049] = 'Rhodes',
        [2147354003] = 'Siska',
        [-765540529] = 'Saint Denis',
        [427683330] = 'Strawberry',
        [-1524959147] = 'Tumbleweed',
        [459833523] = 'Valentine',
        [2126321341] = 'Van Horn',
        [-872622034] = 'Wallace Station',
        [1663398575] = 'Wapiti',
    },
    -- tipo 10: distritos (usados fora das cidades)
    districts = {
        [2025841068] = 'Bayou Nwa',
        [822658194] = 'Big Valley',
        [1308232528] = 'Bluewater Marsh',
        [-108848014] = 'Cholla Springs',
        [1835499550] = 'Cumberland Forest',
        [426773653] = 'Diez Coronas',
        [-2066240242] = 'Gaptooth Ridge',
        [476637847] = 'Great Plains',
        [-120156735] = 'Grizzlies Leste',
        [1645618177] = 'Grizzlies Oeste',
        [-512529193] = 'Guarma',
        [131399519] = 'Heartlands',
        [892930832] = "Hennigan's Stead",
        [-1319956120] = 'Perdido',
        [1453836102] = 'Punta Orgullo',
        [-2145992129] = 'Rio Bravo',
        [178647645] = 'Roanoke Ridge',
        [-864275692] = 'Scarlett Meadows',
        [1684533001] = 'Tall Trees',
    },
    -- tipo 0: estados
    states = {
        [-221059932] = 'Ambarino',
        [1935063277] = 'Guarma',
        [10837344] = 'Lemoyne',
        [-1973391500] = 'West Elizabeth',
        [2045157995] = 'New Austin',
        [-1289136221] = 'New Hanover',
        [613867492] = 'Nuevo Paraíso',
        [-1247148211] = 'West Elizabeth',
        [1246494439] = 'West Elizabeth',
    },
    wilderness = 'Território Selvagem',
}

-- Armas com munição que ativam o widget. icon = arquivo em web/public/tex/items/
-- (armas sem arte própria usam a do modelo mais parecido).
Config.Weapons = {
    WEAPON_REVOLVER_CATTLEMAN = { label = 'Revólver Cattleman', icon = 'weapon_revolver_cattleman' },
    WEAPON_REVOLVER_CATTLEMAN_MEXICAN = { label = 'Revólver Cattleman Mexicano', icon = 'weapon_revolver_cattleman' },
    WEAPON_REVOLVER_DOUBLEACTION = { label = 'Revólver de Ação Dupla', icon = 'weapon_revolver_doubleaction' },
    WEAPON_REVOLVER_DOUBLEACTION_GAMBLER = { label = 'Revólver do Apostador', icon = 'weapon_revolver_doubleaction' },
    WEAPON_REVOLVER_SCHOFIELD = { label = 'Revólver Schofield', icon = 'weapon_revolver_schofield' },
    WEAPON_REVOLVER_LEMAT = { label = 'Revólver LeMat', icon = 'weapon_revolver_schofield' },
    WEAPON_REVOLVER_NAVY = { label = 'Revólver Navy', icon = 'weapon_revolver_schofield' },
    WEAPON_REVOLVER_NAVY_CROSSOVER = { label = 'Revólver Navy', icon = 'weapon_revolver_schofield' },
    WEAPON_PISTOL_VOLCANIC = { label = 'Pistola Volcanic', icon = 'weapon_pistol_volcanic' },
    WEAPON_PISTOL_M1899 = { label = 'Pistola M1899', icon = 'weapon_pistol_semiauto' },
    WEAPON_PISTOL_SEMIAUTO = { label = 'Pistola Semiautomática', icon = 'weapon_pistol_semiauto' },
    WEAPON_PISTOL_MAUSER = { label = 'Pistola Mauser', icon = 'weapon_pistol_mauser' },
    WEAPON_REPEATER_CARBINE = { label = 'Repetidora Carabina', icon = 'weapon_repeater_carbine' },
    WEAPON_REPEATER_HENRY = { label = 'Repetidora Litchfield', icon = 'weapon_repeater_henry' },
    WEAPON_REPEATER_WINCHESTER = { label = 'Repetidora Lancaster', icon = 'weapon_repeater_lancaster' },
    WEAPON_REPEATER_EVANS = { label = 'Repetidora Evans', icon = 'weapon_repeater_henry' },
    WEAPON_RIFLE_SPRINGFIELD = { label = 'Rifle Springfield', icon = 'weapon_rifle_springfield' },
    WEAPON_RIFLE_BOLTACTION = { label = 'Rifle de Ferrolho', icon = 'weapon_rifle_boltaction' },
    WEAPON_RIFLE_VARMINT = { label = 'Rifle Varmint', icon = 'weapon_rifle_varmint' },
    WEAPON_RIFLE_ELEPHANT = { label = 'Rifle Elefante', icon = 'weapon_rifle_boltaction' },
    WEAPON_SNIPERRIFLE_CARCANO = { label = 'Rifle Carcano', icon = 'weapon_sniperrifle_carcano' },
    WEAPON_SNIPERRIFLE_ROLLINGBLOCK = { label = 'Rifle Rolling Block', icon = 'weapon_sniperrifle_rollingblock' },
    WEAPON_SHOTGUN_DOUBLEBARREL = { label = 'Escopeta de Cano Duplo', icon = 'weapon_shotgun_doublebarrel' },
    WEAPON_SHOTGUN_DOUBLEBARREL_EXOTIC = { label = 'Escopeta Rara de Cano Duplo', icon = 'weapon_shotgun_doublebarrel' },
    WEAPON_SHOTGUN_SAWEDOFF = { label = 'Escopeta de Cano Serrado', icon = 'weapon_shotgun_sawedoff' },
    WEAPON_SHOTGUN_PUMP = { label = 'Escopeta de Bombeamento', icon = 'weapon_shotgun_pump' },
    WEAPON_SHOTGUN_REPEATING = { label = 'Escopeta de Repetição', icon = 'weapon_shotgun_repeating' },
    WEAPON_SHOTGUN_SEMIAUTO = { label = 'Escopeta Semiautomática', icon = 'weapon_shotgun_semiauto' },
    WEAPON_BOW = { label = 'Arco', icon = 'weapon_bow' },
    WEAPON_BOW_IMPROVED = { label = 'Arco Aprimorado', icon = 'weapon_bow' },
}

-- Textos que o Lua monta antes de enviar à interface
Config.Text = {
    grade = 'Grau %s',    -- aparece ao lado do emprego
    unknownWeapon = 'Arma',
    defaultHorseName = '', -- nome do cavalo quando nenhum script de estábulo informa (vazio = oculto)
}
