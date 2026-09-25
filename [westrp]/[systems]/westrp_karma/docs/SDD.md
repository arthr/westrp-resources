# Software Design Document (SDD) — `westrp_karma`
> **Padrão:** Spec-Driven Development (SDD)  
> **Versão:** 1.0.0  
> **Status:** Ativo / Especificação Normativa  

---

## 1. Máquina de Estados Finitos de Alvos (Target FSM — Ecossistema PvE)

Para eliminar definitivamente os conflitos de detecção no RedM, cada entidade Ped (NPC civil, autoridade ou bandido do ecossistema PvE) envolvida em confronto é rastreada através de estados estritamente determinísticos. Confrontos PvP entre jogadores reais são processados de forma desacoplada pelo Canal Autoritativo de PvP no Servidor ([SPEC_DUAL_CHANNEL_PVE_PVP.md](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/docs/SPEC_DUAL_CHANNEL_PVE_PVP.md)):

```text
               ┌──────────────┐
               │    ACTIVE    │ (Alvo ativo, de pé ou em combate)
               └──────┬───────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
        │ Golpe Desarmado           │ Golpe Letal (Arma de fogo / Branca)
        │ (Soco / Chute / Asfixia)  │
        ▼                           ▼
┌──────────────┐             ┌──────────────┐
│ KNOCKED_OUT  │             │    KILLED    │ (Óbito direto / Assassinato)
└──────┬───────┘             └──────────────┘
       │
       │ Ataque subsequente no corpo caído
       │ (Tiro / Pisão deliberado após 1.5s)
       ▼
┌──────────────┐
│   EXECUTED   │ (Execução de alvo desacordado)
└──────────────┘
```

### Regras de Transição da FSM:
1. **`ACTIVE` -> `KNOCKED_OUT`**: Ocorre quando o alvo sofre dano desarmado e entra em estado de ragdoll ou incapacitação física. O timestamp da queda é registrado (`knockoutTimestamp`).
2. **Impacto de Ragdoll no Solo (Filtro de Descarte)**: Quando o corpo cai no chão, a colisão de física do motor do jogo emite novos eventos de dano. Se o alvo está em `KNOCKED_OUT` e o agressor **não** é o jogador de forma direta, o evento é **descartado imediatamente**.
3. **`KNOCKED_OUT` -> `EXECUTED`**: Só é permitido se:
   - O jogador atirar no corpo caído com arma de fogo/branca; OU
   - O jogador desferir um pisão/chute desarmado com distância `<= 2.5m` e após pelo menos `1.5s` do nocaute inicial (garantindo que o alvo já estava no chão e o ataque foi intencional).
4. **`ACTIVE` -> `KILLED`**: Ocorre quando o alvo sofre dano fatal de arma letal (fogo, lâmina, explosivo). Se o Ped cambalear e o óbito ocorrer instantes depois, o sistema preserva a hash da arma disparada para promover a ação de agressão para morte letal direta.

---

---

## 2. Contratos de Dados (Dual-Channel Architecture)

O sistema opera com dois canais de dados independentes ([SPEC_DUAL_CHANNEL_PVE_PVP.md](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/docs/SPEC_DUAL_CHANNEL_PVE_PVP.md)):

### 2.1 Canal PvE (Client -> Server via `westrp_karma:server:onCombatAction`)
Utilizado exclusivamente para ações físicas contra pedestres de IA (civis, autoridades e animais):
```lua
---@class CombatActionPayload
---@field targetType "CIVILIAN" | "LAWMAN" | "ANIMAL"
---@field actionType "KILL" | "KNOCKOUT" | "ASSAULT"
---@field initiative "UNPROVOKED" | "SELF_DEFENSE"
---@field isNegative boolean
---@field weaponHash integer
---@field wasKnockedOut boolean       -- True se transição foi KNOCKED_OUT -> EXECUTED
---@field wasAssaulted boolean        -- True se óbito ocorreu após dano não-letal prévio
---@field isHeadshot boolean?         -- True se tiro fatal atingiu crânio
---@field distanceMeters number?      -- Distância euclidiana do impacto
---@field weaponCategory string?      -- Categoria balística normalizada
---@field isBleedoutPromotion boolean? -- True se óbito tardio pós-sangramento sem bitributação
```

