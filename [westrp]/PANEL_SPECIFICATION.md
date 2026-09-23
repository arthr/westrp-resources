# Especificação de Interface — WestRP UI Panel & Workspace Engine
> **Padrão:** Spec-Driven Development (SDD)  
> **Módulo:** `westrp_ui` (Extensão Canvas / Modal de Alta Interatividade)  
> **Versão:** 1.0.0  
> **Target:** RedM (CitizenFX RDR3) — CEF / Chromium  
> **Contexto de Uso:** Telas complexas de gestão e consumo (Crafting, Vitrines/Lojas, Tabelas/Livros Caixa, Buscas, Trocas e Formulários)  

---

## 1. Visão Geral e Propósito

Enquanto o **`Dock`** (menu lateral de 350px) é otimizado para interações rápidas pelo teclado com **câmera livre**, o **`Panel`** é a solução para **alta densidade de informação e interatividade rica**:

* **Controle Total por Cursor do Mouse (`SetNuiFocus(true, true)`):** Ações e disparos do jogo são bloqueados temporariamente para permitir navegação fluida, digitação em campos de texto, arrastar sliders e cliques precisos.
* **Dual Persona (Gestor & Consumidor):** A mesma base atende a visão do **Gestor** (painéis administrativos, tabelas de funcionários, logs, configuração de estoques) e do **Consumidor** (vitrines de compras, bancadas de criação, contratação de serviços).
* **Single NUI Engine:** Reside dentro do mesmo resource centralizado `westrp_ui`, reutilizando a mesma página, os mesmos Design Tokens e a mesma instância Web Audio API, sem nenhum custo extra de memória.

---

## 2. Anatomia Visual e Layout (Canvas Central)

O Panel é renderizado como um canvas central imponente (`1040px` de largura por `660px` de altura), com estética de livro de registro / marchetaria vitoriana e couro escuro:

