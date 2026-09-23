# Especificação de Engenharia — Expansão do Admin Panel (`westrp_admin`)
> **Padrão:** Spec-Driven Development (SDD)  
> **Módulo:** `westrp_admin` (Extensão da Mesa Central de Comando & Auditoria)  
> **Versão:** 2.0.0  
> **Target:** RedM (CitizenFX RDR3) — CEF / Chromium / Lua 5.4  
> **Status:** Proposta de Arquitetura  

---

## 1. Visão Geral & Objetivos de Engenharia

O **Admin Panel 2.0** expande a Mesa Central de Comando (`/adminpanel`), elevando a experiência operacional da equipe de administração e suporte. A arquitetura mantém rigorosamente a **Regra R3 (Bridge Pattern)**, **0.00ms idle resmon** e conformidade com o mini-framework `westrp_ui`.

### Metas Principais:
1. **Desacoplamento & Multi-Alvo**: Permitir que ações de concessão de itens, armamentos e economia operem tanto sobre o próprio operador (`self`) quanto sobre qualquer jogador conectado (`targetId`).
2. **Inspeção em Tempo Real**: Permitir auditar e moderar o inventário e finanças de um jogador sem exigir comandos de terminal ou reinicialização.
3. **Ergonomia Operacional**: Introduzir filtros rápidos por profissão/estado e aba interna de auditoria sem depender de consulta externa ao Discord.

---

## 2. Anatomia do Painel & Estrutura de Abas (Schema 2.0)

O painel central manterá o canvas modal (`1200px` de largura) com abas reorganizadas por domínio de atuação:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│  WESTRP • CENTRAL ADMINISTRATIVA                          Operador: [ID 1] • Online: 12│
│  MESA DE COMANDO & AUDITORIA AVANÇADA                                                ✕ │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ [JOGADORES] | [ITENS] | [ARMAS] | [MONTARIAS/VEÍCULOS] | [PUNIÇÕES/BANS] | [AUDITORIA] │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ FILTROS RÁPIDOS: [TODOS]  [MORTOS / COMA]  [STAFF]  [POLÍCIA]  [MÉDICOS]               │
│                                                                                        │
│  VIEWPORT DINÂMICA (Grid / Table / Inspector):                                         │
│  ...                                                                                   │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ [RODAPÉ / CONTROLE DE ALVO & EXECUÇÃO]                                                 │
│  ALVO: [ (o) PARA MIM  |  ( ) JOGADOR: [ ID: 3 - John Marston ] ]                      │
│  QUANTIDADE: [ - ] [ 1 ] [ + ]                        [ BOTÃO DE AÇÃO: EXECUTAR ]      │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Especificação Detalhada dos Novos Recursos

### 3.1 Seletor de Destinatário no Spawner (Target Selector)
* **Objetivo:** Alternar entre conceder o item/arma para o próprio administrador ou para um jogador alvo.
* **Mecânica:**
  * O rodapé do painel central inclui um seletor de alvo (`targetMode: "self" | "target"`).
  * Quando o administrador seleciona um jogador na tabela de jogadores e clica em "Gerenciar Itens", o painel alterna para o Spawner já pré-selecionando o jogador alvo.
  * O evento `executeAction` envia `targetId = selectedTargetId` com validação de alcance e autorização no servidor.

### 3.2 Spawner de Armamento & Munições (Weapon Spawner - Vitrine Grid)
* **Objetivo:** Catálogo visual de revólveres, pistolas, rifles, escopetas e armas brancas.
* **Schema do Item:**
  ```lua
  {
      id = "WEAPON_REVOLVER_CATTLEMAN",
      title = "Revólver Cattleman",
      subtitle = "Arma Curta • Calibre .45",
      category = "Revólveres",
      icon = "weapon_revolver_cattleman",
      badge = "ARMA",
      badgeType = "gold"
  }
  ```
* **Fluxo de Concessão:**
  * Invoca `WestRP.Shared.Bridge.Inventory.GiveWeapon(targetId, weaponName)`.
  * Valida no servidor se o jogador já atingiu o limite de armas portadas.

### 3.3 Gestor Financeiro / Econômico (Currency Manager)
* **Objetivo:** Injetar ou retirar Dinheiro (`cash`), Ouro (`gold`) ou Rol (`rol`) de jogadores.
* **Interface:** Modal contextual acionado no perfil do jogador com seletor de moeda, campo de valor numérico e campo de justificativa obrigatório para auditoria.
* **Validação:**
  * Adição: `WestRP.Shared.Bridge.Player.AddMoney(targetId, type, amount)`.
  * Remoção: `WestRP.Shared.Bridge.Player.RemoveMoney(targetId, type, amount)` com validação prévia de saldo disponível.
  * Log estruturado no Discord com autor, alvo, valor e justificativa.

