# Design System Oficial — WestRP UI Engine
> **Versão:** 2.1.0  
> **Tema:** 1:1 Authentic Red Dead Redemption 2 Theme (Inspirado no redm-vue-ui)  
> **Referência Visual:** Red Dead Redemption 2 (Rockstar Games) — Menus nativos, catálogos Wheeler, Rawson and Co., livros-caixa, armeiros e bancadas.

---

## 1. Princípios de Design

1. **Fidelidade Visual 1:1 ao RDR2:** Todas as telas reproduzem fielmente as interfaces originais do Red Dead Redemption 2 utilizando as fontes tipográficas oficiais (`Chinese Rocks`, `Hapna Slab Serif`, `RDR Lino Regular`) e as texturas nativas do jogo.
2. **Caminho A (Vanilla JS Modular):** Zero build steps (Vite/Webpack/Vue), zero dependências npm pesadas no client, carregamento instantâneo no CEF e consumo de 0.00ms resmon em idle.
3. **Divisória com Diamante Central:** Toda separação de títulos, seções e rodapés utiliza o divisor original do jogo (`divider.png`), com losango carmesim central.
4. **Botões Chanfrados Texturizados:** Botões primários de ação usam a moldura de madeira/ferro do jogo (`box.png`) e transicionam para vermelho vivo no hover (`box-red.png`).
5. **Imersão Cinemática 3D:** Uso do pós-processamento nativo `OJDominoBlur` para integrar a interface ao mundo do jogo sem escurecer a tela ou criar uma "parede preta" desconectada.

---

## 2. Tokens de Cores (Paleta Oficial Rockstar RDR2)

### 2.1 Cores de Superfície e Fundo
| Token CSS | Valor Hex | Finalidade |
| :--- | :--- | :--- |
| `--rdr-color-surface-header` | `#141414` | Fundo do cabeçalho superior e rodapé de ações. |
| `--rdr-color-surface` | `#262626` | Superfície base de cartões, listas e contêineres de dados. |
| `--rdr-color-surface-hover` | `#303030` | Estado hover de itens de menu e botões secundários. |
| `--rdr-color-surface-pressed` | `#1e1e1e` | Estado pressionado/clicado de botões e seletores. |
| `--rdr-color-surface-red` | `#3a2323` | Fundo carmesim profundo para itens ativos/selecionados. |
| `--rdr-color-border` | `#4d4d4d` | Contorno e borda de cartões e divisões. |
| `--rdr-color-border-hover` | `#626262` | Borda em estado hover. |

### 2.2 Cores de Acento (Rockstar Carmesim)
| Token CSS | Valor Hex | Finalidade |
| :--- | :--- | :--- |
| `--rdr-color-primary` | `#B62A2A` | Vermelho carmesim Rockstar oficial (destaques, bordas ativas, tags). |
| `--rdr-color-primary-dark` | `#B21214` | Vermelho escuro para gradientes de barra de progresso. |
| `--color-gold-light` | `#dfb76c` | Dourado clássico para badges de preços monetários (`$ 15.00`). |

### 2.3 Tipografia e Cores de Texto
| Token CSS | Valor | Finalidade |
| :--- | :--- | :--- |
| `--rdr-color-text` | `#fafafa` | Texto principal com alto contraste contra fundos escuros. |
| `--rdr-color-text-muted` | `rgba(250, 250, 250, 0.7)` | Texto secundário, descrições longas, subtítulos e rodapés. |

---

## 3. Tipografia Nativa RDR2

As fontes são carregadas localmente via `@font-face` diretamente do diretório `html/assets/fonts/` (zero requisições externas para o Google Fonts):

1. **`Chinese Rocks` (`--rdr-font-decorative`):**
   - Uso: Títulos principais do Dock e Panel, tags de categorias, botões de ação Rockstar, teclas de rodapé e badges.
   - Padrão: Caixa alta (`text-transform: uppercase`), `letter-spacing: 1.5px`.
2. **`Hapna Slab Serif` (`--rdr-font-body`):**
   - Uso: Descrições de itens, rótulos de campos de input, textos de confirmação e corpo geral de leitura.
3. **`RDR Lino Regular` (`--rdr-font-title`):**
   - Uso: Títulos de estilo manuscrito e subtítulos estilizados.

---

## 4. Texturas Nativas RDR2 (Assets Locais)

Todos os assets gráficos estão hospedados em `html/assets/textures/` e registrados no `fxmanifest.lua`:

| Arquivo | Token CSS | Aplicação |
| :--- | :--- | :--- |
| `divider.png` | `--rdr-texture-divider` | Linha divisória carmesim com losango central (`.rdr-divider`, `header::after`). |
| `box.png` | `--rdr-texture-box` | Moldura chanfrada de botões de ação e modais (`.panel-cta-btn`, `.dialog-btn-primary`). |
| `box-red.png` | `--rdr-texture-box-red` | Estado ativo/hover carmesim para botões e modais de perigo. |
| `bg.png` | `--rdr-texture-bg` | Pano de fundo rústico texturizado escurecido para Dock, Panel e Dialogs. |
| `crafting_outline.png` | `--rdr-texture-border` | Bordas e molduras chanfradas para contêineres de manufatura e inventário. |
| `arrow_left.png` / `arrow_right.png` | — | Setas nativas RDR2 nos seletores de abas horizontais do Dock lateral. |
| `selector.png` | `--rdr-texture-selector` | Ícone indicador de item focado/ativo. |

---

## 5. Sistema de Áudio Procedural (WebAudio API)

Para garantir **zero dependência de arquivos de áudio pesados** (.wav/.mp3/.ogg) e carregamento instantâneo, os sons de feedback da UI são sintetizados proceduralmente:

* **Clique / Navegação (`nav`):** Pulso senoidal curto de 520Hz decaindo em 35ms.
* **Seleção / Confirmação (`select`):** Acorde duplo harmônico em 440Hz + 880Hz decaindo suavemente em 90ms.
* **Alternar Toggle / Slider (`toggle`):** Frequência de transição rápida de 300Hz para 450Hz.
* **Erro / Negativa (`error`):** Onda dente de serra grave de 120Hz decaindo com leve distorção.
* **Abertura de Menu (`open`):** Tom suave de ressonância com filtro passa-baixas.

---

## 6. Padrões de Responsividade e SafeZone

1. **Dock Lateral:** Largura base ampliada para `460px` (via token CSS `--rdr-dock-width: 460px;`, com suporte a override dinâmico via `options.width` e clamping responsivo `max-width: 90vw`). Garante legibilidade superior para títulos e descrições longas em monitores Ultrawide (21:9 e 32:9 de 34" a 49") e 1440p sem quebras de linha indesejadas, mantendo o campo de visão do personagem 3D totalmente desobstruído no centro-direita. Suporta alternância fluida entre modo câmera livre (teclado/WASD) e modo cursor livre com bloqueio de controles do jogo via tecla `ALT` (com indicador visual `Mouse [ON/OFF]` no rodapé).
2. **Panel Central (Ultrawide Ready):** Largura padrão de `1440px` (com `max-width: 95vw; height: 820px; max-height: 92vh;`). Projetado especificamente para monitores Ultrawide (21:9 e 32:9 de 34" a 49"), proporcionando um espaço de trabalho imponente e legível sem achatar tabelas ou controles, enquanto se adapta perfeitamente via clamping proporcional a monitores padrão 1080p e 1440p (16:9).
3. **SafeZone RedM:** Todos os elementos de HUD próximos às bordas utilizam `margin: env(safe-area-inset-top, 20px)` ou compensação baseada na resolução nativa do jogador.

---

## 7. Eliminação de Desconexões Contemporâneas (Zero Anacronismos)

Para assegurar 100% de coerência histórica e fidelidade à interface nativa do RDR2:

1. **Sem Faixas ou Bordas Coloridas em Notificações:** Notificações e telegramas abandonam as listras verticais coloridas (verde, vermelho, amarelo estilo Bootstrap/web moderna). As mensagens adotam moldura retangular texturizada (`bg.png` / `crafting_outline.png`), tag de despacho em `Chinese Rocks` (`TELEGRAMA`, `REGISTRO`, `ALERTA`) e divisor com losango central (`divider.png`).
2. **Bordas Vivas Retangulares (`border-radius: 0px`):** Todos os contêineres, cartões, botões, modais e trilhos de progresso utilizam cantos retos sem arredondamentos plásticos modernos.
3. **Sem Halos de Brilho Neon (`box-shadow glow`):** Eliminação completa de sombras coloridas brilhantes ou anéis de foco neon em inputs e botões. A profundidade visual é criada estritamente por sombras escuras ambientais e chanfros de textura.
4. **Sem Pílulas Coloridas em Listas:** Preços e estados no Dock lateral utilizam tipografia limpa em `Chinese Rocks` sem fundos em formato de cápsula com tons pastéis.
5. **Seletores Táteis de Época:** Interruptores do tipo "toggle" utilizam caixas de seleção rústicas (`✓`) em vez de LEDs circulares luminosos.

---

## 8. Biblioteca de Componentes RDR2 (Baseada no redm-vue-ui)

Todos os componentes renderizados em `https://alebertz.github.io/redm-vue-ui/` estão integralmente implementados em Vanilla JS no WestRP UI:

