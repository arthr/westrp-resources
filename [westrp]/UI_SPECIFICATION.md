# Especificação de Interface e Design System — WestRP UI Dock Engine
> **Padrão:** Spec-Driven Development (SDD)  
> **Módulo:** `westrp_ui` (Serviço Centralizado de NUI)  
> **Versão:** 1.0.0  
> **Target:** RedM (CitizenFX RDR3) — CEF / Chromium Embedded Framework  
> **Inspiração / Origem:** HUD Dock Lateral Refatorado (Estilo Nativo Rockstar / RDR2 Interaction Menu)  

---

## 1. Visão Geral e Propósito

O **`westrp_ui`** é o serviço unificado de interface gráfica e menus do ecossistema WestRP. Ele transforma a interface de dock lateral (350px, ancorada à esquerda, navegação por teclado/mouse e sintetizador de áudio procedural via Web Audio API) em um **motor NUI 100% orientado a dados (Data-Driven UI Engine)**.

### 1.1 O Princípio Central: Single NUI Instance
* **Zero Fragmentação:** Nenhum módulo de gameplay (`[systems]`) carrega seu próprio `ui_page`.
* **Zero Código Web Duplicado:** Criar uma loja, banco, estábulo, barbearia, crafting ou menu de interação exige **apenas passar uma tabela Lua** para a API do `westrp_ui`.
* **Desempenho Extremo:** Uma única instância do Chromium (CEF) rodando em segundo plano economiza centenas de megabytes de RAM e tempo de GPU.

---

## 2. Anatomia Visual e Design Tokens

A identidade visual é rigorosamente inspirada na elegância rústica do Velho Oeste (1899–1910) e no design de menus nativos da Rockstar:

```
┌────────────────────────────────────────────────────────┐
│ [CABEÇALHO ROCKSTAR]                                   │
│  FRONTIER ADMINISTRATION                 1 / 8         │
│  REGISTRO DE COMANDO                                   │
├────────────────────────────────────────────────────────┤
│ [BARRA DE ABAS HORIZONTAIS]                            │
│  ◄ [ ABA 1 / 4 ]  ESTABELECIMENTO  ►                   │
├────────────────────────────────────────────────────────┤
│ [BREADCRUMB / RETORNO DE SUBMENU] (Opcional)           │
│  ◂ BACKSPACE   COMPRA DE BEBIDAS                       │
├────────────────────────────────────────────────────────┤
│ [VIEWPORT DE ITENS INTERATIVOS] (Rolagem Dinâmica)     │
│  ► Garrafa de Whiskey               $ 2.50             │
│    Cerveja da Casa                  $ 0.75             │
│    Permitir Fumar no Balcão         [ ON ]             │
│    Quantidade por Rodada            ◄ 3 ►              │
│    Acessar Depósito Privado         ▸                  │
├────────────────────────────────────────────────────────┤
│ [CAIXA DE CONTEXTO / DESCRIÇÃO]                        │
│  Bebida destilada de alta qualidade do Saloon.         │
├────────────────────────────────────────────────────────┤
│ [LEGENDA DE TECLAS DE NAVEGAÇÃO]                       │
│  ▲▼ Navegar  ◄► Abas/Opções  ↵ Confirmar  BACK Voltar  │
└────────────────────────────────────────────────────────┘
```

### 2.1 Tokens de Estilo
* **Dimensões:** Largura fixa de `350px`, margem `left: 36px`, `top: 48px`.
* **Tipografia:**
  * Títulos e Tags: `'Cinzel', serif` (autoridade, elegância histórica).
  * Textos, Rótulos e Dados: `'Inter', sans-serif` (legibilidade cristalina em qualquer resolução).
* **Paleta de Cores:**
  * Fundo do Dock: `rgba(13, 12, 11, 0.94)` (couro negro envelhecido).
  * Fundo do Header: `rgba(8, 7, 6, 0.98)` (ébano profundo).
  * Destaques e Bordas: Ouro Velho (`#d4af37`, `#cba332`) com gradiente sutil.
  * Seleção Ativa: `rgba(212, 175, 55, 0.18)` com barra de acento dourada à esquerda.
  * Ações Críticas / Perigo: Vermelho carmesim (`#dc3545`).
  * Indicadores de Sucesso: Verde esmeralda (`#50c878`).

---

## 3. Catálogo de Controles e Componentes Suportados

Cada item de menu declarado em Lua deve ser mapeado para um dos seguintes tipos:

| Tipo | Descrição | Comportamento Interativo |
| :--- | :--- | :--- |
| **`button`** | Ação padrão ou item de compra/venda. | Dispara callback ao pressionar `Enter` ou clicar. Suporta badge lateral (`$ 5.00`, contadores) e estilo `danger`. |
| **`toggle`** | Interruptor On/Off (Switch). | Alterna estado (`true`/`false`) com feedback visual de pílula verde/cinza e som tátil. |
| **`slider`** | Seletor horizontal de valores ou listas. | Navega com `◄` e `►`. Suporta números (`min`, `max`, `step`) ou lista textual (`options = {'Opção A', 'Opção B'}`). |
| **`submenu`** | Link para lista de itens filha. | Ao selecionar, empilha a navegação, atualiza o breadcrumb (`◂ BACKSPACE`) e exibe os novos itens. |
| **`separator`** | Separador estético de grupo. | Rótulo não navegável que divide seções visualmente. |

