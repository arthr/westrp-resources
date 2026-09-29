# Matriz de Inventário & Migração Completa (SDD Spec 07)
> **Origens:** `rsm_nuikit`, `rsm_hud`, `rsm_stables`  
> **Destino Unificado:** `westrp_ui` (Single CEF Interface Service)  
> **Status:** Mapeamento 100% Concluído

---

## 1. Mapeamento de Assets & Identidade Visual (`rsm_nuikit` -> `westrp_ui`)

| Asset / Recurso Original | Caminho Origem (`rsm_nuikit`) | Caminho Destino (`westrp_ui`) | Finalidade |
| :--- | :--- | :--- | :--- |
| **Fontes Oficiais (.woff2)** | `web/public/fonts/*` | `web/public/fonts/*` | `RDR Lino`, `Hapna Slab`, `Redemption`, `RDR Catalogue` |
| **Texturas de Chrome (32 un)** | `web/public/tex/chrome/*` | `web/public/tex/chrome/*` | Máscaras 9-slice para caixas de seleção, molduras, divisores, botões |
| **Texturas de HUD (7 un)** | `web/public/tex/hud/*` | `web/public/tex/hud/*` | Ícones de vitais, anéis, trilhas de progresso e barra de prompt |
| **Tokens & Cores Base** | `web/src/styles.css` | `web/src/styles.css` | Tema Blood & Black, `--kit-accent`, `--kit-surface-rgb`, `--kit-text` |
| **Color Manager Engine** | `web/src/lib/theme.js` | `web/src/lib/theme.js` | Injeção e cálculo dinâmico de cores em tempo de execução |

---

## 2. Inventário de Componentes Base (`rsm_nuikit` -> `westrp_ui/src/components/kit/`)

| Componente | Origem | Destino | Função na Interface |
| :--- | :--- | :--- | :--- |
| `Button.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/Button.vue` | Botão padrão com variantes (`primary`, `danger`, `ghost`) |
| `IconButton.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/IconButton.vue` | Botão de ícone compacto para fechar ou ações rápidas |
| `ArrowButton.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/ArrowButton.vue` | Setas de navegação de carrossel |
| `TextInput.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/TextInput.vue` | Input de texto para nomes, buscas e formulários |
| `Checkbox.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/Checkbox.vue` | Seleção booleana estilo RDR2 |
| `RadioGroup.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/RadioGroup.vue` | Seleção exclusiva de opções |
| `Switch.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/Switch.vue` | Alternador liga/desliga |
| `Slider.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/Slider.vue` | Barra de ajuste contínuo (escala, opacidade, preços) |
| `SliderField.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/SliderField.vue` | Slider com campo de valor numérico integrado |
| `Stepper.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/Stepper.vue` | Incrementador/Decrementador de quantidades |
| `ArrowSelector.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/ArrowSelector.vue` | Seletor horizontal com setas para opções de personalização |
| `Card.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/Card.vue` | Container principal com máscara 9-slice de couro/pergaminho |
| `Brackets.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/Brackets.vue` | Cantoneiras decorativas para itens selecionados |
| `Divider.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/Divider.vue` | Divisor horizontal com ornamento RDR2 |
| `VDivider.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/VDivider.vue` | Divisor vertical de colunas |
| `RowLine.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/RowLine.vue` | Linha sutil de tabela |
| `Tabs.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/Tabs.vue` | Navegação de abas superior |
| `Tag.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/Tag.vue` | Badges de status (Equipado, Ativo, Ferido) |
| `Counter.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/Counter.vue` | Contador visual de limites |
| `Swatch.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/Swatch.vue` | Seletor de cores e pelagens |
| `KeyCap.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/KeyCap.vue` | Tecla estilizada em relevo |
| `Prompt.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/Prompt.vue` | Linha de instrução de tecla |
| `PressPrompt.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/PressPrompt.vue` | Prompt de pressionar com animação |
| `HoldPrompt.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/HoldPrompt.vue` | Prompt circular de segurar tecla |
| `CoreMeter.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/CoreMeter.vue` | Medidor de core + anel |
| `CoreIcon.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/CoreIcon.vue` | Ícone central de vitais |
| `ProgressBar.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/ProgressBar.vue` | Barra de progresso linear |
| `StatBar.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/StatBar.vue` | Barra de atributos de animais |
| `CoreStylePicker.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/CoreStylePicker.vue` | Seletor de estilos de anel |
| `ItemSlot.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/ItemSlot.vue` | Quadrado de inventário com contagem e raridade |
| `InventoryCard.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/InventoryCard.vue` | Grade de inventário com drag-and-drop |
| `DragGhost.vue` | `rsm_nuikit/web/src/components/kit/` | `src/components/kit/DragGhost.vue` | Elemento flutuante de arraste |

---

## 3. Mapeamento do Subsistema de HUD (`rsm_hud` -> `westrp_ui/src/components/hud/`)

