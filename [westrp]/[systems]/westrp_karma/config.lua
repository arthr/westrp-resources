---@class KarmaConfig
Config = {}

-- Limites universais da escala moral
Config.MinKarma = -1000
Config.MaxKarma = 1000
Config.DefaultKarma = 0

-- Janela temporal de legítima defesa (em segundos)
-- Se uma entidade agredir o jogador, ele tem essa janela para revidar sem punição moral
Config.SelfDefenseDuration = 45

-- Persistência em lote (Unit of Work / Batch Write)
-- Intervalo em milissegundos para consolidar dados 'dirty' no oxmysql
Config.BatchInterval = 60000

-- Valores padrão de penalidade moral (Delta negativo para atitudes não provocadas)
Config.Penalties = {
    -- PvP (Jogador vs Jogador)
    PlayerKillUnprovoked = -120,   -- Assassinato não provocado de outro jogador (PK)
    PlayerKnockoutUnprovoked = -25,-- Nocaute injustificado de outro jogador
    PlayerAssaultUnprovoked = -15, -- Agressão corporal injustificada contra outro jogador

    -- Homens da Lei / Autoridades (Xerifes, Policiais, Guardas)
    LawmanKill = -80,              -- Assassinato de homem da lei
    LawmanKnockout = -35,          -- Nocaute / asfixia contra homem da lei
    LawmanAssault = -15,           -- Agressão armada ou corporal contra autoridade

    -- Civis Inocentes
    CivilianKill = -35,            -- Assassinato de cidadão inocente
    CivilianKnockout = -10,        -- Nocaute / asfixia de civil inocente
    CivilianAssault = -5,          -- Agressão menor contra civil inocente

    -- Crimes Gerais
    Robbery = -40                  -- Assalto a mão armada ou roubo
}

-- Aliases de compatibilidade
Config.Penalties.InnocentNpcKill = Config.Penalties.CivilianKill
Config.Penalties.InnocentNpcKnockout = Config.Penalties.CivilianKnockout
Config.Penalties.InnocentNpcAssault = Config.Penalties.CivilianAssault

-- Valores padrão de recompensa moral (Delta positivo)
Config.Rewards = {
    WantedBanditKill = 15, -- Eliminar criminoso procurado / forasteiro hostil
    DeliverBounty = 50,    -- Entregar foragido à justiça
    RevivePlayer = 20,     -- Reanimar/socorrer cidadão ferido
    CommunityWork = 10     -- Atividades cívicas, caridade ou limpeza
}

-- Apresentação Visual no HUD Nativo (Desativado: Foco 100% em Logs e Depuração)
Config.UI = {
    ShowNotifications = false,     -- Desativa avisos e banners na tela do jogador
    PlayNativeAudio = false        -- Desativa efeitos sonoros no cliente
}

-- Depuração e Diagnóstico
Config.Debug = true
