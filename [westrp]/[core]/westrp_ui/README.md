# WestRP UI Engine — Manual Oficial do Desenvolvedor

O **WestRP UI Engine** (`westrp_ui`) é o ecossistema padronizado de interfaces do WestRP Framework para RedM. Ele foi projetado sob os pilares de **alto desempenho (0.00ms idle resmon)**, **fidelidade visual nativa ao Red Dead Redemption 2** e **arquitetura 100% orientada a dados (Data-Driven)**.

---

## 📑 Índice
1. [Arquitetura & Filosofia](#1-arquitetura--filosofia)
2. [Formas de Invocação no seu Script](#2-formas-de-invocação-no-seu-script)
3. [Módulo A: O Dock Lateral (350px / Câmera Livre)](#3-módulo-a-o-dock-lateral-350px--câmera-livre)
   - [Propriedades Globais](#propriedades-do-dock)
   - [Tipos de Controles Suportados](#tipos-de-controles-no-dock)
   - [Ciclo de Vida & Callbacks](#callbacks-do-dock)
   - [Casos de Uso Práticos](#casos-de-uso-do-dock)
4. [Módulo B: O Panel Central (1040px / Cursor Livre)](#4-módulo-b-o-panel-central-1040px--cursor-livre)
   - [Propriedades Globais & Cabeçalho](#propriedades-do-panel)
   - [Desfoque de Tela Nativo (OJDominoBlur)](#desfoque-de-tela-nativo)
   - [Scrollbar Minimalista Dourada](#scrollbar-minimalista-dourada)
   - [Visão 1: `grid` (Vitrine Comercial & Inventário)](#visão-1-grid-vitrine-comercial)
   - [Visão 2: `craft` (Bancada de Manufatura & Receitas)](#visão-2-craft-bancada-de-manufatura)
   - [Visão 3: `queue` (Fila de Produção com Countdown)](#visão-3-queue-fila-de-produção)
   - [Visão 4: `table` (Livro-Razão & Gestão Contábil)](#visão-4-table-livro-razão--gestão)
   - [Callbacks & Ações do Panel](#callbacks--ações-do-panel)
   - [Casos de Uso Práticos](#casos-de-uso-do-panel)
5. [Módulo C: Modal de Diálogos Tipados (OpenDialog)](#5-módulo-c-modal-de-diálogos-tipados-opendialog)
   - [Campos Suportados & Validações](#campos-suportados--validações)
   - [Exemplo de Uso Prático](#exemplo-de-uso-do-dialog)
6. [Módulo D: Sistema de Notificações Toast](#6-módulo-d-sistema-de-notificações-toast)
7. [Módulo E: Resolução Automática de Ícones](#7-módulo-e-resolução-automática-de-ícones)
8. [Boas Práticas & Performance](#8-boas-práticas--performance)
9. [Snippets Prontos Copia-e-Cola](#9-snippets-prontos-copia-e-cola)

---

## 1. Arquitetura & Filosofia

O motor de interface adota os seguintes princípios técnicos:

* **Instância NUI Única (Single NUI Instance):** Todas as telas rodam no mesmo Chromium, eliminando o overhead de instanciar múltiplos iframes ou recursos NUI pesados.
* **Áudio Procedural Nativo (Web Audio API):** Não há arquivos `.mp3` ou `.ogg` pesados. Os cliques e confirmações de interface são sintetizados proceduralmente em tempo de execução via ondas senoidais filtradas.
* **Desfoque Nativo 3D (`OJDominoBlur`):** O mundo 3D é desfocado diretamente pelo motor de pós-processamento da Rockstar Games (`AnimpostfxPlay`), garantindo 60+ FPS, zero escurecimento e estética Rockstar genuína.
* **Resolução Dinâmica de Assets:** Integração transparente com `westrp_assets`. Se você passar `id = 'weapon_thrown_tomahawk'`, a interface resolve a imagem automaticamente a partir do repositório estático central.

---

## 2. Formas de Invocação no seu Script

Você pode invocar o motor de duas maneiras equivalentes:

### Opção A: Via WestRP Core SDK (Recomendado)
Se o seu script importa `@westrp_core/init.lua` no `fxmanifest.lua`:
```lua
WestRP.Client.UI.OpenDock({ ... })
WestRP.Client.UI.OpenPanel({ ... })
WestRP.Client.UI.OpenDialog({ ... })
WestRP.Client.UI.ShowToast("TÍTULO", "Mensagem", "success")
```

### Opção B: Via Direct Exports (Fallback)
Funciona em qualquer resource sem dependência direta do SDK:
```lua
exports['westrp_ui']:OpenDock({ ... })
exports['westrp_ui']:OpenPanel({ ... })
exports['westrp_ui']:OpenDialog({ ... })
exports['westrp_ui']:ShowToast("TÍTULO", "Mensagem", "info")
```

---

## 3. Módulo A: O Dock Lateral (350px / Câmera Livre)

O **Dock** é a interface lateral clássica da Rockstar (inspirada nos menus nativos de estábulo, lojas e armazéns do RDR2). O jogador mantém movimentação restrita, câmera livre e interage via teclado.

### Controles Nativos do Dock
* **[↑] / [↓]**: Navegação vertical na lista.
* **[Q] / [E]** ou **[←] / [→] no cabeçalho**: Alternar abas horizontais.
* **[←] / [→]**: Ajustar sliders (numéricos ou de texto).
* **[ENTER]**: Executar opção ou alternar toggle.
* **[BACKSPACE]**: Voltar do submenu ou fechar o menu.
* **[ESC]**: Fechar o menu imediatamente.

---

### Propriedades do Dock

| Campo | Tipo | Obrigatório | Descrição |
| :--- | :--- | :---: | :--- |
| `id` | `string` | Sim | Identificador único da sessão do menu. |
| `title` | `string` | Sim | Título principal em caixa alta (ex: `'SALOON SMITHFIELD'`). |
| `tag` | `string` | Não | Categoria/Localidade no topo (ex: `'VALENTINE • FRONTIER'`). |
| `keepInput` | `boolean` | Não | Mantém câmera e visão livres. Padrão: `true`. |
| `tabs` | `table[]` | Sim | Array de abas com seus respectivos itens. |
| `onSelect` | `function(item, tabId)` | Não | Disparado ao pressionar [ENTER] em itens de ação. |
| `onChange` | `function(item, val, tabId)`| Não | Disparado ao alterar toggles ou sliders. |
| `onClose` | `function()` | Não | Disparado ao encerrar o menu. |

---

### Tipos de Controles no Dock

#### 1. Ação com Badges de Preço/Status
```lua
{
    id = 'consumable_alcohol_bourbon',
    label = 'Bourbon Envelhecido',
    sublabel = 'Dose de carvalho americano',
    badge = '$ 3.50',
    badgeType = 'gold', -- 'gold' | 'danger' | 'on' | 'off'
    description = 'Destilado forte que recupera a estamina do cavaleiro.'
}
```

#### 2. Interruptor Liga/Desliga (`toggle`)
```lua
{
    id = 'smoke_policy',
    label = 'Permitir Fumo no Balcão',
    type = 'toggle',
    checked = true,
    description = 'Define a permissão de fumo para a clientela no balcão.'
}
```

#### 3. Slider Numérico
```lua
{
    id = 'rounds',
    label = 'Pagar Rodadas',
    type = 'slider',
    min = 1,
    max = 10,
    value = 1,
    description = 'Escolha a quantidade de rodadas para o Saloon.'
}
```

#### 4. Slider de Opções Textuais
```lua
{
    id = 'ambiance_tune',
    label = 'Música do Pianista',
    type = 'slider',
    options = { 'Silêncio', 'Ragtime Animado', 'Valsa Lenta', 'Balada Western' },
    valueIndex = 1,
    description = 'Alterne a melodia tocada no piano do estabelecimento.'
}
```

#### 5. Submenu Aninhado Hierárquico
```lua
{
    id = 'contraband',
    label = 'Mercadorias Clandestinas',
    type = 'submenu',
    description = 'Acesse produtos ilegais fornecidos pelo contrabando.',
    subItems = {
        { id = 'consumable_alcohol_moonshine_apple', label = 'Moonshine Ilegal', badge = '$ 18.00', badgeType = 'danger', danger = true, description = 'Bebida clandestina proibida pela lei.' },
        { id = 'lockpick', label = 'Gazua de Fechadura', badge = '$ 12.00', badgeType = 'danger', danger = true, description = 'Ferramenta fina para violar trincos.' }
    }
}
```

#### 6. Itens Desabilitados ou de Alerta
```lua
{ id = 'bath', label = 'Banho Quente', badge = 'OCUPADO', badgeType = 'off', disabled = true, description = 'Tinas em manutenção no momento.' },
{ id = 'sheriff', label = 'Chamar o Xerife', badge = 'ALERTA', badgeType = 'danger', danger = true, description = 'Dispara chamado de desordem à lei.' }
```

---

### Callbacks do Dock

```lua
onSelect = function(item, tabId)
    -- Disparado ao apertar ENTER
    print("Selecionou:", item.id, "na aba:", tabId)
end,
onChange = function(item, newValue, tabId)
    -- Disparado ao mexer em sliders ou alternar toggles
    print("Alterou:", item.id, "para:", newValue)
end,
onClose = function()
    -- Disparado ao sair
    print("Menu fechado!")
end
```

---

### Casos de Uso do Dock

#### Caso de Uso: Menu de Saloon & Atendimento de Balcão
```lua
local function OpenSaloonMenu()
    WestRP.Client.UI.OpenDock({
        id = 'saloon_smithfield',
        title = 'SALOON SMITHFIELD',
        tag = 'VALENTINE • FRONTIER',
        tabs = {
            {
                id = 'drinks',
                name = 'BEBIDAS',
                items = {
                    { id = 'consumable_alcohol_bourbon', label = 'Bourbon Envelhecido', badge = '$ 3.50', badgeType = 'gold', description = 'Recupera o fôlego imediatamente.' },
                    { id = 'consumable_alcohol_beer_pint_amber', label = 'Cerveja Gelada', badge = '$ 1.00', badgeType = 'gold', description = 'Caneca servida na hora.' }
                }
            },
            {
                id = 'services',
                name = 'SERVIÇOS',
                items = {
                    { id = 'smoke', label = 'Permitir Fumar', type = 'toggle', checked = true, description = 'Alterna permissão de fumar no salão.' },
                    { id = 'piano', label = 'Melodia do Piano', type = 'slider', options = {'Silêncio', 'Ragtime', 'Valsa'}, valueIndex = 1 }
                }
            }
        },
        onSelect = function(item, tabId)
            WestRP.Client.UI.ShowToast("SALOON", "Você selecionou: " .. item.label, "success")
        end
    })
end
```

---

## 4. Módulo B: O Panel Central (1040px / Cursor Livre)

O **Panel** é a área de trabalho multimodal de alta interatividade. Ao abrir, o cursor do mouse é liberado e o cenário 3D recebe um elegante desfoque nativo.

### Desfoque de Tela Nativo
Ao abrir, o motor executa automaticamente:
```lua
AnimpostfxPlay('OJDominoBlur')
```
E ao fechar:
```lua
AnimpostfxStop('OJDominoBlur')
```
Isso mantém o jogo claro, sem overlay escuro artificial, desfocando suavemente o cenário atrás do modal.

### Scrollbar Minimalista Dourada
Todas as visões internas possuem scrollbars estilizadas de 5px em tom dourado escurecido (`rgba(212, 175, 55, 0.35)`) com efeito de brilho e arraste dinâmico, sem a barra cinza padrão do sistema operacional.

---

### Propriedades do Panel

| Campo | Tipo | Obrigatório | Descrição |
| :--- | :--- | :---: | :--- |
| `id` | `string` | Sim | Identificador do painel. |
| `title` | `string` | Sim | Título em destaque no cabeçalho. |
| `tag` | `string` | Não | Tag temática superior (ex: `'OFICINA & BANCADA'`). |
| `subtitle` | `string` | Não | Informação complementar ou saldo (ex: `'Saldo: $ 580.00'`). |
| `ctaLabel` | `string` | Não | Rótulo do botão principal do rodapé (padrão: `'CONFIRMAR'`). |
| `brand` | `table` | Não | Identidade visual `{ name = "WESTRP SERVER", badge = "ADMIN MENU", logo = "..." }`. |
| `operator` | `table` | Não | Perfil do operador `{ name = "John", role = "Admin", avatar = "...", onDuty = true }`. |
| `tabs` | `table[]` | Sim | Array de abas com seus respectivos `viewType`. |
| `onAction` | `function(action, item, tabId, qty, data)` | Não | Callback universal de ações executadas no painel. |
| `onClose` | `function()` | Não | Disparado ao fechar o painel. |

---

### Propriedades das Abas (`PanelTab`)

| Campo | Tipo | Padrão | Descrição |
| :--- | :--- | :---: | :--- |
| `id` | `string` | **Obrigatório** | Identificador único da aba. |
| `label` | `string` | **Obrigatório** | Nome visível na sidebar de abas. |
| `icon` | `string` | `nil` | Classe de ícone FontAwesome (ex: `'fas fa-tachometer-alt'`). |
| `viewType` | `'grid' \| 'table' \| 'craft' \| 'queue' \| 'dashboard' \| 'settings'` | `'grid'` | Modo de renderização da viewport. |
| `badge` | `string \| number` | `nil` | Rótulo/contador decorativo na aba. |
| `badgeType` | `'count-blue' \| 'count-orange' \| 'gold' \| 'on' \| 'off'` | `'gold'` | Estilo visual do badge na sidebar. |
| `stats` | `table` | `nil` | Dados de KPI para `dashboard` (`{ online, maxClients, uptime, peak24h, peakAllTime }`). |
| `actionGroups` | `table[]` | `nil` | Grupos de ações categorizadas para `dashboard` (`{ title, actions = { { id, label, type, active } } }`). |
| `currentPosition` | `string` | `'mid_left'` | Posição selecionada para a aba `settings`. |
| `positions` | `table[]` | `nil` | Posições disponíveis para a aba `settings`. |
| `quickActions` | `table[]` | `nil` | Lista de ações com switches para a aba `settings`. |
| `items` | `table[]` | `nil` | Lista de cards para `grid` ou receitas para `craft`. |
| `columns` | `table[]` | `nil` | Definição de colunas para `table`. |
| `rows` | `table[]` | `nil` | Registros de dados para `table`. |
| `filters` | `table[]` | `nil` | Lista declarativa de chips de filtro (ex: `{{ id = 'all', label = 'Todos' }, ...}`). |
| `filterCategory` | `boolean` | `false` | Se `true`, extrai categorias automaticamente de `items` ou `rows` e cria os chips. |
| `pageSize` | `number` | `nil` | Ativa paginação dinâmica com X itens por página (ex: `12`, `20`). Sem limite se omitido. |
| `pagination` | `table` | `nil` | Configuração avançada `{ pageSize = 12, showSummary = true }`. |

---

### Visão 1: `grid` (Vitrine Comercial)
Ideal para lojas de armas, vestuário, armazéns e vitrines de produtos.

```lua
{
    id = 'weapons',
    label = 'Armamentos',
    badge = 'VITRINE',
    viewType = 'grid',
    items = {
        {
            id = 'weapon_thrown_tomahawk',
            title = 'Tomahawk de Caça',
            subtitle = 'Lâmina de aço temperado balanceada para arremesso.',
            price = 35.0,
            stock = 8,
            badge = 'POPULAR',
            badgeType = 'gold' -- 'gold' | 'danger' | 'on' | 'off'
        },
        {
            id = 'weapon_thrown_molotov',
            title = 'Coquetel Molotov',
            subtitle = 'Garrafa com querosene inflamável.',
            price = 25.0,
            stock = 12,
            badge = 'PERIGO',
            badgeType = 'danger'
        }
    }
}
```
* **Recursos Integrados:**
  * Busca em tempo real por título, subtítulo, ID ou categoria.
  * **Barra de Filtros por Chips:** Filtragem instantânea por sub-categoria com contadores.
  * **Paginação Dinâmica:** Controle visual por páginas (`pageSize`) com botões `◄` e `►`.
  * Seletor de quantidade no rodapé (`-` e `+`) com cálculo do preço total.
  * O clique seleciona o card e atualiza os detalhes no rodapé.

---

### Visão 2: `craft` (Bancada de Manufatura)
Ideal para ferrarias, alquimia, fogueiras de acampamento e artesanato.

```lua
{
    id = 'forge',
    label = 'Bancada de Forja',
    badge = 'BANCADA',
    viewType = 'craft',
    items = {
        {
            id = 'tool_resource_knife',
            title = 'Faca de Caça Rústica',
            subtitle = 'Ferramenta para esfolar animais e combate corpo-a-corpo.',
            requirements = {
                { item = 'resource_iron_dirty', label = 'Minério de Ferro', current = 6, required = 2 },
                { item = 'resource_coal', label = 'Carvão Mineral', current = 12, required = 1 },
                { item = 'lumber_pine_wood_plank', label = 'Madeira de Pinho', current = 4, required = 1 }
            }
        }
    }
}
```
* **Recursos Integrados:**
  * Exibe mini-ícones para cada material da receita.
  * Multiplica dinamicamente os requisitos conforme a quantidade selecionada no rodapé.
  * Exibe indicador visual verde (`ok`) se o jogador possui os insumos ou vermelho (`missing`) se faltam materiais.
  * Desabilita automaticamente o botão de produção caso faltem requisitos.
  * Ao clicar no botão de produção, o lote é **automaticamente enfileirado na aba de Fila de Produção** (se ela existir no mesmo painel)!

---

### Visão 3: `queue` (Fila de Produção)
Ideal para acompanhar manufaturas em tempo real, com contagem regressiva e retirada de produtos finalizados.

```lua
{
    id = 'production_queue',
    label = 'Fila de Produção',
    badge = 'PRODUÇÃO',
    viewType = 'queue',
    items = {
        {
            id = 'job_101',
            item = 'tool_resource_knife',
            title = 'Faca de Caça Rústica',
            subtitle = 'Forjando lâmina na fornalha',
            totalQty = 5,
            completedQty = 2,
            durationPerUnit = 8,      -- Segundos por unidade
            remainingTime = 24,       -- Segundos restantes no lote
            totalDuration = 40,       -- Tempo total do lote
            status = 'in_progress'    -- 'in_progress' | 'queued' | 'completed' | 'cancelled'
        },
        {
            id = 'job_102',
            item = 'lockpick',
            title = 'Gazua Reforçada',
            subtitle = 'Lote pronto para coleta',
            totalQty = 2,
            completedQty = 2,
            durationPerUnit = 5,
            remainingTime = 0,
            totalDuration = 10,
            status = 'completed'
        }
    }
}
```
* **Recursos Integrados:**
  * **Ticker de Countdown em Tempo Real:** Executado no cliente a cada 1 segundo.
  * **Barra de Progresso com Gradiente Dourado:** Atualiza continuamente sua largura (`%`).
  * **Contador de Unidades:** Mostra a evolução `completedQty / totalQty` conforme as unidades são finalizadas.
  * **Finalização Automática:** Ao zerar o tempo, toca áudio procedural, vira para `CONCLUÍDO` e libera o botão dourado **COLETAR (X UNIDADES)**.
  * **Botão Cancelar:** Permite cancelar lotes em andamento ou em espera.
  * **Rodapé Adaptativo:** Oculta o seletor numérico e resume o estado da linha de montagem: `X lote(s) em produção • Y pronto(s) para retirada`.

---

### Visão 4: `table` (Livro-Razão & Gestão)
Ideal para extratos contábeis, livros de registros do xerife, histórico de vendas de empresas e tabelas de logs.

```lua
{
    id = 'ledger',
    label = 'Livro-Razão',
    badge = 'GESTOR',
    viewType = 'table',
    columns = {
        { key = 'code', label = 'Nº', width = '10%', align = 'center' },
        { key = 'date', label = 'DATA', width = '12%' },
        { key = 'desc', label = 'MERCADORIA / OPERAÇÃO', width = '36%' },
        { key = 'client', label = 'CIDADÃO', width = '20%' },
        { key = 'amount', label = 'VALOR', width = '12%', align = 'right' },
        { key = 'status', label = 'STATUS', width = '10%', align = 'center', type = 'pill' }
    },
    rows = {
        { id = 'r1', code = '#101', date = '23/09', desc = 'Venda: Tomahawk de Caça', client = 'Arthur Morgan', amount = '$ 35.00', status = 'CONCLUÍDO', status_type = 'on' },
        { id = 'r2', code = '#102', date = '23/09', desc = 'Encomenda: 50x Balas', client = 'Micah Bell', amount = '$ 12.50', status = 'PENDENTE', status_type = 'off' },
        { id = 'r3', code = '#103', date = '22/09', desc = 'Lote Rejeitado: Querosene', client = 'Bill Williamson', amount = '$ 30.00', status = 'CANCELADO', status_type = 'danger' }
    }
}
```
* **Recursos Integrados:**
  * Busca instantânea por qualquer coluna da tabela.
  * **Barra de Filtros por Chips:** Filtragem dinâmica de linhas por status ou categoria (ex: Todos, Pagos, Pendentes).
  * **Paginação Dinâmica:** Controle por páginas (`pageSize = 10`) com navegação rápida `◄` e `►`.
  * Status Pills coloridas personalizadas com suporte a clique e seleção de linha.

---

### Callbacks & Ações do Panel

O callback `onAction(action, item, tabId, qty)` gerencia todas as intenções disparadas pelo usuário no painel:

```lua
onAction = function(action, item, tabId, qty)
    local qty = qty or 1
    local itemName = item.title or item.label or item.item or item.id or "Item"

    if action == 'confirm' and tabId == 'weapons' then
        -- Compra de item na vitrine
        TriggerServerEvent('minha_loja:server:comprar', item.id, qty)
    elseif action == 'craft' then
        -- Item enviado para produção na forja
        TriggerServerEvent('minha_forja:server:iniciarProducao', item.id, qty)
    elseif action == 'collect_job' then
        -- Jogador clicou em COLETAR na Fila de Produção
        TriggerServerEvent('minha_forja:server:coletarProducao', item.id, qty)
    elseif action == 'cancel_job' then
        -- Jogador cancelou um lote na Fila de Produção
        TriggerServerEvent('minha_forja:server:cancelarLote', item.id)
    end
end
```

---

### Casos de Uso do Panel

#### Caso de Uso Completo: Loja de Ferraria Integrada
```lua
local function OpenBlacksmithWorkshop()
    WestRP.Client.UI.OpenPanel({
        id = 'valentine_blacksmith',
        title = 'FERRARIA DE VALENTINE',
        tag = 'ESTABELECIMENTO ARTESANAL',
        subtitle = 'Saldo: $ 450.00',
        ctaLabel = 'EXECUTAR AÇÃO',
        tabs = {
            -- Aba 1: Vitrine de Peças Prontas
            {
                id = 'showcase',
                label = 'Armamento Pronto',
                badge = 'VITRINE',
                viewType = 'grid',
                items = {
                    { id = 'weapon_melee_hammer', title = 'Martelo Pesado', price = 45.0, stock = 3, badge = 'ROBUSTO', badgeType = 'gold' },
                    { id = 'weapon_thrown_tomahawk', title = 'Tomahawk de Caça', price = 35.0, stock = 10, badge = 'POPULAR', badgeType = 'gold' }
                }
            },
            -- Aba 2: Bancada de Forja
            {
                id = 'forge',
                label = 'Forja Manual',
                badge = 'BANCADA',
                viewType = 'craft',
                items = {
                    {
                        id = 'tool_resource_knife',
                        title = 'Faca de Caça',
                        subtitle = 'Forja com têmpera em água fria',
                        requirements = {
                            { item = 'resource_iron_dirty', label = 'Minério de Ferro', current = 4, required = 2 },
                            { item = 'resource_coal', label = 'Carvão', current = 10, required = 1 }
                        }
                    }
                }
            },
            -- Aba 3: Fila de Produção
            {
                id = 'production_queue',
                label = 'Fila de Produção',
                badge = 'PRODUÇÃO',
                viewType = 'queue',
                items = {}
            }
        },
        onAction = function(action, item, tabId, qty)
            if action == 'confirm' and tabId == 'showcase' then
                WestRP.Client.UI.ShowToast("FERRARIA", "Comprado: " .. item.title .. " (x" .. qty .. ")", "success")
            elseif action == 'craft' then
                WestRP.Client.UI.ShowToast("PRODUÇÃO", "Enviado para manufatura: " .. item.title .. " (x" .. qty .. ")", "info")
            elseif action == 'collect_job' then
                WestRP.Client.UI.ShowToast("RETIRADA", "Você coletou seu lote da bancada!", "success")
            end
        end
    })
end
```

---

## 5. Módulo C: Modal de Diálogos Tipados (OpenDialog)

O **Modal de Diálogos Tipados** (`OpenDialog`) é a solução canônica para formulários modais dinâmicos no RedM. Ele exibe uma caixa de diálogo estilizada no centro da tela com suporte a formulários multifield, validação em tempo real no cliente e no servidor, foco de mouse e áudio procedural de confirmação ou recusa.

### Propriedades do Diálogo (`DialogOptions`)

| Campo | Tipo | Obrigatório | Descrição |
| :--- | :--- | :---: | :--- |
| `id` | `string` | Sim | Identificador único do diálogo. |
| `title` | `string` | Sim | Título em destaque dourado no topo. |
| `tag` | `string` | Não | Tag temática superior (ex: `'GESTÃO FINANCEIRA'`). |
| `description` | `string` | Não | Texto explicativo ou de aviso abaixo do título. |
| `confirmLabel` | `string` | Não | Rótulo do botão de submissão (padrão: `'CONFIRMAR'`). |
| `cancelLabel` | `string` | Não | Rótulo do botão de cancelamento (padrão: `'CANCELAR'`). |
| `fields` | `DialogField[]`| Sim | Array de definições de campos do formulário. |
| `onSubmit` | `function(values)` | Não | Disparado quando o usuário preenche os campos válidos e submete. |
| `onCancel` | `function()` | Não | Disparado quando o usuário cancela ou pressiona `[ESC]`. |

---

### Campos Suportados & Validações

Cada campo (`DialogField`) possui a seguinte estrutura:

```lua
{
    id = 'motivo',                  -- Identificador do campo no objeto values retornado
    type = 'text',                  -- 'text' | 'number' | 'select' | 'textarea'
    label = 'Motivo Obrigatório',   -- Rótulo em caixa alta acima do input
    required = true,                -- Se obrigatório, barra submissão se vazio
    placeholder = 'Digite aqui...', -- Texto fantasma informativo
    value = '',                     -- Valor inicial padrão
    min = 1,                        -- Para 'number': valor mínimo aceito
    max = 50000,                    -- Para 'number': valor máximo aceito
    step = 0.01,                    -- Para 'number': incremento de casas decimais
    options = {                     -- Apenas para type = 'select'
        { value = 'opt_1', label = 'Opção 1' },
        { value = 'opt_2', label = 'Opção 2' }
    }
}
```

* **Validações Integradas no DOM**:
  * Campos `required` não preenchidos acionam borda vermelha (`field-error`) e som de recusa sonora.
  * Campos `number` validam `min`, `max` e parse float seguro.
  * O fechamento via tecla `[ESC]` dispara o callback `onCancel`.

---

### Exemplo de Uso do Dialog

```lua
WestRP.Client.UI.OpenDialog({
    id = 'dialog_multa_sheriff',
    title = 'APLICAR MULTA OFICIAL',
    tag = 'DEPARTAMENTO DO XERIFE',
    description = 'Aplique uma sanção financeira ao infrator com motivo registrado em ata.',
    confirmLabel = 'APLICAR MULTA',
    cancelLabel = 'CANCELAR',
    fields = {
        {
            id = 'infracao',
            type = 'select',
            label = 'Infração Comentida',
            required = true,
            options = {
                { value = 'desordem', label = 'Desordem em Estabelecimento ($ 15.00)' },
                { value = 'porte_ilegal', label = 'Porte Ilegal de Dinamite ($ 50.00)' },
                { value = 'desacato', label = 'Desacato à Autoridade da Lei ($ 30.00)' }
            }
        },
        {
            id = 'valor',
            type = 'number',
            label = 'Valor da Multa ($)',
            value = 15.0,
            min = 1.0,
            max = 500.0,
            step = 0.5,
            required = true
        },
        {
            id = 'relatorio',
            type = 'textarea',
            label = 'Relatório Circunstanciado',
            placeholder = 'Descreva os fatos e testemunhas...',
            required = true
        }
    },
    onSubmit = function(values)
        print("Multa aplicada:", values.infracao, values.valor, values.relatorio)
        WestRP.Client.UI.ShowToast("XERIFE", "Multa aplicada com sucesso!", "success")
    end,
    onCancel = function()
        print("Operação cancelada pelo oficial.")
    end
})
```

---

## 6. Módulo D: Sistema de Notificações Toast

O motor fornece toasts elegantes de canto superior direito, sem poluir o centro da tela:

```lua
WestRP.Client.UI.ShowToast(title, message, type, duration)
```

| Parâmetro | Tipo | Padrão | Descrição |
| :--- | :--- | :--- | :--- |
| `title` | `string` | `"NOTIFICAÇÃO"` | Cabeçalho em destaque. |
| `message` | `string` | `""` | Mensagem descritiva. |
| `type` | `string` | `"info"` | `"info"` (ouro), `"success"` (verde), `"alert"` (amarelo), `"error"` (vermelho). |
| `duration`| `number` | `3500` | Tempo de exibição em milissegundos. |

---

## 7. Módulo E: Resolução Automática de Ícones

Graças à centralização em `westrp_assets`, você **nunca precisa saber em qual pasta o arquivo PNG está**.

### Ordem de Resolução Automática:
1. Se você passar uma URL externa (`http://...`) ou caminho NUI (`nui://...`), ela é usada diretamente.
2. Se você passar o `id` do item (ex: `weapon_thrown_tomahawk`), o JavaScript consulta o dicionário `html/index.json` do `westrp_assets` e resolve para:
   `https://cfx-nui-westrp_assets/html/icons/weapons/weapon_thrown_tomahawk.png`
3. Se não encontrar imagem, o motor exibe um contêiner limpo sem quebras visuais.

---

## 8. Boas Práticas & Performance

1. **Sempre use Sono Dinâmico (Tick Manager):** Se o seu script tem POIs espaciais no mapa, nunca use `Citizen.Wait(0)` solto. Use o `WestRP.Client.TickManager` para dormir 1.5s longe de marcadores (0.00ms idle resmon).
2. **Autoridade no Servidor:** A UI é apenas a camada de apresentação. Ao disparar uma compra ou produção no `onAction`, envie o evento para o servidor validar inventário, dinheiro e coordenadas (`WestRP.Server.Security`).
3. **Fechamento Limpo:** Se o recurso consumidor for descarregado (`onResourceStop`), o `westrp_ui` fecha automaticamente qualquer menu aberto e limpa o foco do mouse/teclado e o efeito de desfoque.

---

## 9. Snippets Prontos Copia-e-Cola

### Template Mínimo: Dock Lateral
```lua
WestRP.Client.UI.OpenDock({
    id = 'menu_simples',
    title = 'MEU MENU',
    tag = 'CIDADE',
    tabs = {
        {
            id = 'geral',
            name = 'OPÇÕES',
            items = {
                { id = 'opt_1', label = 'Opção 1', badge = 'GRÁTIS', description = 'Descrição informativa da opção 1.' },
                { id = 'opt_2', label = 'Opção 2', badge = '$ 10.00', badgeType = 'gold', description = 'Descrição informativa da opção 2.' }
            }
        }
    },
    onSelect = function(item)
        WestRP.Client.UI.ShowToast("MENU", "Selecionado: " .. item.label, "success")
    end
})
```

### Template Mínimo: Panel de Alta Interatividade
```lua
WestRP.Client.UI.OpenPanel({
    id = 'painel_simples',
    title = 'ARMADURAS & FERRAMENTAS',
    tag = 'COMÉRCIO',
    subtitle = 'Disponível para todos os cidadãos',
    ctaLabel = 'CONFIRMAR COMPRA',
    tabs = {
        {
            id = 'itens',
            label = 'Itens à Venda',
            badge = 'LOJA',
            viewType = 'grid',
            items = {
                { id = 'tool_resource_knife', title = 'Faca de Caça', price = 15.0, stock = 5 }
            }
        }
    },
    onAction = function(action, item, tabId, qty)
        WestRP.Client.UI.ShowToast("LOJA", "Comprado x" .. qty .. " de " .. item.title, "success")
    end
})
```

### Template Mínimo: Diálogo Modal Tipado
```lua
WestRP.Client.UI.OpenDialog({
    id = 'dialog_simples',
    title = 'TRANSFERIR QUANTIA',
    tag = 'BANCO DE VALENTINE',
    description = 'Informe a quantia e a descrição para formalizar a remessa.',
    confirmLabel = 'TRANSFERIR',
    cancelLabel = 'CANCELAR',
    fields = {
        {
            id = 'valor',
            type = 'number',
            label = 'Quantia em Dólares ($)',
            value = 10.0,
            min = 1.0,
            max = 1000.0,
            required = true
        },
        {
            id = 'descricao',
            type = 'text',
            label = 'Descrição da Remessa',
            placeholder = 'Ex: Pagamento de gado',
            required = true
        }
    },
    onSubmit = function(values)
        WestRP.Client.UI.ShowToast("BANCO", "Enviado $" .. values.valor .. " (" .. values.descricao .. ")", "success")
    end
})
```
