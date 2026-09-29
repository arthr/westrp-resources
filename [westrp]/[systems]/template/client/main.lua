local TemplateModule = {}

function TemplateModule:OnLoad()
    WestRP.Shared.Logger.Info("TEMPLATE", "Módulo carregado com sucesso no cliente!")

    -- Exemplo de uso do TickManager com intervalo adaptativo dinâmico (0.00ms idle)
    WestRP.Client.TickManager.CreateTask('template_task_example', function(task)
        -- Regra de sono adaptativo:
        -- Se nenhuma ação relevante estiver acontecendo por perto, dorme 1.5s
        task:SetInterval(1500)
    end)
end

function TemplateModule:OnUnload()
    WestRP.Shared.Logger.Info("TEMPLATE", "Limpando recursos do módulo no cliente...")
    WestRP.Client.TickManager.RemoveTask('template_task_example')
    WestRP.Client.PromptManager.DeleteAll()
end

AddEventHandler('onResourceStart', function(resName)
    if resName == GetCurrentResourceName() then
        TemplateModule:OnLoad()
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        TemplateModule:OnUnload()
    end
end)

CreateThread(function()
    TemplateModule:OnLoad()
end)
