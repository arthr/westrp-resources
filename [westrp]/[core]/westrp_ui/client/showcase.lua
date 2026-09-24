-- ============================================================================
-- WESTRP UI — SHOWCASE & COMPONENT TEST SUITE (PLAYGROUND)
-- Permite simular, inspecionar e testar 100% dos componentes criados no motor.
-- ============================================================================

local function LogShowcase(action, data)
    print(string.format("^3[WestRP UI Showcase]^7 Ação: ^2%s^7 | Dados: %s", action, json.encode(data or {})))
end

-- ============================================================================
-- 1. SHOWCASE: DOCK LATERAL (ROCKSTAR 350px / TECLADO & CÂMERA LIVRE)
-- ============================================================================
function OpenShowcaseDock()
    OpenDock({
        id = 'showcase_dock',
        title = 'SHOWCASE DOCK ENGINE',
        tag = 'SISTEMA DE TESTE • RDR2',
        keepInput = true,
        tabs = {
            {
                id = 'tab_controls',
                name = 'CONTROLES BÁSICOS',
                items = {
                    {
                        id = 'btn_normal',
                        label = 'Ação Padrão (Button)',
                        description = 'Item padrão com disparo de evento ao pressionar [ENTER].'
                    },
                    {
                        id = 'btn_gold_badge',
                        label = 'Bourbon Importado',
                        badge = '$ 15.00',
                        badgeType = 'gold',
                        description = 'Item com badge de preço dourado no padrão Rockstar.'
                    },
                    {
                        id = 'btn_green_badge',
                        label = 'Vínculo com Estábulo',
                        badge = 'ATIVO',
                        badgeType = 'on',
                        description = 'Item com badge de status positivo verde esmeralda.'
                    },
                    {
                        id = 'btn_danger',
                        label = 'Disparar Alarme Geral',
                        badge = 'PERIGO',
                        badgeType = 'danger',
                        danger = true,
                        description = 'Ação crítica com destaque em carmesim para operações irreversíveis.'
                    },
                    {
                        id = 'btn_disabled',
                        label = 'Cavalo Puro-Sangue',
                        badge = 'ESGOTADO',
                        badgeType = 'off',
                        disabled = true,
                        description = 'Item desabilitado que não permite seleção nem disparo de callback.'
                    },
                    {
                        id = 'sep_controls',
                        label = 'INTERRUPTORES & SLIDERS',
                        type = 'separator'
                    },
                    {
                        id = 'toggle_smoke',
                        label = 'Permitir Fumar no Balcão',
                        type = 'toggle',
                        checked = true,
                        description = 'Interruptor binário On/Off com som tátil de clique.'
                    },
                    {
                        id = 'slider_stepper',
                        label = 'Quantidade por Rodada',
                        type = 'slider',
                        min = 1,
                        max = 10,
                        step = 1,
                        value = 3,
                        description = 'Slider numérico navegável com as setas horizontais ◄ e ►.'
                    },
                    {
                        id = 'slider_options',
                        label = 'Melodia do Pianista',
                        type = 'slider',
                        options = { 'Silêncio', 'Ragtime Animado', 'Valsa do Saloon', 'Balada Western' },
                        valueIndex = 2,
                        description = 'Slider com lista textual pré-definida de opções.'
                    }
                }
            },
            {
                id = 'tab_submenus',
                name = 'SUBMENUS & NAVEGAÇÃO',
                items = {
                    {
                        id = 'sub_contraband',
                        label = 'Mercadorias Clandestinas',
                        type = 'submenu',
                        description = 'Acesse o catálogo de itens ilegais com breadcrumb nativo.',
                        subItems = {
                            {
                                id = 'item_moonshine',
                                label = 'Moonshine Destilado',
                                badge = '$ 22.00',
                                badgeType = 'danger',
                                danger = true,
                                description = 'Bebida de alto teor alcoólico fabricada na calada da noite.'
                            },
                            {
                                id = 'item_lockpick',
                                label = 'Gazua Reforçada',
                                badge = '$ 8.50',
                                badgeType = 'gold',
                                description = 'Ferramenta clandestina para abrir fechaduras de residências.'
                            },
                            {
                                id = 'sub_explosives',
                                label = 'Explosivos & Detonadores',
                                type = 'submenu',
                                description = 'Submenu de segundo nível hierárquico.',
                                subItems = {
                                    {
                                        id = 'dynamite',
                                        label = 'Dinamite Volátil',
                                        badge = '$ 35.00',
                                        badgeType = 'danger',
                                        danger = true,
                                        description = 'Explosivo perigoso com pavio de queima rápida.'
                                    }
                                }
                            }
                        }
                    },
                    {
                        id = 'sub_services',
                        label = 'Serviços do Estabelecimento',
                        type = 'submenu',
                        description = 'Acesse os serviços de quarto e higiene pessoal.',
                        subItems = {
                            { id = 'bath_service', label = 'Banho Quente Completo', badge = '$ 2.00', badgeType = 'gold', description = 'Recupera totalmente os núcleos de vida e fôlego.' },
                            { id = 'hair_cut', label = 'Aparar Barba e Cabelo', badge = '$ 1.50', badgeType = 'gold', description = 'Serviço de barbearia higiênica.' }
                        }
                    }
                }
            }
        },
        onSelect = function(item, tabId)
            LogShowcase('DOCK_SELECT', { item = item.id, label = item.label, tab = tabId })
            ShowToast("DOCK INTERACTION", "Selecionado: " .. (item.label or item.id), "success", 3000)
        end,
        onChange = function(item, newValue, tabId)
            LogShowcase('DOCK_CHANGE', { item = item.id, value = newValue, tab = tabId })
            ShowToast("VALOR ALTERADO", item.label .. " = " .. tostring(newValue), "info", 2500)
        end,
        onClose = function()
            LogShowcase('DOCK_CLOSE', { status = 'closed' })
            ShowToast("DOCK", "Menu lateral encerrado com sucesso.", "alert", 2000)
        end
    })
