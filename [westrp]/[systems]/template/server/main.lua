local TemplateModuleServer = {}

function TemplateModuleServer:OnLoad()
    WestRP.Shared.Logger.Info("TEMPLATE", "Módulo carregado com sucesso no servidor!")

    -- Exemplo de registro de Callback seguro
    WestRP.Server.Callback.Register('westrp_template:requestData', function(source, cb, payload)
        -- 1. Validação de Rate-Limit
        if not WestRP.Server.Security.CheckRateLimit(source, 'template_request', Config.Cooldown) then
            cb({ success = false, message = "Aguarde antes de tentar novamente!" })
            return
        end

        -- 2. Obtenção de dados do personagem via Bridge (Zero VORP coupling)
        local character = WestRP.Shared.Bridge.Player.GetCharacter(source)
        if not character then
            cb({ success = false, message = "Personagem não encontrado!" })
            return
        end

        cb({
            success = true,
            message = "Olá, " .. character.firstname .. " " .. character.lastname,
            money = character.money
        })
    end)
end

CreateThread(function()
    TemplateModuleServer:OnLoad()
end)
