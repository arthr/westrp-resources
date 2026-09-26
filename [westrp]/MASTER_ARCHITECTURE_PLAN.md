# Especificação Arquitetural Mestra e Plano Diretor — Framework [westrp]
> **Padrão:** Spec-Driven Development (SDD) & Clean Architecture  
> **Versão:** 2.0.0 (Core Refactor & Modernization)  
> **Target:** RedM (CitizenFX RDR3 - Game Build 1491+)  
> **Stack Base:** Lua 5.4 (Strict / Locals) + oxmysql (Prepared Statements) + CitizenFX State Bags + Single Chromium NUI Engine (`westrp_ui`)  
> **Diretriz:** Liberdade total de reestruturação — prioridade absoluta para performance (0.00ms idle), segurança Zero-Trust e código limpo.

---

## 1. Visão Geral e Filosofia Arquitetural

O **[westrp]** é um ecossistema de engenharia modular de altíssimo desempenho projetado especificamente para servidores de **Roleplay Imersivo em Red Dead Redemption 2** de alta densidade (100 a 256+ slots).

### 1.1 A Decisão Estratégica: O Padrão Estrangulador (*Strangler Fig Pattern*)
* **Não ao "Ground-Up" ingênuo:** Não tentamos reinventar a roda de sistemas de alta complexidade do RDR3 de uma vez só (como o motor de vestuário e metapeds do `vorp_character`).
* **Não ao "Hard-Fork" caótico:** Não alteramos a pasta `[VORP]` diretamente, evitando o acoplamento e o "merge hell" de atualizações do RedM.
* **A Estratégia Adotada:** O VORP torna-se apenas um provedor temporário (*vendor*). O ecossistema **WESTRP** consome o VORP estritamente através de uma camada de abstração (**Bridge**). Conforme os módulos do WESTRP amadurecem, os recursos legados do VORP são desligados um a um até a total independência.

---

## 2. Diagnóstico Técnico Comparativo

```
┌───────────────────────────────────────────────┐
│                 VORP LEGADO                   │
├───────────────────────────────────────────────┤
│ • Loops cegos com Wait(0) em dezenas de peds  │
│ • Resmon cumulativo > 1.5ms em idle           │
│ • Múltiplos contextos Chromium CEF separados  │
│ • Falhas de "script host" em closures         │
│ • Prompts nativos vazando na tela após stops  │
│ • Polling de rede e eventos desordenados      │
│ • Segurança permissiva (client-authoritative) │
└───────────────────────┬───────────────────────┘
                        │
                        ▼  TRANSFORMAÇÃO
┌───────────────────────────────────────────────┐
│              WESTRP ESTADO DA ARTE            │
├───────────────────────────────────────────────┤
│ • TickManager adaptativo (0.00ms em idle)     │
│ • Single CEF NUI Engine (westrp_ui)           │
│ • SDK híbrido (módulos utilitários locais)    │
│ • PromptManager com scoped lifecycle nativo   │
│ • State Bags reativas (LocalPlayer.state)     │
│ • Callbacks RPC protegidos com Rate Limit     │
│ • Segurança Zero-Trust absoluta no servidor   │
└───────────────────────────────────────────────┘
```

---

## 3. Arquitetura do Core (`westrp_core` v2)

O núcleo do framework é dividido em quatro camadas fundamentais:

### 3.1 Camada 1: SDK de Inclusão Local (`@westrp_core/init.lua`)
Em vez de depender puramente de chamadas `exports` para todas as operações (o que gera travamento de threads ao reiniciar recursos), o `init.lua` injeta **utilitários no runtime local de cada script**:
* **`WestRP.Client.TickManager` Local:** A thread e o mapa de ticks pertencem ao próprio script consumidor. Ao executar `ensure <meu_script>`, todas as threads morrem e renascem perfeitamente.
* **`WestRP.Client.PromptManager` Local:** Handles de prompt nativos do RDR3 são indexados com o nome do recurso consumidor. Ao parar o recurso, todas as prompts são deletadas da tela automaticamente.
* **`WestRP.Shared.Logger` Local:** Logs de alta performance sem marshaling de export.

### 3.2 Camada 2: Reatividade com CitizenFX State Bags
Acaba com o tráfego excessivo de rede e resmon no cliente para checar dados de personagem:
* Ao selecionar um personagem, o servidor popula:
  ```lua
  Player(source).state:set('westrp:char', {
      charid = char.charIdentifier,
      firstname = char.firstname,
      lastname = char.lastname,
      job = char.job,
      jobGrade = char.jobGrade,
      group = effectiveGroup,
      cash = char.money,
      gold = char.gold
  }, true) -- Replicado para o cliente
  ```
* No cliente, a leitura é instantânea e custa **0.00ms**:
  ```lua
  local myChar = LocalPlayer.state['westrp:char']
  ```

