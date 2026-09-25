# Especificação Técnica & Guia de Tasks: Detecção e Avaliação de Armamentos
> **Resource:** `westrp_karma`  
> **Padrão:** Spec-Driven Development (SDD) & Event-Driven Architecture  
> **Status:** Aprovado para Implementação  
> **Versão da Spec:** 1.1.0  
> **Compatibilidade:** RedM (Cerulean / RDR3) — WestRP / VORP Core

---

## 1. Visão Geral & Contexto de Engenharia

O módulo `westrp_karma` possui atualmente uma infraestrutura modular e altamente performática para combate corpo a corpo desarmado (`KNOCKOUT` vs `KILL` via `IsPedFatallyInjured`, 0.00ms idle resmon via `TickManager`, pipeline funcional de 8 estágios e telemetria NUI).

### 1.1 O Desafio Balístico no RDR3 / RedM
Diferente do combate físico direto (que necessita de observação corporal adaptativa), o combate com armas de fogo e projéteis deve operar em arquitetura **100% orientada a eventos (*Event-Driven*)**, interceptando o evento nativo `CEventNetworkEntityDamage` emitido pela engine do jogo no exato milissegundo do impacto balístico.

Contudo, a engine do RDR3 apresenta particularidades que exigem tratamento algorítmico rigoroso:
1. **Ambiguidade entre Arma e Munição:** A engine com frequência envia no evento a hash da munição (ex: `AMMO_REVOLVER_EXPRESS`, `AMMO_PISTOL_SPLITPOINT`) ou a hash do tipo de cartucho em vez da arma em si.
2. **Localização Anatômica e Critical Hits:** Um tiro no crânio (*Headshot*) caracteriza execução sumária ou homicídio direto, enquanto um tiro na perna ou braço pode ser um tiro de contenção ou desarme.
3. **Mecânica de Sangramento/Agonia (*Bleedout State*):** Vítimas atingidas no tronco ou artérias entram em colapso com sangramento lento no solo (`IsPedDeadOrDying` com pulso fraco), vindo a falecer segundos depois. O sistema não pode aplicar dupla punição moral (debitar uma agressão armada inicial e depois debitar um homicídio integral).
4. **Legítima Defesa Preventiva e Duelos:** Se um NPC ou jogador saca uma arma de fogo e mira na cabeça do jogador, a reação rápida do jogador deve ser categorizada como **Legítima Defesa / Duelo Justo** (`SELF_DEFENSE`), mesmo que o jogador dispare o primeiro tiro.
5. **Armas de Arremesso e Efeitos de Área:** Lâminas arremessáveis (facas, tomahawks), flechas (normais, incendiárias, venenosas) e explosivos (dinamite, molotov).

---

## 2. Modelos de Domínio e Contratos de Dados (EmmyLua)

### 2.1 Extensão do Contexto de Combate (`CombatContext`)
Atualização da estrutura que transita entre os estágios da pipeline linear:

```lua
---@class BallisticDetails
---@field weaponCategory "REVOLVER" | "PISTOL" | "REPEATER" | "RIFLE" | "SHOTGUN" | "SNIPER" | "BOW" | "THROWN" | "EXPLOSIVE" | "MELEE" | "UNARMED"
---@field ammoHash integer?
---@field damageBone integer?
---@field isHeadshot boolean
---@field distanceMeters number
---@field isBleedoutPromotion boolean

---@class CombatContext
---@field victim integer Handle da entidade agredida
---@field culprit integer Handle do agressor
---@field args table Argumentos brutos de CEventNetworkEntityDamage
---@field playerPed integer Handle do jogador local
---@field isAuthor boolean Se o jogador é o causador comprovado
---@field isDead boolean Se o alvo está morto
---@field isKnockedOut boolean Se o alvo está nocauteado/desmaiado
---@field isAssault boolean Se é agressão não-letal em pé
---@field targetType "CIVILIAN" | "LAWMAN" | "PLAYER" | "ANIMAL" | "UNKNOWN"
---@field weaponHash integer Hash da arma resolvida
---@field weaponLabel string Nome amigável formatado
---@field actionType "KILL" | "KNOCKOUT" | "ASSAULT"
---@field initiative "UNPROVOKED" | "SELF_DEFENSE"
---@field victimServerId integer? Server ID (se jogador)
---@field estimatedDelta integer Variação numérica calculada
---@field killerSource integer Handle reportado como fonte da morte
---@field ballistic BallisticDetails? Metadados balísticos estendidos
```

