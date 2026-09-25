# Roadmap Técnico — `westrp_karma`
> **Estratégia:** Evolução Iterativa com Entregas Verificadas em Jogo  

---

## 📌 Fase 1: Fundação & Detecção Limpa de Conflito (ATUAL)
- [x] Reset do resource e alinhamento com a arquitetura WestRP.
- [x] Implementação da FSM no cliente (`ACTIVE` -> `KNOCKED_OUT` -> `EXECUTED` / `KILLED`).
- [x] Filtro estrito de descarte para colisões físicas de ragdoll no solo.
- [x] Resolvedor de armas multi-acoplamento (`GetPlayerHeldWeapon` nos slots 0, 1, 2, 3).
- [x] Persistência assíncrona em banco via `oxmysql` (`characters.karma`).
- [x] Formatação padronizada de logs informativos no cliente (F8) e console do servidor.

## 📌 Fase 2: Morality Engine & Integração VORP Core
- [ ] Carregamento automático no login (`vorp:SelectedCharacter`).
- [ ] Salvamento em lote (*Batch Write / Unit of Work*) no `onResourceStop` e `playerDropped`.
- [ ] Comando administrativo de calibração `/setkarma [id] [valor]`.
- [ ] Export de verificação moral para outros scripts (`exports.westrp_karma:GetPlayerKarma`).

## 📌 Fase 3: Consequências Sistêmicas & Recompensas
- [ ] Descontos e penalidades automáticas em lojas baseadas no Tier moral.
- [ ] Elegibilidade para caçadores de recompensa caso o karma atinja níveis de infâmia extrema (`bountyEligible`).
- [ ] Notificações visuais elegantes no HUD via `westrp_ui`.