1. **`RdrButton`:**
   - `--default`: Botão primário 80px de altura, textura `box.png` com transição para `box-red.png` no hover/active, fonte `Chinese Rocks`.
   - `--subtle`: Botão elegante com moldura rústica (`border-image`), variantes de tamanho `sm` (13px), `md` (15px) e `lg` (18px), e estado ativo em carmesim (`--rdr-color-surface-red`).
2. **`RdrCheckbox`:**
   - Caixa de seleção quadrada de 24x24px com borda retangular nítida de 2px.
   - **Estado Marcado (`checked`):** A caixa é completamente preenchida em vermelho carmesim Rockstar (`--rdr-color-primary`), destacando com alto contraste a marcação autêntica em branco via `tick.png`.
   - **Hover / Foco:** Borda e preenchimento transicionam para vermelho carmesim profundo (`--rdr-color-primary-dark`).
3. **`RdrSliderInput`:**
   - Controle deslizante com botões de ajuste lateral fino (`nav_decrease.png`, `nav_increase.png`), trilho com preenchimento em gradiente via `--rdr-slider-progress`, thumb texturizado com `selector.png` e tooltip flutuante dinâmico.
4. **`RdrNumberInput`:**
   - Campo numérico com moldura `crafting_outline.png` e botões de incremento/decremento com feedback tátil e áudio procedural.
5. **`RdrDropdown`:**
   - Menu suspenso com chevron animado (rotação de 180°), painel com scrollbar nativa e lista com realce de seleção.
   - **Elevação Dinâmica de Camada (`z-index`):** Camada de empilhamento de alta prioridade (`z-index: 1000` no contêiner/wrap e `99999` no painel suspenso), garantindo que a lista de opções sobreponha com perfeição absoluta qualquer cartão, botão, entrada ou rodapé subsequente sem ficar escondida atrás de outros elementos.
6. **`RdrTable` (Ordenável):**
   - Tabela nativa de livro-razão com cabeçalhos interativos (`data-sort-key`, `data-sort-dir="asc"|"desc"`), setas de ordenação `▲`/`▼` via pseudo-elemento `::after`, densidades `compact`, `default` e `relaxed`, e suporte a rodapé contábil (`<tfoot>`).
7. **`RdrCard`:**
   - Cartões com fundo em textura `box.png`, preenchimentos configuráveis (`padding-sm`, `padding-md`, `padding-lg`, `padding-xl`) e modo rolável (`scrollable`).
8. **`RdrModal` (Janela Modal Flutuante & Confirmação Unificada):**
   - Diálogo flutuante centralizado de 520px com textura de fundo `bg.png` (ou `bg-red.png` para a variante `.rdr-modal--danger`), sombra radial cinematográfica de backdrop (`--rdr-color-overlay`), animação de entrada `zoomAndFadeIn` e saída `zoomAndFadeOut`, cantos vivos de 0px e botão nativo de fechar com `nav_close.png`.
   - Fecha ao teclar `BACKSPACE`, clicar no botão `X` ou clicar na área externa do backdrop (comportamento de clique externo configurável via parâmetro `closeOnOverlay` / `closeOnBackdrop`, padronizado como `false` em confirmações e formulários para evitar cancelamentos acidentais ou perda de dados digitados).
   - Confirma a ação primária (`isPrimary = true`) imediatamente ao teclar `[ENTER]`.
   - Botões de ação padronizados com altura de 46px, tipografia `Chinese Rocks`, molduras chanfradas autênticas e hint visual `[ENTER]`.
   - Unifica as operações de `OpenModal` e `OpenConfirm` (rápidas e críticas) sob a mesma identidade e motor visual.
9. **`RdrSlider` (Slider Panel / Gaveta Lateral):**
   - Gaveta deslizante ancorada à borda direita (`--right`) ou esquerda (`--left`) da tela, com largura ajustável (padrão `360px` a `380px`), textura rústica `bg.png` e transição `translateX` suave via curva cúbica `cubic-bezier(0.25, 0.8, 0.25, 1)`.
   - Possui botão nativo `nav_close.png`, suporte a fechamento com `BACKSPACE` ou clique externo, e permite exibir inventários complementares, detalhes de registros, logs e ferramentas de suporte mantendo o ambiente do jogo visível.
10. **`RdrInput` (Campo de Texto de Linha Única):**
    - Input de texto temático envolto em `.rdr-input__wrap` com moldura texturizada `crafting_outline.png` (`--rdr-border-image`), cantos vivos de 0px, fundo translúcido `#21212180` no foco e suporte a estado desabilitado (`opacity: 0.5`).
    - Integração de valor reativo com exibição de texto em tempo real (`Valor: [texto]`).
