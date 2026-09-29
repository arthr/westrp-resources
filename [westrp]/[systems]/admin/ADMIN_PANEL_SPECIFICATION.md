# Especificação Técnica de Engenharia — Admin Panel 3.0 & Hot Menu (`westrp_admin`)
> **Padrão:** Spec-Driven Development (SDD) & Rockstar Victorian Design System  
> **Módulos:** `westrp_admin` (Painel Central & Hot Menu Dock) e `westrp_ui` (Motor NUI Central)  
> **Versão:** 3.0.0  
> **Target:** RedM (CitizenFX RDR3) — CEF / Chromium / Lua 5.4  
> **Status:** Implementado & Validado  

---

## 1. Visão Geral & Hierarquia de Comandos

O **Admin Panel 3.0** redefine a arquitetura operacional da administração do WestRP, separando as ferramentas em dois pilares complementares de alta performance:

1. **Painel Administrativo Principal (`/admin` | `/adminpanel`)**:
   - Centro de comando e controle centralizado em canvas modal modal (`1160px` x `720px`).
   - Estética Victorian Dark Onyx com adornos de latão dourado envelhecido (`#d4af37`), cantos em arabescos ornamentais e efeito RedM Screen Blur nativo.
   - Apresenta Dashboard com KPIs em tempo real do servidor, catálogo de ações operacionais categorizadas, gerenciamento de jogadores, spawner de itens/armas, tabela de punições e configurações visuais.

2. **Hot Menu / Dock Lateral (`/admhot` | Tecla `[PGDOWN]` / `NEXT`)**:
   - Menu lateral rápido de atalhos em modo Câmera Livre (*Keep Input* com bloqueio cirúrgico de combate).
   - Renderização 100% dinâmica baseada na lista de ações rápidas habilitadas pelo operador na aba de Configurações do painel.
   - Posição da tela ancorada dinamicamente conforme preferência salva no KVP local (`top_left`, `top_right`, `mid_left`, `mid_right`, `bottom_left`, `bottom_right`).

---

## 2. Anatomia do Painel Administrativo (`/admin`)

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  [SIDEBAR ESQUERDA]           │  [CANVAS CENTRAL SUPERIOR - BRAND & HEADER]                            │
│  ⭐ WESTRP SERVER             │  WESTRP • DASHBOARD & GESTÃO                     Operador: [ID 1]      │
│  ADMIN MENU                   │  PAINEL ADMINISTRATIVO                           Online: 12            │
│  ──────────────────────────── ├────────────────────────────────────────────────────────────────────────┤
│  [ABAS DO SISTEMA]            │  [VIEWPORT DINÂMICA DA ABA SELECIONADA]                                │
│  🎛️ Dashboard                 │                                                                        │
│  👥 Jogadores        [12]     │  * DASHBOARD:                                                          │
│  📦 Item Spawner    [ITENS]   │    [KPI STAT CARDS: JOGADORES | UPTIME | PICO 24H | PICO GERAL]        │
│  🛡️ Armamento       [65]      │    [AÇÕES CATEGORIZADAS: TELEPORT | SELF | WORLD | SPAWN | ALL PLAYERS]│
│  ⚖️ Punições & Bans  [3]      │  * JOGADORES: Tabela de dados com modal contextual                     │
│  ⚙️ Configurações             │  * ITEM SPAWNER: Vitrine com filtros de categorias e busca             │
│  ──────────────────────────── │  * ARMAMENTO: Catálogo de armas de fogo, arremessáveis e munições      │
│  [RODAPÉ DO OPERADOR]         │  * PUNIÇÕES: Tabela de bans com revogação em 1 clique                  │
│  👤 John Doe (Super Admin)    │  * CONFIGURAÇÕES: Seletor de 6 posições e interruptores do Hot Menu    │
│  [ 🟢 Em Serviço ] (Toggle)   │                                                                        │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Especificação das Abas do Painel

### Aba 1: Dashboard Principal (`viewType = "dashboard"`)
* **KPI Stat Cards (Server Overview):**
  - **Jogadores Online:** Contador de clientes ativos vs `sv_maxclients` (ex: `12 / 32`).
  - **Tempo de Atividade (Uptime):** Duração contínua do servidor em horas e minutos.
  - **Pico em 24h:** Maior número de conexões simultâneas nas últimas 24 horas.
  - **Recorde Geral:** Pico histórico de jogadores desde o início do ciclo.