---

## 4. Motor de Áudio Procedural (Web Audio API)

Para garantir **zero lag de áudio**, sem necessidade de baixar arquivos `.wav` ou `.ogg`, a UI utiliza osciladores nativos sintetizados em tempo real:

* **Nav Tick (`nav`):** `650Hz` decaindo para `320Hz` em 20ms (feedback sutil de navegação entre itens).
* **Confirm Chime (`confirm`):** `880Hz` subindo para `1320Hz` em 40ms (confirmação nítida de ação executada).
* **Back Chime (`back`):** `450Hz` decaindo para `200Hz` em 30ms (retorno de submenu ou fechamento).
* **Error Thud (`error`):** `220Hz` decaindo para `110Hz` em 50ms (tentativa de ação inválida/bloqueada).

---

## 5. Contratos de API Lua (Client-Side)

### 5.1 Definições de Tipos (EmmyLua Annotations)

```lua
---@class DockItem
---@field public id string Identificador único do item
---@field public label string Texto exibido
---@field public type "button"|"toggle"|"slider"|"submenu"|"separator"
---@field public description? string Texto exibido na caixa de contexto inferior
---@field public badge? string Texto ou valor no canto direito (ex: "$ 50.00", "Novo")
---@field public badgeType? "gold"|"green"|"danger"|"muted"
---@field public danger? boolean Se verdadeiro, destaca o item em tom de alerta vermelho
---@field public disabled? boolean Se verdadeiro, impede seleção e esmaece o item
---@field public checked? boolean Estado inicial para itens do tipo 'toggle'
---@field public value? any Valor inicial para 'slider'
---@field public min? number Valor mínimo se 'slider' numérico
---@field public max? number Valor máximo se 'slider' numérico
---@field public step? number Incremento do 'slider' numérico
---@field public options? string[] Lista de opções textuais para 'slider'
---@field public subItems? DockItem[] Lista de itens filhos se for 'submenu'

---@class DockTab
---@field public id string
---@field public name string
---@field public items DockItem[]

---@class DockOptions
---@field public id string Identificador único do menu
---@field public title string Título principal do menu
---@field public tag? string Tag de categoria superior (ex: "ESTABELECIMENTO", "STAFF")
---@field public keepInput? boolean Se verdadeiro, mantém câmera livre durante a navegação
---@field public tabs? DockTab[] Lista de abas horizontais
---@field public items? DockItem[] Lista direta de itens (se o menu não usar abas)
---@field public onSelect? fun(item: DockItem, tabId?: string) Callback disparado ao executar ação
---@field public onChange? fun(item: DockItem, newValue: any, tabId?: string) Callback para toggle/slider
---@field public onClose? fun() Callback disparado ao fechar
```

### 5.2 Funções da Fachada `WestRP.Client.UI`

```lua
-- Abre o Dock Lateral
WestRP.Client.UI.OpenDock(options)

-- Fecha o Dock Lateral
WestRP.Client.UI.CloseDock()

-- Checa se o Dock está visível
---@return boolean
WestRP.Client.UI.IsDockOpen()

-- Atualiza dados de um item em tempo real sem recarregar o menu
WestRP.Client.UI.UpdateItem(tabId, itemId, updates)

-- Dispara notificação toast elegante no padrão Rockstar
WestRP.Client.UI.ShowToast(title, message, type, duration)
```

---

## 6. Protocolo de Comunicação NUI (NUI Bridge)

A comunicação entre o Client Lua e o Chromium ocorre via `SendNUIMessage` e `RegisterNUICallback`:

### 6.1 Mensagens do Client Lua -> NUI (JavaScript)
* **`westrp_ui:open`**: Envia o schema completo do menu para renderização imediata.
* **`westrp_ui:close`**: Oculta o container e limpa estados.
* **`westrp_ui:updateItem`**: Atualiza label, badge ou estado de um item específico.
* **`westrp_ui:toast`**: Injeta um toast na pilha de notificações temporárias.

### 6.2 Callbacks do NUI (JavaScript) -> Client Lua
* **`westrp_ui:selectItem`**: `{ tabId, itemId, item }`
* **`westrp_ui:changeValue`**: `{ tabId, itemId, newValue }`
* **`westrp_ui:tabChanged`**: `{ tabIndex, tabId }`
* **`westrp_ui:closed`**: `{ reason }` (fechado via ESC, Backspace no topo ou comando)

---

## 7. Controle de Câmera e Foco (KeepInput Pattern)

Para proporcionar a experiência autêntica de RDR2 (onde o jogador pode navegar no menu enquanto observa o ambiente ao redor):
* **Modo Câmera Livre (`keepInput = true`):**
  * O `SetNuiFocus(true, false)` é ativado com `SetNuiFocusKeepInput(true)`.
  * Um loop leve no Client desabilita as teclas de combate e troca de arma (ex: disparo, socos), enquanto preserva o controle livre do mouse para rotação de câmera.
* **Modo Foco Total (`keepInput = false`):**
  * Cursor visível na tela (`SetNuiFocus(true, true)`), ideal para quando o menu exigir cliques precisos ou formulários.