### 2.2 FSM Estendida para Armamentos

```text
                        ┌───────────────────────────────┐
                        │            ACTIVE             │ (Alvo ativo / Em combate)
                        └───────────────┬───────────────┘
                                        │
                    ┌───────────────────┴───────────────────┐
                    │                                       │
     Disparo Não-Letal (Membros)            Disparo Crítico / Letal Direto
     (Braço, Perna, Desarme)                (Headshot / Calibre Pesado no Peito)
                    ▼                                       ▼
         ┌─────────────────────┐                 ┌─────────────────────┐
         │       ASSAULT       │                 │        KILL         │
         │   (Agressão Armada) │                 │ (Homicídio Direto)  │
         └──────────┬──────────┘                 └─────────────────────┘
                    │
                    │ Atingiu artéria / pulmão
                    ▼
         ┌─────────────────────┐
         │  WOUNDED / BLEEDOUT │ (Sangrando no solo, morre em 10-20s)
         └──────────┬──────────┘
                    │
                    │ Falecimento por perda de sangue
                    ▼
         ┌─────────────────────┐
         │  PROMOTED TO KILL   │ (Abate apenas o delta restante)
         └─────────────────────┘
```

---

## 3. Matriz de Consequências Morais Balísticas

| Alvo | Arma / Circunstância | Dano / Localização | Iniciativa | Ação | Delta de Karma |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Civil Inocente** | Arma de Fogo | Membros (Perna/Braço) | Não Provocado | `ASSAULT` | **-10 pts** |
| **Civil Inocente** | Arma de Fogo | Tronco / Não-Fatal | Não Provocado | `ASSAULT` | **-15 pts** |
| **Civil Inocente** | Arma de Fogo | Headshot Letal | Não Provocado | `KILL` | **-45 pts** (Agravante) |
| **Civil Inocente** | Arma de Fogo | Morte por Bleedout | Não Provocado | `KILL` | **-35 pts** (-20 adicionais pós-tiro) |
| **Autoridade** | Arma de Fogo | Qualquer Acerto Não-Letal | Não Provocado | `ASSAULT` | **-25 pts** |
| **Autoridade** | Arma de Fogo | Disparo Letal / Headshot | Não Provocado | `KILL` | **-90 pts** |
| **Jogador (PvP)** | Arma de Fogo | Não-Letal / Ferimento | Não Provocado | `ASSAULT` | **-20 pts** |
| **Jogador (PvP)** | Arma de Fogo | Execução / PK Letal | Não Provocado | `KILL` | **-120 pts** |
| **Qualquer** | Qualquer Arma | Qualquer Localização | **Legítima Defesa / Duelo** | `DEFENSE` | **0 pts** (ou +15 se foragido) |

---

## 4. Guia de Implementação Passo a Passo (Task-Driven)

---

### 📌 FASE 1: Mapeamento Balístico Bidirecional & Catálogo de Munições

#### Contexto e Necessidade
Ao receber `CEventNetworkEntityDamage`, a engine do RDR3 popula `args[5]` ou `args[7]` ora com a hash da arma empunhada, ora com a hash da munição usada (ex: munição incendiária, cartucho split point). Sem um resolvedor bidirecional, armas de fogo são rejeitadas como `WEAPON_UNARMED` ou registradas como números desconhecidos.

---

#### 📋 Task 1.1 — Implementar Dicionário Unificado de Armas e Munições
* **Arquivo Alvo:** [`shared/weapons.lua`](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/shared/weapons.lua)
* **Objetivo:** Adicionar tabelas de lookup de munições, famílias balísticas e resolvedores normalizados.
* **Instruções:**
  1. Criar o mapa `AMMO_TO_WEAPON_FAMILY` contendo as hashes das munições do RDR3 mapeadas para as categorias correspondentes:
     * `AMMO_REVOLVER` -> "REVOLVER"
     * `AMMO_REVOLVER_EXPRESS` -> "REVOLVER"
     * `AMMO_PISTOL` -> "PISTOL"
     * `AMMO_REPEATER` -> "REPEATER"
     * `AMMO_RIFLE` -> "RIFLE"
     * `AMMO_SHOTGUN` -> "SHOTGUN"
     * `AMMO_SHOTGUN_BUCKSHOT` -> "SHOTGUN"
     * `AMMO_ARROW` -> "BOW"
  2. Implementar função `Weapons.ResolveWeaponFromAmmo(ammoHash, heldWeapon)`:
     * Se `ammoHash` for conhecido, verificar se a arma em punho do jogador pertence à mesma família.
     * Caso positivo, retorna a hash da arma em punho; caso contrário, retorna a hash padrão da família.
  3. Adicionar método `Weapons.GetWeaponCategory(weaponHash)` retornando as strings literais: `"REVOLVER"`, `"PISTOL"`, `"REPEATER"`, `"RIFLE"`, `"SHOTGUN"`, `"SNIPER"`, `"BOW"`, `"THROWN"`, `"EXPLOSIVE"`, `"MELEE"`, `"UNARMED"`.

