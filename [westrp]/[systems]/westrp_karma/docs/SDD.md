# Software Design Document (SDD) — `westrp_karma`
> **Padrão:** Spec-Driven Development (SDD)  
> **Versão:** 1.0.0  
> **Status:** Ativo / Especificação Normativa  

---

## 1. Máquina de Estados Finitos de Alvos (Target FSM)

Para eliminar definitivamente os conflitos de detecção no RedM, cada entidade Ped envolvida em confronto é rastreada através de estados estritamente determinísticos:

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

## 2. Contrato de Dados (Payload Unificado)

O cliente envia exclusivamente a intenção física da ação:

```lua
---@class CombatActionPayload
---@field targetType "CIVILIAN" | "LAWMAN" | "PLAYER" | "ANIMAL"
---@field actionType "KILL" | "KNOCKOUT" | "ASSAULT"
---@field initiative "UNPROVOKED" | "SELF_DEFENSE"
---@field isNegative boolean
---@field weaponHash integer
---@field victimServerId integer? -- Apenas se targetType == "PLAYER"
---@field wasKnockedOut boolean   -- True se transição foi KNOCKED_OUT -> EXECUTED
---@field wasAssaulted boolean    -- True se óbito ocorreu após dano não-letal prévio
```

---

## 3. Matriz de Consequências Morais (Deltas e Tiers)

| Tipo de Alvo | Ação Realizada | Iniciativa | Delta Aplicado | Motivo Registrado |
| :--- | :--- | :--- | :--- | :--- |
| **Civil** | `KILL` (Direto) | Não Provocada | **-35 pts** | Assassinato de civil inocente |
| **Civil** | `KNOCKOUT` | Não Provocada | **-10 pts** | Nocaute / asfixia de civil inocente |
| **Civil** | `KILL` (Pós-Nocaute) | Não Provocada | **-25 pts** | Execução de civil desacordado |
| **Civil** | `ASSAULT` (Não-letal) | Não Provocada | **-5 pts** | Agressão corporal contra civil |
| **Autoridade** | `KILL` (Direto) | Não Provocada | **-80 pts** | Assassinato de homem da lei |
| **Autoridade** | `KNOCKOUT` | Não Provocada | **-35 pts** | Nocaute contra autoridade |
| **Autoridade** | `KILL` (Pós-Nocaute) | Não Provocada | **-45 pts** | Execução de autoridade desacordada |
| **Jogador** | `KILL` (PK) | Não Provocada | **-120 pts** | Assassinato não provocado de cidadão |
| **Jogador** | `KNOCKOUT` | Não Provocada | **-25 pts** | Nocaute injustificado de outro cidadão |
| **Qualquer** | Qualquer ação | **Legítima Defesa** | **0 pts** (ou bônus) | Honra preservada (ou bônus se for foragido) |
| **Animal** | Qualquer ação | Qualquer | **0 pts** | Fauna silvestre (ignorado pelo Karma) |

---

## 4. Salvaguardas de Segurança e Performance

1. **Anti-Flood & Rate Limiting:** Agressões menores em pé possuem debounce de 2.5s por vítima para evitar saturação do console em brigas contínuas.
2. **Dynamic Sleep do TickManager:**
   - Fora de combate: o loop de varredura dorme `1000ms` a `1500ms`.
   - Em combate ativo (`lastCombatTime < 8s` ou `IsPedInMeleeCombat`): o loop acelera para `150ms` para capturar desmaios silenciosos.
3. **Resolução de Armas em Múltiplos Pontos:** O cliente inspeciona coldres primários, secundários e coldres de costas (`attachPoint` 0, 1, 2, 3), eliminando a falha em que armas longas eram classificadas como desarmado.