end

-- ============================================================================
-- 2. SHOWCASE: PANEL CENTRAL (1040px MODAL / 6 MODOS)
-- ============================================================================
function OpenShowcasePanel(targetTabId)
    OpenPanel({
        id = 'showcase_panel',
        title = 'CENTRAL MULTIMODAL DE COMPONENTES',
        tag = 'WESTRP DESIGN SYSTEM • SHOWCASE',
        subtitle = 'Saldo Disponível: $ 1.450,00',
        ctaLabel = 'CONFIRMAR OPERAÇÃO',
        brand = {
            name = 'WESTRP FRAMEWORK',
            badge = 'COMPONENT PLAYGROUND'
        },
        operator = {
            name = 'Arthur Morgan',
            role = 'Desenvolvedor / Tester',
            onDuty = true
        },
        tabs = {
            -- ABA 1: GRID (Vitrine Comercial / Loja)
            {
                id = 'grid_showcase',
                label = 'Vitrine (Grid)',
                icon = 'fas fa-store',
                badge = 'LOJA',
                viewType = 'grid',
                pageSize = 6,
                filters = {
                    { id = 'all', label = 'Todos os Produtos', default = true },
                    { id = 'weapons', label = 'Armamentos', key = 'category', value = 'weapons' },
                    { id = 'tools', label = 'Ferramentas', key = 'category', value = 'tools' },
                    { id = 'provisions', label = 'Provisões', key = 'category', value = 'provisions' }
                },
                items = {
                    {
                        id = 'weapon_thrown_tomahawk',
                        title = 'Tomahawk de Caça',
                        subtitle = 'Lâmina de aço temperado com empunhadura em couro cru.',
                        category = 'weapons',
                        price = 35.0,
                        stock = 8,
                        badge = 'POPULAR',
                        badgeType = 'gold'
                    },
                    {
                        id = 'weapon_melee_knife',
                        title = 'Faca Bowie Artesanal',
                        subtitle = 'Lâmina afiada para esfolar caças e combate corpo-a-corpo.',
                        category = 'weapons',
                        price = 18.5,
                        stock = 15,
                        badge = 'NOVO',
                        badgeType = 'green'
                    },
                    {
                        id = 'weapon_thrown_molotov',
                        title = 'Coquetel Incendiário',
                        subtitle = 'Garrafa com óleo mineral inflamável e pavio de estopa.',
                        category = 'weapons',
                        price = 45.0,
                        stock = 5,
                        badge = 'PERIGO',
                        badgeType = 'danger'
                    },
                    {
                        id = 'tool_resource_pickaxe',
                        title = 'Picareta de Minerador',
                        subtitle = 'Ferramenta reforçada para extração de rochas e minérios.',
                        category = 'tools',
                        price = 22.0,
                        stock = 10,
                        badge = 'ROBUSTO',
                        badgeType = 'gold'
                    },
                    {
                        id = 'consumable_coffee',
                        title = 'Café Moído Forte',
                        subtitle = 'Provisão energética que renova completamente a estamina.',
                        category = 'provisions',
                        price = 1.25,
                        stock = 40,
                        badge = 'POPULAR',
                        badgeType = 'gold'
                    },
                    {
                        id = 'consumable_meat_cured',
                        title = 'Carne Seca Salgada',
                        subtitle = 'Alimento não-perecível para longas viagens na fronteira.',
                        category = 'provisions',
                        price = 3.5,
                        stock = 25,
                        badge = 'ESSENCIAL',
                        badgeType = 'gold'
                    },
                    {
                        id = 'resource_wood_pine',
                        title = 'Prancha de Pinho',
                        subtitle = 'Madeira serrada de alta densidade para construções.',
                        category = 'tools',
                        price = 5.0,
                        stock = 60
                    }
                }
            },

            -- ABA 2: TABLE (Livro-Razão Contábil / Registros)
            {
                id = 'table_showcase',
                label = 'Livro-Razão (Table)',
                icon = 'fas fa-book',
                badge = 'LEDGER',
                viewType = 'table',
                pageSize = 5,
                filters = {
                    { id = 'all', label = 'Todas as Transações', default = true },
                    { id = 'completed', label = 'Concluídas', key = 'status_type', value = 'on' },
                    { id = 'pending', label = 'Pendentes', key = 'status_type', value = 'off' },
                    { id = 'cancelled', label = 'Canceladas', key = 'status_type', value = 'danger' }
                },
                columns = {
                    { key = 'code', label = 'Nº', width = '10%', align = 'center' },
                    { key = 'date', label = 'DATA', width = '12%' },
                    { key = 'desc', label = 'MERCADORIA / OPERAÇÃO', width = '34%' },
                    { key = 'client', label = 'CIDADÃO', width = '22%' },
                    { key = 'amount', label = 'VALOR', width = '12%', align = 'right' },
                    { key = 'status', label = 'STATUS', width = '10%', align = 'center', type = 'pill' }
                },
                rows = {
                    { id = 'r1', code = '#201', date = '24/09', desc = 'Venda: Tomahawk de Caça', client = 'Arthur Morgan', amount = '$ 35.00', status = 'CONCLUÍDO', status_type = 'on' },
                    { id = 'r2', code = '#202', date = '24/09', desc = 'Encomenda: 50x Balas .44', client = 'John Marston', amount = '$ 12.50', status = 'PENDENTE', status_type = 'off' },
                    { id = 'r3', code = '#203', date = '24/09', desc = 'Lote Devolvido: Querosene', client = 'Bill Williamson', amount = '$ 28.00', status = 'CANCELADO', status_type = 'danger' },
                    { id = 'r4', code = '#204', date = '23/09', desc = 'Compra: Minério de Ferro', client = 'Hosea Matthews', amount = '$ 42.00', status = 'CONCLUÍDO', status_type = 'on' },
                    { id = 'r5', code = '#205', date = '23/09', desc = 'Manutenção de Carroça', client = 'Sadie Adler', amount = '$ 15.00', status = 'CONCLUÍDO', status_type = 'on' },
                    { id = 'r6', code = '#206', date = '22/09', desc = 'Pensão do Estábulo (7d)', client = 'Charles Smith', amount = '$ 7.00', status = 'PENDENTE', status_type = 'off' },
                    { id = 'r7', code = '#207', date = '22/09', desc = 'Carga de Peles de Cervo', client = 'Javier Escuella', amount = '$ 54.00', status = 'CONCLUÍDO', status_type = 'on' }
                }
            },

            -- ABA 3: CRAFT (Bancada de Manufatura / Receitas)
            {
                id = 'craft_showcase',
                label = 'Bancada (Craft)',
                icon = 'fas fa-hammer',
                badge = 'FORJA',
                viewType = 'craft',
                items = {
                    {
                        id = 'craft_knife_hunting',
                        title = 'Faca de Caça Rústica',
                        subtitle = 'Forja com têmpera especial em água mineral fria.',
                        requirements = {
                            { item = 'resource_iron_dirty', label = 'Minério de Ferro', current = 6, required = 2 },
                            { item = 'resource_coal', label = 'Carvão Mineral', current = 12, required = 1 },
                            { item = 'lumber_pine_wood_plank', label = 'Madeira de Pinho', current = 4, required = 1 }
                        }
                    },
                    {
                        id = 'craft_tomahawk_steel',
                        title = 'Machadinha de Aço Forjado',
                        subtitle = 'Lâmina equilibrada para alta penetração e impacto.',
                        requirements = {
                            { item = 'resource_iron_dirty', label = 'Minério de Ferro', current = 6, required = 4 },
                            { item = 'resource_coal', label = 'Carvão Mineral', current = 12, required = 2 },
                            { item = 'leather_strip', label = 'Tiras de Couro', current = 1, required = 3 }
                        }
                    },
                    {
                        id = 'craft_lockpick_fine',
                        title = 'Gazua de Aço Reforçado',
                        subtitle = 'Ferramenta flexível com ponta endurecida.',
                        requirements = {
                            { item = 'resource_iron_dirty', label = 'Minério de Ferro', current = 6, required = 1 },
                            { item = 'resource_coal', label = 'Carvão Mineral', current = 12, required = 1 }
                        }
                    }
                }
            },

            -- ABA 4: QUEUE (Fila de Produção em Tempo Real)
            {
                id = 'queue_showcase',
                label = 'Produção (Queue)',
                icon = 'fas fa-hourglass-half',
                badge = 'FILA',
                viewType = 'queue',
                items = {
                    {
                        id = 'job_showcase_1',
                        item = 'craft_knife_hunting',
                        title = 'Faca de Caça Rústica',
                        subtitle = 'Forjando lâmina na fornalha',
                        totalQty = 3,
                        completedQty = 1,
                        durationPerUnit = 10,
                        remainingTime = 20,
                        totalDuration = 30,
                        status = 'in_progress'
                    },
                    {
                        id = 'job_showcase_2',
                        item = 'craft_lockpick_fine',
                        title = 'Gazua de Aço Reforçado',
                        subtitle = 'Lote finalizado e pronto para coleta',
                        totalQty = 2,
                        completedQty = 2,
                        durationPerUnit = 5,
                        remainingTime = 0,
                        totalDuration = 10,
                        status = 'completed'
                    }
                }
            },

            -- ABA 5: DASHBOARD (Cockpit de Monitoramento & Ações Rápidas)
            {
                id = 'dashboard_showcase',
                label = 'Dashboard (KPIs)',
                icon = 'fas fa-tachometer-alt',
                badge = 'COCKPIT',
                viewType = 'dashboard',
                stats = {
                    online = 28,
                    maxClients = 64,
                    uptime = '06h 12m',
                    peak24h = 54,
                    peakAllTime = 128
                },
                actionGroups = {
                    {
                        title = 'TELEPORT & LOCALIZAÇÃO',
                        icon = 'fa-location-arrow',
                        actions = {
                            { id = 'tp_waypoint', label = 'Ir para Marcador (TPM)', icon = 'fa-map-pin', type = 'action' },
                            { id = 'copy_coords', label = 'Copiar Minhas Coordenadas', icon = 'fa-copy', type = 'action' },
                            { id = 'tp_coords', label = 'Teleportar Coords (X,Y,Z)', icon = 'fa-crosshairs', type = 'action' }
                        }
                    },
                    {
                        title = 'OPERADOR (SELF BOOSTERS)',
                        icon = 'fa-user-shield',
                        actions = {
                            { id = 'godmode', label = 'Modo Deus (GodMode)', icon = 'fa-shield-alt', type = 'toggle', active = true },
                            { id = 'noclip', label = 'Modo Voo (NoClip)', icon = 'fa-rocket', type = 'toggle', active = false },
                            { id = 'invis', label = 'Invisibilidade', icon = 'fa-ghost', type = 'toggle', active = false },
                            { id = 'self_heal', label = 'Curar Personagem', icon = 'fa-medkit', type = 'action' }
                        }
                    }
                }
            },

            -- ABA 6: SETTINGS (Posições do Dock & Switches)
            {
                id = 'settings_showcase',
                label = 'Preferências (Settings)',
                icon = 'fas fa-cog',
                badge = 'AJUSTES',
                viewType = 'settings',
                currentPosition = 'mid_left',
                positions = {
                    { id = 'top_left', label = 'Top Left' },
                    { id = 'top_right', label = 'Top Right' },
                    { id = 'mid_left', label = 'Mid Left', active = true },
                    { id = 'mid_right', label = 'Mid Right' },
                    { id = 'bottom_left', label = 'Bottom Left' },
                    { id = 'bottom_right', label = 'Bottom Right' }
                },
                quickActions = {
                    { id = 'noclip', label = 'Modo Voo (NoClip)', icon = 'fa-rocket', enabled = true },
                    { id = 'show_names', label = 'GamerTags 3D (ESP)', icon = 'fa-id-badge', enabled = true },
                    { id = 'godmode', label = 'Modo Invencível (GodMode)', icon = 'fa-shield-alt', enabled = true },
                    { id = 'show_blips', label = 'Radar de Jogadores', icon = 'fa-map-marker-alt', enabled = false }
                }
            }
        },
        onAction = function(action, item, tabId, qty, data)
            LogShowcase('PANEL_ACTION', { action = action, item = item, tabId = tabId, quantity = qty, data = data })
            if action == 'confirm' then
                ShowToast("COMPRA CONCLUÍDA", string.format("Comprado: %s (x%d)", item.title or item.label or item.id, qty or 1), "success", 3500)
            elseif action == 'craft' then
                ShowToast("BANCADA DE CRIAÇÃO", string.format("Produzindo: %s (x%d)", item.title or item.id, qty or 1), "info", 3500)
            elseif action == 'collect_job' then
                ShowToast("LOTE COLETADO", "Lote transferido para o inventário!", "success", 3000)
            elseif action == 'cancel_job' then
                ShowToast("LOTE CANCELADO", "Produção cancelada com sucesso.", "alert", 2500)
            elseif action == 'set_dock_position' then
                ShowToast("POSIÇÃO DO MENU", "Ancoragem alterada para: " .. tostring(data.position or item), "info", 2500)
            elseif action == 'toggle_quick_action' then
                ShowToast("ATALHO RÁPIDO", string.format("Atalho '%s' = %s", data.actionId or "ação", tostring(data.enabled)), "info", 2000)
            else
                ShowToast("AÇÃO DO PAINEL", "Ação: " .. tostring(action), "info", 2500)
            end
        end,
        onClose = function()
            LogShowcase('PANEL_CLOSE', { status = 'closed' })
            ShowToast("PAINEL", "Painel centralizado encerrado.", "alert", 2000)
        end
    })