* **Critérios de Aceite (Acceptance Criteria):**
  - [x] `Weapons.GetWeaponCategory(GetHashKey("WEAPON_REVOLVER_CATTLEMAN"))` retorna `"REVOLVER"`.
  - [x] `Weapons.ResolveWeaponFromAmmo(GetHashKey("AMMO_REVOLVER_EXPRESS"), wep)` retorna a arma correta do jogador.
  - [x] Nenhuma hash balística válida é classificada como `"UNARMED"`.

---

#### 📋 Task 1.2 — Refinar o Estágio 4 (`CombatStages.Weapon`) na Pipeline
* **Arquivo Alvo:** [`client/pipeline/stages.lua`](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/client/pipeline/stages.lua)
* **Objetivo:** Atualizar a resolução de armas para priorizar acertos balísticos.
* **Instruções:**
  1. Extrair os argumentos de dano de `ctx.args`:
     ```lua
     local rawWeapon = ctx.args and (ctx.args[7] or ctx.args[5]) or 0
     ```
  2. Se a vítima veio a óbito imediato, invocar `GetPedCauseOfDeath(ctx.victim)`.
  3. Se `rawWeapon` for uma munição, executar `Weapons.ResolveWeaponFromAmmo(rawWeapon, KarmaState.GetPlayerHeldWeapon(ctx.playerPed))`.
  4. Popular o novo sub-objeto `ctx.ballistic`:
     ```lua
     ctx.ballistic = {
         weaponCategory = Weapons.GetWeaponCategory(ctx.weaponHash),
         ammoHash = rawWeapon,
         isHeadshot = false,
         damageBone = 0,
         distanceMeters = #(GetEntityCoords(ctx.playerPed) - GetEntityCoords(ctx.victim)),
         isBleedoutPromotion = false
     }
     ```

* **Critérios de Aceite:**
  - [x] Tiros com Cattleman, Lancaster ou Carcano registram o nome legível no `ctx.weaponLabel`.
  - [x] A distância do disparo é calculada e armazenada em metros em `ctx.ballistic.distanceMeters`.

---

### 📌 FASE 2: Análise Anatômica e Tiros Críticos (*Headshots*)

#### Contexto e Necessidade
No RedM, a native `GetPedLastDamageBone(ped)` retorna se um osso específico sofreu o último impacto de dano. Diferente do GTA V, o RDR2/RAGE utiliza a tag óssea `31086` (`SKEL_Head`) como identificador canônico primário do crânio, além de tags faciais (`46065`, `46066`, `FACIAL_facialRoot`) e cervicais (`14283`-`14285`, `39317`). Além disso, valores retornados pela native podem vir em formato signed de 32-bit, exigir verificação via `GetPedBoneIndex(ped, tag)` ou requerer fallback de mira livre quando a morte instantânea limpa o registro de dano antes da consulta.

---

#### 📋 Task 2.1 — Implementar Detector Ósseo de Dano Crítico
* **Arquivo Alvo:** [`client/services/state_evaluator.lua`](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/client/services/state_evaluator.lua)
* **Objetivo:** Criar função estrita de inspeção anatômica de impacto com suporte multicamada.
* **Instruções:**
  1. Definir o dicionário expandido de tags cranianas e cervicais:
     ```lua
     local HEAD_BONE_TAGS = {
         [31086] = true, -- SKEL_Head (Tag canônica do RDR2/RAGE)
         [21030] = true, -- SKEL_Head alt
         [46065] = true, -- SKEL_L_Jaw
         [46066] = true, -- SKEL_R_Jaw
         [GetHashKey("SKEL_HEAD")] = true,
         [GetHashKey("SKEL_Head")] = true,
         [GetHashKey("FACIAL_facialRoot")] = true
     }

     local NECK_BONE_TAGS = {
         [14283] = true, [14284] = true, [14285] = true, [39317] = true,
         [GetHashKey("SKEL_NECK0")] = true, [GetHashKey("SKEL_Neck0")] = true,
         [GetHashKey("SKEL_NECK1")] = true, [GetHashKey("SKEL_Neck1")] = true,
         [GetHashKey("SKEL_NECK2")] = true
     }
     ```
  2. Implementar `KarmaState.GetDamageLocation(ped)`:
     - Normalizar valores signed/unsigned de 32 bits (`bNum < 0` -> `+ 0x100000000`).
     - Verificar tags diretas em `HEAD_BONE_TAGS` e `NECK_BONE_TAGS`.
     - Comparar com `GetPedBoneIndex(ped, tag)` dinâmico para os ossos cranianos e cervicais.
     - Implementar fallback com `GetEntityPlayerIsFreeAimingAt` apontando para o ped para casos em que o motor zera o osso no milissegundo do óbito.