### 2.2 Canal PvP (Server-Authoritative via VORP Core Bridge)
Mortes entre jogadores reais não dependem da pipeline do cliente atacante. Elas são recebidas diretamente no servidor pelos eventos canônicos do framework:
* `vorp_core:Server:OnPlayerDeath(killerServerId, deathCause)`
* `baseevents:onPlayerKilled(killerid, data)`

---

## 3. Matriz de Consequências Morais (Deltas e Tiers)

| Tipo de Alvo | Ação Realizada | Canal de Processamento | Iniciativa | Delta Aplicado | Motivo Registrado |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Civil** | `KILL` (Direto) | PvE (Client Pipeline) | Não Provocada | **-35 pts** | Assassinato de civil inocente |
| **Civil** | `KNOCKOUT` | PvE (Client Pipeline) | Não Provocada | **-10 pts** | Nocaute / asfixia de civil inocente |
| **Civil** | `KILL` (Pós-Nocaute) | PvE (Client Pipeline) | Não Provocada | **-25 pts** | Execução de civil desacordado |
| **Civil** | `ASSAULT` (Não-letal) | PvE (Client Pipeline) | Não Provocada | **-5 pts** | Agressão corporal contra civil |
| **Autoridade** | `KILL` (Direto) | PvE (Client Pipeline) | Não Provocada | **-80 pts** | Assassinato de homem da lei |
| **Autoridade** | `KNOCKOUT` | PvE (Client Pipeline) | Não Provocada | **-35 pts** | Nocaute contra autoridade |
| **Autoridade** | `KILL` (Pós-Nocaute) | PvE (Client Pipeline) | Não Provocada | **-45 pts** | Execução de autoridade desacordada |
| **Jogador** | `KILL` (PK) | **PvP (Server Autoritativo)** | Não Provocada | **-120 pts** | Assassinato não provocado de cidadão |
| **Jogador** | `KILL` (Headshot) | **PvP (Server Autoritativo)** | Não Provocada | **-150 pts** | Assassinato de cidadão com tiro na cabeça |
| **Jogador** | `KNOCKOUT` | PvE/HUD (Visual) | Não Provocada | **-25 pts** | Nocaute injustificado de outro cidadão |
| **Qualquer** | Qualquer ação | PvE / PvP | **Legítima Defesa** | **0 pts** (ou bônus) | Honra preservada (ou bônus se for foragido) |
| **Animal** | Qualquer ação | PvE (Client Pipeline) | Qualquer | **0 pts** | Fauna silvestre (ignorado pelo Karma) |

---

## 4. Salvaguardas de Segurança e Performance

1. **Anti-Flood & Rate Limiting (PvE):** Agressões menores em pé possuem debounce de 2.5s por vítima para evitar saturação do console em brigas contínuas.
2. **Deduplicação de Morte PvP no Servidor:** Janela deslizante de 4 segundos por vítima (`recentPvPDeaths[victimSource]`) para descartar eventos duplicados entre `vorp_core:Server:OnPlayerDeath` e `baseevents:onPlayerKilled`.
3. **Dynamic Sleep do TickManager:**
   - Fora de combate: o loop de varredura dorme `1000ms` a `1500ms`.
   - Em combate ativo (`lastCombatTime < 8s` ou `IsPedInMeleeCombat`): o loop acelera para `150ms` para capturar desmaios silenciosos.
4. **Resolução Estrita de Arma em Mãos:** O cliente inspeciona a arma ativa na mão principal (`attachPoint 0`), com suporte condicional à mão secundária via validação de empunhadura ativa (`IsPedArmed`), prevenindo categoricamente que armas guardadas nos coldres do cinto ou costas sejam interpretadas como arma atual quando desarmado.