### 3.4 Inspetor de Inventário em Tempo Real (Live Inventory Inspector)
* **Objetivo:** Exibir os itens e armas carregados pelo personagem do jogador selecionado.
* **Endpoint RPC:** `westrp_admin:server:getPlayerInventory(targetId)`
  * Retorna tabela unificada contendo itens (nome, label, quantidade, peso) e armas (nome, número de série).
* **Ações Disponíveis:**
  * `confiscate_item`: Remove uma quantidade específica do item da bolsa do jogador.
  * `confiscate_weapons`: Remove todo o armamento ilegal do personagem.

### 3.5 Gerenciador de Empregos & Cargos (Job & Role Manager)
* **Objetivo:** Alterar a profissão (`job`), patente (`jobGrade`) e permissão (`group`) de forma visual.
* **Endpoints:**
  * `WestRP.Shared.Bridge.Player.SetJob(targetId, job, grade, label)`
  * `WestRP.Shared.Bridge.Player.SetGroup(targetId, group)`
* **Regra de Segurança:** Operadores não podem atribuir cargos (`group`) iguais ou superiores ao seu próprio cargo hierárquico.

### 3.6 Spawner de Montarias e Veículos (Mount & Wagon Spawner)
* **Objetivo:** Catálogo de cavalos de raça e carroças/carruagens para spawn imediato.
* **Categorias:** Cavalos de Trabalho, Cavalos de Guerra, Cavalos de Corrida, Carroças de Carga e Diligências.
* **Mecânica de Spawn:** Invocação client-side com verificação de rota livre, criação de ped/veículo via native e atribuição de sela/arreios.

### 3.7 Aba de Auditoria Interna (Live Audit Logs)
* **Objetivo:** Buffer circular em memória no servidor contendo as últimas 50 ações executadas pela staff.
* **Endpoint RPC:** `westrp_admin:server:getRecentLogs()`
* **Visualização:** Tabela com Horário, Operador, Ação, Alvo e Detalhes.

### 3.8 Filtros Rápidos na Tabela de Jogadores
* **Filtros Disponíveis no Cabeçalho:**
  * `TODOS`: Exibe todos os jogadores conectados.
  * `MORTOS / COMA`: Filtra jogadores onde `isDead == true`.
  * `STAFF`: Filtra jogadores onde `group ~= "user"`.
  * `POLÍCIA`: Filtra jogadores cujo `job` pertence à segurança pública (`sheriff`, `police`, `marshal`).
  * `MÉDICOS`: Filtra médicos em serviço (`medic`, `doctor`).

---

## 4. Matriz de Segurança Zero-Trust & RBAC

Todas as novas rotinas obedecem estritamente à matriz de permissões no `config.lua`:

| Ação | Root (100) | Admin (80) | Moderator (50) | Support (20) |
| :--- | :---: | :---: | :---: | :---: |
| `give_item` (Self) | ✅ | ✅ | ✅ | ❌ |
| `give_item` (Target) | ✅ | ✅ | ✅ | ❌ |
| `give_weapon` | ✅ | ✅ | ❌ | ❌ |
| `give_currency` | ✅ | ✅ | ❌ | ❌ |
| `inspect_inventory` | ✅ | ✅ | ✅ | ✅ |
| `confiscate_item` | ✅ | ✅ | ✅ | ❌ |
| `set_job` | ✅ | ✅ | ❌ | ❌ |
| `set_group` | ✅ | ❌ | ❌ | ❌ |
| `spawn_mount` | ✅ | ✅ | ✅ | ❌ |
| `view_audit_logs` | ✅ | ✅ | ✅ | ❌ |

---

## 5. Critérios de Aceite (Gherkin)

### Cenário 1: Concessão de item com seletor de destinatário
* **Dado** que o operador é um `admin` e abre o Spawner de Itens
* **Quando** seleciona o modo "Para Jogador Alvo" com o ID `2` e confirma a entrega de 5x Maçãs
* **Então** o jogador `2` deve receber os 5 itens em seu inventário
* **E** o operador recebe confirmação Toast na tela
* **E** o log estruturado é registrado na auditoria com operador e alvo identificados.

### Cenário 2: Inspeção e confisco de item
* **Dado** que um moderador clica sobre um jogador suspeito na tabela
* **Quando** seleciona a ação "Inspecionar Inventário"
* **Então** uma lista em tempo real de todos os itens e quantidades daquele jogador é exibida
* **E** ao clicar em "Confiscar", o item é subtraído imediatamente da bolsa do jogador via Bridge.

### Cenário 3: Validação de hierarquia no gestor de cargos
* **Dado** que um administrador com nível `80` tenta promover outro jogador para `root` (`100`)
* **Quando** a requisição atinge o servidor
* **Então** o middleware `Security.CanExecute` rejeita a ação com aviso "Ação não permitida"
* **E** nenhum dado é modificado no banco de dados.
