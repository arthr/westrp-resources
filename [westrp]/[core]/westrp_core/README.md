# WestRP Core Engine (`westrp_core`)

O **WestRP Core** é a espinha dorsal modular e reativa do ecossistema WestRP para RedM. Ele padroniza comunicação RPC, gerenciamento de ciclos de processamento (0.00ms idle resmon), logging estruturado e desacoplamento de frameworks legados através de uma camada canônica de **Bridge Pattern** (Regra R3).

---

## 🏛️ Arquitetura & Estrutura

```text
westrp_core/
├── fxmanifest.lua           -- Manifesto cerulean com exports canônicos
├── init.lua                 -- Inicializador compartilhado global (@westrp_core/init.lua)
├── shared/
│   ├── callback.lua         -- Sistema de RPC assíncrono (WestRP.Server.Callback / WestRP.Client.Callback)
│   ├── logger.lua           -- Logger padronizado com color grading ANSI
│   └── bridge/
│       └── vorp/            -- Implementação canônica da Bridge com VORP
│           ├── player.lua   -- Métodos de jogador, dados, saúde, cargos e economia
│           └── inventory.lua-- Concessão, remoção, contagem e verificação de itens/armas
└── client/
    ├── tick_manager.lua     -- Gestor de ticks adaptativos e registro de loops (0.00ms)
    └── ui_bridge.lua        -- Ponte cliente de comunicação unificada com o westrp_ui
```

---

## 🔌 WestRP.Shared.Bridge

A camada Bridge isola todos os resources de sistema (`[systems]`) de qualquer dependência direta do VORP ou outros frameworks.

### Player Bridge (`WestRP.Shared.Bridge.Player`)

| Método | Tipo | Descrição |
| :--- | :---: | :--- |
| `GetCharacter(source)` | Server | Retorna `{ source, identifier, charid, firstname, lastname, job, jobGrade, group, money, gold, rol, isDead, raw }` |
| `IsDead(source)` | Server | Retorna `boolean` indicando se o jogador está morto ou em coma |
| `AddMoney(source, type, amount)` | Server | Concede saldo em dinheiro (`cash`), ouro (`gold`) ou rol (`rol`) |
| `RemoveMoney(source, type, amount)` | Server | Debita saldo com validação prévia de fundos suficientes |
| `GetMoney(source, type)` | Server | Consulta saldo em conta específica |
| `Notify(source, text, duration)` | Server | Dispara notificação nativa para o cliente |
| `Heal(source)` | Server | Restaura vida, estamina e núcleos do personagem |
| `Revive(source)` | Server | Reanima jogador em caso de morte ou coma |
| `Respawn(source)` | Server | Força respawn limpo com transição de tela |
| `SetJob(source, job, grade, label)` | Server | Altera o emprego, graduação e label do personagem |
| `SetGroup(source, group)` | Server | Altera a permissão administrativa do usuário e personagem |
| `WhitelistUser(identifier)` | Server | Adiciona identificador à whitelist |
| `UnwhitelistUser(identifier)` | Server | Remove identificador da whitelist |

### Inventory Bridge (`WestRP.Shared.Bridge.Inventory`)

| Método | Tipo | Descrição |
| :--- | :---: | :--- |
| `AddItem(source, itemName, count, metadata)` | Server | Concede item com validação imediata de espaço e peso |
| `RemoveItem(source, itemName, count, metadata)` | Server | Remove item do inventário do jogador |
| `GetItemCount(source, itemName)` | Server | Retorna a quantidade total do item em posse |
| `CanCarryItem(source, itemName, count)` | Server | Valida se há espaço/capacidade para carregar o item |
| `GiveWeapon(source, weaponName)` | Server | Concede arma de fogo ou corpo a corpo com validação de limite |
| `ClearInventory(source)` | Server | Remove atomicamente todos os itens, armas e munições |

---

## ⚡ Gerenciamento de Processamento (`TickManager`)

O `TickManager` elimina loops de espera tradicionais (`while true do Wait(0)`), garantindo consumo de **0.00ms em repouso**:

```lua
-- Registro de tarefa periódica adaptativa
WestRP.Client.TickManager.CreateTask("interacao_porta", function(task)
    local dist = #(GetEntityCoords(PlayerPedId()) - CoordsPorta)
    if dist > 20.0 then
        task:SetInterval(1500) -- Longe: 1.5s
    elseif dist > 2.5 then
        task:SetInterval(250)  -- Perto: 250ms
    else
        task:SetInterval(0)    -- Ao alcance: Renderiza prompt por quadro
    end
end)

-- Registro de tick contínuo ligado/desligado sob demanda (NoClip, DevLaser)
WestRP.Client.TickManager.RegisterTick("noclip_loop", function()
    -- Movimentação por quadro
end, 0)

WestRP.Client.TickManager.UnregisterTick("noclip_loop")
```

---

## 🔄 RPC Assíncrono (`WestRP.Callback`)

Garante tráfego de dados bidirecional de alto desempenho sem necessidade de `RegisterNetEvent` soltos:

```lua
-- Servidor
WestRP.Server.Callback.Register("meu_resource:obterDados", function(source, cb, filtro)
    local dados = ConsultarBanco(filtro)
    cb(dados)
end)

-- Cliente (Síncrono com Await)
local dados = WestRP.Client.Callback.TriggerAwait("meu_resource:obterDados", "todos")
```
