WestRP = WestRP or {}
WestRP.Config = {}

-- Modo Debug (exibe logs detalhados e medições no console)
WestRP.Config.Debug = true

-- Nível de log padrão: "DEBUG", "INFO", "WARN", "ERROR"
WestRP.Config.LogLevel = "DEBUG"

-- Tolerância padrão de distância vetorial (em metros) para validações de segurança
WestRP.Config.DistanceTolerance = 3.5

-- Cooldown padrão em milissegundos para o rate-limiter de eventos do servidor
WestRP.Config.DefaultRateLimitMs = 800

-- Framework alvo do Bridge
WestRP.Config.Bridge = "vorp"
