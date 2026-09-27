# Especificação Arquitetural — WestRP UI Engine (`westrp_ui`)
> **Padrão:** Spec-Driven Development (SDD) & Clean Architecture  
> **Versão:** 2.0.0 (Modular Refactor & Native Layer)  
> **Target:** RedM (CitizenFX RDR3 - Game Build 1491+)  
> **Filosofia:** Resmon 0.00ms idle, Instância Chromium Única, Separação Estrita de Componentes, Consumo Declarativo em Lua.

---

## 1. Visão Geral e Filosofia

O **WestRP UI Engine** é o motor exclusivo e unificado de interface de usuário de todo o ecossistema WestRP.  
Em vez de permitir que cada novo recurso de gameplay (como bancos, lojas, estábulos, inventário ou roubos) suba sua própria janela NUI ou dependa de scripts legados e descontinuados (como `vorp_menu`, `vorp_inputs`, `vorp_progressbar`), o `westrp_ui` centraliza **100% da renderização visual do servidor**.

### 1.1 Os Pilares Arquiteturais
1. **Instância NUI Única (Single Chromium Instance):** Todo o frontend roda em uma única página HTML (`html/index.html`). Não há múltiplos contextos CEF, eliminando o overhead de memória e repaints desnecessários.
2. **Arquitetura Híbrida (NUI + Native DataBinding):**
   * **Telas Ricas e Interativas:** Renderizadas no NUI (Dock Lateral, Panel Central, Diálogos de Entrada, Menus Radiais).
   * **HUDs de Jogo Leves e Reativos:** Renderizados diretamente pelo motor C++/Scaleform do RDR2 via **DataBinding** com **0.00ms de resmon** (Barra de Honra/Karma, Timers de Missão, Dinheiro na Carteira, Nível/XP).
3. **Frontend Modular (Adeus Monólitos de 80 KB):** CSS e JavaScript são quebrados em componentes isolados com responsabilidade única (`variables.css`, `dock.js`, `dialog.js`, etc.), tornando a manutenção previsível e fácil.
4. **Developer Experience (DX) Declarativa:** Desenvolvedores de outros recursos de gameplay **nunca escrevem HTML/CSS/JS**. Eles apenas chamam funções declarativas em Lua via SDK (`WestRP.Client.UI.*`).

---

## 2. Mapa Geral de Camadas

```
┌────────────────────────────────────────────────────────────────────────┐
│                        WESTRP UI ENGINE (v2.0)                         │
├──────────────────────────────────┬─────────────────────────────────────┤
│      CAMADA NUI (Chromium Único) │ CAMADA NATIVA (DataBinding 0.00ms)  │
├──────────────────────────────────┼─────────────────────────────────────┤
│ • Dialog / Input Modal (ex-vorp) │ • Honor / Karma Bar (westrp_karma)  │
│ • Dock Lateral (350px / Câmera)  │ • Top-Center Timer (Assaltos/Duelo) │
│ • Panel Central (1000px / Mouse) │ • Dinheiro & Recompensa (Tithing)   │
│ • Toast Notifications            │ • Rank & XP Progression Bar         │
│ • Action Progress Bar            │ • Wanted / Law Status               │
│ • Menu Radial (Quick Actions)    │                                     │
└──────────────────────────────────┴─────────────────────────────────────┘
```

---

## 3. A Camada de Entrada de Dados (O Substituto do `vorp_inputs`)

### 3.1 O Problema do `vorp_inputs` Legado
O script legado `vorp_inputs`:
* Abria um Chromium isolado e custoso.
* Apresentava visual cinza sem harmonia com o RDR2.
* Não oferecia máscaras, validações de mínimo/máximo, selects nem tipos variados.

### 3.2 O Padrão `WestRP.Client.UI.PromptInput`
O `westrp_ui` incorpora um modal de diálogo especializado para coleta de dados do jogador.

