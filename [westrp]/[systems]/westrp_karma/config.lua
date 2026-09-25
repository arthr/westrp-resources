-- ====================================================================
-- WestRP Karma — Configuration
-- File: config.lua
-- ====================================================================

Config = {}

---Modo de depuração: exibe logs detalhados e formatação estendida nos consoles
Config.Debug = true

---Painel HUD de telemetria e diagnóstico em tempo real na tela (Top-Right)
---Pode ser alternado em jogo a qualquer momento através do comando /karmahud
Config.DebugHUD = true

---Pontuação moral padrão para novos personagens
Config.DefaultKarma = 0

---Duração do direito de legítima defesa em segundos após ser agredido
Config.SelfDefenseDuration = 45

---Penalidades de Karma por Agressões Não Provocadas
Config.Penalties = {
    -- Civis Inocentes
    CivilianKill = -35,       -- Assassinato direto
    CivilianKnockout = -10,   -- Nocaute / asfixia
    CivilianAssault = -5,     -- Agressão armada não-letal

    -- Autoridades da Lei (Xerifes, Guardas, Policiais)
    LawmanKill = -80,         -- Assassinato de autoridade
    LawmanKnockout = -35,     -- Nocaute contra autoridade
    LawmanAssault = -15,      -- Agressão armada contra autoridade

    -- Jogadores (PvP não provocado)
    PlayerKillUnprovoked = -120,
    PlayerKnockoutUnprovoked = -25,
    PlayerAssaultUnprovoked = -15
}

---Recompensas de Karma por Ações Positivas
Config.Rewards = {
    WantedBanditKill = 15     -- Eliminação em legítima defesa de agressor hostil
}
