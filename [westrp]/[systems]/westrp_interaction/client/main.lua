local currentPrompt = nil
local activePointKey = nil
local isProcessing = false

local InteractionModule = {}

---Abre o menu demonstrativo do Saloon usando o WestRP UI Dock Engine
local function OpenSaloonMenu()
    WestRP.Client.UI.OpenDock({
        id = 'saloon_smithfield',
        title = 'SALOON SMITHFIELD',
        tag = 'VALENTINE',
        tabs = {
            {
                id = 'drinks',
                name = 'BEBIDAS',
                items = {
                    { id = 'whiskey', label = 'Whiskey Especial', sublabel = 'Envelhecido em barril de carvalho', badge = '$ 2.50', badgeType = 'gold', description = 'Dose de destilado forte que recupera o fôlego.' },
                    { id = 'beer', label = 'Cerveja Artesanal', sublabel = 'Cerveja gelada do condado', badge = '$ 0.75', badgeType = 'gold', description = 'Uma caneca refrescante de cerveja pura.' },
                    { id = 'smoke', label = 'Permitir Fumar no Balcão', type = 'toggle', checked = true, description = 'Alterna a permissão de fumo para os clientes no balcão.' }
                }
            },
            {
                id = 'services',
                name = 'SERVIÇOS',
                items = {
                    { id = 'rounds', label = 'Rodadas para o Saloon', type = 'slider', min = 1, max = 10, value = 1, description = 'Pague rodadas para todos os presentes no estabelecimento.' },
                    {
                        id = 'special_orders',
                        label = 'Encomendas Especiais',
                        type = 'submenu',
                        description = 'Acesse produtos raros fornecidos pelo contrabando.',
                        subItems = {
                            { id = 'moonshine', label = 'Moonshine Ilegal', badge = '$ 15.00', badgeType = 'danger', danger = true, description = 'Bebida destilada clandestina com teor alcoólico violento.' },
                            { id = 'cigar', label = 'Charuto Premium', badge = '$ 5.00', badgeType = 'gold', description = 'Tabaco nobre importado de Cuba.' }
                        }
                    }
                }
            }
        },
        onSelect = function(item, tabId)
            WestRP.Shared.Logger.Info("SALOON", "Item selecionado: %s (Aba: %s)", item.label, tabId)
            WestRP.Client.UI.ShowToast("SALOON SMITHFIELD", "Você selecionou: " .. item.label, "success")
        end,
        onChange = function(item, newValue, tabId)
            WestRP.Shared.Logger.Info("SALOON", "Item alterado: %s -> %s", item.label, tostring(newValue))
            WestRP.Client.UI.ShowToast("SALOON", item.label .. ": " .. tostring(newValue), "info")
        end,
        onClose = function()
            WestRP.Shared.Logger.Info("SALOON", "Menu do Saloon encerrado.")
        end
    })
end

-- Comando para teste rápido em qualquer lugar do mapa
RegisterCommand('testdock', function()
    OpenSaloonMenu()
end, false)

function InteractionModule:OnLoad()
    WestRP.Shared.Logger.Info("INTERACTION", "Sistema de Interação Espacial carregado!")

    -- Agendamento de Tick com Sono Adaptativo Dinâmico (0.00ms quando ocioso)
    WestRP.Client.TickManager.CreateTask('spatial_interaction_loop', function(task)
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)

        local closestKey = nil
        local closestDist = 999999.0
        local closestPoint = nil

        for key, point in pairs(Config.Points) do
            local dist = #(playerCoords - point.coords)
            if dist < closestDist then
                closestDist = dist
                closestKey = key
                closestPoint = point
            end
        end

        -- Lógica de Sono Dinâmico (Frame Budget)
        if closestDist > 30.0 then
            -- Jogador longe de qualquer ponto: dorme 1.5 segundo
            task:SetInterval(1500)
            if currentPrompt then
                currentPrompt:Delete()
                currentPrompt = nil
                activePointKey = nil
            end
            return
        elseif closestDist > (closestPoint and closestPoint.radius or 2.0) then
            -- Jogador se aproximando: dorme 300ms
            task:SetInterval(300)
            if currentPrompt then
                currentPrompt:Delete()
                currentPrompt = nil
                activePointKey = nil
            end
            return
        end

        -- Jogador dentro da zona de interação (< radius): atualiza a cada frame (Wait 0)
        task:SetInterval(0)

        -- Se o menu estiver aberto, oculta o prompt
        if WestRP.Client.UI.IsDockOpen() then
            if currentPrompt then
                currentPrompt:SetVisible(false)
            end
            return
        end

        -- Inicializa o prompt se ainda não existir para este ponto
        if not currentPrompt or activePointKey ~= closestKey then
            if currentPrompt then currentPrompt:Delete() end
            activePointKey = closestKey

            currentPrompt = WestRP.Client.PromptManager.Create({
                text = closestPoint.label,
                control = closestPoint.control,
                hold = closestPoint.hold,
                holdTime = closestPoint.holdTime or 1000
            })
        else
            currentPrompt:SetVisible(true)
        end

        -- Checa se o jogador concluiu o acionamento do prompt
        if currentPrompt and currentPrompt:IsCompleted() and not isProcessing then
            isProcessing = true
            WestRP.Shared.Logger.Debug("INTERACTION", "Prompt acionado para o ponto: %s", closestKey)

            if closestPoint.actionType == "dock_menu" then
                OpenSaloonMenu()
            else
                -- Solicita autorização e execução autoritativa no servidor
                TriggerServerEvent('westrp_interaction:server:interact', closestKey)
            end

            Wait(1000)
            isProcessing = false
        end
    end)
end

function InteractionModule:OnUnload()
    WestRP.Shared.Logger.Info("INTERACTION", "Descarregando sistema de interação...")
    WestRP.Client.TickManager.RemoveTask('spatial_interaction_loop')
    if currentPrompt then
        currentPrompt:Delete()
        currentPrompt = nil
    end
    activePointKey = nil
    WestRP.Client.UI.CloseDock()
end

AddEventHandler('onResourceStart', function(resName)
    if resName == GetCurrentResourceName() then
        InteractionModule:OnLoad()
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        InteractionModule:OnUnload()
    end
end)

CreateThread(function()
    InteractionModule:OnLoad()
end)
