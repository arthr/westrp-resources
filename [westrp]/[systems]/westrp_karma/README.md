# WestRP Karma — Dynamic Morality & Combat Detection Engine
> **Subsistema de Moralidade e Registro de Conduta para RedM (WestRP)**

O **`westrp_karma`** é um módulo de alta performance construído especificamente para o ecossistema `[westrp]`. Ele gerencia a reputação social de personagens com persistência assíncrona, máquina de estados finitos para eventos físicos de combate e resmon 0.00ms em idle.

---

## 🌟 Características Principais

* **Performance 0.00ms (Idle):** Integrado ao `WestRP.Client.TickManager`, adaptando o intervalo de execução para 1.5s fora de combate e acelerando para 150ms durante brigas ativas.
* **Máquina de Estados de Combate (FSM):** Rastreia de forma determinística transições entre `ACTIVE`, `KNOCKED_OUT`, `EXECUTED` e `KILLED`.
* **Filtro de Física de Ragdoll:** Descarta automaticamente colisões com o solo após nocautes, evitando falsos disparos de execução.
* **Resolvedor de Armas Multi-Acoplamento:** Detecta coldres primários, secundários, armas longas de costas e ombro (`attachPoint` 0, 1, 2, 3), garantindo que armas de fogo nunca sejam tratadas como mãos vazias.
* **Zero-Trust & Persistência em Lote:** O cliente reporta apenas intenções e evidências físicas; o servidor valida e consolida em lote a cada 60s via `oxmysql`.

---

## 📁 Estrutura de Arquivos

```text
westrp_karma/
├── config.lua               # Configurações globais e valores de penalidade/recompensa
├── fxmanifest.lua           # Manifesto Cerulean com dependência do westrp_core
├── schema.sql               # Migração segura da coluna characters.karma
├── README.md                # Visão geral do módulo
├── docs/
│   ├── ARCHITECTURE.md      # Desenho de arquitetura e fluxo de dados
│   ├── SDD.md               # Software Design Document & Matriz Moral
│   └── ROADMAP.md           # Planejamento de fases e evolução
├── shared/
│   ├── tiers.lua            # Patamares morais determinísticos (-1000 a +1000)
│   ├── types.lua            # Anotações estritas de tipo EmmyLua
│   └── weapons.lua          # Dicionário e resolvedor de armas
├── client/
│   ├── controllers/
│   │   └── hud.lua          # Controlador NUI, mira livre (PC) e telemetria
│   ├── listeners/
│   │   └── game_events.lua  # Listener de CEventNetworkEntityDamage e agressões
│   ├── pipeline/
│   │   ├── stages.lua       # 8 estágios atômicos da pipeline de confronto
│   │   └── engine.lua       # Motor sequencial e Step-Ladder Logger (F8/txAdmin)
│   ├── services/
│   │   ├── state_evaluator.lua # Avaliação de Morte vs Nocaute e classes de alvos
│   │   └── combat_watcher.lua  # Observador corporal (TickManager 0.00ms) e GC
│   └── main.lua             # Ciclo de vida (OnLoad/OnUnload), sync e comando /karma
└── server/
    ├── database.lua         # Persistência oxmysql, cache e Unit of Work
    └── main.lua             # Regras morais, legítima defesa, /setkarma e exports
```

---

## 🕹️ Comandos & Exports

* `/karma` (Cliente): Exibe a moralidade atual e o respectivo patamar no chat e no F8.
* `/setkarma [id] [valor]` (Admin/Server): Define diretamente a pontuação de um jogador.
* `exports.westrp_karma:GetPlayerKarma(source)`: Retorna o número de karma do personagem.
* `exports.westrp_karma:GetPlayerTier(source)`: Retorna a tabela do patamar moral atual.
* `exports.westrp_karma:ModifyKarma(source, amount, reason)`: Aplica variação moral com evento e sincronização.