end

-- ============================================================================
-- 3. SHOWCASE: MODAL DE DIÁLOGO / FORMULÁRIO TIPADO (OpenDialog)
-- ============================================================================
function OpenShowcaseDialog()
    OpenDialog({
        id = 'showcase_dialog',
        tag = 'REGISTRO DE PENALIDADE',
        title = 'NOTIFICAÇÃO OFICIAL DO XERIFE',
        subtitle = 'Preencha os termos para aplicação de advertência formal',
        submitLabel = 'APLICAR SANÇÃO',
        cancelLabel = 'CANCELAR',
        fields = {
            {
                id = 'infracao',
                type = 'select',
                label = 'Infração Registrada',
                required = true,
                options = {
                    { value = 'desordem', label = 'Perturbação da Ordem em Estabelecimento ($ 15.00)' },
                    { value = 'porte_armas', label = 'Porte Não Autorizado de Dinamite ($ 45.00)' },
                    { value = 'desacato', label = 'Desacato à Autoridade Policial ($ 30.00)' }
                }
            },
            {
                id = 'valor_multa',
                type = 'number',
                label = 'Valor da Multa ($)',
                value = 25.0,
                min = 5.0,
                max = 500.0,
                step = 1.0,
                required = true
            },
            {
                id = 'observacoes',
                type = 'textarea',
                label = 'Relatório Circunstanciado',
                placeholder = 'Descreva os detalhes da ocorrência, testemunhas presentes e apreensões...',
                required = true
            }
        },
        onSubmit = function(values)
            LogShowcase('DIALOG_SUBMIT', values)
            ShowToast("FORMULÁRIO ENVIADO", string.format("Sanção de $ %.2f aplicada! Motivo: %s", tonumber(values.valor_multa) or 0, values.infracao), "success", 4000)
        end,
        onCancel = function()
            LogShowcase('DIALOG_CANCEL', { status = 'cancelled' })
            ShowToast("FORMULÁRIO CANCELADO", "A operação foi cancelada pelo operador.", "alert", 2500)
        end
    })