11. **`RdrTextarea` (Área de Texto Multilinhas):**
    - Caixa de texto ampla para relatórios policiais, escrituras e declarações, envolta em `.rdr-textarea__wrap` com moldura `crafting_outline.png`.
    - Altura configurável via atributo `rows` (padrão 4 ou 5), redimensionamento desabilitado (`resize: none`), foco texturizado e contador reativo de caracteres digitados.
12. **`RdrHeader` & `RdrDivider` (Cabeçalhos e Divisores):**
    - `RdrHeader`: Tipografia hierárquica `h1` (`Chinese Rocks` 32px), `h2` (24px) ou `h3` (`RDR Lino Regular` 20px) com linha divisória horizontal automática e losango central.
    - `RdrDivider`: `<hr class="rdr-divider">` com textura `divider.png` de alta resolução e opacidade ajustada (`--rdr-divider-opacity: 0.85`).
13. **`RdrPanel` (Superfície de Conteúdo Ampla):**
    - Painel de fundo com textura rústica `bg.png` e variante carmesim `rdr-panel--red` com textura `bg-red.png`, com preenchimentos padronizados (`padding-sm`, `padding-md`, `padding-lg`, `padding-xl`).
14. **Transições Nativas RDR2:**
    - `.animate-zoom-in`: Animação suave `zoomAndFadeIn` (escala 0.94 -> 1.0 e opacidade 0 -> 1) com curva cúbica Rockstar.
    - `.animate-fade-in`: Transição linear suave de opacidade.
    - `.animate-slide-in-right` / `.animate-slide-in-left`: Transição de deslize lateral com aceleração natural da época.
    - `.animate-slide-in-bottom`: Deslize vertical para notificações e barras de ferramentas.
15. **`RdrDashboardView` (Cockpit de Monitoramento & Ações Rápidas):**
    - Grid de KPIs `Server Overview` com 4 cartões de estatísticas (Jogadores Online, Tempo Ativo/Uptime, Pico 24h e Recorde Histórico) em tipografia `Chinese Rocks`.
    - Contêiner de ações categorizadas `Admin Actions` com grupos temáticos (Teleporte, Operador), botões de ação com ícones táteis e switches de alternância com caixas de seleção rústicas `RdrCheckbox`.
16. **`RdrSettingsView` (Preferências Operacionais & Ancoragem):**
    - Seletor visual de posição de tela para o Hot Menu/Dock com 6 quadrantes (`Top Left`, `Top Right`, `Mid Left`, `Mid Right`, `Bottom Left`, `Bottom Right`) e destaque ativo carmesim (`.active`).
    - Lista de atalhos rápidos operacionais com caixas de seleção `RdrCheckbox` reativas e sincronização em tempo real com o servidor via callback `panelAction`.
17. **`RdrCraftView` & `RdrQueueView` (Bancada de Forja & Acompanhamento de Produção):**
    - `CraftView`: Lista de receitas artesanais com seleção interativa, exibição comparativa de materiais possuídos vs necessários (`6 / 2` em dourado quando suficiente, vermelho quando insuficiente) e despacho de ordem de produção.
    - `QueueView`: Acompanhamento de lotes em forjamento com barra de progresso, percentual, tempo restante em segundos e botões de cancelamento ou coleta de lote finalizado.
18. **`RdrDock` (Dock Lateral / Quick Actions Menu):**
    - Contêiner vertical de navegação nativa RDR2 ancorado à tela (largura base `350px`).
    - **Navegação Exclusiva por Setas (`▲▼◄►`):**
      - `▲` (`ArrowUp`) / `▼` (`ArrowDown`): Navegação vertical entre os itens da lista.
      - `◄` (`ArrowLeft`) / `►` (`ArrowRight`): Ajuste de controles deslizantes (`slider`) ou alternância de abas (`prevTab`/`nextTab`) caso o item ativo não seja um slider.
      - As teclas `W`, `A`, `S`, `D` são intencionalmente desvinculadas da interface para manter total liberdade de movimentação do personagem e montaria no modo Câmera Livre (`keepInput = true`).
    - **Controle Dinâmico de Cursor (`ALT`):**
      - Pressionar `ALT` alterna entre o modo teclado (foco NUI sem cursor) e o modo cursor livre do mouse (com bloqueio temporário de controles de câmera/jogo), indicado dinamicamente no rodapé (`Mouse [OFF]` / `Mouse [ON]`).
    - **Ações e Encerramento:**
      - `ENTER`: Executa o item selecionado ou alterna toggle.
      - `BACKSPACE`: Retorna ao nível anterior de submenu ou fecha o Dock quando na raiz de navegação (o atalho `ESC` foi inteiramente desativado para blindagem contra abertura involuntária do menu de pausa nativo do RDR2).
