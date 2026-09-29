# Especificação dos Componentes da Biblioteca Base (SDD Spec 02)
> **Padrão:** Vue 3 Composition API (`<script setup>`)  
> **Localização:** `src/components/kit/`  
> **Objetivo:** Conjunto padronizado de componentes reutilizáveis para HUD, Modais, Menus e Apps

---

## 1. Inventário dos Componentes Base (36 Componentes)

Todos os componentes abaixo são migrados e unificados de `rsm_nuikit/web/src/components/kit/`:

| Categoria | Componente | Props Principais | Descrição e Comportamento |
| :--- | :--- | :--- | :--- |
| **Ações** | `Button.vue` | `variant` (primary, secondary, danger, ghost), `size` (sm, md, lg), `icon`, `disabled` | Botão temático com efeito hover e som nativo de clique |
| | `IconButton.vue` | `icon`, `title`, `variant`, `size`, `active` | Botão quadrado para ícones compactos de ação |
| | `ArrowButton.vue` | `direction` (left, right), `disabled` | Botão estilizado com setas para carrosséis/seletores |
| **Formulários & Inputs** | `TextInput.vue` | `modelValue`, `placeholder`, `label`, `error`, `maxlength`, `icon` | Input de texto estilizado com foco iluminado em vermelho |
| | `Checkbox.vue` | `modelValue`, `label`, `description`, `disabled` | Caixa de seleção estilo RDR2 com borda trabalhada |
| | `RadioGroup.vue` | `modelValue`, `options`, `label` | Grupo de rádio com seleção exclusiva de itens |
| | `Switch.vue` | `modelValue`, `label`, `disabled` | Interruptor liga/desliga com transição animada |
| | `Slider.vue` | `modelValue`, `min`, `max`, `step`, `unit` | Barra deslizante com indicador de porcentagem ou valor |
| | `SliderField.vue` | `modelValue`, `label`, `min`, `max` | Combinação de label + Slider com edição precisa |
| | `Stepper.vue` | `modelValue`, `min`, `max`, `step` | Controle numérico com botões [-] e [+] para quantidades |
| | `ArrowSelector.vue` | `modelValue`, `options`, `label` | Seletor horizontal com setas (estilo personalização RDR2) |
| **Containers & Layout** | `Card.vue` | `title`, `kicker`, `variant` (solid, transparent), `padded` | Painel com máscara de couro/pergaminho e borda texturizada |
| | `Brackets.vue` | `color`, `size` | Cantoneiras decorativas RDR2 para focar elementos ativos |
| | `Divider.vue` | `ornament` (boolean) | Linha divisória horizontal com nó central opcional |
| | `VDivider.vue` | `height` | Linha divisória vertical para separar colunas |
| | `RowLine.vue` | - | Linha pontilhada tênue de separação de linhas de dados |
| | `Tabs.vue` | `modelValue`, `tabs` ({ id, label, count, icon }) | Barra superior de abas de navegação de menus |
| | `Tag.vue` | `variant` (accent, success, warning, dim) | Selo/badge de status (ex: "Equipado", "Esgotado", "Ferido") |
| | `Counter.vue` | `current`, `max` | Exibição de slots ocupados (ex: "4 / 8") |
| | `Swatch.vue` | `color`, `active`, `label` | Mostrador de cor/pelagem para seleção visual rápida |
| **Prompts & Teclas** | `KeyCap.vue` | `keyName` (ex: "E", "ESC", "SPACE", "G") | Tecla física estilizada com relevo e sombra |
| | `Prompt.vue` | `keyName`, `label` | Linha clássica de prompt de controle (Ícone de tecla + Ação) |
| | `PressPrompt.vue` | `keyName`, `label`, `active` | Prompt que pisca na ativação |
| | `HoldPrompt.vue` | `keyName`, `label`, `progress` (0-100) | Prompt circular de segurar tecla com animação SVG de preenchimento |
| **Medidores & Barras** | `CoreMeter.vue` | `type` (health, stamina, deadeye), `core` (0-100), `ring` (0-100), `style` | Medidor de vitais completo (anel externo + ícone interno) |
| | `CoreIcon.vue` | `type`, `level`, `color` | Ícone interno de coração, raio ou olho |
| | `ProgressBar.vue` | `value` (0-100), `color`, `label` | Barra linear de progresso com animação suave |
| | `StatBar.vue` | `value`, `max`, `bonus` | Barra de atributos de animal (Velocidade, Aceleração) |
| | `CoreStylePicker.vue` | `modelValue` | Componente do estúdio para alternar estilo dos anéis |
| **Inventário & Itens** | `ItemSlot.vue` | `item` ({ name, count, image, rarity, locked }), `selected`, `active` | Quadrado de inventário com borda ornamental e contador |
| | `InventoryCard.vue` | `slots`, `capacity`, `weight` | Grid de inventário com drag-and-drop e tooltips |
| | `DragGhost.vue` | `item` | Elemento flutuante que segue o cursor durante o arraste |

---

## 2. Componentes Compostos do Sistema (Camada de Serviços)

### 2.1 `ToastStack.vue` (Sistema de Notificações)
- Renderiza pilha de avisos em posição configurável (superior direita por padrão).
- Animação de entrada `animate-kit-slide` e barra regressiva de duração.
- Tipos suportados: `info`, `success`, `warning`, `error`, `bounty`.

### 2.2 `ConfirmDialog.vue` (Diálogos Modais)
- Substitui o popup estático anterior por um componente dinâmico com:
  - Título, kicker (ex: "Valentine Gunsmith"), descrição, tabela de custos/itens (`lines`).
  - Botão de confirmação com destaque em vermelho/perigo (`danger`).
  - Suporte total a navegação por teclado (Enter = Confirmar, ESC = Cancelar).
  - Captura e devolução de foco segura via `FocusManager`.

### 2.3 `ContextMenu.vue` & `RadialMenu.vue` (Novo Serviço de Ações Rápidas)
- **ContextMenu:** Menu contextual vertical que surge na posição do mouse ou ao lado de um elemento selecionado.
- **RadialMenu:** Roda circular de 8 posições para interações rápidas de montaria, algemas e emotes (substituindo o antigo menu radial do `westrp_ui`).

### 2.4 `ActionProgressBar.vue` (Barra de Progresso com Bloqueio de Ação)
- Suporta dois modos visuais:
  - **Circular Hold:** Aparece no centro inferior da tela com o ícone da ação sendo realizada.
  - **Linear Clean:** Barra sutil com percentual e label explicativa (ex: "Ferrando cavalo...").
- Dispara evento de cancelamento caso o jogador sofra dano ou pressione tecla de cancelamento.