* **Critérios de Aceite:**
  - [x] Tiros na cabeça de NPCs ou players retornam `"HEAD"`.
  - [x] Dano sem osso identificado retorna `"UNKNOWN"` de forma segura sem lançar exceptions Lua.
  - [x] Resiste a valores negativos ou signed int retornados pela engine Cfx.re.

---

#### 📋 Task 2.2 — Integrar Headshot no Estágio de Desfecho (`CombatStages.Outcome`)
* **Arquivo Alvo:** [`client/pipeline/stages.lua`](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/client/pipeline/stages.lua)
* **Objetivo:** Marcar o contexto com a flag de Headshot e modular a penalidade moral.
* **Instruções:**
  1. Após determinar se a ação é letal ou agressão, chamar `KarmaState.GetDamageLocation(ctx.victim)`.
  2. Se retornar `"HEAD"`:
     - Marcar `ctx.ballistic.isHeadshot = true`.
     - Forçar `ctx.actionType = "KILL"` se o dano for de arma de fogo e a vida do Ped estiver zerada ou em agonia fatal.
  3. Em `CombatStages.CalculateEstimatedDelta`:
     - Se `ctx.ballistic.isHeadshot == true` e `ctx.initiative == "UNPROVOKED"`:
       - Aplicar agravante moral (ex: penalidade de -45 em vez de -35 para civis).
       - Definir `badgeLabel = "HEADSHOT KILL"`.

* **Critérios de Aceite:**
  - [x] Tiros na cabeça exibem `"HEADSHOT KILL"` no badge do HUD NUI.
  - [x] Log F8 exibe a indicação explícita `[CRÍTICO: HEADSHOT]`.

---

### 📌 FASE 3: Ciclo de Sangramento e Morte Tardia (*Bleedout Lifecycle*)

#### Contexto e Necessidade
No RDR2, um civil ou policial baleado no tórax pode cambalear e cair sangrando no chão (estado de agonia/sangramento). A morte por parada cardíaca ou hemorragia ocorre de 10 a 25 segundos depois.
* Se tratarmos como dois eventos isolados: O jogador perde -15 pts no tiro e depois perde -35 pts na morte final (-50 pts no total para um único homicídio).
* A solução padronizada pela comunidade é o **Promoted Kill**: o sistema memoriza o autor do ferimento que causou o sangramento; quando a morte ocorre, o sistema abate apenas a diferença (-20 pts).

---

#### 📋 Task 3.1 — Estruturar o Cache de Vítimas em Sangramento
* **Arquivo Alvo:** [`client/services/state_evaluator.lua`](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/client/services/state_evaluator.lua)
* **Objetivo:** Adicionar armazenamento e detecção do estado de hemorragia/agonia.
* **Instruções:**
  1. Adicionar em `KarmaState`:
     ```lua
     ---@type table<integer, { author: integer, weaponHash: integer, assaultTimestamp: integer, penaltyPaid: integer }>
     KarmaState.bleedingVictims = {}
     ```
  2. Implementar `KarmaState.IsPedInBleedout(ped)`:
     - Verificar se o Ped está vivo (`GetEntityHealth(ped) > 0`).
     - Verificar se está deitado no chão, sem andar, e com a flag nativa de agonia (`IsPedDeadOrDying(ped, true)` ou vida `< 15`).
  3. No garbage collector de `client/services/combat_watcher.lua`:
     - Limpar registros de `bleedingVictims` superiores a 45 segundos.

* **Critérios de Aceite:**
  - [x] Peds feridos em estado agonizante são registrados em `KarmaState.bleedingVictims`.
  - [x] Registros são liberados após expiração sem fugas de memória via GC de 60s.