end

-- ============================================================================
-- 4. SHOWCASE: TOASTS DE NOTIFICAÇÃO
-- ============================================================================
function OpenShowcaseToasts()
    CreateThread(function()
        ShowToast("NOTIFICAÇÃO (INFO)", "Informação de sistema com acento ouro velho.", "info", 3000)
        Wait(800)
        ShowToast("SUCESSO (GREEN)", "Ação executada e validada pelo servidor com êxito!", "success", 3000)
        Wait(800)
        ShowToast("ALERTA (AMBER)", "Atenção: Área de fronteira com patrulha armada.", "alert", 3000)
        Wait(800)
        ShowToast("PERIGO (DANGER)", "Erro: Você não possui autorização para esta ação.", "error", 3500)
    end)
end

-- ============================================================================
-- 5. MENU MASTER DO SHOWCASE (/uitest)
-- ============================================================================
local function OpenMasterShowcaseMenu()
    OpenDock({
        id = 'master_showcase',
        title = 'CENTRAL DE TESTE DE UI',
        tag = 'WESTRP • COMPONENT SUITE',
        keepInput = true,
        tabs = {
            {
                id = 'main_suite',
                name = 'CATÁLOGO DE COMPONENTES',
                items = {
                    {
                        id = 'test_dock',
                        label = '1. Dock Lateral (350px)',
                        badge = 'TECLADO',
                        badgeType = 'gold',
                        description = 'Testa todos os controles nativos do Dock: buttons, badges, toggles, sliders e submenus.'
                    },
                    {
                        id = 'test_panel_all',
                        label = '2. Painel Central (1040px)',
                        badge = '6 MODOS',
                        badgeType = 'on',
                        description = 'Abre o Panel completo com abas de Loja (Grid), Livro (Table), Forja (Craft), Fila (Queue), Dashboard e Settings.'
                    },
                    {
                        id = 'test_dialog',
                        label = '3. Modal de Diálogo (Formulário)',
                        badge = 'PROMPT',
                        badgeType = 'gold',
                        description = 'Testa o modal flutuante de formulário com campos text, number, select e textarea.'
                    },
                    {
                        id = 'test_toasts',
                        label = '4. Bateria de Notificações Toasts',
                        badge = '4 CORES',
                        badgeType = 'gold',
                        description = 'Dispara uma sequência de 4 toasts (Info, Sucesso, Alerta e Erro) com áudio procedural.'
                    },
                    {
                        id = 'sep_panel_shortcuts',
                        label = 'ATALHOS DIRETOS DO PANEL',
                        type = 'separator'
                    },
                    {
                        id = 'quick_grid',
                        label = '-> Abrir Modo Grid (Loja / Vitrine)',
                        description = 'Abre diretamente o painel na aba de Vitrine Comercial com busca e filtros.'
                    },
                    {
                        id = 'quick_table',
                        label = '-> Abrir Modo Table (Livro-Razão)',
                        description = 'Abre diretamente o painel na aba de Livro-Razão Contábil com paginação.'
                    },
                    {
                        id = 'quick_craft',
                        label = '-> Abrir Modo Craft (Bancada de Forja)',
                        description = 'Abre diretamente o painel na aba de Manufatura e verificação de insumos.'
                    },
                    {
                        id = 'quick_dashboard',
                        label = '-> Abrir Modo Dashboard (Cockpit)',
                        description = 'Abre diretamente o painel no modo de telemetria e ações operacionais.'
                    }
                }
            }
        },
        onSelect = function(item)
            if item.id == 'test_dock' then
                CloseDock()
                Wait(200)
                OpenShowcaseDock()
            elseif item.id == 'test_panel_all' then
                CloseDock()
                Wait(200)
                OpenShowcasePanel('grid_showcase')
            elseif item.id == 'test_dialog' then
                CloseDock()
                Wait(200)
                OpenShowcaseDialog()
            elseif item.id == 'test_toasts' then
                OpenShowcaseToasts()
            elseif item.id == 'quick_grid' then
                CloseDock()
                Wait(200)
                OpenShowcasePanel('grid_showcase')
            elseif item.id == 'quick_table' then
                CloseDock()
                Wait(200)
                OpenShowcasePanel('table_showcase')
            elseif item.id == 'quick_craft' then
                CloseDock()
                Wait(200)
                OpenShowcasePanel('craft_showcase')
            elseif item.id == 'quick_dashboard' then
                CloseDock()
                Wait(200)
                OpenShowcasePanel('dashboard_showcase')
            end
        end
    })
end

-- ============================================================================
-- 6. REGISTRO DE COMANDOS DE CHAT / CONSOLE
-- ============================================================================
RegisterCommand('uitest', function(source, args)
    local sub = args[1] and string.lower(args[1]) or nil

    if sub == 'dock' then
        OpenShowcaseDock()
    elseif sub == 'panel' then
        local view = args[2] or 'grid_showcase'
        OpenShowcasePanel(view)
    elseif sub == 'dialog' then
        OpenShowcaseDialog()
    elseif sub == 'toast' or sub == 'toasts' then
        OpenShowcaseToasts()
    else
        OpenMasterShowcaseMenu()
    end
end, false)

RegisterCommand('uishowcase', function()
    OpenMasterShowcaseMenu()
end, false)

print("^2[WestRP UI]^7 Módulo de Showcase carregado com sucesso! Utilize ^3/uitest^7 ou ^3/uishowcase^7 para testar todos os componentes.")
