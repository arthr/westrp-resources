local currentPrompt = nil
local activePointKey = nil
local isProcessing = false

local InteractionModule = {}

---Abre o menu demonstrativo do Saloon usando o WestRP UI Dock Engine
local function OpenSaloonMenu()
    local UI = (WestRP and WestRP.Client and WestRP.Client.UI)
    if not (UI and UI.OpenDock) then
        UI = exports['westrp_ui']
    end
    UI.OpenDock({
        id = 'saloon_smithfield',
        title = 'SALOON SMITHFIELD',
        tag = 'VALENTINE • FRONTIER',
        tabs = {
            {
                id = 'drinks',
                name = 'BEBIDAS & DESTILADOS',
                items = {
                    { id = 'consumable_alcohol_bourbon', label = 'Bourbon Envelhecido', sublabel = 'Dose pura de carvalho americano', badge = '$ 3.50', badgeType = 'gold', description = 'Destilado forte e aromático que recupera a estamina do cavaleiro.' },
                    { id = 'consumable_alcohol_beer_pint_amber', label = 'Caneca de Cerveja Âmbar', sublabel = 'Cerveja artesanal gelada do condado', badge = '$ 1.00', badgeType = 'gold', description = 'Uma caneca generosa servida em estanho direto do barril da adega.' },
                    { id = 'consumable_alcohol_bottle_brandy', label = 'Garrafa de Conhaque Fino', sublabel = 'Importado de Saint Denis', badge = '$ 7.50', badgeType = 'gold', description = 'Bebida destilada refinada para cavalheiros e ocasiões solenes.' },
                    { id = 'coffee_pot', label = 'Café Preto de Fogueira', sublabel = 'Fresco, quente e revigorante', badge = '$ 0.50', badgeType = 'gold', description = 'Café passado forte na hora para dispersar o cansaço e o frio.' }
                }
            },
            {
                id = 'provisions',
                name = 'PROVISÕES & FUMO',
                items = {
                    { id = 'consumable_meat_prime_beef_wild_mint_cooked', label = 'Bife de Primeira com Menta', sublabel = 'Carne nobre assada na brasa', badge = '$ 4.50', badgeType = 'gold', description = 'Corte suculento grelhado na brasa que restaura toda a energia vital.' },
                    { id = 'consumable_bread6', label = 'Pão Rústico de Centeio', sublabel = 'Fornada do dia com manteiga fresca', badge = '$ 1.20', badgeType = 'gold', description = 'Fatia generosa de pão de forno rústico tradicional da fronteira.' },
                    { id = 'cigar1', label = 'Charuto Premium Havano', sublabel = 'Tabaco puro enrolado à mão', badge = '$ 5.00', badgeType = 'gold', description = 'Charuto de aroma nobre e amadeirado apreciado por homens de negócio.' },
                    { id = 'cigar_box_preimium', label = 'Caixa Lacrada de Charutos', sublabel = 'Caixa de cedro contendo 10 unidades', badge = '$ 22.00', badgeType = 'gold', description = 'Lote nobre para grandes apreciadores ou revenda de alto valor.' }
                }
            },
            {
                id = 'services',
                name = 'SERVIÇOS & GESTÃO',
                items = {
                    { id = 'rounds', label = 'Pagar Rodada Geral', type = 'slider', min = 1, max = 10, value = 1, description = 'Pague uma rodada de cerveja gelada para todos os presentes no estabelecimento.' },
                    { id = 'ambiance_tune', label = 'Música do Pianista', type = 'slider', options = {'Silêncio', 'Ragtime Animado', 'Valsa Lenta', 'Balada Western'}, valueIndex = 1, description = 'Comande o pianista no canto do Saloon para mudar a melodia ambiente.' },
                    { id = 'smoke_policy', label = 'Permitir Fumo no Balcão', type = 'toggle', checked = true, description = 'Alterna a tolerância de cinzas e fumo de charuto para a clientela no balcão.' },
                    {
                        id = 'special_orders',
                        label = 'Mercadorias Clandestinas',
                        type = 'submenu',
                        description = 'Acesse itens ilegais fornecidos pelo contrabando da meia-noite.',
                        subItems = {
                            { id = 'consumable_alcohol_moonshine_apple', label = 'Moonshine de Maçã Ilegal', badge = '$ 18.00', badgeType = 'danger', danger = true, description = 'Bebida clandestina com teor alcoólico violento proibido pelas autoridades.' },
                            { id = 'lockpick', label = 'Gazua de Fechadura', badge = '$ 12.00', badgeType = 'danger', danger = true, description = 'Ferramenta precisa de aço fino para violar fechaduras e trincos.' },
                            { id = 'weapon_thrown_molotov', label = 'Garrafa Incendiária Caseira', badge = '$ 15.00', badgeType = 'danger', danger = true, description = 'Garrafa inflamável com pavio embebido em querosene para desordem.' }
                        }
                    },
                    { id = 'bath_service', label = 'Banho Quente Deluxe', badge = 'OCUPADO', badgeType = 'off', disabled = true, description = 'As tinas de imersão estão ocupadas por outros hóspedes no momento.' },
                    { id = 'sheriff_alert', label = 'Disparar Alerta ao Xerife', badge = 'ALERTA', badgeType = 'danger', danger = true, description = 'Aciona um chamado discreto de perturbação da ordem ao gabinete da lei.' }
                }
            }
        },
        onSelect = function(item, tabId)
            WestRP.Shared.Logger.Info("SALOON", "Item selecionado: %s (Aba: %s)", item.label or item.id, tabId)
            WestRP.Client.UI.ShowToast("SALOON SMITHFIELD", "Você selecionou: " .. (item.label or item.id), "success")
        end,
        onChange = function(item, newValue, tabId)
            WestRP.Shared.Logger.Info("SALOON", "Item alterado: %s -> %s", item.label or item.id, tostring(newValue))
            WestRP.Client.UI.ShowToast("SALOON SMITHFIELD", (item.label or item.id) .. ": " .. tostring(newValue), "info")
        end,
        onClose = function()
            WestRP.Shared.Logger.Info("SALOON", "Menu do Saloon encerrado.")
        end
    })