* **Ações Categorizadas (Grid Tiles):**
  - **TELEPORT:** Teleport to Waypoint, Teleport to Coords, Send Back, Guarma Island.
  - **SELF ACTIONS:** Ghost (Noclip), Godmode, Invisibility, Golden Cores, Infinite Ammo, Self Heal, Self Revive, Clean Ped.
  - **WORLD TOGGLES:** Clear Area, Clear Weather (Sunny), Freeze Time (12:00).
  - **SPAWN:** Spawn Horse (dialog modal de modelos), Spawn Wagon (dialog modal de carroças).
  - **ALL PLAYERS:** Heal All Players, Revive All Players, Bring All Players, Kick All Players (dialog de confirmação).
  - **SERVER:** Announcement (dialog modal de transmissão global), Server Logs (Discord webhook).

### Aba 2: Jogadores Online (`viewType = "table"`)
* Tabela completa com colunas: `ID`, `PERSONAGEM`, `STEAM`, `EMPREGO / CARGO`, `PERMISSÃO`, `DINHEIRO`, `ESTADO`.
* Clique na linha abre o menu contextual lateral (`player_action_dock`) permitindo:
  - Inspecionar Inventário em Tempo Real (`OpenInventoryInspector`).
  - Gestão Financeira & Moedas (`OpenCurrencyDialog` tipado com Cash, Gold, Rol).
  - Definir como Alvo do Spawner.
  - Teleportes direcionados (`GoTo`, `Bring`, `Spectate`).
  - Ações de saúde (`Heal`, `Revive`, `Respawn`, `Freeze`).
  - Punições (`Kick`, `Ban 3D`, `Ban Permanente`).
  - Trolagens administrativas (`Raio`, `Fogo`, `Céu`, `Ragdoll`, `Algemas`, `Bêbado`).

### Aba 3: Item Spawner (`viewType = "grid"`)
* Catálogo dinâmico de todos os itens registrados no ecossistema Vorp/WestRP.
* Filtros por categoria e busca em tempo real com debounce procedural.
* Seletor de quantidade no rodapé e entrega direta para o alvo selecionado (`currentTarget`).

### Aba 4: Armamento & Munições (`viewType = "grid"`)
* Catálogo completo extraído dos dados nativos do RDR3, incluindo revólveres, pistolas, rifles, escopetas, armas longas e armas de arremesso (`WEAPON_THROWN_MOLOTOV`, `WEAPON_THROWN_DYNAMITE`, `WEAPON_MOONSHINEJUG_MP`, etc.).
* Filtro categórico (`Revólveres`, `Pistolas`, `Rifles & Carabinas`, `Espingardas`, `Arco & Arremesso`, `Armas Brancas`, `Munições`).

### Aba 5: Punições & Bans (`viewType = "table"`)
* Tabela de punições ativas com busca por identificador Steam/Licença.
* Ação de desbanimento imediato e sincronizado.

### Aba 6: Configurações do Menu & Posição (`viewType = "settings"`)
* **Seletor de Posição da Dock (Hot Menu):**
  - Matriz com 6 posições gráficas: `Top Left`, `Top Right`, `Mid Left`, `Mid Right`, `Bottom Left`, `Bottom Right`.
  - Salva instantaneamente no KVP do cliente (`westrp_admin:dock_position`).
* **Interruptores de Ações Rápidas (Quick Actions Toggles):**
  - Lista de interruptores tipados (`.ui-switch`) permitindo ao administrador escolher exatamente quais ferramentas aparecem no seu menu lateral `/admhot`.
  - Persistido no KVP local (`westrp_admin:quick_actions`) em formato JSON.

---

## 4. Auditoria, Segurança e Zero-Trust

1. **Permissões RBAC Hierárquicas:**
   - Todos os eventos de servidor utilizam `WestRP.Server.Admin.Security.CanExecute(_source, action, targetId)`.
   - Proteção de hierarquia estrita: moderadores e administradores não podem punir ou alterar dados de administradores de hierarquia igual ou superior.
2. **Rate-Limiting:**
   - Proteção anti-spam de 400ms em todas as rotas administrativas.
3. **Webhooks Discord Estruturados:**
   - Cores e metadados categorizados por canal: Geral, Punições, Teleporte, Spawner e Ferramentas Dev.
4. **Desempenho (0.00ms Idle Resmon):**
   - Zero loops contínuos de verificação de tecla (utiliza `RegisterKeyMapping` e eventos NUI nativos).