### 3.3 Camada 3: RPC e Segurança Zero-Trust
* **Rate Limiting no Dispatcher:** Toda requisição `triggerCallback` é interceptada e validada pelo `WestRP.Server.Security.CheckRateLimit`. Cheaters com executores não conseguem floodar queries ou lógica de negócio.
* **Timeout & Promessas:** O cliente limpa requisições que não receberem resposta em tempo hábil, evitando vazamento de memória.
* **Validação de Distância e Estado:** O servidor nunca aceita coordenadas do cliente. O ped do jogador é obtido no servidor via `GetPlayerPed(source)` e comparado com a coordenada da entidade/ponto com tolerância vetorial `#(coords - target)`.

### 3.4 Camada 4: Banco de Dados de Alta Performance (`oxmysql`)
* Inclusão do método `WestRP.Server.Database.Prepare` (`MySQL.prepare.await`).
* Queries repetitivas usam prepared statements compilados pelo MariaDB/MySQL.
* Proteção de corrotinas com fallback seguro.

---

## 4. O Plano Diretor de Execução (Roadmap)

### 📌 FASE 1: Refatoração Mestra do Core (`westrp_core`) — *[PRÓXIMO PASSO]*
1. **Reestruturar o SDK (`init.lua`):**
   - Implementar carregador híbrido: utilitários (`TickManager`, `PromptManager`, `Logger`) no runtime local de cada resource.
   - Resolver definitivamente os erros de `script host failed / invalid function reference`.
2. **Ciclo de Vida Limpo para Prompts Nativos:**
   - Garantir que qualquer prompt criado por um módulo de gameplay seja destruído imediatamente no encerramento daquele módulo (`onResourceStop`).
3. **Player State Bags:**
   - Implementar a sincronização automática do estado do personagem do VORP para o `Player(source).state['westrp:char']`.
   - Adicionar métodos cliente no `WestRP.Shared.Bridge.Player` (`GetPlayerData()`, `GetJob()`, `GetGroup()`, `IsLoggedIn()`).
4. **Hardening do Sistema de Callbacks:**
   - Adicionar proteção de rate limit no dispatcher de callbacks.
   - Adicionar timeout de segurança no `TriggerAwait`.
5. **Aprimoramento do Banco de Dados:**
   - Adicionar suporte a `MySQL.prepare` no wrapper de banco.

---

### 📌 FASE 2: Desativação do Lixo Legado do VORP
1. **Desativar Recursos Obsoletos:**
   - `vorp_admin` (já superado pelo `westrp_admin`).
   - `vorp_menu`, `vorp_inputs`, `vorp_progressbar` (substituídos pelo `westrp_ui`).
   - `vorp_zonenotify` e avisos legados (substituídos por `westrp_ui` / `westrp_core:feed`).
2. **Sanitização do `server.cfg`:**
   - Reordenar a inicialização: `oxmysql` -> `[core]` -> `[assets]` -> `[VORP]` (apenas dependências essenciais) -> `[systems]`.

---

### 📌 FASE 3: Conclusão dos Componentes Restantes da UI (`westrp_ui`)
1. **Menu Radial de Ações Rápidas:**
   - Integração completa para montaria, inventário, algemas e interações sociais.
2. **HUD de Vitais & Status:**
   - Fome, sede, vida, estamina e voz integrados com estética rústica e 0.00ms de resmon.
3. **Action Progress Bar NUI:**
   - Barra de progresso circular e linear com cancelamento suave e bloqueio de inputs seguro.

---

### 📌 FASE 4: Criação de Sistemas de Gameplay (`[systems]`)
1. **Boilerplate Oficial:** Utilizar `westrp_template` para criar:
   - `westrp_banking` (Banco e transferências com NUI moderna).
   - `westrp_stores` (Lojas gerais e açougue).
   - `westrp_stables` (Gestão de montarias e carruagens).
2. Cada sistema construído 100% sobre as bridges e padrões do WESTRP.

---

### 📌 FASE 5: Independência Total do VORP (*Independence Day*)
1. Construção do `westrp_character` (Criador e seletor nativo RDR3).
2. Construção do `westrp_inventory` (Inventário de slots com metadados e armas).
3. Migração da Bridge de "VORP Driver" para "Native Driver".
4. Exclusão completa da pasta `[VORP]` do servidor.

---

## 5. Regras Inegociáveis de Código (Cheat Sheet)

1. **Nunca use `Wait(0)` incondicional:** Sempre use `TickManager` ou controle adaptativo de sono (1500ms longe, 400ms aproximando, 0ms renderizando prompt).
2. **Zero-Trust Client:** O cliente solicita intenção; o servidor valida distância (`#(coords - target)`), estado de vida e permissões.
3. **Nunca chame o VORP diretamente nos módulos:** Use exclusivamente `WestRP.Shared.Bridge.*`.
4. **Lua de Alta Performance:**
   - Nunca use `table.insert` em loops críticos (use `t[#t + 1] = v`).
   - Itere arrays com `for i = 1, #t`.
   - Localize nativas frequentemente chamadas (`local PlayerPedId = PlayerPedId`).
5. **Permissões Administrativas:** Prefira `IsPlayerAceAllowed(source, "westrp.admin")` em vez de checagem exclusiva por strings no banco.
