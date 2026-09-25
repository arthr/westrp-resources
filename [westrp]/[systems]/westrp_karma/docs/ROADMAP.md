# Roadmap Técnico — `westrp_karma`
> **Estratégia:** Evolução Iterativa com Entregas Verificadas em Jogo  

---

## 📌 Fase 1: Fundação & Combate Corpo a Corpo (Concluído)
- [x] Reset do resource e alinhamento com a arquitetura WestRP.
- [x] Implementação da FSM no cliente (`ACTIVE` -> `KNOCKED_OUT` -> `EXECUTED` / `KILLED`).
- [x] Filtro estrito de descarte para colisões físicas de ragdoll no solo.
- [x] Diferenciação precisa de nocaute vs morte via padrão `baseevents` (`IsPedFatallyInjured`).
- [x] Refatoração modular completa do cliente (`controllers`, `listeners`, `pipeline`, `services`).
- [x] Persistência assíncrona em banco via `oxmysql` (`characters.karma`).
- [x] HUD de telemetria NUI com handshake `nuiReady` e Step-Ladder Logger (F8/txAdmin).

## 📌 Fase 1.1: Detecção Balística & Armamentos (Concluído — SDD)
> Especificação detalhada e tarefas: [SPEC_FIREARMS_COMBAT.md](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/docs/SPEC_FIREARMS_COMBAT.md)
- [x] **Sprint 1:** Mapeamento balístico bidirecional e catálogo de munições (`shared/weapons.lua`).
- [x] **Sprint 2:** Análise anatômica e detecção de tiros críticos (`GetPedLastDamageBone` / Headshot).
- [x] **Sprint 3:** Rastreamento do ciclo de sangramento e morte tardia (*Bleedout Lifecycle*).
- [x] **Sprint 4:** Legítima defesa preventiva contra hostilidade armada e duelos.
- [x] **Sprint 5:** Telemetria balística detalhada no HUD NUI e rastro no console F8.

## 📌 Fase 1.2: Arquitetura Dual-Channel — Desacoplamento PvE vs PvP (Concluído — SDD)
> Especificação detalhada e tarefas: [SPEC_DUAL_CHANNEL_PVE_PVP.md](file:///c:/txData/VORPCore_B1A065.base/resources/%5Bwestrp%5D/%5Bsystems%5D/westrp_karma/docs/SPEC_DUAL_CHANNEL_PVE_PVP.md)
- [x] **Task 1.2.1:** Especialização da Pipeline Cliente exclusivamente para PvE (Filtro precoce de players em `stages.lua`).
- [x] **Task 1.2.2:** Listener Servidor Autoritativo de Morte PvP via `vorp_core:Server:OnPlayerDeath` e `baseevents:onPlayerKilled`.
- [x] **Task 1.2.3:** Handler especializado `Karma.HandlePvPDeath` no servidor com validação de Legítima Defesa PvP e cálculo de PK.
- [x] **Task 1.2.4:** Sincronização e Feedback de Agressão PvP no HUD (`hud.lua`).
- [x] **Task 1.2.5:** Atualização formal e alinhamento de não-conflito em `docs/SDD.md` e `docs/ARCHITECTURE.md`.

## 📌 Fase 2: Morality Engine & Integração VORP Core
- [ ] Carregamento automático no login (`vorp:SelectedCharacter`).
- [ ] Salvamento em lote (*Batch Write / Unit of Work*) no `onResourceStop` e `playerDropped`.
- [ ] Comando administrativo de calibração `/setkarma [id] [valor]`.
- [ ] Export de verificação moral para outros scripts (`exports.westrp_karma:GetPlayerKarma`).

## 📌 Fase 3: Consequências Sistêmicas & Recompensas
- [ ] Descontos e penalidades automáticas em lojas baseadas no Tier moral.
- [ ] Elegibilidade para caçadores de recompensa caso o karma atinja níveis de infâmia extrema (`bountyEligible`).
- [ ] Notificações visuais elegantes no HUD via `westrp_ui`.
