# Especificação da API Lua e Exports (SDD Spec 05)
> **Padrão:** Clean Architecture & Zero-Trust Client  
> **Linguagem:** Lua 5.4  
> **Namespace:** `exports.ui`

---

## 1. Visão Geral da API

O `ui` atua como o **Provedor Universal de Interface**. Todos os scripts de gameplay do servidor interagem com a UI estritamente através dos exports documentados abaixo.

---

## 2. Camada de Notificações & Alertas

### 2.1 `Notify` (Cliente e Servidor)
Exibe uma notificação toast na pilha de avisos da tela:
```lua
-- No cliente:
exports.ui:Notify(kind, title, message, duration)

-- No servidor:
exports.ui:Notify(targetSrc, kind, title, message, duration)
```
- **Parâmetros:**
  - `targetSrc` (number): ID do jogador no servidor (-1 para todos).
  - `kind` (string): `"info"` | `"success"` | `"warning"` | `"error"` | `"bounty"`.
  - `title` (string): Título breve do aviso (ex: "Compra Realizada").
  - `message` (string): Descrição detalhada (ex: "Você comprou 2x Café por $1.50").
  - `duration` (number, opcional): Tempo em milissegundos (padrão: 5000ms).

---

## 3. Camada de Modais, Confirmações e Diálogos

### 3.1 `Confirm` (Cliente e Servidor)
Abre um diálogo modal com 2 escolhas, capturando foco de teclado e mouse de forma segura:
```lua
-- No cliente:
exports.ui:Confirm({
    kicker = "Valentine Armorer",
    title = "Comprar Revólver Schofield?",
    body = "A arma será enviada diretamente para o seu alforje.",
    lines = {
        { label = "Revólver Schofield", value = "$98.00" },
        { label = "Munição Normal x24", value = "$6.00" },
        { label = "Total", value = "$104.00" }
    },
    confirm = "Comprar",
    cancel = "Agora Não",
    danger = false
}, function(accepted)
    if accepted then
        TriggerServerEvent("gunsmith:buy", "schofield")
    end
end)

-- No servidor:
exports.ui:Confirm(targetSrc, opts, function(accepted)
    -- Callback executado quando o jogador responde ou timeout expira
end)
```

### 3.2 `InputDialog` (Cliente)
Solicita que o jogador preencha um formulário ou campo de texto/número:
```lua
local input = exports.ui:InputDialog({
    title = "Renomear Montaria",
    fields = {
        { type = "text", name = "horseName", label = "Novo Nome", max = 24, required = true },
        { type = "slider", name = "saddleHeight", label = "Ajuste da Sela", min = 1, max = 5 }
    }
})

if input then
    print("Nome escolhido:", input.horseName)
end
```

---

## 4. Camada de Barras de Progresso e Ações

### 4.1 `ProgressBar` (Cliente)
Inicia uma barra de progresso com animação, bloqueio suave de inputs e som de finalização:
```lua
local success = exports.ui:ProgressBar({
    duration = 5000,                -- Duração em ms
    label = "Ferrando cavalo...",  -- Texto explicativo
    useWhileDead = false,
    canCancel = true,
    anim = {
        dict = "amb_work@world_human_blacksmith@hammer@idle_a",
        clip = "idle_a"
    }
})

if success then
    print("Ação concluída com sucesso!")
else
    print("Ação cancelada pelo jogador ou dano!")
end
```

---

## 5. Camada de Views & Telas Complexas

### 5.1 `OpenView` & `CloseView` (Cliente)
Abre uma tela completa registrada no `ui` (ex: estábulos, lojas, banco):
```lua
exports.ui:OpenView("stables", {
    stableId = "valentine",
    title = "Estábulos de Valentine",
    rides = myRidesList,
    shop = catalogBreeds,
    tack = tackConfig
}, function(action, data)
    -- Listener de eventos disparados pela view
    if action == "preview" then
        UpdatePreviewEntity(data)
    elseif action == "buy" then
        TriggerServerEvent("stables:purchase", data)
    end
end)

-- Fechar a view programaticamente:
exports.ui:CloseView("stables")
```

---

## 6. Camada de HUD & Status

### 6.1 Métodos de Controle do HUD:
```lua
-- Ocultar ou exibir o HUD temporariamente (ex: cutscenes ou modo cinema):
exports.ui:SetHudHidden(true)

-- Atualizar vitais específicos (vida, estamina, deadeye):
exports.ui:SetCores({
    health = { core = 80, ring = 100 },
    stamina = { core = 90, ring = 70 }
})

-- Definir texto de ajuda contextual:
exports.ui:ShowHelp("Segure perto do caixa para roubar.", "G")
exports.ui:HideHelp()

-- Definir linha de objetivo:
exports.ui:SetObjective("Cavalgar até Valentine e encontrar o Xerife.")
```