---

#### 📋 Task 3.2 — Implementar Promoção Atômica de Agressão para Homicídio no Stage 7 e 8
* **Arquivo Alvo:** [`client/pipeline/stages.lua`](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/client/pipeline/stages.lua)
* **Objetivo:** Reconciliar o fechamento da morte tardia sem penalização cumulativa injusta.
* **Instruções:**
  1. No `CombatStages.Deduplication`:
     - Se `ctx.actionType == "KILL"` e `KarmaState.bleedingVictims[ctx.victim]` existir:
       - Permitir o avanço (não barrar por deduplicação de agressão recente).
       - Marcar `ctx.ballistic.isBleedoutPromotion = true`.
       - Preservar a flag `isHeadshot` original armazenada no cache de sangramento para não perder o agravante na morte tardia.
  2. Em `CombatStages.CalculateEstimatedDelta`:
     - Se `ctx.ballistic.isBleedoutPromotion == true`:
       - Calcular o delta como: `TotalKillPenalty - AlreadyPaidAssaultPenalty`.
       - Exemplo civil sem headshot: `-35 - (-5) = -30 pts`.
       - Exemplo civil com headshot: `-45 - (-5) = -40 pts`.
       - Configurar `badgeLabel = isHeadshot and "ÓBITO HEADSHOT (BLEEDOUT)" or "ÓBITO (BLEEDOUT)"`.
  3. No `CombatStages.Dispatch`:
     - Limpar `KarmaState.bleedingVictims[ctx.victim]` após despachar a morte final.

* **Critérios de Aceite:**
  - [x] Vítima que falece 15 segundos após o tiro sofre dedução apenas do restante da penalidade.
  - [x] O HUD exibe a transição limpa para `ÓBITO (BLEEDOUT)`.
  - [x] Headshot inicial é preservado mesmo se o óbito terminal ocorrer segundos após o tiro.

---

### 📌 FASE 4: Legítima Defesa Balística & Provocação Armada

#### Contexto e Necessidade
Em um confronto armado, esperar levar o primeiro tiro para poder revidar é irrealista para um jogo de Roleplay. Se um suspeito saca uma arma de fogo e mira na direção do jogador, o jogador possui amparo de legítima defesa para efetuar o disparo de contenção.

---

#### 📋 Task 4.1 — Observador de Mira Hostil em `CombatWatcher`
* **Arquivo Alvo:** [`client/services/combat_watcher.lua`](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/client/services/combat_watcher.lua)
* **Objetivo:** Identificar se o alvo mirou uma arma de fogo ou iniciou hostilidade armada contra o jogador.
* **Instruções:**
  1. No loop `RunMainLoop` de `combat_watcher.lua`:
     - Varrer peds no raio de 40 metros via `GetGamePool('CPed')`:
       - Se o ped hostil não-civil estiver disparando contra o jogador sem provocação prévia, registrar em `KarmaState.recentAimThreats[ped] = now`.
  2. Isso estende a proteção de **Legítima Defesa** em duelos armados contra bandidos antes mesmo de sua primeira bala atingir o jogador.

* **Critérios de Aceite:**
  - [x] Se um NPC bandido saca arma e atira contra o jogador (ou se posiciona em combate armado), abater esse NPC é registrado como `SELF_DEFENSE`.
  - [x] Civis desarmados que apenas correm ou gritam **não** ativam a proteção e continuam classificados como `UNPROVOKED`.
  - [x] Elimina chamadas a natives inexistentes no RedM (como `GetSelectedPedWeapon` do GTA V).

---

### 📌 FASE 5: Telemetria Balística no HUD NUI e Console F8

#### Contexto e Necessidade
O HUD de diagnóstico (`/karmahud`) e o console F8 precisam fornecer telemetria clara das informações balísticas para testes de QA e transparência para a equipe técnica.

---

#### 📋 Task 5.1 — Atualizar Estilos e Badges no HUD NUI
* **Arquivos Alvo:**
  * [`html/script.js`](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/html/script.js)
  * [`html/style.css`](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/html/style.css)
* **Objetivo:** Adicionar suporte visual a disparos à distância e badges críticos.
* **Instruções:**
  1. Em `style.css`, adicionar estilos para os badges balísticos:
     * `.log-badge.headshot`: fundo carmim profundo com borda dourada pulsante (`#8b0000` / `#ffd700`).
     * `.log-badge.bleedout`: cor âmbar de transição (`#d97706`).
  2. Em `script.js`:
     * Exibir a distância do disparo no log detalhado quando disponível (ex: `"Cattleman #104 | KILL | 28.5m | HEADSHOT"`).

