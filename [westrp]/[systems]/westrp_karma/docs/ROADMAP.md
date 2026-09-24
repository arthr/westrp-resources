# WestRP Karma — Roadmap & Plano Diretor de Implementação

> **Status do Documento:** Ativo / Versão 1.0.0  
> **Objetivo:** Estabelecer a visão final do sistema e orientar a implementação passo a passo de forma incremental e testável, partindo de um núcleo funcional mínimo ("do zero") até a versão completa.

---

## 1. Visão Geral do Sistema Final (End Goal)

O `westrp_karma` é o motor de moralidade e reputação sistêmica do WestRP. O objetivo final é criar um ecossistema vivo onde as ações morais do personagem produzem consequências reais no mundo:

```text
       ┌────────────────────────────────────────────────────────┐
       │               AÇÕES MORAIS DO PERSONAGEM               │
       ├──────────────────────────┬─────────────────────────────┤
       │     AÇÕES POSITIVAS      │       AÇÕES NEGATIVAS       │
       │  - Socorrer feridos      │  - Assassinato de inocentes │
       │  - Caçar foras da lei    │  - Assassinato de xerifes   │
       │  - Proteger a cidade     │  - Agressão e roubo armado  │
       └─────────────┬────────────┴──────────────┬──────────────┘
                     │                           │
                     ▼                           ▼
       ┌────────────────────────────────────────────────────────┐
       │        NÚCLEO DE KARMA (-1000 a +1000) & TIERS         │
       │    Santo > Nobre > Honrado > Neutro > Malfeitor >      │
       │                 Criminoso > Fora da Lei                │
       └─────────────────────────────┬──────────────────────────┘
                                     │
                     ┌───────────────┴───────────────┐
                     ▼                               ▼
       ┌──────────────────────────┐    ┌──────────────────────────┐
       │     ECONOMIA & LOJAS     │    │     JUSTIÇA & LEI        │
       │ - Até 20% de desconto    │    │ - Caçadores de Recompensa│
       │ - Até 25% de sobretaxa   │    │ - Alerta a homens da lei │
       │ - Acesso a itens únicos  │    │ - Prisão e procurado     │
       └──────────────────────────┘    └──────────────────────────┘
```

### Características do Produto Final
1. **Escala Moral Universal:** Pontuação contínua de `-1000` (Puro Malfeitor/Fora da Lei) a `+1000` (Santo/Ícone da Lei).
2. **7 Tiers Declarativos:** Classificação transparente com títulos e benefícios/punições.
3. **Diferenciação PvP e PvE:**
   - **PvE:** Matar cidadãos locais inocentes reduz a moral; eliminar forasteiros armados/hostis protege a honra.
   - **PvP:** Assassinato não provocado gera perda severa de karma; legítima defesa (reagir a tiros/agressões recentes) preserva integralmente a honra.
4. **Integração Econômica:** Descontos em lojas para cidadãos honrados e cobrança extra/recusa de atendimento para criminosos.
5. **Integração com a Lei & Bounties:** Jogadores com karma muito baixo se tornam alvos de caçadores de recompensa com valores definidos na cabeça.
6. **Apresentação Imersiva:** Notificações instantâneas na interface, barra nativa e áudios originais do Red Dead Redemption 2.

---

## 2. Fases de Implementação Incremental

Para garantir estabilidade, cada fase deve ser **100% validada em jogo antes de avançar para a próxima**.

| Fase | Foco Principal | Status | Critério de Aceite |
| :--- | :--- | :---: | :--- |
| **Fase 0** | **Núcleo Base & Persistência** | ✅ Concluído | DB migrado, `/karma` exibe pontuação, `/setkarma` altera e salva no banco. |
| **Fase 1** | **Iniciativa & Detecção de Ações** | ✅ Concluído | Identificação de quem atacou primeiro (legítima defesa vs provocação), mortes e nocautes no F8 e txAdmin. |
| **Fase 2** | **Tiers & Apresentação Visual** | ⏳ Próximo | Mudança de Tier emite som temático e atualiza rótulo (`Nobre`, `Criminoso`, etc). |
| **Fase 3** | **Ações de Mundo & Crimes** | ⏳ Planejado | Export declarativo para roubos, furtos e saques de outros scripts. |
| **Fase 4** | **Integrações de Mundo (Lojas & Bounties)** | ⏳ Planejado | Export para lojas aplicarem descontos e gatilho de procurado para caçadores. |
| **Fase 5** | **Hardening & Segurança** | ⏳ Planejado | Validações de rede contra trapaças e rate limiting. |

---

## 3. Detalhamento da Fase 1 (Detecção Confiável de NPCs)

### O Problema Encontrado Anteriormente
O detector de combate anterior acumulou filtros restritivos prematuros (anti-teleporte, checagem server-side de entidades ambientais que o servidor OneSync não gerencia, verificações de raycast enquanto a thread dormia). Como resultado, o client descartava os eventos silenciosamente antes de emitir qualquer registro.

### A Abordagem "Passo a Passo"
1. **Detecção no Client (`client/combat_detector.lua`):**
   - **Camada 1 (`gameEventTriggered`):** Escuta `CEventNetworkEntityDamage` e captura danos críticos e óbitos.
   - **Camada 2 (Pool Scan):** Varredura de alta frequência ativada durante e logo após combates (`lastCombatTime < 8000ms`), capturando finalizações por socos, coronhadas e estrangulamento/agarro.
   - **Classificação em 4 Categorias:** `ANIMAL` (ignorado), `LAWMAN` (autoridade), `HOSTILE` (bandido armado em combate) e `INNOCENT` (civil pacífico).
   - **Diferenciação Letal vs Não-Letal:**
     - **KILL (Morte):** `IsEntityDead(ped)` ou `isFatalFlag`.
     - **KNOCKOUT (Nocaute/Asfixia):** Ped inconsciente em ragdoll (`IsPedRagdoll` + `health <= 0` ou `IsPedDeadOrDying(ped, false)`).
   - **Transição de Estados:** Se um NPC nocauteado for posteriormente executado no chão, o sistema cobra apenas a diferença residual para atingir a penalidade de assassinato, sem bitributação.
2. **Envio ao Servidor (`server/main.lua`):**
   - Dispara `westrp_karma:server:onNpcAction(actionType, npcType, weaponHash, wasKnockedOut)`.
3. **Processamento no Servidor (`server/services/karma_service.lua`):**
   - Aplica a penalidade exata da ação e exibe logs coloridos no console do txAdmin.
   - Dispara notificação com anti-spam visual e de áudio para o cliente.
