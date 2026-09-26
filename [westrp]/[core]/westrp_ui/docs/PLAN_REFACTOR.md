# Plano Diretor de Refatoração e Modularização — WestRP UI Engine
> **Objetivo:** Enxugar o monólito de 87 KB de JS e 64 KB de CSS, adotar arquitetura de componentes independentes e implementar os módulos pendentes (Dialogs/Inputs e HUD Nativo).

---

## 1. Visão Geral das Etapas

```
[FASE 1: Modularização CSS/JS]
       │
       ▼
[FASE 2: Módulo Dialog/Input (Adeus vorp_inputs)]
       │
       ▼
[FASE 3: Camada de HUD Nativo (0.00ms DataBinding)]
       │
       ▼
[FASE 4: Action Progress Bar (Adeus vorp_progressbar)]
       │
       ▼
[FASE 5: Limpeza de Código Morto & Showcase Enxuto]
```

---

## 2. Detalhamento das Fases

### 📌 FASE 1: Quebra do Monólito Frontend (Estrutura de Arquivos)
* **Objetivo:** Nenhum arquivo CSS deve ter mais de 10-15 KB; nenhum arquivo JS deve ter mais de 20 KB.
* **Tarefas:**
  1. Criar `html/css/variables.css` com os tokens do `DESIGN_SYSTEM.md`.
  2. Criar `html/css/base.css` (reset, fontes, backdrop de desfoque, scrollbar dourada).
  3. Mover regras do Dock para `html/css/dock.css`.
  4. Mover regras do Panel para `html/css/panel.css`.
  5. Criar `html/css/dialog.css` para os modais de entrada de dados.
  6. Criar `html/css/progress.css` para a barra de progresso.
  7. Criar `html/css/toast.css` para as notificações.
  8. Criar `html/js/audio.js` (WebAudio procedural independente).
  9. Criar a pasta `html/js/components/` contendo:
     * `dock.js`: Controle de teclado, abas, sliders, toggles e foco.
     * `panel.js`: Renderização de grid, craft, table e dashboard.
     * `dialog.js`: Modais de entrada de dados (currency, number, text, confirm).
     * `progress.js`: Barra de progresso com cancelamento.
     * `toast.js`: Fila de notificações toast.
  10. Refatorar `html/js/app.js` para ser estritamente um **Roteador de Eventos NUI** de ~60 linhas que despacha as mensagens para cada módulo correspondente.

---

### 📌 FASE 2: Implementação do Módulo de Diálogo/Input (Substituto do `vorp_inputs`)
* **Objetivo:** Fornecer aos outros resources uma forma trivial e robusta de solicitar valores numéricos, monetários e textuais ao jogador.
* **Tarefas:**
  1. Implementar o modal no `html/index.html` e `html/css/dialog.css`.
  2. Criar validador de máscara para moeda (`$ 0.00`) e limites numéricos no `dialog.js`.
  3. Expor as APIs em Lua no `client/main.lua`:
     * `WestRP.Client.UI.PromptInput(options, callback)`
     * `WestRP.Client.UI.ConfirmDialog(options, callback)`
     * `WestRP.Client.UI.FormDialog(options, callback)` (múltiplos campos)
  4. Testar abertura, preenchimento, confirmação (`ENTER`) e cancelamento (`ESC` / `BACKSPACE`).

---

### 📌 FASE 3: Camada de HUD Nativo (DataBinding 0.00ms)
* **Objetivo:** Aproveitar os aprendizados do `redm-uiapps` sem pesar o Chromium.
* **Tarefas:**
  1. Criar `client/native_hud.lua`.
  2. Implementar `SetHonor(level)` vinculado ao contêiner `RPGStatusIcons / HonorIcon`.
  3. Implementar `StartTimer(seconds, alertSeconds)` e `StopTimer()` via `centralInfoDatastore`.
  4. Implementar `ShowMoney(cash, camp)` via `Tithing`.
  5. Implementar `SetRank(name, rank, xpPct)` via `mp_rank_bar`.
  6. Exportar essas funções no SDK do WestRP Core (`WestRP.Client.UI.NativeHUD.*`).

---

### 📌 FASE 4: Action Progress Bar (Substituto do `vorp_progressbar`)
* **Objetivo:** Fornecer uma barra de carregamento de ações do jogador com bloqueio suave de controles e suporte a cancelamento por movimento/dano.
* **Tarefas:**
  1. Componente NUI leve em `html/css/progress.css` e `html/js/components/progress.js`.
  2. Expor `WestRP.Client.UI.ProgressBar(options, callback)`:
     * Duração em milissegundos.
     * Label da ação (ex: *"Esfolando carneiro..."*).
     * Opções de cancelamento (`canCancel`, `cancelOnDamage`, `cancelOnMove`).
     * Animação do ped associada (opcional: dicionário e clip de animação enquanto a barra progride).

---

### 📌 FASE 5: Sanitização, Testes e Documentação Rápida
* **Tarefas:**
  1. Remover o arquivo monolítico antigo `html/css/style.css` e `html/js/app.js` antigo.
  2. Atualizar o `README.md` principal da raiz do `westrp_ui` como o guia de referência rápida dos desenvolvedores.
  3. Criar comandos de teste enxutos no `client/showcase.lua` para validar cada um dos 6 módulos isoladamente.
