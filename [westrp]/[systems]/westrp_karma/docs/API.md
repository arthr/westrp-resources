# Documentação de API & Integrações — `westrp_karma`

Este documento contém os contratos de interface pública (Exports), eventos de rede e exemplos de código para integrar o `westrp_karma` com outros módulos do ecossistema WestRP.

---

## 1. Server-Side Exports

### `ModifyKarma`
Altera a pontuação moral de um jogador conectado.

```lua
---@param source integer ID do jogador no servidor
---@param amount integer Valor a adicionar (positivo) ou subtrair (negativo)
---@param reason string Motivo legível da alteração (usado para logs e notificações)
---@return boolean success Se a operação foi executada com sucesso
---@return integer? newKarma Novo valor do karma após a mutação
exports['westrp_karma']:ModifyKarma(source, amount, reason)
```

**Exemplo de Uso (Sistema de Roubo a Loja):**
```lua
-- Penaliza o assaltante por cometer roubo à mão armada
local success, novoKarma = exports['westrp_karma']:ModifyKarma(source, -40, "Roubo a estabelecimento comercial")
```

---

### `GetPlayerKarma`
Retorna a pontuação numérica bruta de karma do jogador.

```lua
---@param source integer
---@return integer karma Pontuação entre -1000 e 1000
exports['westrp_karma']:GetPlayerKarma(source)
```

---

### `GetPlayerTier`
Retorna a tabela completa de propriedades do Tier moral atual do jogador.

```lua
---@param source integer
---@return KarmaTier tier Objeto completo contendo id, name, discount, etc.
exports['westrp_karma']:GetPlayerTier(source)
```

**Exemplo de Uso:**
```lua
local tier = exports['westrp_karma']:GetPlayerTier(source)
print("O jogador está no tier: " .. tier.name .. " (ID: " .. tier.id .. ")")
```

---

### `GetShopModifier`
Retorna o multiplicador de preço que deve ser aplicado em lojas da cidade.

```lua
---@param source integer
---@return number multiplier (Ex: -0.20 para 20% de desconto, +0.25 para 25% de taxa extra)
exports['westrp_karma']:GetShopModifier(source)
```

**Exemplo de Uso (Integração com Armaria / Loja Geral):**
```lua
local basePrice = 50.0
local modifier = exports['westrp_karma']:GetShopModifier(source)
local finalPrice = basePrice * (1.0 + modifier)
-- Se o jogador tiver 20% de desconto (modifier = -0.20): finalPrice = 40.0
```

---

### `IsBountyEligible`
Verifica se o jogador ultrapassou o limiar de fora-da-lei e se tornou elegível para ser caçado por mercenários ou delegados.

```lua
---@param source integer
---@return boolean isEligible
---@return number bountyPrice
exports['westrp_karma']:IsBountyEligible(source)
```

---

## 2. Eventos de Rede (Network Events)

### Servidor para Cliente: `westrp_karma:client:onKarmaUpdated`
Emitido sempre que o karma do cliente for alterado.

```lua
RegisterNetEvent('westrp_karma:client:onKarmaUpdated', function(payload)
    print("Novo Karma:", payload.currentKarma)
    print("Tier:", payload.tier.name)
    print("Variação (Delta):", payload.delta)
    print("Motivo:", payload.reason)
end)
```

### Servidor para Servidor: `westrp_karma:server:onTierChanged`
Disparado internamente quando a pontuação de um jogador cruza a fronteira entre dois patamares morais.

```lua
AddEventHandler('westrp_karma:server:onTierChanged', function(source, oldTier, newTier)
    print(string.format("Player %d mudou de [%s] para [%s]", source, oldTier.name, newTier.name))
end)
```

### Servidor para Servidor: `westrp_karma:server:onBountyEligible`
Disparado quando um jogador comete crimes suficientes para entrar na lista de procurados.

```lua
AddEventHandler('westrp_karma:server:onBountyEligible', function(source, bountyPrice)
    -- Pode ser escutado por um script de cartazes de procurado no xerifado!
end)
```

---

## 3. Client-Side Exports

### `GetLocalKarma`
Retorna a pontuação de karma em cache do próprio cliente.

```lua
---@return integer
exports['westrp_karma']:GetLocalKarma()
```

### `GetLocalTier`
Retorna o objeto do patamar moral em cache no cliente.

```lua
---@return KarmaTier
exports['westrp_karma']:GetLocalTier()
```
