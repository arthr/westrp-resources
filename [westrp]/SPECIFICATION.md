# Especificação Arquitetural e Técnica — Framework [westrp]
> **Padrão:** Spec-Driven Development (SDD)  
> **Versão:** 1.0.0  
> **Autor / Arquiteto:** Equipe de Engenharia WestRP  
> **Target Engine:** RedM (CitizenFX RDR3 - Game Build 1491+)  
> **Stack Base:** Lua 5.4 (Strict / EmmyLua Type Annotations) + oxmysql + PolyZone + Bridge VORP Core v3.3  

---

## 1. Visão Geral e Filosofia do Projeto

O **[westrp]** é um ecossistema modular, seguro e de altíssima performance projetado especificamente para servidores de **Roleplay Imersivo em Red Dead Redemption 2**.

### 1.1 O Desafio Histórico no RedM
Tradicionalmente, servidores de RedM sofrem com:
1. **Script Bloat & Alto Resmon:** Loops concorrentes em `Wait(0)` varrendo distâncias desnecessariamente, degradando o frametime do cliente (resmon acumulado > 2.0ms).
2. **Fragilidade por Acoplamento:** Scripts chamando `exports.vorp_core` ou disparando eventos do VORP diretamente em dezenas de arquivos. Se o VORP atualiza ou altera tabelas, o servidor inteiro quebra.
3. **Vulnerabilidades de Segurança (Client-Authoritative):** Eventos de rede que aceitam quantidade de itens, valores de dinheiro ou coordenadas diretamente do cliente, permitindo injeção de exploits por executores Lua.
4. **Falta de Padronização para Desenvolvedor Solo:** Códigos desiguais, sem padrões de inicialização ou limpeza (`onResourceStop`), gerando vazamento de memória (memory leaks) e perda de produtividade ao reiniciar scripts (`ensure`).

### 1.2 A Solução WestRP
Uma arquitetura fundamentada em **Spec-Driven Development (SDD)**, com:
* **Target Resmon 0.00ms em Idle** através de agendamento adaptativo de frames (*Dynamic Sleeping*).
* **Camada de Abstração (Bridge Pattern):** O código de negócio nunca fala com o VORP diretamente. O VORP é apenas um *driver* substituível.
* **Segurança Zero-Trust:** O cliente nunca tem autoridade sobre regras de estado, itens ou distâncias.
* **Desenvolvimento Ágil para Solo Dev:** Um template pré-configurado permite criar um novo recurso completo, seguro e performático em menos de 5 minutos.

---

## 2. Princípios de Engenharia e Regras Inegociáveis

Todo e qualquer código adicionado ao ecossistema `[westrp]` deve obedecer estritamente aos seguintes mandamentos:

### R1. Regra do Resmon 0.00ms (Dynamic Sleep)
* **Proibido:** `while true do Wait(0) ... end` sem controle de distância ou estado.
* **Obrigatório:** Uso do `WestRP.Client.TickManager` ou controle de sono adaptativo:
  * Distância > 30 metros: `Wait(1500)` a `Wait(2000)`.
  * Distância entre 10 e 30 metros: `Wait(500)`.
  * Distância < 2 metros (zona de interação ativa): `Wait(0)` apenas enquanto o prompt estiver visível ou ação em execução.

### R2. Regra da Autoridade Absoluta do Servidor (Zero-Trust)
* O cliente **nunca** envia: `"me dê 10 maçãs"` ou `"paguei $20"`.
* O cliente envia apenas uma intenção: `TriggerServerEvent('westrp:action:request', actionId, entityNetId)`.
* O servidor **sempre** valida:
  1. *Player Identity:* O jogador existe e tem um personagem selecionado?
  2. *Physical Distance:* O ped do jogador está a menos de `X` metros do ponto/entidade no momento da execução? (`#(GetEntityCoords(GetPlayerPed(src)) - targetCoords) <= maxDist`).
  3. *State Sanity:* O jogador não está morto, algemado ou em outra animação de bloqueio?
  4. *Rate-Limit:* O jogador não está disparando chamadas com frequência anormal?

### R3. Princípio do Desacoplamento (Bridge Pattern)
* **Nenhum** recurso em `[systems]` pode importar arquivos do VORP ou disparar eventos proprietários do VORP.
* Toda operação de inventário, dinheiro, personagem ou permissão deve ser feita via:
  ```lua
  WestRP.Shared.Bridge.Inventory.*
  WestRP.Shared.Bridge.Player.*
  ```

### R4. Ciclo de Vida Limpo (Lifecycle Management)
* Todo módulo deve registrar seu encerramento com limpeza completa de:
  * Prompts de interface nativa (`PromptDelete`).
  * Loops de repetição ativos (`TickManager:StopAll()`).
  * Handlers de eventos temporários.
* Isso garante que comandos como `ensure <resource_name>` funcionem instantaneamente em desenvolvimento sem duplicar threads ou prompts na tela.

---

## 3. Estado Atual vs. Estado Alvo (North Star Architecture)