```
┌──────────────────────────────────────────────────────────────────────────┐
│ [HEADER]: Tag Categoria, Título Principal, Barra de Busca, Saldo, [✕]    │
├───────────────────┬──────────────────────────────────────────────────────┤
│ [SIDEBAR (Abas)]  │ [MAIN CONTENT VIEWPORT]                              │
│                   │                                                      │
│ ⚒️  Armas         │  MODO VITRINE (Grid de Cards):                       │
│ 🏹 Munições       │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐│
│ 🪵 Materiais      │  │ [Ícone/Img]  │  │ [Ícone/Img]  │  │ [Ícone/Img]  ││
│ 📋 Encomendas     │  │ Revólver .44 │  │ Rifle Caça   │  │ Faca Caçador ││
│                   │  │ $ 45.00      │  │ $ 80.00      │  │ $ 12.50      ││
│ ⚙️ Gestão Loja     │  │ [Fabricar]   │  │ [Fabricar]   │  │ [Fabricar]   ││
│                   │  └──────────────┘  └──────────────┘  └──────────────┘│
│                   │                                                      │
│                   │  MODO TABELA (Ledger / Registros):                   │
│                   │  DATA       ITEM       QTD   VALOR   STATUS   AÇÃO   │
│                   │  23/09      Madeira    x10   $ 5.00  [PAGO]   [Ver]  │
│                   │  23/09      Ferro      x4    $ 8.00  [PEND]   [Ver]  │
├───────────────────┴──────────────────────────────────────────────────────┤
│ [DRAWER INFERIOR / PAINEL DE DETALHES & RECEITA DE CRAFTING]             │
│  Item Selecionado: Revólver Cattleman  |  Requisitos: Ferro x3, Madeira x2│
│  Quantidade: [ ◄  1  ► ]   Tempo: 5s   |  [ BOTÃO DE AÇÃO: FABRICAR ]    │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Catálogo de Modos de Exibição (Data-Driven Viewports)

O Panel suporta 4 modos de visualização intercambiáveis via schema Lua:

### 3.1 Modo Vitrine / Grid (`type = "grid"`)
* **Uso:** Lojas de armeiro, alfaiataria, armazém geral, vitrines de cavalos, catálogo de itens.
* **Componentes por Card:**
  * Imagem ou ícone temático.
  * Título e subtítulo (ex: nome do item e descrição breve).
  * Tag de preço / raridade (`badge`, `price`).
  * Indicador de estoque (`stock`).
  * Botão de ação direta (Comprar / Inspecionar).

### 3.2 Modo Tabela / Livro Caixa (`type = "table"`)
* **Uso:** Livro de membros da gangue, folhas de pagamento, histórico de transações bancárias, lista de propriedades, denúncias/contratos.
* **Componentes:**
  * Colunas configuráveis com alinhamento (`left`, `center`, `right`).
  * Formatação de status pills (`pago`, `pendente`, `procurado`, `ativo`).
  * Botões de ação por linha (Editar, Demitir, Pagar, Inspecionar).
  * Paginação dinâmica integrada.

### 3.3 Modo Crafting / Bancada (`type = "craft"`)
* **Uso:** Forja, culinária na fogueira, carpintaria, destilaria de moonshine, alquimia.
* **Componentes:**
  * Lista de receitas disponíveis à esquerda.
  * Painel de detalhes à direita com:
    * Lista de ingredientes necessários vs. quantidade que o jogador possui no inventário (com indicadores visuais verde/vermelho).
    * Nível ou ferramenta exigida.
    * Barra de progresso de criação.
    * Seletor numérico de quantidade a produzir.

### 3.4 Modo Formulário / Gestão (`type = "form"`)
* **Uso:** Cadastros, ordens de serviço, precificação de produtos para donos de loja, concessão de cargos.
* **Componentes:**
  * Inputs de texto estilizados com placeholders.
  * Sliders de valores financeiros e margens de lucro.
  * Dropdowns e checkboxes de permissão.

---

## 4. Sistema Universal de Busca, Filtros e Paginação

### 4.1 Busca Textual em Tempo Real (Live Client Filter)
* **Campo de Busca Global:** Presente no cabeçalho do Panel. Filtra instantaneamente os itens do viewport ativo conforme o operador digita (`title`, `subtitle`, `id`, `category`), com debounce de 60 FPS e sem recarregar a tela.

### 4.2 Sistema Modular de Filtros Categóricos (Filter Chips)
* **Barra de Chips Sub-Aba:** Exibida no topo do viewport principal quando a aba ativa define opções de filtro.
* **Modo Declarativo (`filters`):** Permite configurar filtros pontuais com correspondência por chave (`key`) e valor (`value` ou lista de valores), além de contadores dinâmicos.
* **Modo Automático (`filterCategory = true`):** A UI extrai automaticamente todas as categorias distintas presentes no conjunto de dados (`items` ou `rows`), gerando os chips ordenados com contadores e o chip padrão "Todos".
* **Comportamento Reativo:** Clicar em um chip aplica o filtro visual instantaneamente, toca o áudio procedural de navegação (`playUiTick('nav')`) e redefine a página ativa para 1.

### 4.3 Sistema Universal de Paginação (Dynamic Paginator)
* **Configuração Granular (`pageSize` / `pagination`):** Suportado nativamente nas visões `grid` e `table`.
* **Cálculo de Slices:** O motor calcula em memória `(currentPage - 1) * pageSize` até `currentPage * pageSize` a partir dos dados já filtrados (pela busca textual e pelos chips).
* **Controles Integrados:**
  * Botões Anterior (`◄`) e Próximo (`►`) com desativação nos limites.
  * Indicador de página atual e total (`Página X de Y`).
  * Resumo numérico (`Exibindo 1-12 de 48 registros`).
* **Zero Overhead:** Se `pageSize` não for especificado ou for nulo, a visualização opera em scroll contínuo nativo.

---

## 5. Contrato de API Lua (Client-Side)

### 5.1 Definições de Tipos (EmmyLua)

```lua
---@class PanelCardItem
---@field public id string Identificador do item
---@field public title string Nome do produto/receita
---@field public subtitle? string Descrição curta
---@field public icon? string Caminho da imagem ou ícone
---@field public price? number Valor financeiro
---@field public badge? string Tag adicional (ex: "PROMOÇÃO", "RARO")
---@field public badgeType? "gold"|"green"|"danger"|"muted"
---@field public stock? number Quantidade disponível
---@field public disabled? boolean Se verdadeiro, impede seleção
---@field public requirements? { item: string, label: string, current: number, required: number }[] (Para Crafting)
---@field public metadata? table Dados adicionais customizados

---@class PanelTableColumn
---@field public key string Chave correspondente no objeto de dados
---@field public label string Título da coluna
---@field public align? "left"|"center"|"right"
---@field public width? string Ex: "20%", "150px"