* **Critérios de Aceite:**
  - [x] Badges de `HEADSHOT` e `BLEEDOUT` aparecem com contraste e formatação visual adequados no HUD.
  - [x] A distância do tiro é exibida com uma casa decimal e unidade `m`.

---

#### 📋 Task 5.2 — Enriquecer o Step-Ladder Logger (`CombatPipeline.PrintSuccess`)
* **Arquivo Alvo:** [`client/pipeline/engine.lua`](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/client/pipeline/engine.lua)
* **Objetivo:** Detalhar dados balísticos no rastro em escada do console F8 e txAdmin.
* **Instruções:**
  1. Em `CombatPipeline.PrintSuccess`, incluir os dados de `ctx.ballistic`:
     ```text
     [INFO] [KARMA_PIPE] Confronto em Ped #1452 (Culprit: 345) -> KILL CONFIRMADO:
       ├─ [✓] 1. Sanidade
       ├─ [✓] 2. Autoria
       ├─ [✓] 3. Classificação: CIVILIAN
       ├─ [✓] 4. Resolução de Arma: WEAPON_REVOLVER_CATTLEMAN (Família: REVOLVER)
       ├─ [✓] 5. Desfecho: KILL (Anatomia: HEADSHOT | Distância: 18.2m)
       ├─ [✓] 6. Iniciativa: UNPROVOKED
       ├─ [✓] 7. Deduplicação: Aprovado
       └─ [🚀] 8. Despacho: CIVILIAN | Ação: KILL | UNPROVOKED | Cattleman | -45 pts
     ```

* **Critérios de Aceite:**
  - [x] O console F8 e o relay txAdmin mostram com precisão as etapas 4 e 5 enriquecidas com categoria balística e distância.

---

## 5. Matriz de Verificação & Testes de Aceitação

| Cenário de Teste | Ação do Jogador | Comportamento Esperado | Resultado Técnico |
| :--- | :--- | :--- | :--- |
| **TC-01: Headshot com Revólver** | Disparo na cabeça de um civil a 10 metros | Morte imediata; classificação como `KILL`; badge dourado/vermelho `HEADSHOT KILL` | `ctx.ballistic.isHeadshot == true`, penalidade agravada (-45 pts) |
| **TC-02: Tiro na Perna (Contenção)** | Disparo de pistola na perna do NPC sem matar | NPC cambaleia e continua vivo; classificado como `ASSAULT` | `ctx.actionType == "ASSAULT"`, dedução leve (-10 pts) |
| **TC-03: Sangramento Agonizante (Bleedout)** | Tiro no tórax de civil; civil cai sangrando e morre após 15s | 1º evento: `ASSAULT` (-15 pts); 2º evento: `PROMOTED KILL` (-20 pts). Total = -35 pts | Transição atômica sem deduplicação de -50 pts |
| **TC-04: Duelo / Legítima Defesa Armada** | Bandido saca revólver e mira no jogador; jogador atira e mata | Reconhecido como `SELF_DEFENSE`; zero penalidade moral ou bônus | `ctx.initiative == "SELF_DEFENSE"`, delta 0 pts |
| **TC-05: Sniper / Longa Distância** | Tiro de Carcano em inimigo a 90 metros | Detecção correta da autoria mesmo em alta distância; registro da distância | `ctx.ballistic.distanceMeters > 80`, autoria confirmada |

---

## 6. Ordem de Execução Recomendada

1. **Sprint 1 (Fundações Balísticas):** Executar **Task 1.1** e **Task 1.2** (Dicionário de Munições e resolvedor no Stage 4).
2. **Sprint 2 (Precisão Anatômica):** Executar **Task 2.1** e **Task 2.2** (Inspetor de osso cranial e tags de Headshot).
3. **Sprint 3 (Justiça Sistêmica & Bleedout):** Executar **Task 3.1** e **Task 3.2** (Rastreamento de agonia e promoção suave para óbito).
4. **Sprint 4 (Hostilidade & Duelos):** Executar **Task 4.1** (Proteção preventiva de legítima defesa em mira hostil).
5. **Sprint 5 (Observabilidade & HUD):** Executar **Task 5.1** e **Task 5.2** (Interface NUI e Step-Ladder Logger).
