# Subsistema de HUD & Status do Jogador (SDD Spec 03)
> **Padrão:** Single CEF Reactive Subsystem  
> **Localização:** `src/components/hud/`  
> **Comando de Edição:** `/hudlayout`  
> **Performance:** 0.00ms no cliente em idle (Reatividade via CitizenFX State Bags)

---

## 1. Visão Geral e Princípios

O subsistema de HUD do `westrp_ui` absorve e refatora integralmente todas as funcionalidades desenvolvidas no `rsm_hud`. Em vez de rodar em um CEF separado, o HUD passa a ser a **Camada 1 (Layer 1)** permanente do `westrp_ui`, ficando invisível ao mouse e sem consumir foco durante o gameplay.

---

## 2. Catálogo de Widgets do HUD

| Widget | Componente | Dados de Entrada / State Bags | Comportamento em Jogo |
| :--- | :--- | :--- | :--- |
| **Vitais do Jogador** | `PlayerCores.vue` | `health`, `stamina`, `deadeye` (0-100 para core e anel) | Exibição clássica RDR2 no canto inferior esquerdo. Pisca em vermelho quando a vida está baixa |
| **Vitais da Montaria** | `HorseCores.vue` | `horseHealth`, `horseStamina` | Aparece automaticamente apenas quando o jogador está montado em um cavalo |
| **Necessidades Fisiológicas** | `NeedsBar.vue` | `hunger`, `thirst`, `temperature` | Anéis secundários integrados ao metabolismo do VORP |
| **Dinheiro & Ouro** | `MoneyPanel.vue` | `cash`, `gold` (de `LocalPlayer.state['westrp:char']`) | Mostra saldo no topo direito; atualiza com animação de contagem ao receber pagamentos |
| **Relógio & Clima** | `ClockWeather.vue` | `hours`, `minutes`, `weather` | Relógio de bolso sincronizado com o tempo do servidor |
| **Localização & Bússola** | `LocationBanner.vue` | `street`, `zone`, `heading` | Aparece sutilmente ao entrar em uma nova cidade ou região |
| **Indicador de Voz** | `VoiceIndicator.vue` | `range` (whisper, normal, shout), `talking` (boolean) | Indicador visual de alcance e transmissão do microfone (SaltyChat/Mumble) |
| **Status de Armas** | `WeaponAmmo.vue` | `ammoInClip`, `ammoTotal`, `weaponHash`, `condition` | Ícone da arma equipada, balas no tambor e desgaste do armamento |
| **Recompensa / Lei** | `WantedStatus.vue` | `bounty` (valor), `wantedLevel` | Banner de procurado com valor da recompensa ativa |
| **Texto de Ajuda & Dicas** | `HelpWidget.vue` | `text`, `key` | Caixa superior esquerda com dicas contextuais de gameplay |
| **Barra de Objetivo** | `ObjectiveWidget.vue` | `text`, `progress` | Indicador central superior da missão ou trabalho em andamento |

---

## 3. O Gerenciador de Layout em Jogo (`/hudlayout`)

### 3.1 Funcionalidades do Editor:
1. **Ativação por Comando ou Menu:**
   - Digitar `/hudlayout` abre o modo de edição.
   - O `FocusManager` ativa o cursor do mouse (`SetNuiFocus(true, true)`).
   - O jogo entra em modo de congelamento de câmera parcial para permitir movimentação livre.
2. **Manipulação dos Elementos:**
   - **Arrastar e Soltar (Drag & Drop):** Cada widget possui uma alça de arraste. A posição é calculada em coordenadas normalizadas (0.00 a 1.00 de X e Y) para ser 100% responsiva em qualquer resolução (1080p, 1440p, Ultrawide, 4K).
   - **Escala e Opacidade:** Sliders flutuantes para ajustar o tamanho (0.5x a 1.6x) e a transparência (30% a 100%).
   - **Visibilidade:** Checkbox para ocultar elementos desnecessários (ex: desligar bússola ou relógio).
3. **Predefinições (Presets):**
   - **Fronteira (Padrão):** Visual completo com todos os medidores nos cantos tradicionais do RDR2.
   - **Compacto:** Elementos agrupados no canto inferior esquerdo para liberar a visão.
   - **Mínimo:** Apenas vitais em modo dinâmico (surgem apenas quando sofrem alteração de valor).
4. **Persistência de Layout:**
   - Ao clicar em "Salvar", os dados são persistidos no personagem via Callback para o servidor (`oxmysql`).
   - Ao logar com o personagem, o layout customizado é carregado instantaneamente.

---

## 4. Otimização de Performance e State Bags

Em vez de criar threads no cliente com `Wait(100)` enviando `SendNUIMessage` constante para atualizar fome, sede e dinheiro, o sistema utiliza **CitizenFX State Bags**:

```lua
-- No servidor (ao alterar saldo ou status):
Player(source).state:set('westrp:char', {
    cash = newCash,
    gold = newGold,
    job = job
}, true) -- Replicado para o cliente com 0 de resmon

-- No cliente do westrp_ui (escuta de mudanças):
AddStateBagChangeHandler('westrp:char', nil, function(bagName, key, value)
    local ply = GetPlayerFromStateBagName(bagName)
    if ply == PlayerId() and value then
        SendNUIMessage({
            action = "hud:updateMoney",
            cash = value.cash,
            gold = value.gold
        })
    end
end)
```
Isso garante **0.00ms de consumo de CPU no cliente** em idle.
