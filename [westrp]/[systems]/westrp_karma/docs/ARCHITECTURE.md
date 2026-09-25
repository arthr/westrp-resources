# Arquitetura de Software — `westrp_karma`
> **Padrão:** WestRP System Specification & Zero-Trust  
> **Versão:** 1.0.0  
> **Target:** RedM / RDR2 (Cfx.re Game Build 1491+)  
> **Dependências:** `westrp_core`, `oxmysql`, VORP Core (via Bridge)  

---

## 1. Visão Geral da Arquitetura

O **`westrp_karma`** é o subsistema de moralidade dinâmica, reputação social e registro de conduta do ecossistema WestRP. Ele foi concebido para operar em harmonia com o núcleo `westrp_core`, observando três pilares fundamentais:

1. **Performance Absoluta (0.00ms em Idle):** Utilização do `WestRP.Client.TickManager` com sono adaptativo dinâmico, evitando loops ociosos.
2. **Segurança Zero-Trust:** O cliente nunca dita seu próprio karma nem envia modificações arbitrárias de pontuação moral. Ele reporta apenas intenções e eventos de combate físicos verificáveis. A validação, cálculo de patamar moral e persistência são 100% responsabilidade do servidor.
3. **Máquina de Estados de Combate Determinística:** Alvos de agressão transitam de forma clara entre estados finitos (`ACTIVE` -> `KNOCKED_OUT` -> `EXECUTED` ou `ACTIVE` -> `KILLED`), prevenindo conflitos entre nocautes desarmados, colisões de física de ragdoll e assassinatos diretos.

---

## 2. Diagrama de Fluxo de Dados e Camadas

```text
                            ┌────────────────────────┐
                            │      CLIENT REDM       │
                            │                        │
                            │  CEventNetworkEntity-  │
                            │         Damage         │
                            │           │            │
                            │           ▼            │
                            │   [Combat Pipeline]    │
                            │   - Stages & Engine    │
                            │   - State Evaluator    │
                            │   - Combat Watcher     │
                            └───────────┬────────────┘
                                        │
                                        │ NetEvent Seguro:
                                        │ 'westrp_karma:server:reportCombat'
                                        │ (victimNetId, action, weaponHash)
                                        ▼
                            ┌────────────────────────┐
                            │     SERVER PIPELINE    │
                            │                        │
                            │ 1. Rate-Limit & Sanity │
                            │ 2. Distância Física    │
                            │ 3. Legítima Defesa     │
                            │ 4. Cálculo de Delta    │
                            │ 5. Avaliação de Tier   │
                            └───────────┬────────────┘
                                        │
                         ┌──────────────┴──────────────┐
                         ▼                             ▼
              ┌─────────────────────┐       ┌─────────────────────┐
              │    Database Sync    │       │     Client Sync     │
              │  (oxmysql / Cache)  │       │ (onKarmaUpdated)    │
              │  - characters.karma │       │ - HUD / Notificação │
              └─────────────────────┘       └─────────────────────┘
```

---

## 3. Divisão de Responsabilidades

### 3.1 Camada Compartilhada (`shared/`)
* **`shared/types.lua`:** Definição rigorosa de interfaces e anotações de tipo via EmmyLua (`KarmaTier`, `CombatPayload`, etc.).
* **`shared/tiers.lua`:** Tabela pura de patamares morais (-1000 a +1000) e funções utilitárias determinísticas de resolução de patamar moral.

### 3.2 Camada do Servidor (`server/`)
* **`server/database.lua`:** Gerenciador de persistência assíncrona. Mantém cache em memória por `charIdentifier`, executa auto-migrações seguras da tabela `characters` e realiza consolidação em lote (*Unit of Work*) para minimizar I/O no MySQL.
* **`server/main.lua`:** Ponto de entrada do servidor. Orquestra o recebimento de eventos de combate, aplica as regras morais (provocação vs legítima defesa), sincroniza o cliente e expõe a API pública de exports (`ModifyKarma`, `GetPlayerKarma`, `SetPlayerKarma`).

### 3.3 Camada do Cliente (`client/`)
A camada cliente foi modularizada seguindo as melhores práticas do RedM e do framework WestRP, desacoplando responsabilidades de escuta, pipeline, avaliação física e apresentação de interface:
* **`client/listeners/game_events.lua`:** Escuta eventos nativos do motor RDR3 (`gameEventTriggered` - `CEventNetworkEntityDamage`), captura agressores em legítima defesa e aciona a pipeline.
* **`client/pipeline/stages.lua`:** Conjunto atômico de funções puras representando os 8 estágios de filtragem (Sanidade, Autoria, Classificação, Arma, Desfecho, Iniciativa, Deduplicação e Despacho).
* **`client/pipeline/engine.lua`:** Motor sequencial que itera a pipeline linear e gera logs estruturados no padrão Step Ladder (escada) no console F8, Logger do Framework e txAdmin.
* **`client/services/state_evaluator.lua`:** Camada de domínio e avaliação de estado físico (diferenciação estrita de Morte vs Nocaute desacordado, classificação de alvos e resolução de armas).
* **`client/services/combat_watcher.lua`:** Observador em segundo plano de combate corporal desarmado e coletor de lixo (GC) periódica com consumo de 0.00ms via `WestRP.Client.TickManager`.
* **`client/controllers/hud.lua`:** Controlador do HUD de Telemetria NUI, inspecionando alvos via Mira Livre de mouse/teclado, trava de controle ou proximidade corporal.
* **`client/main.lua`:** Ponto de entrada e orquestrador do ciclo de vida (`OnLoad` e `OnUnload`), sincronização de moralidade com o servidor, comandos (`/karma`, `/karmahud`) e exports públicos.

