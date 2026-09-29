WestRP = WestRP or {}
WestRP.Shared = WestRP.Shared or {}
WestRP.Shared.Bridge = WestRP.Shared.Bridge or {}

-- Ponto central da fachada Bridge
-- Permite facilmente trocar ou suportar múltiplos frameworks no futuro mantendo a mesma assinatura.
WestRP.Shared.Logger.Info("BRIDGE", "Bridge inicializado para o driver: %s", WestRP.Config and WestRP.Config.Bridge or "vorp")