end

-- Comando para teste rápido do Dock em qualquer lugar do mapa
RegisterCommand('testdock', function()
    OpenSaloonMenu()
end, false)

---Abre o painel demonstrativo de Oficina / Bancada usando o WestRP UI Panel Engine
local function OpenWorkshopPanel()
    local UI = (WestRP and WestRP.Client and WestRP.Client.UI)
    if not (UI and UI.OpenPanel) then
        UI = exports['westrp_ui']
    end
    UI.OpenPanel({
        id = 'valentine_workshop',
        title = 'OFICINA & ARMAZÉM DE VALENTINE',
        tag = 'ESTABELECIMENTO COMERCIAL & ARTESÃO',
        subtitle = 'Saldo em Caixa: $ 580.00',
        ctaLabel = 'EXECUTAR TRANSAÇÃO',
        tabs = {
            {
                id = 'weapons',
                label = 'Vitrine de Armamentos',
                badge = 'VITRINE',
                viewType = 'grid',
                items = {
                    { id = 'weapon_thrown_tomahawk', title = 'Tomahawk de Caça', subtitle = 'Arma de arremesso forjada em aço carbono com peso balanceado.', price = 35.0, stock = 8, badge = 'POPULAR', badgeType = 'gold' },
                    { id = 'weapon_melee_hammer', title = 'Martelo Pesado de Combate', subtitle = 'Ferramenta e arma de impacto demolidora para ferraria e defesa.', price = 45.0, stock = 4, badge = 'PESADO', badgeType = 'gold' },
                    { id = 'weapon_thrown_molotov', title = 'Coquetel Molotov Incendiário', subtitle = 'Garrafa inflamável com pavio embebido em querosene de lampião.', price = 25.0, stock = 12, badge = 'PERIGO', badgeType = 'danger' },
                    { id = 'weapon_lasso_reinforced', title = 'Laço Reforçado de Couro', subtitle = 'Corda de couro cru entrelaçado com alta resistência à tração.', price = 50.0, stock = 5, badge = 'ROBUSTO', badgeType = 'gold' },
                    { id = 'weapon_fishingrod_master', title = 'Vara de Pesca Profissional', subtitle = 'Vara flexível de bambu tratado com molinete de precisão para rios bravios.', price = 38.0, stock = 6 },
                    { id = 'weapon_kit_binoculars_improved', title = 'Binóculos Militares', subtitle = 'Lentes prismáticas de longo alcance para patrulha e rastreamento.', price = 65.0, stock = 3, badge = 'ÓTICA', badgeType = 'gold' },
                    { id = 'tool_hatchet', title = 'Machadinha de Lenhador', subtitle = 'Machado compacto para extração florestal de madeira e sobrevivência.', price = 22.0, stock = 10 },
                    { id = 'tool_heavy_pickaxe', title = 'Picareta de Mineração', subtitle = 'Ponta de aço temperado indicada para pedreiras densas e veios auríferos.', price = 42.0, stock = 7 }
                }
            },
            {
                id = 'forge',
                label = 'Bancada de Forja',
                badge = 'BANCADA',
                viewType = 'craft',
                items = {
                    {
                        id = 'tool_resource_knife',
                        title = 'Faca de Caça Rústica',
                        subtitle = 'Lâmina afiada para esfolar animais de grande porte e corte geral.',
                        requirements = {
                            { item = 'resource_iron_dirty', label = 'Minério de Ferro', current = 6, required = 2 },
                            { item = 'resource_coal', label = 'Carvão Mineral', current = 12, required = 1 },
                            { item = 'lumber_pine_wood_plank', label = 'Empunhadura de Madeira', current = 4, required = 1 }
                        }
                    },
                    {
                        id = 'ammo_revolver_split_point',
                        title = 'Munição .45 Dum-Dum (x12)',
                        subtitle = 'Cartuchos perfurantes com ponta entalhada para maior expansão.',
                        requirements = {
                            { item = 'brick', label = 'Chumbo Fundido', current = 8, required = 2 },
                            { item = 'acid', label = 'Pólvora Seca', current = 5, required = 2 },
                            { item = 'tool_chisel', label = 'Cinzel de Entalhe', current = 1, required = 1 }
                        }
                    },
                    {
                        id = 'lockpick',
                        title = 'Gazua Reforçada de Aço',
                        subtitle = 'Ferramenta precisa com haste fina para destrancar fechaduras.',
                        requirements = {
                            { item = 'tool_hammer', label = 'Martelo de Forjar', current = 1, required = 1 },
                            { item = 'resource_iron_dirty', label = 'Haste de Ferro', current = 4, required = 2 }
                        }
                    },
                    {
                        id = 'tool_repair_kit',
                        title = 'Kit de Limpeza & Manutenção',
                        subtitle = 'Conjunto de escovas e óleos para preservar o funcionamento das armas.',
                        requirements = {
                            { item = 'gunoil3', label = 'Óleo de Armamento', current = 3, required = 1 },
                            { item = 'washcloth', label = 'Flanela Limpa', current = 6, required = 2 }
                        }
                    },
                    {
                        id = 'campfire',
                        title = 'Kit de Acampamento & Fogueira',
                        subtitle = 'Fogueira portátil com estacas de apoio para assar carnes em viagens.',
                        requirements = {
                            { item = 'lumber_cedar_hardwood', label = 'Lenha de Cedro', current = 15, required = 5 },
                            { item = 'match', label = 'Fósforos Sulfúricos', current = 2, required = 1 }
                        }
                    }
                }
            },
            {
                id = 'supplies',
                label = 'Armazém Geral',
                badge = 'ARMAZÉM',
                viewType = 'grid',
                items = {
                    { id = 'consumable_coffee', title = 'Café Moído Torrado', subtitle = 'Pacote com café puro para infusão em caneca no acampamento.', price = 1.50, stock = 20, badge = 'ENERGIA', badgeType = 'gold' },
                    { id = 'consumable_meat_venison_cooked', title = 'Carne de Cervo Assada', subtitle = 'Corte farto defumado com sal marinho e especiarias da floresta.', price = 4.00, stock = 15 },
                    { id = 'consumable_bread6', title = 'Pão Caseiro de Centeio', subtitle = 'Pão fresco assado na madrugada pelos colonos locais.', price = 1.20, stock = 30 },
                    { id = 'consumable_med_herbal_tonic', title = 'Tônico Medicinal Herbal', subtitle = 'Xarope reconstituinte feito de ervas amargas da pradaria.', price = 8.00, stock = 8, badge = 'SAÚDE', badgeType = 'gold' },
                    { id = 'torch_smoker', title = 'Tocha Noturna Embebida', subtitle = 'Tocha de estopa com querosene para iluminar cavernas e minas.', price = 2.50, stock = 16 },
                    { id = 'horse_shoe', title = 'Jogo de Ferraduras de Ferro', subtitle = 'Quatro ferraduras batidas para proteger os cascos da sua montaria.', price = 12.00, stock = 6 }
                }
            },
            {
                id = 'ledger',
                label = 'Livro-Razão de Vendas',
                badge = 'LIVRO-RAZÃO',
                viewType = 'table',
                columns = {
                    { key = 'code', label = 'Nº REGISTRO', width = '12%', align = 'center' },
                    { key = 'date', label = 'DATA', width = '10%' },
                    { key = 'item', label = 'MERCADORIA / SERVIÇO', width = '34%' },
                    { key = 'client', label = 'CIDADÃO', width = '20%' },
                    { key = 'amount', label = 'VALOR TOTAL', width = '12%', align = 'right' },
                    { key = 'status', label = 'SITUAÇÃO', width = '12%', align = 'center', type = 'pill' }
                },
                rows = {
                    { id = 'l1', code = '#201', date = '23/09', item = 'Compra: Tomahawk de Caça (x2)', client = 'Arthur Morgan', amount = '$ 70.00', status = 'CONCLUÍDO', status_type = 'on' },
                    { id = 'l2', code = '#202', date = '23/09', item = 'Reparo: Cano de Revólver Cattleman', client = 'John Marston', amount = '$ 7.50', status = 'CONCLUÍDO', status_type = 'on' },
                    { id = 'l3', code = '#203', date = '23/09', item = 'Encomenda: 50x Balas .45 Dum-Dum', client = 'Micah Bell', amount = '$ 25.00', status = 'PENDENTE', status_type = 'off' },
                    { id = 'l4', code = '#204', date = '22/09', item = 'Fornecimento: 20x Barras de Ferro', client = 'Mineradora Annesburg', amount = '$ 60.00', status = 'PAGO', status_type = 'gold' },
                    { id = 'l5', code = '#205', date = '22/09', item = 'Reparo: Molinete Vara de Pesca', client = 'Hosea Matthews', amount = '$ 14.00', status = 'CONCLUÍDO', status_type = 'on' },
                    { id = 'l6', code = '#206', date = '21/09', item = 'Pedido Especial: Lote Querosene', client = 'Bill Williamson', amount = '$ 32.00', status = 'CANCELADO', status_type = 'danger' }
                }
            },
            {
                id = 'queue',
                label = 'Fila de Produção',
                badge = 'PRODUÇÃO',
                viewType = 'queue',
                items = {
                    {
                        id = 'job_1',
                        item = 'tool_resource_knife',
                        title = 'Faca de Caça Rústica',
                        subtitle = 'Lote de ferramentas de corte em produção na forja',
                        totalQty = 5,
                        completedQty = 2,
                        durationPerUnit = 8,
                        remainingTime = 24,
                        totalDuration = 40,
                        status = 'in_progress'
                    },
                    {
                        id = 'job_2',
                        item = 'ammo_revolver_split_point',
                        title = 'Munição .45 Dum-Dum (x12)',
                        subtitle = 'Aguardando liberação do molde e resfriamento do chumbo',
                        totalQty = 3,
                        completedQty = 0,
                        durationPerUnit = 6,
                        remainingTime = 18,
                        totalDuration = 18,
                        status = 'queued'
                    },
                    {
                        id = 'job_3',
                        item = 'lockpick',
                        title = 'Gazua Reforçada de Aço',
                        subtitle = 'Lote finalizado pronto para retirada na bancada',
                        totalQty = 2,
                        completedQty = 2,
                        durationPerUnit = 5,
                        remainingTime = 0,
                        totalDuration = 10,
                        status = 'completed'
                    }
                }
            }
        },
        onAction = function(action, item, tabId, qty)
            local count = qty or 1
            local itemName = item.title or item.label or item.item or item.desc or item.id or "Item"
            local totalPrice = (item.price and (item.price * count)) or 0

            if action == 'collect_job' then
                WestRP.Shared.Logger.Info("PANEL", "Coleta de Produção: %s (x%d) retirado da bancada!", itemName, count)
                WestRP.Client.UI.ShowToast("PRODUÇÃO CONCLUÍDA", string.format("Você retirou da bancada: %s (x%d)!", itemName, count), "success", 4000)
            elseif action == 'cancel_job' then
                WestRP.Shared.Logger.Info("PANEL", "Cancelamento de Produção: Lote de %s cancelado.", itemName)
                WestRP.Client.UI.ShowToast("PRODUÇÃO CANCELADA", string.format("Lote cancelado: %s", itemName), "alert", 3500)
            elseif tabId == 'weapons' or tabId == 'supplies' then
                WestRP.Shared.Logger.Info("PANEL", "Transação Comercial: Compra de %s (x%d) por $ %.2f", itemName, count, totalPrice)
                WestRP.Client.UI.ShowToast("OFICINA VALENTINE", string.format("Compra realizada: %s (x%d) - Total: $ %.2f", itemName, count, totalPrice), "success", 4000)
            elseif tabId == 'forge' or action == 'craft' then
                WestRP.Shared.Logger.Info("PANEL", "Bancada de Forja: Enviado %s (x%d) para a fila de produção!", itemName, count)
                WestRP.Client.UI.ShowToast("FILA DE PRODUÇÃO", string.format("Lote enviado para forja: %s (x%d)! Acompanhe na aba Fila de Produção.", itemName, count), "info", 4500)
            elseif tabId == 'ledger' then
                WestRP.Shared.Logger.Info("PANEL", "Livro-Razão: Inspecionado %s (Cliente: %s)", item.code or "Item", item.client or "N/A")
                WestRP.Client.UI.ShowToast("LIVRO-RAZÃO", string.format("Registro aberto: %s (%s)", item.code or "", item.item or ""), "info", 3500)
            else
                WestRP.Shared.Logger.Info("PANEL", "Ação executada: %s (x%d)", itemName, count)
                WestRP.Client.UI.ShowToast("OFICINA", itemName .. " (x" .. tostring(count) .. ")", "info", 3500)
            end
        end,
        onClose = function()
            WestRP.Shared.Logger.Info("PANEL", "Painel da oficina fechado.")
        end
    })
end

-- Comando para teste rápido do Panel de Alta Interatividade
RegisterCommand('testpanel', function()
    OpenWorkshopPanel()
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
    WestRP.Client.UI.ClosePanel()
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