```
ESTADO ATUAL (Baseline)                    ESTADO ALVO (WestRP North Star)
┌─────────────────────────────────┐        ┌───────────────────────────────────────────┐
│ txAdmin VORP Recipe             │        │ resources/                                │
│ ├── [VORP] (37 scripts acoplados│        │ ├── [VORP] (Isolado / Vendor Puro)        │
│ ├── [standalone]                │        │ ├── [standalone] (oxmysql, polyzone, etc.)│
│ └── [local] (Vazio)             │        │ └── [westrp]/                             │
└─────────────────────────────────┘        │     ├── SPECIFICATION.md (Este Guia)      │
                                           │     ├── [core]/                           │
                                           │     │   └── westrp_core (Kernel / SDK)    │
                                           │     └── [systems]/                        │
                                           │         ├── westrp_template (Boilerplate) │
                                           │         ├── westrp_interaction            │
                                           │         ├── westrp_economy                │
                                           │         └── westrp_...                    │
                                           └───────────────────────────────────────────┘
```

### Onde começamos:
* Servidor com VORP 3.3 padrão instalado, banco de dados oxmysql operacional.
* Zero padronização para novos scripts de gameplay.

### Onde estamos indo (A Estrutura Final):
* Um ecossistema isolado em `resources/[westrp]`, auto-contido e versionável em Git independente.
* Núcleo `westrp_core` fornecendo bibliotecas nativas de alto desempenho.
* Galeria de `[systems]` homogêneos, rápidos de manter por um desenvolvedor solo e fáceis de plugar/desplugar.

---

## 4. Taxonomia de Pastas e Nomenclatura

```text
resources/[westrp]/
│
├── SPECIFICATION.md                  # Este documento (Contrato Geral)
├── UI_SPECIFICATION.md               # Especificação de UI (Dock Lateral)
├── PANEL_SPECIFICATION.md            # Especificação de Painéis (Workspaces / Alta Interatividade)
├── README.md                         # Resumo executivo do repositório
│
├── [assets]/                         # 🖼️ Camada Central de Mídias e Recursos Estáticos
│   └── westrp_assets/                # Repositório de 2.122 ícones e índice index.json
│       ├── fxmanifest.lua
│       └── html/
│           ├── index.json            # Mapeamento automático de resolução itemId -> URL
│           └── icons/                # 34 categorias limpas de ícones PNG do RDR2
│
├── [core]/                           # ⚙️ Camada de Infraestrutura, SDK e UI Engine
│   ├── westrp_core/                  # Núcleo Central (Bridges, TickManager, RPC, Security)
│   └── westrp_ui/                    # Motor NUI Centralizado (Dock Lateral + Panel Workspace)
│
└── [systems]/                        # 🎮 Módulos de Gameplay / Features
    ├── westrp_template/              # Molde oficial para novos recursos
    ├── westrp_interaction/           # Sistema de pontos de interação no mundo
    └── [futuros_recursos]/           # Economia, caça, trabalhos, moradia...
```

---

## 5. Especificação de Contratos de API do `westrp_core`

Qualquer recurso que inclua `@westrp_core/init.lua` em seu `fxmanifest.lua` terá acesso instantâneo ao objeto global `WestRP`.

### 5.1 Shared Layer

#### `WestRP.Shared.Logger`
Gera logs formatados e coloridos com identificação da origem e nível de severidade.
```lua
WestRP.Shared.Logger.Debug(tag, message, ...)
WestRP.Shared.Logger.Info(tag, message, ...)
WestRP.Shared.Logger.Warn(tag, message, ...)
WestRP.Shared.Logger.Error(tag, message, ...)
```

#### `WestRP.Shared.Callback`
Executa chamadas RPC assíncronas bidirecionais sem poluição de eventos manuais.
```lua
-- No Servidor (Registro):
WestRP.Server.Callback.Register('westrp:getPlayerBalance', function(source, cb, accountType)
    local money = WestRP.Shared.Bridge.Player.GetMoney(source, accountType)
    cb(money)
end)

-- No Cliente (Invocação com Promise/Callback):
WestRP.Client.Callback.Trigger('westrp:getPlayerBalance', function(balance)
    print("Meu saldo:", balance)
end, 'cash')
```

#### `WestRP.Shared.Bridge`
Interface única com o VORP (Regra R3).

**Player Bridge (`WestRP.Shared.Bridge.Player`):**
```lua
-- Obter dados e estado de vida do personagem
local char = WestRP.Shared.Bridge.Player.GetCharacter(source)
local isDead = WestRP.Shared.Bridge.Player.IsDead(source)

-- Manipular economia (cash, gold, rol)
local success = WestRP.Shared.Bridge.Player.AddMoney(source, 'cash', 50.0)
local hasEnough = WestRP.Shared.Bridge.Player.RemoveMoney(source, 'cash', 25.0)

-- Saúde e reanimação
WestRP.Shared.Bridge.Player.Heal(source)
WestRP.Shared.Bridge.Player.Revive(source)
WestRP.Shared.Bridge.Player.Respawn(source)

-- Gestão de cargos e whitelist
WestRP.Shared.Bridge.Player.SetJob(source, 'sheriff', 2, 'Deputy')
WestRP.Shared.Bridge.Player.SetGroup(source, 'admin')
WestRP.Shared.Bridge.Player.WhitelistUser(identifier)
WestRP.Shared.Bridge.Player.UnwhitelistUser(identifier)
```

