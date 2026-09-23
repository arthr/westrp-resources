RegisterNetEvent('westrp_interaction:server:interact', function(pointKey)
    local src = source

    -- 1. Validação de existência da configuração do ponto
    local point = Config.Points and Config.Points[pointKey]
    if not point then
        WestRP.Shared.Logger.Warn("INTERACTION", "Player %s tentou interagir com ponto inexistente: %s", src, tostring(pointKey))
        return
    end

    -- 2. Validação física autoritativa de distância (Anti-Noclip / Teleport)
    local maxAllowedDistance = point.radius + 1.5
    if not WestRP.Server.Security.ValidateDistance(src, point.coords, maxAllowedDistance) then
        return
    end

    -- 3. Validação de Rate-Limit (Anti-Spam / Anti-Macro)
    if not WestRP.Server.Security.CheckRateLimit(src, 'interact_' .. pointKey, point.cooldown) then
        WestRP.Shared.Bridge.Player.Notify(src, "Você precisa aguardar antes de interagir novamente!", 3000)
        return
    end

    -- 4. Validação de Estado (Player Vivo)
    if not WestRP.Server.Security.IsPlayerAlive(src) then
        return
    end

    -- 5. Obtenção de dados do personagem via Bridge desacoplado
    local character = WestRP.Shared.Bridge.Player.GetCharacter(src)
    if not character then
        WestRP.Shared.Logger.Warn("INTERACTION", "Personagem não carregado para o player %s", src)
        return
    end

    -- 6. Execução da Ação
    WestRP.Shared.Logger.Info("INTERACTION", "Interação autorizada: Player %s (%s %s) no ponto '%s'", src, character.firstname, character.lastname, pointKey)

    -- Feedback ao jogador
    WestRP.Shared.Bridge.Player.Notify(src, point.rewardMessage or "Ação concluída!", 4000)
end)
