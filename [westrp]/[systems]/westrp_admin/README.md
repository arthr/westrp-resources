# WestRP Admin Engine — Manual Oficial do Desenvolvedor & Operador

O **WestRP Admin** (`westrp_admin`) é o sistema administrativo, operacional e de auditoria de última geração do ecossistema WestRP. Ele foi desenvolvido com foco estrito em **desempenho absoluto (0.00ms idle resmon)**, **segurança Zero-Trust** e **integração nativa com a suíte de interfaces (`westrp_ui`) e repositório central de assets (`westrp_assets`)**.

---

## 📑 Índice
1. [Visão Geral & Filosofia](#1-visão-geral--filosofia)
2. [Arquitetura & Estrutura](#2-arquitetura--estrutura)
3. [Controle de Acesso Baseado em Cargos (RBAC)](#3-controle-de-acesso-baseado-em-cargos-rbac)
4. [Módulo A: O Dock Lateral (Acesso Rápido / Teclado)](#4-módulo-a-o-dock-lateral-acesso-rápido--teclado)
5. [Módulo B: O Painel Central (Mesa de Trabalho Multimodal)](#5-módulo-b-o-painel-central-mesa-de-trabalho-multimodal)
6. [Segurança Zero-Trust & Prevenção de Abuso](#6-segurança-zero-trust--prevenção-de-abuso)
7. [Desempenho & Garantia de 0.00ms Resmon](#7-desempenho--garantia-de-000ms-resmon)
8. [Auditoria & Integração com Discord Webhooks](#8-auditoria--integração-com-discord-webhooks)
9. [Guia de Comandos & Teclas de Atalho](#9-guia-de-comandos--teclas-de-atalho)

---

## 1. Visão Geral & Filosofia

O `westrp_admin` substitui definitivamente soluções legadas como `vorp_admin`, adotando padrões de ponta:

* **0.00ms Idle Resmon**: Não há threads em loop constante (`while true do Wait(0)`). O atalho PGDOWN é registrado via `RegisterKeyMapping` nativo do RedM, e rotinas pesadas (NoClip, DevLaser, GodMode) são injetadas no `WestRP.Client.TickManager` estritamente quando ativadas.
* **Desacoplamento Visual Completo**: Toda a renderização gráfica fica a cargo do `westrp_ui`. O script administra apenas o modelo de dados e regras de negócio.
* **Desfoque 3D Sem Telas Escuras**: O Painel Central utiliza `OJDominoBlur` diretamente da engine da Rockstar Games, sem fundos pretos artificiais via CSS `backdrop-filter`.
* **Resolução Dinâmica de Ícones**: Integração com `westrp_assets`. Ao abrir o Item Spawner, as imagens de mais de 2.100 itens são resolvidas e carregadas instantaneamente.
* **Segurança Zero-Trust**: O servidor não confia em eventos do cliente. Todas as ações passam por middleware com validação de hierarquia, permissões RBAC e rate limit contra spam.

---

## 2. Arquitetura & Estrutura

O resource está estruturado em módulos especializados:

```text
westrp_admin/
├── fxmanifest.lua           -- Manifesto cerulean com importação do @westrp_core/init.lua
├── config.lua               -- Configuração de cargos, controles, velocidades e webhooks
├── shared/
│   └── permissions.lua      -- Resolução de cargos e validação hierárquica
├── client/
│   ├── data/
│   │   ├── datapeds.lua     -- Dicionário de hashes de peds para o DevLaser
│   │   └── dataprops.lua    -- Dicionário de hashes de props e veículos
│   ├── boosters.lua         -- NoClip (TickManager), GodMode 511 proofs, Invisibilidade, Munição Infinita
│   ├── teleport.lua         -- Teleporte seguro, TPM, Auto-TPM, Guarma e histórico de coordenadas
│   ├── devtools.lua         -- Dev Laser raycast, desenho 3D, cópia de vetores e deleção de objetos
│   ├── spectate.lua         -- Modo espectador roteirizado com câmera suave e fade
│   ├── dock.lua             -- Controlador do menu rápido lateral (westrp_ui:OpenDock)
│   ├── panel.lua            -- Controlador do painel central completo (westrp_ui:OpenPanel)
│   └── main.lua             -- Registro de comandos, keymapping e handlers de ciclo de vida
└── server/
    ├── security.lua         -- Middleware de autorização e rate limiting
    ├── logger.lua           -- Disparo de webhooks Discord estruturados com rich embeds
    ├── players.lua          -- Gestão de jogadores online (GoTo, Bring, Freeze, Heal, Revive, Kick, Troll)
    ├── bans.lua             -- Gestão de banimentos ativos, unban e whitelist
    ├── items.lua            -- Catálogo do spawner, concessão de armas/itens/moedas e wipe de inventário
    ├── world.lua            -- Anúncios globais com Toast sonoro para toda a cidade
    └── main.lua             -- Registro dos callbacks RPC (WestRP.Callback) e roteamento de ações
```

---

## 3. Controle de Acesso Baseado em Cargos (RBAC)

As permissões são definidas no `config.lua` e resolvidas via `shared/permissions.lua`:

| Cargo | Nível Hierárquico | Permissões Principais |
| :--- | :---: | :--- |
| **`root`** | `100` | Acesso irrestrito (`all = true`). Imune a ações de outros administradores. |
| **`admin`** | `80` | Gestão completa de jogadores, teleporte, spawner de itens/armas, banimentos e devtools. |
| **`moderator`** | `50` | Ações operacionais: curar, reviver, spectate, tp básico, freeze, kick e bans de até 3 dias. |
| **`support`** | `20` | Ações de auxílio: spectate, auto-cura, teleporte assistido e anúncios. |

---

## 4. Módulo A: O Dock Lateral (Acesso Rápido / Teclado)

Invocado ao pressionar **`[PGDOWN]`** ou digitar **`/admin`**.
Permite movimentação restrita e visão livre da câmera com foco de teclado na interface de 350px.

### Abas & Recursos Disponíveis:
1. **BOOSTERS**:
   - `Modo Voo (NoClip)`: Ativa movimentação livre sem colisão física. Pressione `[L-SHIFT]` para alternar entre as 5 velocidades pré-configuradas. Ao aterrissar em queda, o script absorve o impacto automaticamente sem acionar ragdoll.
   - `Modo Deus (GodMode)`: Imunidade total (511 proofs RDR3: balas, fogo, explosão, colisão, melee, etc.). Se o operador estiver montado em um cavalo, a proteção é estendida imediatamente à montaria.
   - `Invisibilidade`: Oculta o ped do operador para ações discretas de monitoramento.
   - `Núcleos Dourados`: Preenche núcleos e barras externas em nível máximo.
   - `Munição Infinita`: Trava os pentes da arma atualmente empunhada.
   - `Auto Cura` & `Auto Reviver`: Restauração instantânea de saúde, fôlego e metabolismo.
2. **TELEPORTES**:
   - `Ir para Marcador (TPM)`: Teleporta com verificação assíncrona de colisão no solo para evitar cair no limbo.
   - `Auto-TPM ao Marcar`: Teleporta automaticamente assim que o operador marca um novo ponto no mapa.
   - `Voltar Posição Anterior`: Retorna para onde o operador estava antes da última ação de deslocamento.
   - `Zarpar / Voltar de Guarma`: Configura as instâncias de minimap e área caribenha nativa.
3. **DEV TOOLS**:
   - `Laser Inspecionador Raycast`: Mira laser 3D que desenha cubo vermelho e lê Hash, Modelo, Coordenadas e Rotações.
     - `[G]`: Copia `vector3(x, y, z)` para o clipboard.
     - `[H]`: Copia o relatório completo da entidade.
     - `[DEL]`: Exclui a entidade apontada.
   - `Copiar Vetores`: Atalhos para copiar `vector3`, `vector4`, `heading` e `interior_id`.
   - `Deletar Objeto Mais Próximo`: Remove props indesejados no raio de 5 metros.
   - `Mesa de Trabalho Completa`: Transiciona com elegância para o Painel Central.

---

## 5. Módulo B: O Painel Central (Mesa de Trabalho Multimodal)

Invocado via opção no Dock ou comando **`/adminpanel`**.
Ativa o cursor livre do mouse e aplica o desfoque cinematográfico nativo `OJDominoBlur`.

### Abas do Painel:
1. **JOGADORES ONLINE (`viewType = 'table'`)**:
   - Livro-razão em tempo real de todos os jogadores conectados.
   - Colunas: ID, Nome do Personagem, Steam, Emprego/Cargo, Permissão, Saldo em Dinheiro e Estado (Vivo, Morto, Congelado).
   - Ao selecionar um jogador e confirmar, abre o **Menu Contextual de Ações no Jogador**:
     - *Deslocamento*: Ir Até Ele (GoTo), Puxar Para Mim (Bring), Modo Espectador.
     - *Saúde & Controle*: Curar, Reviver, Forçar Respawn Limpo, Congelar/Descongelar.
     - *Punições*: Expulsar (Kick), Banir por 3 Dias, Banir Permanentemente.
     - *Trolagens*: Raio dos Céus, Colocar em Chamas, Enviar para o Céu, Derrubar no Chão (Ragdoll), Algemar e Efeito Embriaguez/Pântano.
2. **ITEM SPAWNER (`viewType = 'grid'`)**:
   - Vitrine em grade com todos os itens cadastrados no servidor.
   - Renderização automática de ícones através do `westrp_assets`.
   - Seletor de quantidade no rodapé (`-` e `+`) com busca em tempo real por nome.
   - Um clique entrega o item diretamente ao inventário com notificação Toast.
3. **PUNIÇÕES & BANS (`viewType = 'table'`)**:
   - Listagem de todas as punições ativas no servidor (offline e online).
   - Exibe identificador, motivo, expiração e status (Temporário / Permanente).
   - Ação de 1 clique para revogar punições imediatamente (Unban).

---

## 6. Segurança Zero-Trust & Prevenção de Abuso

1. **Validação de Hierarquia**:
   - Administradores de cargo menor não conseguem expulsar, banir ou interferir em operadores de cargo superior ou igual.
2. **Rate Limiting Anti-Spam**:
   - Comandos com alta demanda de processamento contam com cooldown de segurança no servidor para mitigar ataques de flood via NUI ou NetEvents injetados.
3. **Sanitização de Coordenadas & Entidades**:
   - Toda solicitação de teleporte valida limites máximos de coordenadas do mapa para prevenir quedas no vazio.

---

## 7. Desempenho & Garantia de 0.00ms Resmon

```text
+-----------------------+-------------+------------------------------------+
| Estado                | Consumo     | Mecanismo                          |
+-----------------------+-------------+------------------------------------+
| Em Repouso (Idle)     | 0.00 ms     | RegisterKeyMapping nativo (sem Wait)|
| Dock Aberto           | 0.01 ms     | NUI Chromium + KeepInput           |
| NoClip Ativo          | 0.02 - 0.03 | Injetado no WestRP.TickManager     |
| DevLaser Ativo        | 0.03 - 0.04 | ShapeTestRay no WestRP.TickManager |
+-----------------------+-------------+------------------------------------+
```

---

## 8. Auditoria & Integração com Discord Webhooks

Todas as operações sensíveis geram rich embeds automáticos contendo:
* Nome do operador, ID e menção ao Discord (`<@ID>`).
* Endereço IP e identificadores Steam/Licença.
* Dados completos do jogador alvo afetado.
* Coordenadas de origem e destino em teleportes.
* Quantidade e IDs de itens concedidos no Spawner.

---

## 9. Guia de Comandos & Teclas de Atalho

| Atalho / Comando | Função |
| :--- | :--- |
| **`[PGDOWN]`** | Abre ou fecha o menu lateral rápido (Dock). |
| **`/admin`** | Alternativa via chat/console para abrir o Dock. |
| **`/adminpanel`** | Abre diretamente a Mesa de Trabalho Central completa. |
| **`[L-SHIFT]`** *(no NoClip)* | Alterna entre as 5 velocidades de voo. |
| **`[G]`** *(no DevLaser)* | Copia `vector3(x, y, z)` para a área de transferência. |
| **`[H]`** *(no DevLaser)* | Copia todos os dados da entidade inspecionada. |
| **`[DEL]`** *(no DevLaser)* | Deleta o objeto selecionado pelo laser. |
