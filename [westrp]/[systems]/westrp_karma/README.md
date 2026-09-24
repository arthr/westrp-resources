# WestRP Karma (`westrp_karma`)

> **Dynamic Morality, Systemic Karma & Combat Self-Defense Engine for WestRP**  
> Desenvolvido pela Equipe de Engenharia WestRP para ambientes RedM (VORP Core).

---

## 📖 Visão Geral

O **`westrp_karma`** é um módulo de infraestrutura moral para servidores de RedM Roleplay. Ele introduz um sistema de pontuação ética contínua ($-1000$ a $+1000$) que reflete o alinhamento moral de cada habitante da fronteira (desde santos benfeitores até flagelos desalmados).

O sistema resolve problemas históricos de servidores de RP:
1. **Fim do Griefing de Legítima Defesa:** O agressor inicial é identificado em um buffer temporal (`SelfDefensePool`); a vítima que revida não sofre penalidades morais.
2. **Alta Escalabilidade (Zero Lag de I/O):** Mutações de estado ocorrem em memória e são gravadas em lote via *Unit of Work* com `oxmysql`, eliminando travamentos de banco de dados em tiroteios.
3. **Imersão Nativa:** Renderiza a clássica **Barra de Honra do RDR2** via `DataBinding` nativo sem necessidade de NUI pesado, acompanhada pelos efeitos sonoros originais do jogo.
4. **Impacto Real no Mundo:** Aplica descontos e sobretaxas em lojas da cidade, altera o comportamento de NPCs e gera contratos automáticos de caça a recompensa para foras-da-lei conhecidos.

---

## 📁 Estrutura de Arquivos

```text
westrp_karma/
├── fxmanifest.lua                  # Manifesto com ordenação estrita de scripts
├── config.lua                      # Configuração geral de balanceamento e tempos
├── schema.sql                      # Migração DDL para a tabela characters
├── README.md                       # Este arquivo
├── docs/                           # Documentação detalhada
│   ├── SDD.md                      # Software Design Document formal
│   ├── ARCHITECTURE.md             # Desenho da Arquitetura Hexagonal
│   └── API.md                      # Contratos de Exports e Eventos
├── shared/                         # Código compartilhado entre client e server
│   ├── types.lua                   # Tipos e interfaces EmmyLua (LuaLS)
│   └── tiers.lua                   # Tabela de Tiers e avaliador puro de domínio
├── client/                         # Camada de apresentação e detecção
│   ├── combat_detector.lua         # Listener de impacto de dano (CEventNetworkEntityDamage)
│   ├── honor_presenter.lua         # Driver da barra nativa do RDR2 (DataBinding)
│   └── main.lua                    # Ciclo de vida e sincronização no cliente
└── server/                         # Camada de domínio, segurança e infraestrutura
    ├── domain/
    │   ├── karma_entity.lua        # Objeto de domínio do Karma com dirty tracking
    │   └── self_defense_pool.lua   # Buffer de autodefesa com Lazy GC
    ├── security/
    │   └── combat_verifier.lua     # Filtro anti-cheat, anti-teleport e distâncias
    ├── infrastructure/
    │   ├── database_adapter.lua    # Unit of Work / Batching com oxmysql
    │   └── framework_adapter.lua   # Bridge isolada para VORP Core
    ├── services/
    │   └── karma_service.lua       # Orquestrador de regras de negócio
    └── main.lua                    # Bootstrap do servidor e exports
```

---

## 🚀 Instalação e Inicialização

### 1. Migração de Banco de Dados (100% Automática)
O `westrp_karma` possui um mecanismo integrado de **Auto-Migration** no `DatabaseAdapter`.
Assim que o resource inicia pela primeira vez, ele verifica a integridade da tabela `characters` e cria automaticamente as colunas (`karma`, `karma_tier`, `bounty_price`) e o índice (`idx_character_karma`) através do `oxmysql`.

> **Nota:** Não é necessário rodar comandos manuais no terminal! O arquivo `schema.sql` é mantido apenas como documentação e referência DDL para DBAs.

### 2. Ativação no `server.cfg`
Certifique-se apenas de iniciar o `westrp_karma` após as dependências do core (`westrp_core` e `oxmysql`):

```cfg
ensure oxmysql
ensure vorp_core
ensure westrp_core
...
ensure westrp_karma
```

---

## 📚 Documentação Técnica

Para mais detalhes sobre o design e integrações:
* [Software Design Document (SDD)](docs/SDD.md)
* [Guia de Arquitetura Hexagonal](docs/ARCHITECTURE.md)
* [Referência de API e Exports](docs/API.md)