| Módulo / Widget | Origem | Destino | Dados / Integração |
| :--- | :--- | :--- | :--- |
| **Vitais do Jogador** | `rsm_hud/web/src/components/widgets/PlayerCores.vue` | `src/components/hud/widgets/PlayerCores.vue` | Vida, Vigor, Dead Eye + Cores Dourados |
| **Vitais da Montaria** | `rsm_hud/web/src/components/widgets/HorseCores.vue` | `src/components/hud/widgets/HorseCores.vue` | Vida e Vigor do Cavalo (ativação contextual ao montar) |
| **Necessidades** | `rsm_hud/web/src/components/widgets/NeedsBar.vue` | `src/components/hud/widgets/NeedsBar.vue` | Fome, Sede (VORP Metabolism), Higiene, Estresse, Álcool |
| **Dinheiro & Ouro** | `rsm_hud/web/src/components/widgets/MoneyPanel.vue` | `src/components/hud/widgets/MoneyPanel.vue` | Saldo sincronizado via State Bags (`LocalPlayer.state['westrp:char']`) |
| **Relógio & Clima** | `rsm_hud/web/src/components/widgets/ClockWeather.vue` | `src/components/hud/widgets/ClockWeather.vue` | Horário do jogo e ícone do clima atual |
| **Localização** | `rsm_hud/web/src/components/widgets/LocationBanner.vue` | `src/components/hud/widgets/LocationBanner.vue` | Nome da cidade, distrito e bússola cardinal |
| **Indicador de Voz** | `rsm_hud/web/src/components/widgets/VoiceIndicator.vue` | `src/components/hud/widgets/VoiceIndicator.vue` | Alcance (sussurro, normal, grito) e detecção de voz |
| **Status de Armas** | `rsm_hud/web/src/components/widgets/WeaponAmmo.vue` | `src/components/hud/widgets/WeaponAmmo.vue` | Balas no pente, reserva, ícone da arma e desgaste |
| **Recompensa / Lei** | `rsm_hud/web/src/components/widgets/WantedStatus.vue` | `src/components/hud/widgets/WantedStatus.vue` | Valor da recompensa ativa por região |
| **Efeitos de Status** | `rsm_hud/web/src/components/widgets/StatusEffects.vue` | `src/components/hud/widgets/StatusEffects.vue` | Frio, Calor, Doente, Envenenado, Sangrando |
| **Cartão de Identidade** | `rsm_hud/web/src/components/widgets/IdentityCard.vue` | `src/components/hud/widgets/IdentityCard.vue` | Nome do personagem, ID, emprego e cargo |
| **Editor de Layout** | `rsm_hud/web/src/components/layout/LayoutManager.vue` | `src/components/hud/layout/LayoutManager.vue` | Arraste livre, escala, opacidade e comando `/hudlayout` |

---

## 4. Mapeamento do Módulo de Estábulos (`rsm_stables` -> `westrp_ui/src/views/stables/`)

| Tela / Módulo | Origem | Destino | Função |
| :--- | :--- | :--- | :--- |
| **Shell do Estábulo** | `rsm_stables/web/src/components/StableShell.vue` | `src/views/stables/StableView.vue` | Estrutura principal da janela com abas e cabeçalho |
| **Loja de Cavalos & Carroças** | `rsm_stables/web/src/components/shop/` | `src/views/stables/tabs/ShopTab.vue` | Catálogo de compra de montarias e veículos com preview 3D |
| **Meus Animais** | `rsm_stables/web/src/components/stable/` | `src/views/stables/tabs/MyRidesTab.vue` | Lista de montarias do jogador, retirada, guarda e cura |
| **Customização de Arreios** | `rsm_stables/web/src/components/tack/` | `src/views/stables/tabs/TackTab.vue` | Selas, mantas, estribos, alforjes, crinas e caudas |
| **Transferência de Animais** | `rsm_stables/web/src/components/transfer/` | `src/views/stables/tabs/TransferTab.vue` | Venda ou doação de montarias para jogadores próximos |
| **Estado Reativo do Estábulo** | `rsm_stables/web/src/state/stable.js` | `src/stores/stablesStore.js` | Gerenciamento de estado, seleções e requisições NUI |

---

## 5. Mapeamento de Funções & Exports Lua

| Export Original | Origem | Novo Export Unificado | Escopo |
| :--- | :--- | :--- | :--- |
| `Notify` | `rsm_nuikit` | `exports.westrp_ui:Notify(kind, title, body, duration)` | Client & Server |
| `Confirm` | `rsm_nuikit` | `exports.westrp_ui:Confirm(opts, cb)` | Client & Server |
| `SetCores` | `rsm_nuikit` | `exports.westrp_ui:SetCores(cores)` | Client |
| `SetMoney` | `rsm_nuikit` | `exports.westrp_ui:SetMoney(cash, gold)` | Client |
| `ShowHelp` / `HideHelp` | `rsm_nuikit` | `exports.westrp_ui:ShowHelp(text, key)` | Client |
| `SetHudHidden` | `rsm_nuikit` | `exports.westrp_ui:SetHudHidden(hidden)` | Client |
| `setNeed` / `addNeed` | `rsm_hud` | `exports.westrp_ui:SetNeed(src, need, value)` | Server |
| `setBounty` / `clearBounty` | `rsm_hud` | `exports.westrp_ui:SetBounty(src, amount, region)` | Server |
| `setEffect` | `rsm_hud` | `exports.westrp_ui:SetEffect(src, effect, active)` | Server |
| *Novo:* `OpenView` | Novo | `exports.westrp_ui:OpenView(viewName, data, cb)` | Client |
| *Novo:* `InputDialog` | Novo | `exports.westrp_ui:InputDialog(schema, cb)` | Client |
| *Novo:* `ProgressBar` | Novo | `exports.westrp_ui:ProgressBar(opts, cb)` | Client |