**Inventory Bridge (`WestRP.Shared.Bridge.Inventory`):**
```lua
-- Itens
local canCarry = WestRP.Shared.Bridge.Inventory.CanCarryItem(source, 'bread', 2)
if canCarry then
    WestRP.Shared.Bridge.Inventory.AddItem(source, 'bread', 2, { quality = 100 })
end
WestRP.Shared.Bridge.Inventory.RemoveItem(source, 'bread', 1)
local count = WestRP.Shared.Bridge.Inventory.GetItemCount(source, 'bread')

-- Armas e Wipe
WestRP.Shared.Bridge.Inventory.GiveWeapon(source, 'WEAPON_REVOLVER_CATTLEMAN')
WestRP.Shared.Bridge.Inventory.ClearInventory(source)
```

---

### 5.2 Client Layer

#### `WestRP.Client.TickManager`
Substitui loops `while true do` convencionais, garantindo que o consumo do script caia a 0.00ms quando inativo.
```lua
-- Registra uma tarefa com frequência adaptativa
WestRP.Client.TickManager.CreateTask('interaction_loop', function(task)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local dist = #(playerCoords - TargetCoords)
    
    if dist > 30.0 then
        task:SetInterval(1500) -- Longe: Dorme 1.5s
    elseif dist > 3.0 then
        task:SetInterval(400)  -- Aproximando: Dorme 400ms
    else
        task:SetInterval(0)    -- Ao lado: Atualiza a cada frame para renderizar prompt
        -- Exibe prompt ou texto 3D
    end
end)

-- Para cancelar e limpar:
WestRP.Client.TickManager.RemoveTask('interaction_loop')
```

#### `WestRP.Client.PromptManager`
Cria prompts do RDR3 com um comando limpo e gerencia o registro no motor nativo do jogo.
```lua
local prompt = WestRP.Client.PromptManager.Create({
    title = "Falar com Xerife",
    control = 0x760A9C6F, -- [G]
    mode = "hold",         -- "standard" ou "hold"
    holdDuration = 1000,   -- ms se hold
})

prompt:OnComplete(function()
    print("Segurou o botão!")
end)

-- Limpeza ao sair da área:
prompt:Delete()
```

---

### 5.3 Server Layer

#### `WestRP.Server.Security`
Validação preventiva antes de executar qualquer ação solicitada pelo cliente.
```lua
-- Validação de distância vetorial (Anti-Noclip / Anti-Teleport)
local isNear = WestRP.Server.Security.ValidateDistance(source, targetCoords, maxDistance)
if not isNear then
    WestRP.Shared.Logger.Warn("SECURITY", "Player %s tentou interagir fora de alcance!", source)
    return false
end

-- Rate-Limiter (Anti-Flood)
local allowed = WestRP.Server.Security.CheckRateLimit(source, 'harvest_herb', 2000) -- max 1 vez a cada 2s
if not allowed then
    return false
end
```

---

## 6. Guia Passo a Passo para o Desenvolvedor Solo (Playbook)

### 6.1 Como criar um novo recurso em 3 minutos:
1. Copie a pasta `resources/[westrp]/[systems]/westrp_template` para `resources/[westrp]/[systems]/westrp_minhanovafuncao`.
2. Renomeie o resource no `fxmanifest.lua` (`name 'westrp_minhanovafuncao'`).
3. Adicione suas configurações em `config.lua`.
4. Escreva sua lógica no `client/main.lua` e `server/main.lua`. O `WestRP` já estará disponível globalmente com todo o ferramental.
5. Adicione `ensure westrp_minhanovafuncao` no `server.cfg`.

### 6.2 Como testar em tempo real:
* No console do servidor (F8 ou txAdmin):
  * `restart westrp_minhanovafuncao`
* Como o template possui hooks `OnUnload`, todos os prompts e loops anteriores são purgados da memória e recriados imediatamente sem duplicatas.

---

## 7. Roadmap Evolutivo (Milestones)

* [ ] **Fase 1: Fundação do Núcleo (`westrp_core`)**
  * Criação do `fxmanifest.lua` e `init.lua`.
  * Implementação dos módulos Shared (`Logger`, `Utils`, `Bridge VORP`).
  * Implementação dos módulos Client (`TickManager`, `PromptManager`).
  * Implementação dos módulos Server (`Security`, `Callback`).
* [ ] **Fase 2: Boilerplate (`westrp_template`)**
  * Criação do template universal pronto para duplicação.
* [ ] **Fase 3: Módulo de Validação e Estresse (`westrp_interaction`)**
  * Criação de pontos de interação configuráveis.
  * Validação de 0.00ms de resmon em idle e 0.01ms em foco ativo.
  * Validação de segurança de distância no servidor.
* [ ] **Fase 4: Configuração do `server.cfg` e Testes de Carga**
  * Inclusão ordenada da nova base e teste de hot-reload.