---

## 4. ADR: Pipeline Linear Funcional no Detector de Combate

### Contexto
Anteriormente, a detecção de combate utilizava estruturas condicionais procedurais densas misturadas com inspeções de mira da UI (raycasts, foco de tela), provocando falsos positivos (como confundir agarro com tiro de revólver) e falsos negativos em tiros à distância.

### Decisão
Substituir a lógica procedural monolítica por uma **Pipeline Linear Funcional (Filter Chain)** pura em Lua. Cada impacto recebido pelo motor gera um contexto (`CombatContext`) avaliado por estágios sequenciais independentes:
1. `Stage_Sanity`: Existência e integridade das entidades (valida se é Ped válido e descarta objetos/cenário).
2. `Stage_Authorship`: Confirmação inequívoca de que o jogador ou sua montaria foi o autor da agressão.
3. `Stage_TargetType`: Classificação de alvos (civil, homem da lei, jogador ou animal descartado).
4. `Stage_Weapon`: Resolução precisa da arma causadora (desarmado, faca, revólver, etc.).
5. `Stage_Outcome`: Avaliação do desfecho do confronto (KILL direto, KNOCKOUT inconsciente ou ASSAULT físico/armado).
6. `Stage_Initiative`: Análise de legítima defesa (revidou agressão recente dentro de 45s) vs atitude não provocada.
7. `Stage_Deduplication`: Prevenção de duplicações e controle de resfriamento (cooldown).
8. `Stage_Dispatch`: Despacho autorizado ao servidor, log F8 (Step Ladder) e telemetria no HUD.

### Consequências
- **Observabilidade Total:** Se um evento for descartado, o log informa exatamente qual estágio barrou e o motivo.
- **Isolamento de UI:** O HUD é um observador 100% passivo; o combate não depende de mira de tela para ser detectado.
- **Zero Over-engineering:** Executado como um array puro de funções iteradas via loop `for`, sem alocações pesadas de metatables (< 0.001ms por impacto).
- **Evolução Modular:** Novas etapas (como Nocaute desarmado e Legítima Defesa) podem ser inseridas como novos estágios sem risco de regressão.

---

## 5. Padrão de Observabilidade & Logging Estruturado

### 5.1 Integração com o Core (`WestRP.Shared.Logger`)
Todos os subsistemas do Karma (Pipeline Client, Ciclo de Vida e Servidor) utilizam a infraestrutura de logging do Framework (`WestRP.Shared.Logger`), herdando tags de severidade ANSI, controle de log level e timestamps em milissegundos.

### 5.2 Rastreamento em Escada (*Step Ladder*) no Console F8
Ao detectar impacto que envolve o jogador, a pipeline emite um rastro hierárquico claro no console:
* **Interrupção Segura (Ex: Alvo é um animal):**
  ```text
  [DEBUG] [KARMA_PIPE] Avaliando confronto em Ped #1822 (Culprit: 345):
    ├─ [✓] 1. Sanidade
    ├─ [✓] 2. Autoria
    └─ [✗] 3. Classificação: Alvo é um animal (ignorado pelo sistema moral humano) -> Pipeline interrompida.
  ```
* **Agressão Física / Armada (Confronto não-letal):**
  ```text
  [INFO] [KARMA_PIPE] Confronto em Ped #1452 (Culprit: 345) -> ASSAULT CONFIRMADO:
    ├─ [✓] 1. Sanidade
    ├─ [✓] 2. Autoria
    ├─ [✓] 3. Classificação
    ├─ [✓] 4. Resolução de Arma
    ├─ [✓] 5. Desfecho do Confronto
    ├─ [✓] 6. Iniciativa & Defesa
    ├─ [✓] 7. Deduplicação
    └─ [🚀] 8. Despacho: CIVILIAN (Ped: 1452) | Ação: ASSAULT | UNPROVOKED | WEAPON_UNARMED | -5 pts
  ```
* **Morte Confirmada (Passagem completa):**
  ```text
  [INFO] [KARMA_PIPE] Confronto em Ped #1452 (Culprit: 345) -> KILL CONFIRMADO:
    ├─ [✓] 1. Sanidade
    ├─ [✓] 2. Autoria
    ├─ [✓] 3. Classificação
    ├─ [✓] 4. Resolução de Arma
    ├─ [✓] 5. Desfecho do Confronto
    ├─ [✓] 6. Iniciativa & Defesa
    ├─ [✓] 7. Deduplicação
    └─ [🚀] 8. Despacho: CIVILIAN (Ped: 1452) | Ação: KILL | UNPROVOKED | Cattleman Revolver | -35 pts
  ```

### 5.3 Espelhamento de Debug para o Servidor (*Server Relay*)
Para permitir acompanhamento em tempo real tanto no console F8 quanto no console do servidor (txAdmin/Terminal), os logs de diagnóstico e as escadas de decisão da pipeline são transmitidos via evento de rede `westrp_karma:server:relayClientDebug` quando `Config.Debug = true`.

### 5.4 Telemetria NUI em Tempo Real
No HUD de Telemetria (`/karmahud`), cada etapa emite badges visuais dedicados:
* `[PIPE HALT]`: Identifica o Ped e o estágio exato onde a execução cessou sem gerar penalidade.
* `[KILL DIRETO]`: Identifica a passagem com sucesso com óbito confirmado.
* `[NOCAUTE]`: Identifica quando o alvo fica inconsciente/desacordado.
* `[AGRESSÃO]`: Identifica impactos físicos e combates ativos sem óbito imediato.
* `[LEGÍTIMA DEFESA]`: Identifica retaliação autorizada contra agressor hostil.