#### Tipos Suportados:
* `currency`: Entrada monetária com prefixo `$`, formatação automática de centavos, mínimo e máximo.
* `number`: Quantidade inteira com botões rápidos de incremento/decremento (`+`, `-`, `MÁX`).
* `text`: Linha de texto simples (ex: nome de personagem, nome de cavalo).
* `textarea`: Bloco de texto com limite de caracteres (ex: cartas, telegramas, boletim de ocorrência).
* `select`: Menu suspenso estilizado (ex: escolher qual cavalo resgatar no estábulo).
* `confirm`: Modal simples de Confirmação com título, mensagem de alerta e botões `[CONFIRMAR]` e `[CANCELAR]`.

#### Exemplo de Chamada no Lua:
```lua
-- Coleta de quantidade para venda/depósito
WestRP.Client.UI.PromptInput({
    title = "DEPÓSITO BANCÁRIO",
    description = "Digite o valor que deseja depositar no cofre:",
    type = "currency",
    min = 0.50,
    max = 2500.00,
    placeholder = "0.00"
}, function(amount)
    if amount and amount > 0 then
        TriggerServerEvent("westrp_banking:deposit", amount)
    end
end)
```

---

## 4. O Catálogo de Componentes NUI

### 4.1 Módulo A: Dock Lateral (350px / Câmera Livre)
Inspirado nos menus de loja e estábulo da Rockstar. O jogador mantém visão do cenário 3D e navega exclusivamente pelo teclado ou gamepad.
* **Largura:** Fixa em 350px (alinhado à esquerda ou à direita).
* **Navegação:** `[W]/[S]` ou `[↑]/[↓]` navega; `[A]/[D]` ajusta opções; `[ENTER]` seleciona; `[BACKSPACE]` volta/fecha.
* **Controles por Item:** `action` (com badge de preço dourado), `slider` (numérico ou textual), `toggle` (interruptor liga/desliga), `submenu` (gaveta secundária).
* **Controle de Teclas (`KeepInput`):** Desabilita tiros, socos e pulos (`DisableControlAction`) mantendo rotação livre de câmera e movimento contido.

### 4.2 Módulo B: Panel Central (1000px / Cursor Livre)
Área de trabalho ampla para tarefas de alta densidade de dados com interação via mouse.
* **Desfoque 3D Automático:** O cenário é suavemente desfocado com `AnimpostfxPlay('OJDominoBlur')` nativo.
* **Visões Estruturadas (`view`):**
  * `grid`: Vitrine de itens e inventário com slots, contagem, raridade e peso.
  * `craft`: Bancada de receitas de manufatura com lista de ingredientes requeridos.
  * `table`: Livro-razão e relatórios contábeis com paginação e busca rápida.
  * `dashboard`: Cockpit de gestão (facções, negócios) com estatísticas e botões de ação.

### 4.3 Módulo C: Action Progress Bar
Substituto oficial do `vorp_progressbar`.
* Exibição de barra horizontal ou circular centralizada na parte inferior da tela.
* Suporte a texto de ação (ex: *"Esfolando animal..."*, *"Arrombando fechadura..."*).
* Interrupção inteligente: se o jogador sofrer dano, pular ou pressionar tecla de cancelamento configurada, a barra é abortada e a callback retorna `false`.

### 4.4 Módulo D: Toasts & Notificações
Mensagens informativas no canto da tela com ícones temáticos e tempo de vida automático.
* Categorias: `success` (dourado/verde), `error` (vermelho sangue), `info` (couro claro), `warning` (âmbar).

### 4.5 Módulo E: Menu Radial (Quick Actions Wheel)
Roda de ações rápida de 8 a 12 slots, ativada por tecla de atalho (`RegisterKeyMapping`), ideal para ações de cavalos, algemas, bolsas e interações de proximidade.

---

## 5. A Camada de HUD Nativo (RDR2 Scaleform/DataBinding)

O arquivo `client/native_hud.lua` fornece funções utilitárias que manipulam a UI interna do RDR2 sem tocar no Chromium:

