# Índice de Especificações Técnicas (SDD) — `ui` v2.0
> **Metodologia:** Spec-Driven Development (SDD) & Clean Architecture  
> **Target:** RedM (CitizenFX RDR3 - Game Build 1491+)  
> **Módulo:** `[westrp]/[core]/ui`

---

## 1. O que é esta documentação?

Este diretório contém a especificação técnica integral que rege a reconstrução do **`ui`** como o **Single Chromium NUI Engine & Interface Service** definitivo do ecossistema WestRP.

Ela consolida e unifica todos os recursos, componentes, estilos e estados que estavam fragmentados entre:
- `rsm_nuikit` (identidade visual, design system, 36 componentes de kit, toasts, confirmações).
- `rsm_hud` (vitais do jogador e montaria, necessidades, dinheiro, relógio, layout manager `/hudlayout`).
- `stables` (módulo de estábulos, loja de cavalos e carroças, personalização de arreios e transferências).

---

## 2. Mapa das Especificações Técnicas (Specs)

| Documento | Título | Escopo e Conteúdo |
| :--- | :--- | :--- |
| **[00_ARCHITECTURE_SPEC.md](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/ui/plans/00_ARCHITECTURE_SPEC.md)** | **Arquitetura & Engenharia do Sistema** | Modelo Single CEF, hierarquia de camadas z-index, compatibilidade com CEF 103, `FocusManager` centralizado e barramento IPC. |
| **[01_DESIGN_SYSTEM_AND_TOKENS.md](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/ui/plans/01_DESIGN_SYSTEM_AND_TOKENS.md)** | **Design System & Tokens Visuais** | Tema Blood & Black, fontes oficiais RDR2 (.woff2), texturas 9-slice CSS masks e configuração Tailwind v3. |
| **[02_COMPONENT_SPECIFICATION.md](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/ui/plans/02_COMPONENT_SPECIFICATION.md)** | **Especificação de Componentes Base** | Catálogo completo dos 36 componentes base (`Button`, `Card`, `ItemSlot`, `Slider`, `TextInput`, etc.) e modais compostos. |
| **[03_HUD_SUBSYSTEM_SPEC.md](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/ui/plans/03_HUD_SUBSYSTEM_SPEC.md)** | **Subsistema de HUD & Status** | Widgets de vitais, montaria, necessidades, relógio, dinheiro, bússola, reatividade via State Bags e editor `/hudlayout`. |
| **[04_APP_AND_STABLES_VIEW_SPEC.md](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/ui/plans/04_APP_AND_STABLES_VIEW_SPEC.md)** | **Engine de Views & Módulo de Estábulos** | Host de telas complexas (`ViewRouter.vue`), especificação da tela de estábulos (`StableView.vue`) e protocolo NUI. |
| **[05_LUA_API_AND_EXPORTS_SPEC.md](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/ui/plans/05_LUA_API_AND_EXPORTS_SPEC.md)** | **API Lua & Exports** | Contrato formal de todos os exports (`Notify`, `Confirm`, `InputDialog`, `ProgressBar`, `OpenView`, `SetCores`, etc.). |
| **[06_EXECUTION_ROADMAP_AND_TASKS.md](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/ui/plans/06_EXECUTION_ROADMAP_AND_TASKS.md)** | **Roadmap de Execução & Tarefas** | 6 Fases estruturadas com tarefas, subtarefas, critérios de aceite (DoD) e dependências de implementação. |
| **[07_MIGRATION_INVENTORY_MATRIX.md](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/ui/plans/07_MIGRATION_INVENTORY_MATRIX.md)** | **Matriz de Inventário & Migração** | Inventário 100% exaustivo de todos os 36 componentes, 11 widgets de HUD, 4 abas de estábulos, assets e exports mapeados. |

---

## 3. Diretrizes Inegociáveis de Desenvolvimento

1. **Single CEF:** Nenhum outro script de gameplay deve ter pasta `web` ou `ui_page`. O `ui` é o único host de renderização.
2. **Tailwind v3:** Manter `tailwindcss@^3.4.17` para compatibilidade estrita com Chromium CEF v103.
3. **Gerenciamento Seguro de Foco:** Todas as chamadas a `SetNuiFocus` passam exclusivamente pelo `FocusManager` do `ui`.
4. **Reatividade Zero-Resmon:** Atualizações de HUD utilizam CitizenFX State Bags (`LocalPlayer.state`), eliminando loops de polling desnecessários.
