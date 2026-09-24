---@class KarmaConfig
Config = {}

-- Limites universais do sistema moral
Config.MinKarma = -1000
Config.MaxKarma = 1000
Config.DefaultKarma = 0

-- Janela temporal de legítima defesa (em segundos)
-- Se um jogador A agredir B, B pode retaliar dentro dessa janela sem sofrer perda moral
Config.SelfDefenseDuration = 180

-- Persistência em lote (Unit of Work / Batch Write)
-- Intervalo em milissegundos para consolidar dados 'dirty' no oxmysql
Config.BatchInterval = 60000

-- Parâmetros de segurança e verificação física no servidor
Config.Security = {
    MaxDistance = 300.0,       -- Distância máxima permitida para tiros/agressões
    TeleportThreshold = 15.0,  -- Tolerância máxima de desync espacial entre coordenadas client e server
    EnforceFatalIntegrity = true -- Confere se a entidade atingida está de fato morta/incapacitada
}

-- Valores padrão de penalidade moral (Delta negativo)
Config.Penalties = {
    PlayerKillUnprovoked = -120,   -- Assassinato não provocado de outro jogador (PK)
    PlayerAssaultUnprovoked = -15, -- Dano injustificado contra outro jogador
    LawmanKill = -80,              -- Assassinato de autoridade/delegado (NPC ou Player)
    InnocentNpcKill = -35,         -- Assassinato de pedestre/civil NPC inocente
    InnocentNpcAssault = -5,       -- Dano ou agressão contra civil inocente
    Robbery = -40                  -- Assalto a mão armada ou roubo
}

-- Valores padrão de recompensa moral (Delta positivo)
Config.Rewards = {
    WantedBanditKill = 15,         -- Eliminar criminoso procurado / forasteiro hostil
    DeliverBounty = 50,            -- Entregar foragido à justiça
    RevivePlayer = 20,             -- Reanimar/socorrer cidadão ferido
    CommunityWork = 10             -- Atividades cívicas, caridade ou limpeza
}

-- Apresentação Visual no HUD Nativo (RDR2 DataBinding)
Config.UI = {
    UseNativeHonorBar = true,      -- Habilita a barra nativa de Honra do RDR2 via DataBinding
    HonorDisplayDuration = 4500,   -- Tempo em milissegundos que a barra de honra fica visível ao alterar o karma
    PlayNativeAudio = true,        -- Reproduz os efeitos sonoros originais do RDR2 (sino angelical vs acorde sombrio)
    NotifyBountyChange = true      -- Emite alerta quando o jogador atinge elegibilidade para caçadores de recompensa
}

-- Depuração
Config.Debug = false