| Função SDK | Native DataBinding | Caso de Uso |
| :--- | :--- | :--- |
| `WestRP.Client.UI.NativeHUD.SetHonor(val, dur, min, max)` | `RPGStatusIcons / HonorIcon` (1 a 16) | Conexão dinâmica com `westrp_karma` (mapeia qualquer escala para 1..16). |
| `WestRP.Client.UI.NativeHUD.AnimateHonor(from, to, step, hold, min, max)` | Animação suave com interpolação de frames | Feedback visual de ganho/perda de honra. |
| `WestRP.Client.UI.NativeHUD.ConfigureHonorScale(min, max, dur)` | Configuração em runtime da escala global | Permite que o framework defina sua própria amplitude moral. |
| `WestRP.Client.UI.NativeHUD.StartTimer(sec, alertSec)` | `centralInfoDatastore / timerString` | Roubos, duelos, contagem de missões. |
| `WestRP.Client.UI.NativeHUD.StopTimer()` | Destrói a máquina de estado do timer. | Cancelamento de roubo/evento. |
| `WestRP.Client.UI.NativeHUD.ShowCash(player, camp)` | `Tithing / PlayerCash / CampFunds` | Exibição de saldo na carteira. |
| `WestRP.Client.UI.NativeHUD.SetRank(name, rank, xpPct)` | `mp_rank_bar / xp_bar_value` | Evolução de profissão e passe de temporada. |
| `WestRP.Client.UI.NativeHUD.SetWanted(wanted, bounty)` | `wanted / BountyCash` | Sistema de procurado e xerifado. |

---

## 6. Estrutura Modular de Pastas e Arquivos

Adeus ao arquivo único de 87 KB de JS e 64 KB de CSS. A estrutura será rigidamente modular:

```
westrp_ui/
├── fxmanifest.lua
├── README.md                          <-- Guia de bolso para o desenvolvedor
├── docs/
│   ├── ARCHITECTURE.md                <-- Este documento
│   ├── DESIGN_SYSTEM.md               <-- Tokens de cor, tipografia e regras visuais
│   └── PLAN_REFACTOR.md               <-- Roteiro de transição da base antiga
├── client/
│   ├── main.lua                       <-- Despachante NUI e controle de janelas
│   ├── keep_input.lua                 <-- Controle fino de teclas (câmera livre)
│   ├── native_hud.lua                 <-- Wrappers DataBinding (0.00ms)
│   └── keybinds.lua                   <-- Registro oficial de KeyMappings
└── html/
    ├── index.html                     <-- Estrutura esqueleto limpa
    ├── css/
    │   ├── variables.css              <-- Tokens: cores, fontes, sombras, raios
    │   ├── base.css                   <-- Resets, layout mestre, animações globais
    │   ├── dock.css                   <-- Estilos exclusivos do Dock Lateral
    │   ├── panel.css                  <-- Estilos exclusivos do Panel Central
    │   ├── dialog.css                 <-- Estilos de InputDialog / Confirm
    │   ├── progress.css               <-- Estilos da Barra de Progresso de Ação
    │   ├── toast.css                  <-- Estilos das Notificações
    │   └── radial.css                 <-- Estilos do Menu Radial
    └── js/
        ├── audio.js                   <-- WebAudio procedural (cliques e bips)
        ├── components/
        │   ├── dock.js                <-- Máquina de estado do Dock Lateral
        │   ├── panel.js               <-- Máquina de estado do Panel Central
        │   ├── dialog.js              <-- Controle do Input / Form Dialog
        │   ├── progress.js            <-- Temporizador suave da ProgressBar
        │   ├── toast.js               <-- Gerenciador de fila de Toasts
        │   └── radial.js              <-- Roda de ações radial
        └── app.js                     <-- Roteador de NUI messages (~60 linhas)
```

---

## 7. Diretrizes de Consumo para Novos Resources

1. **Nunca duplique HTML/CSS em resources secundários:** Se você estiver criando `westrp_stores` ou `westrp_stables`, utilize exclusivamente os componentes do `westrp_ui`.
2. **Utilize o SDK Local:** Inclua `'@westrp_core/init.lua'` no `fxmanifest.lua` e invoque `WestRP.Client.UI.*`.
3. **Mantenha os payloads leves:** Envie apenas identificadores e dados visíveis para a tela; a lógica de negócio pesada e segurança pertencem ao servidor.