---@class PanelFilterOption
---@field public id string Identificador único do filtro (ex: "all", "revolver", "ammo")
---@field public label string Texto exibido no chip (ex: "Todos", "Revólveres")
---@field public key? string Chave do objeto para filtrar (default: "category")
---@field public value? string|string[] Valor ou lista de valores aceitos
---@field public badge? string|number Tag opcional ou contador
---@field public default? boolean Se é o filtro ativo inicial

---@class PanelPagination
---@field public pageSize number Quantidade de registros por página
---@field public showSummary? boolean Se exibe resumo "Exibindo X-Y de Z" (default: true)

---@class PanelTab
---@field public id string Identificador da aba
---@field public label string Nome da aba
---@field public icon? string Ícone decorativo (ex: "fa-hammer")
---@field public viewType "grid"|"table"|"craft"|"queue"|"form"
---@field public items? PanelCardItem[] (Se for grid ou craft)
---@field public columns? PanelTableColumn[] (Se for table)
---@field public rows? table[] (Se for table)
---@field public filters? PanelFilterOption[] Lista explícita de filtros por chips
---@field public filterCategory? boolean Se verdadeiro, extrai categorias automaticamente
---@field public pageSize? number Atalho para paginação simples (ex: 12)
---@field public pagination? PanelPagination Configuração avançada de paginação

---@class DialogFieldOption
---@field public value string|number Valor do option
---@field public label string Rótulo exibido
---@field public selected? boolean Se selecionado inicialmente

---@class DialogField
---@field public id string Identificador do campo no payload retornado
---@field public label string Título do campo
---@field public type "text"|"number"|"select"|"textarea" Tipo do input
---@field public required? boolean Se o preenchimento é obrigatório
---@field public placeholder? string Texto de dica no input
---@field public default? any Valor padrão inicial
---@field public min? number (Para type number) Valor mínimo
---@field public max? number (Para type number) Valor máximo
---@field public step? number|string (Para type number) Incremento
---@field public rows? number (Para type textarea) Altura em linhas
---@field public options? DialogFieldOption[] (Para type select) Lista de opções

---@class DialogOptions
---@field public id? string Identificador único do diálogo
---@field public tag? string Categoria superior (ex: "ADMINISTRAÇÃO")
---@field public title string Título principal do diálogo
---@field public subtitle? string Informações contextuais (ex: Saldo atual)
---@field public submitLabel? string Texto do botão de confirmação (default: "CONFIRMAR")
---@field public cancelLabel? string Texto do botão de cancelamento (default: "CANCELAR")
---@field public fields DialogField[] Lista de campos dinâmicos
---@field public onSubmit? fun(values: table<string, any>) Callback invocado com os valores válidos
---@field public onCancel? fun() Callback invocado caso o operador cancele

---@class PanelOptions
---@field public id string Identificador único do painel
---@field public title string Título no cabeçalho
---@field public tag? string Categoria superior
---@field public subtitle? string Saldo do jogador ou informação complementar
---@field public showSearch? boolean Se exibe a barra de busca (default: true)
---@field public tabs PanelTab[] Abas verticais
---@field public onAction? fun(action: string, data: table, tabId: string, qty?: number)
---@field public onClose? fun()
```

### 5.2 Funções da Fachada `WestRP.Client.UI`

```lua
-- Abre o Painel Centralizado
WestRP.Client.UI.OpenPanel(options)

-- Fecha o Painel
WestRP.Client.UI.ClosePanel()

-- Checa se o painel está aberto
---@return boolean
WestRP.Client.UI.IsPanelOpen()

-- Abre Diálogo Modal Tipado (Prompt/Formulário)
WestRP.Client.UI.OpenDialog(options)

-- Fecha Diálogo Modal Tipado
WestRP.Client.UI.CloseDialog()

-- Checa se o diálogo está aberto
---@return boolean
WestRP.Client.UI.IsDialogOpen()
```

---

## 6. Fluxo de Foco e Transições

1. **Abertura (`OpenPanel`):**
   * Executa `SetNuiFocus(true, true)` (ativa cursor e bloqueia inputs do jogo).
   * O canvas central faz transição suave de escala (`scale: 0.95 -> 1.0` com `fade-in`).
   * Toca som procedural de abertura de livro/madeira (`playUiTick('confirm')`).
2. **Fechamento (`ClosePanel` / `ESC` / `[✕]`):**
   * Executa `SetNuiFocus(false, false)` (devolve controle total ao jogo).
   * Limpa estados e dispara callback `onClose`.
