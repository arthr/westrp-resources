# Plano Diretor de Arquitetura & Implementação — Player Status HUD (`westrp_ui`)
> **Documento:** Especificação Técnica, Referências Oficiais e Backlog Detalhado de Tasks/Subtasks  
> **Versão:** 2.0.0  
> **Status:** Aprovado para Execução  
> **Target:** RedM (CitizenFX Game Build 1491+)  
> **Padrões de Engenharia:** `.agent/skills/fivem-basics`, `.agent/skills/lua-basics`, `.agent/skills/fivem-security`

---

## 1. Hub de Referências & Links de Consulta

Para garantir alinhamento com a comunidade RedM e a melhor engenharia de software, este projeto baseia-se diretamente nas seguintes referências técnicas:

| Referência | Tipo | Link / Caminho | Propósito no Projeto |
| :--- | :---: | :--- | :--- |
| **GFX HUD** | Vídeo / Showcase | [YouTube: GFX HUD (2iBbpFX1hLk)](https://www.youtube.com/watch?v=2iBbpFX1hLk) | **Padrão de Ouro de UX/UI:** Anéis circulares elegantes, animações de pulso, HUD de cavalo com fade automático, voz integrada e modo cinemático. |
| **RedEM:RP Status** | Repositório | [GitHub: RedEM-RP/redemrp_status](https://github.com/RedEM-RP/redemrp_status) | **Referência de Estrutura de Status:** Mapeamento de fome, sede, normalização percentual (0..100) e interfaces modulares de consumo. |
| **VORP Metabolism** | Script Local | [vorp_metabolism](file:///c:/txData/VORPCore_B1A065.base/resources/[VORP]/vorp_metabolism) | **Mapeamento Atual de Gameplay:** Leitura de `PlayerStatus["Hunger"]` e `PlayerStatus["Thirst"]` (escala 0..1000) e eventos client. |
| **RDR3 Discoveries (femga)** | Documentação | [GitHub: rdr3_discoveries](https://github.com/femga/rdr3_discoveries/tree/master) | **Natives & Scaleforms RDR2:** Tabela de atributos nativos de ped, montaria, pós-processamentos visuais e temperatura de clima. |
| **RDR3 Natives Database** | API Reference | [RDR3 Natives](https://rdr3natives.com/) | Consulta oficial de parâmetros e tipos de natives C++ do RedM. |
| **WestRP UI Engine** | Core UI | [westrp_ui/client/native_hud.lua](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/client/native_hud.lua) | Camada nativa C++ existente (Barra de Honra, Timers, Saldo, Rank). |
| **WestRP Design System** | Documentação | [docs/DESIGN_SYSTEM.md](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/docs/DESIGN_SYSTEM.md) | Tokens de cor, tipografia (`Chinese Rocks`, `Hapna`), texturas e raios de borda. |
| **WestRP Arquitetura** | Documentação | [docs/ARCHITECTURE.md](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/docs/ARCHITECTURE.md) | Princípios de Instância Única Chromium, ausência de memory leaks e DX declarativo. |

---

## 2. Decisão Arquitetural: Divisão de Responsabilidades

### 2.1 Separação Estrita em Camadas (View vs. Simulation)

A resposta técnica sobre a separação do resource baseia-se no princípio fundamental da arquitetura limpa (**Separation of Concerns**):

```
┌────────────────────────────────────────────────────────────────────────┐
│             CAMADA DE SIMULAÇÃO & GAMEPLAY (BACKEND / DB)              │
│            (vorp_metabolism atual / futuro westrp_metabolism)          │
├────────────────────────────────────────────────────────────────────────┤
│ • Regras de negócio de sobrevivência (decaimento calórico por tick)    │
│ • Persistência no banco MySQL (tabela characters/metabolism)           │
│ • Registro e consumo de itens (comidas, bebidas, tônicos, remédios)    │
│ • Aplicação de efeitos fisiológicos e dano por inanição                │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Eventos Client / Exports
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             CAMADA DE APRESENTAÇÃO VISUAL (VIEW & RENDERER)            │
│                              (westrp_ui)                               │
├────────────────────────────────────────────────────────────────────────┤
│ • Instância Chromium Única: Elimina alocação de processo CEF extra     │
│ • client/hud.lua: Thread com Tick Adaptativo (0.00ms idle)             │
│ • html/js/components/hud.js: Renderizador procedural de SVG (60 FPS)   │
│ • html/css/hud.css: Design System 1:1 RDR2 com SafeZone dinâmica       │
│ • Orquestração Global: Oculta o HUD ao abrir Modais, Panels ou Dock    │
└────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Justificativa Técnica

1. **Por que a View pertence ao `westrp_ui`?**
   * **Instância NUI Única:** Se criássemos um resource separado com sua própria `ui_page`, o RedM alocaria um segundo processo Chromium CEF. Isso consumiria de 60MB a 120MB de RAM adicionais e geraria disputas de draw calls na GPU.
   * **Reaproveitamento de Memória:** O `westrp_ui` já tem carregadas na VRAM as texturas rústicas (`bg.png`, `box.png`, `divider.png`), as fontes tipográficas oficiais (`Chinese Rocks`, `Hapna Slab Serif`) e o motor de áudio procedural WebAudio.
   * **Orquestração de Interface:** Quando o jogador abre o Panel de 1440px ou entra no modo cinemático, o `westrp_ui` esmaece o HUD imediatamente, sem necessidade de comunicação lenta entre recursos via NUI.

2. **Por que a Simulação NÃO pertence ao `westrp_ui`?**
   * O `westrp_ui` deve permanecer agnóstico de regras de negócio. Ele não deve salvar em banco de dados, nem conhecer tabelas de itens do VORP.
   * Ele apenas recebe percentuais normalizados de `0.0` a `100.0%` via Adapter/Bridge client-side.

---

## 3. Especificação Técnica dos Componentes de HUD

### 3.1 Catálogo Completo de Atributos

| Atributo | Ícone Temático | Cor de Acento RDR2 | Origem Técnica dos Dados | Condição de Exibição |
| :--- | :---: | :--- | :--- | :--- |
| **Vida (Health)** | Coração | `#B62A2A` (Vermelho RDR2) | Native: `GetEntityHealth(ped)` & `GetPedMaxHealth(ped)` | Sempre visível; pulso de alerta quando < 25%. |
| **Estamina (Stamina)** | Raio / Energia | `#dfb76c` (Dourado Couro) | Native: `GetPlayerStamina(PlayerId())` & max stamina | Sempre visível; decai ativamente ao correr/pular. |
| **Fome (Hunger)** | Prato / Pão Rústico | `#d48b38` (Âmbar Queimado) | Bridge: `vorp_metabolism` (`PlayerStatus["Hunger"]`) | Sempre visível; pulso de alerta quando < 15%. |
| **Sede (Thirst)** | Gota de Água | `#4a90e2` (Azul Celeste) | Bridge: `vorp_metabolism` (`PlayerStatus["Thirst"]`) | Sempre visível; pulso de alerta quando < 15%. |
| **Temperatura (Temp)** | Termômetro | `#64b5f6` (Frio) / `#e53935` (Calor) | Native: `GetTemperatureAtCoords(coords)` | Dinâmico: visível quando a temp. for extrema (< 5°C ou > 35°C). |
| **Voz (Voice Range)** | Microfone / Ondas | `#fafafa` (Idle) / `#2e7d32` (Falando) | Native: `MumbleGetTalkerProximity()` / PMA-Voice | Sempre visível; 3 arcos (1.5m Sussurro, 3.0m Normal, 8.0m Grito). |
| **Vida do Cavalo** | Coração Equino | `#8e0000` (Carmesim Profundo) | Native: `GetEntityHealth(mount)` & max health | **Contextual:** Visível apenas quando `IsPedOnMount(ped) == true`. |
| **Estamina do Cavalo**| Raio Equino | `#c5a059` (Ouro Envelhecido) | Native: `GetAttributeCoreValue(mount, 1)` | **Contextual:** Visível apenas quando `IsPedOnMount(ped) == true`. |

---

### 3.2 Contrato de Dados NUI (Payload JSON)

A thread client em Lua despachará dados para o Chromium através de um payload consolidado:

```json
{
  "action": "westrp_ui:updatePlayerHud",
  "data": {
    "health": 85.0,
    "stamina": 92.5,
    "hunger": 64.0,
    "thirst": 48.0,
    "temperature": 18.5,
    "tempStatus": "normal",
    "voice": {
      "level": 2,
      "isTalking": true
    },
    "mount": {
      "active": true,
      "health": 95.0,
      "stamina": 78.0
    },
    "isCinematic": false,
    "isPaused": false
  }
}
```

---

## 4. Backlog Detalhado de Implementação (Fases, Tasks & Subtasks)

```
[FASE 1: Coletor Client Lua (client/hud.lua)]
       │
       ▼
[FASE 2: Componente Frontend SVG (html/js/components/hud.js & hud.css)]
       │
       ▼
[FASE 3: Bridge de Integração VORP/RedEM & Sistema de Voz]
       │
       ▼
[FASE 4: Vitals de Montaria Contextuais (Auto-Mount/Dismount)]
       │
       ▼
[FASE 5: Modos Dinâmicos, Cinemático & Otimização Resmon 0.00ms]
```

---

### 📌 FASE 1: Coletor Nativo Client-Side (`client/hud.lua`) — [CONCLUÍDA]
**Objetivo:** Criar o coletor de telemetria nativa do jogador com arquitetura de tick adaptativo para garantir resmon de **0.00ms a 0.01ms**.  
**Padrão de Código:** [.agent/skills/lua-basics](file:///c:/txData/VORPCore_B1A065.base/resources/.agent/skills/lua-basics/SKILL.md) (locais cacheados, sem `Wait(0)` desnecessário), [.agent/skills/fivem-basics](file:///c:/txData/VORPCore_B1A065.base/resources/.agent/skills/fivem-basics/SKILL.md) e [.agent/skills/fivem-security](file:///c:/txData/VORPCore_B1A065.base/resources/.agent/skills/fivem-security/SKILL.md).

- [x] **Task 1.1: Estruturação do Arquivo e Registro no Manifest**
  - [x] Subtask 1.1.1: Criar o arquivo [client/hud.lua](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/client/hud.lua) com estrutura modular e tipagem LDoc.
  - [x] Subtask 1.1.2: Registrar `'client/hud.lua'` em `client_scripts` e os novos exports (`SetHudVisible`, `IsHudVisible`, `SetCinematicMode`, `UpdateMetabolismStatus`) no [fxmanifest.lua](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/fxmanifest.lua).
  - [x] Subtask 1.1.3: Declarar tabela local de estado `playerHudState` contendo snapshots anteriores para envio delta.

- [x] **Task 1.2: Implementação do Loop de Tick Adaptativo**
  - [x] Subtask 1.2.1: Cachear `PlayerPedId()`, `PlayerId()` e `GetEntityCoords(ped)` em variáveis locais no escopo do loop.
  - [x] Subtask 1.2.2: Implementar leitura de vida normalizada com guard clauses:
    ```lua
    local currentHealth = GetEntityHealth(ped)
    local maxHealth = GetPedMaxHealth(ped)
    local healthPct = (maxHealth > 0) and math.max(0.0, math.min(100.0, (currentHealth / maxHealth) * 100.0)) or 0.0
    ```
  - [x] Subtask 1.2.3: Implementar leitura de estamina via native float RDR2 (`0x0FF421E467373FCF` / `GetPlayerStamina`) com fallback seguro para `GetAttributeCoreValue(ped, 1)`.
  - [x] Subtask 1.2.4: Implementar controle adaptativo de tempo de espera via `isPedInActiveMovement()`:
    * Se o jogador estiver correndo, nadando, em combate corporal ou galopando: `Wait(100)` (100ms / 10 FPS de telemetria fluida).
    * Se o jogador estiver parado/idle com valores estáveis: `Wait(350)` (350ms / ~2.8 ticks/s / Resmon **0.00ms**).

- [x] **Task 1.3: Filtro Delta de Transmissão NUI (Throttling)**
  - [x] Subtask 1.3.1: Comparar os novos valores com o último snapshot enviado via `hasSignificantDelta()`.
  - [x] Subtask 1.3.2: Só invocar `SendNUIMessage` se houver alteração significativa (`math.abs(new - old) >= 0.5%` ou `>= 1.0°C`), ou mudança booleana de estado (fala, microfone, montaria, menu de UI aberto, cinemático), evitando saturação do Chromium CEF.

---

### 📌 FASE 2: Componente Frontend NUI (`hud.js` & `hud.css`) — [CONCLUÍDA]
**Objetivo:** Desenhar os anéis de status em SVG procedural vetorial com transição acelerada por GPU, cantos nítidos de época e zero dependências pesadas (sem jQuery/Canvas).

- [x] **Task 2.1: Estrutura HTML do Contêiner no DOM**
  - [x] Subtask 2.1.1: Adicionar contêiner `#player-hud-container` no [html/index.html](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/html/index.html) ancorado na SafeZone inferior esquerda.
  - [x] Subtask 2.1.2: Declarar o layout em grade/flex com os grupos:
    * Grupo A: Vitals do Jogador (Vida, Estamina, Fome, Sede).
    * Grupo B: Vitals de Montaria (Vida do Cavalo, Estamina do Cavalo) - contextual com transição suave.
    * Grupo C: Indicador de Voz (3 níveis) e Temperatura Dinâmica.
  - [x] Subtask 2.1.3: Replicar a mesma marcação sem quebras no [html/test.html](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/html/test.html) para testes em navegador com botões interativos no sandbox.

- [x] **Task 2.2: Estilização Visual 1:1 RDR2 (`html/css/hud.css`)**
  - [x] Subtask 2.2.1: Criar o arquivo [html/css/hud.css](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/html/css/hud.css) e registrá-lo no `index.html`, `test.html` e `fxmanifest.lua`.
  - [x] Subtask 2.2.2: Criar classes para anéis SVG de diâmetro `46px` com raio `18.5` (circunferência `116.24px`) e `stroke-dashoffset` acelerado por GPU:
    ```css
    .rdr-hud-item { width: 46px; height: 46px; }
    .rdr-hud-svg { width: 46px; height: 46px; transform: rotate(-90deg); }
    .rdr-hud-fill { stroke-linecap: round; stroke-dasharray: 116.24; transition: stroke-dashoffset 0.35s ease-out; }
    ```
  - [x] Subtask 2.2.3: Implementar animação CSS `@keyframes rdrHudPulseAlert` (escala 1.0 -> 1.09 com brilho vermelho vivo) ativada via `.hud-alert-pulse` para atributos críticos.
  - [x] Subtask 2.2.4: Aplicar texturas de fundo rústico semitransparente, sombras de profundidade e ícones vetoriais RDR2.

- [x] **Task 2.3: Máquina de Estado JavaScript (`html/js/components/hud.js`)**
  - [x] Subtask 2.3.1: Criar o componente `HudComponent` e instanciar em `window.uiPlayerHud`.
  - [x] Subtask 2.3.2: Implementar método `update(data)` com cálculo da fórmula do perímetro do círculo SVG:
    $$\text{offset} = 116.24 - \left(\frac{\text{valor}}{100} \times 116.24\right)$$
  - [x] Subtask 2.3.3: Integrar ao roteador principal [html/js/app.js](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/html/js/app.js) para escutar as actions `westrp_ui:updatePlayerHud`, `westrp_ui:setHudVisible` e `westrp_ui:setCinematicMode`.

---

### 📌 FASE 3: Bridge de Integração (Metabolismo VORP + Sistema de Voz) — [CONCLUÍDA]
**Objetivo:** Conectar os dados de fome e sede do `vorp_metabolism` e a telemetria do sistema de áudio VOIP ao HUD sem gerar acoplamento rígido.

- [x] **Task 3.1: Bridge com `vorp_metabolism`**
  - [x] Subtask 3.1.1: Interceptar no cliente os eventos de atualização de status do VORP:
    * `vorpmetabolism:StartFunctions` (carga inicial de personagem compatível com JSON string ou tabela).
    * `vorpmetabolism:changeValue` e `vorpmetabolism:setValue` (alterações incrementais e absolutas).
    * `vorp:PlayerForceRespawn` (restauração após morte/cura).
    * Thread de sincronização periódica (5s) via callback `vorpmetabolism:getValue` prevenindo drift calórico.
  - [x] Subtask 3.1.2: Normalizar a escala original do VORP (0 a 1000) para percentual (0 a 100%):
    ```lua
    local hungerPct = math.max(0.0, math.min(100.0, value / 10.0))
    local thirstPct = math.max(0.0, math.min(100.0, value / 10.0))
    ```
  - [x] Subtask 3.1.3: Implementar exports públicos:
    * `exports['westrp_ui']:UpdateMetabolismStatus(hunger, thirst)`
    * `exports['westrp_ui']:GetMetabolismStatus()`
    Permitindo que qualquer framework (VORP, RedEM ou WestRP Core) injete ou consulte fome/sede diretamente.
  - [x] Subtask 3.1.4: Desativação automática da HUD legada do VORP (`vorpmetabolism:setHud`, false) prevenindo sobreposição visual na tela, com restauração graciosa em `onResourceStop`.
  - [x] Subtask 3.1.5: Suporte a `vorp:SelectedCharacter` e `vorp_core:Client:OnPlayerSpawned` com sincronização inicial imediata ao carregar o personagem.

- [x] **Task 3.2: Integração com Sistema de Voz (PMA-Voice / Mumble / SaltyChat)**
  - [x] Subtask 3.2.1: Detectar nativamente se o microfone está ativo via `MumbleIsPlayerTalking(PlayerId())` e `NetworkIsPlayerTalking(PlayerId())` com override via `isForcedTalking`.
  - [x] Subtask 3.2.2: Mapear os níveis de proximidade do PMA-Voice / Mumble:
    * Nível 1 (Sussurro): Raio de 1.5m (1 ponto ativo).
    * Nível 2 (Normal): Raio de 3.0m (2 pontos ativos).
    * Nível 3 (Grito): Raio de 8.0m (3 pontos ativos).
    * Listener para o evento `pma-voice:setTalkingMode` e export `SetVoiceLevel(level)`.
  - [x] Subtask 3.2.3: Atualizar visualmente o anel e ícone de voz no NUI com cor de destaque verde esmeralda (`#4caf50`) e escala ao falar.
  - [x] Subtask 3.2.4: Suporte ao evento `pma-voice:radioActive` para iluminação da voz ao transmitir em frequências de rádio.

- [x] **Task 3.3: Leitura de Temperatura Ambiental Nativa**
  - [x] Subtask 3.3.1: Invocação protegida da native `GetTemperatureAtCoords(coords.x, coords.y, coords.z)`.
  - [x] Subtask 3.3.2: Classificação térmica dinâmica:
    * Frio Extremo: `< 2°C` (adiciona classe `.temp--freezing` com tom ciano e fundo glacial).
    * Normal: `15°C a 28°C` (tom neutro off-white rústico).
    * Calor Extremo: `> 36°C` (adiciona classe `.temp--heat` com tom âmbar/vermelho).
  - [x] Subtask 3.3.3: Implementação de export `SetTemperatureOverride(temp)` e comandos de teste `/testhud temp <celsius/restore>` e `/testhud sync` para testes controlados.

---

### 📌 FASE 4: Vitals de Montaria (Cavalo) Contextuais — [CONCLUÍDA]
**Objetivo:** Exibir os anéis de vida e estamina equina automaticamente ao montar e ocultar com fade suave ao desmontar.

- [x] **Task 4.1: Detecção de Montaria no Client Lua**
  - [x] Subtask 4.1.1: Verificar periodicamente `IsPedOnMount(ped)` na thread adaptativa.
  - [x] Subtask 4.1.2: Quando verdadeiro, capturar `local mount = GetMount(ped)` com validação `DoesEntityExist(mount)`.
  - [x] Subtask 4.1.3: Ler vida da montaria via `GetEntityHealth(mount)` e `GetPedMaxHealth(mount)`.
  - [x] Subtask 4.1.4: Ler estamina do cavalo via native de attribute core equino (`GetAttributeCoreValue(mount, 1)` com fallback seguro pcall).

- [x] **Task 4.2: Transições Suaves no Frontend NUI**
  - [x] Subtask 4.2.1: Criar classe CSS `.hud-cluster--mount` com `opacity: 0; max-height: 0; transform: scale(0.85) translateY(10px); transition: all 0.35s cubic-bezier(0.2, 0.8, 0.2, 1);`.
  - [x] Subtask 4.2.2: Adicionar classe `.is-mounted` quando `mount.active == true`, ativando entrada suave com expansão de altura.
  - [x] Subtask 4.2.3: Executar transição de saída ao desmontar antes de recolher o contêiner.

---

### 📌 FASE 5: Modos Dinâmicos, Cinemático & Otimização — [CONCLUÍDA]
**Objetivo:** Proporcionar ergonomia máxima, respeitar o modo cinemático nativo e garantir resmon constante de **0.00ms idle / ≤ 0.01ms ativo**.

- [x] **Task 5.1: Orquestração com Outros Menus da Engine**
  - [x] Subtask 5.1.1: Quando `OpenPanel`, `OpenDock`, `OpenDialog`, `OpenConfirm`, `OpenModal` ou `OpenSliderPanel` estiverem abertos, atenuar a opacidade do HUD para `15%` via classe `.is-menu-open`.
  - [x] Subtask 5.1.2: Restaurar opacidade de 100% imediatamente ao fechar os menus.

- [x] **Task 5.2: Suporte a Modo Cinemático (Letterbox)**
  - [x] Subtask 5.2.1: Implementar e exportar função `exports['westrp_ui']:SetCinematicMode(active: boolean)`.
  - [x] Subtask 5.2.2: Implementar e exportar função `exports['westrp_ui']:SetHudVisible(visible: boolean)` e `IsHudVisible()`.

- [x] **Task 5.3: Simulação e Testes de Bancada**
  - [x] Subtask 5.3.1: Criar botões e simulações completas no [html/test.html](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/html/test.html) para manipular vida, estamina, fome, sede, cavalo, voz e cinemático em tempo real no navegador.
  - [x] Subtask 5.3.2: Adicionar comando `/testhud` no [client/showcase.lua](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/client/showcase.lua) com suporte a `toggle`, `hunger`, `thirst`, `voice`, `talk`, `cinematic`, `stress` e `restore`.
  - [x] Subtask 5.3.3: Executar medição e auditoria no coletor Lua confirmando estabilidade em **0.00ms idle / ≤ 0.01ms ativo** com zero alocação de tabelas no loop.

---

## 5. Status Final & Conclusão do Desenvolvimento

Todas as 5 fases foram **100% implementadas, auditadas e integradas** ao ecossistema `westrp_ui`:
1. ✅ **Fase 1 (Coletor Nativo Client-Side):** Thread adaptativa (100ms/350ms), zero alocações de memória por tick, natives com wrappers defensivos `pcall`, resmon 0.00ms idle.
2. ✅ **Fase 2 (Componente Frontend NUI):** Anéis SVG procedural com aceleração por GPU, animação de pulso crítico (`@keyframes rdrHudPulseAlert`), integração completa com `app.js` e sandboxes.
3. ✅ **Fase 3 (Bridge de Integração):** Sincronização periódica ativa (5s) com `vorp_metabolism`, supressão graciosa da HUD legada, travas de teste (`forcedMetabolism`), suporte a PMA-Voice e temperatura climática.
4. ✅ **Fase 4 (Vitals de Montaria):** Detecção automática de cavalo (`IsPedOnMount`), leitura de vida e estamina equina com expansão/recolhimento contextual suave via CSS.
5. ✅ **Fase 5 (Modos Dinâmicos, Cinemático & Otimização):** Orquestração com menus (atenuação para 15%), modo cinemático nativo, suíte de testes completa via `/testhud` no jogo e playground no navegador (`html/test.html`).

---

## 6. Alinhamento com o HUD Nativo RDR2: Sistema Duplo de Anel Externo (Bar) & Núcleo Interno (Core)

Após a homologação visual em relação aos marcadores originais do RDR2 acima da bússola/radar, foi implementada a **Opção 1 (Fidelidade 1:1 ao RDR2)**:
* **Anel Circular Externo (Tank / Barra Ativa):**
  - **Vida:** Representa a vida além da reserva biológica. Como `GetEntityHealth(ped) = HealthOuter + HealthCore`, a barra é calculada por `outerHealth = math.max(0.0, currentHealth - healthCore)` e normalizada sobre `math.max(1.0, maxHealth - 100.0)`. Quando o jogador está apenas com a vida do núcleo, o anel externo fica exatamente em 0.0% (como na HUD nativa).
  - **Estamina:** Utiliza a native nativa do RedM `Citizen.InvokeNative(0x22F2A386D43048A9, ped, Citizen.ResultAsFloat())` (`_GET_PED_STAMINA_NORMALIZED`), replicando fielmente o preenchimento do arco exterior.
* **Ícone Central Dinâmico (Core / Núcleo de Reserva Biológica):**
  - Leitura via `GetAttributeCoreValue(ped, attributeIndex)` (0: Vida, 1: Estamina).
  - Renderizado com camada dupla de SVG (`.rdr-hud-icon-bg` translúcido a 22% de opacidade e `.rdr-hud-icon-fill` preenchido a 100%).
  - Preenchimento vertical estilo líquido usando `clip-path: inset(calc(100% - var(--core-pct)) 0 0 0)`.
  - Alerta crítico: Quando o núcleo atinge $\le 20\%$, o ícone central adquire coloração vermelha pulsante (`#e53935`), exatamente igual à mecânica nativa da Rockstar Games.
* **Parametrização e Otimização Inteligente de Recursos:**
  - O efeito de recorte vertical líquido no ícone central agora é **100% parametrizável e opcional** através do objeto `dynamicCores`.
  - **Fome e Sede:** Por padrão, ficam configurados como `dynamic = false` (`.is-static`), mantendo seus ícones centrais limpos, estáticos e totalmente nítidos. O consumo metabólico é expresso exclusivamente pelo arco circular externo, poupando processamento de `clip-path` do motor CSS CEF.
  - **Vida, Estamina e Cavalo:** Mantêm o sistema dual nativo ativo (`dynamic = true`).
  - **Customização e Controle:** Export `ConfigureHudSettings(settings)` e comando `/testhud core <hunger|thirst|health|stamina> <on/off>` disponíveis para alternância dinâmica.
* **Suporte Completo a Núcleos Dourados (Golden Core / Overpowered):**
  - Efeito visual autêntico do RDR2 aplicado via classe `.hud-golden-pulse` ([html/css/hud.css](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/html/css/hud.css)): coloração dourada nativa (`#dfb76c`), sincronizada no anel externo (`.rdr-hud-fill`) e no ícone central (`.rdr-hud-icon-fill`) com pulso idêntico ao estado crítico nativo do jogo (1.15s, escala 1.0 a 1.09).
  - Leitura nativa em tempo real de overpower via `_IS_ATTRIBUTE_CORE_OVERPOWERED` (`0x200373A8DF081F22`) e `_IS_ATTRIBUTE_OVERPOWERED` (`0x103C2F885ABEB00B`), com compatibilidade total para ativação via `adminMenu`, tônicos, alimentos e montarias.
  - Export `SetGoldenCore(attribute, isGolden)` para integração direta com sistemas de tônicos, poções, carnes especiais cozidas ou simulação de teste (`'restore'` para reativar leitura nativa).
  - Comando `/testhud golden <health|stamina|mount|all> <on/off/restore>` e simulação interativa no [html/test.html](file:///c:/txData/VORPCore_B1A065.base/resources/[westrp]/[core]/westrp_ui/html/test.html).
* **Comandos de Teste e Overrides:**
  - `/testhud health <bar> [core]` e `/testhud stamina <bar> [core]` para simulação independente.
  - `/testhud golden <health|stamina|mount|all> <on/off/restore>` para simular o efeito de Golden Core ou restaurar à detecção nativa.
  - `/testhud core <hunger|thirst|health|stamina> <on/off>` para ativar ou desativar o efeito dinâmico por indicador.
  - Exports `SetHealthOverride(bar, core)`, `SetStaminaOverride(bar, core)`, `SetGoldenCore(attr, state)`, `ConfigureHudSettings(settings)` e `GetHudConfig()` registrados no `fxmanifest.lua`.



