# Design System & Tokens Visuais (SDD Spec 01)
> **Tema Base:** Blood & Black (Autêntico RDR2 Western Industrial)  
> **Framework:** Tailwind CSS v3.4 + CSS Custom Properties  
> **Origem dos Assets:** Extraídos do `rsm_nuikit` e integrados em `westrp_ui/web/public/`

---

## 1. Tipografia Oficial do RDR2

O `westrp_ui` padroniza as fontes oficiais da Rockstar Games no formato `.woff2`, garantindo renderização rápida e nítida no CEF 103:

| Família de Fonte | Nome CSS | Arquivo Fonte | Uso Principal |
| :--- | :--- | :--- | :--- |
| **RDR Lino** | `font-display` | `fonts/RDRLino-Regular.woff2` | Cabeçalhos de menu, kickers, números de stats |
| **Hapna Slab** | `font-sans` | `fonts/HapnaSlabSerif-DemiBold.woff2` | Textos corridos, botões, opções de lista, badges |
| **Redemption** | `font-title` | `fonts/Redemption.woff2` | Títulos grandes, títulos de cartas, banners de localidade |
| **RDR Catalogue** | `font-cat` | `fonts/RDRCatalogueBold-Bold.woff2` | Estilo jornal/catálogo de compras de época |

---

## 2. Paleta de Cores e Tokens do Color Manager

As cores são controladas dinamicamente via variáveis CSS injetadas no `:root`. O **Color Manager** permite customizar e persistir esquemas sem alterar código-fonte:

```css
:root {
  /* Cores Base do Sistema */
  --bg-deep: #010101;
  --panel-surface: #0d0d0d;
  --panel-surface-alt: #141414;
  --border-line: rgba(255, 255, 255, 0.08);

  /* Blood & Black Theme Tokens */
  --kit-accent: #CB0101;            /* Vermelho sangue clássico RDR2 */
  --kit-accent-rgb: 203, 1, 1;
  --kit-accent-hover: #A50101;
  --kit-on-accent: #FFFFFF;

  --kit-surface-rgb: 13, 13, 13;
  --kit-surface-alpha: 0.93;

  --kit-text: #F5F3EE;              /* Papel envelhecido / marfim */
  --kit-text-rgb: 245, 243, 238;
  --kit-dim: #9A948A;               /* Texto secundário */
  --kit-faint: #6B665E;             /* Detalhes sutis / bordas de campos */

  /* Cores Semânticas de Notificações / Status */
  --color-success: #388E3C;
  --color-warning: #F57C00;
  --color-error: #D32F2F;
  --color-info: #1976D2;
}
```

---

## 3. Texturas RDR2 e 9-Slice CSS Masks

Todas as molduras e placas de UI utilizam texturas originais do RDR2 em formato SVG ou PNG aplicadas como **máscaras CSS 9-slice** (`mask-image` ou `border-image`), garantindo que os cantos nunca fiquem esticados ou pixelados:

```css
/* Exemplo de utilitário 9-slice para caixas de seleção RDR2 */
.tx-card {
  position: relative;
  isolation: isolate;
}

.tx-card::before {
  content: "";
  position: absolute;
  inset: 0;
  z-index: -1;
  pointer-events: none;
  background-color: rgba(var(--kit-surface-rgb), var(--kit-surface-alpha));
  -webkit-mask-image: var(--tex-selection-box-bg-1a);
  mask-image: var(--tex-selection-box-bg-1a);
  -webkit-mask-size: 100% 100%;
  mask-size: 100% 100%;
}
```

### Catálogo de Texturas Obrigatórias em `public/tex/`:
1. **Chrome / Molduras:**
   - `selection_box_bg_1a.png`, `selection_box_bg_1d.png` (Caixas selecionáveis)
   - `menu_header_1a.png` (Cabeçalho de janelas com ornamento)
   - `crafting_outline.png` (Borda de crafting e slots de item)
   - `divider_line.png`, `vertical_divider_line.png` (Divisores ornamentados)
   - `toast_notification_1a.png` (Fundo de avisos toast)
2. **HUD / Medidores:**
   - `core_health.png`, `core_stamina.png`, `core_deadeye.png` (Ícones centrais dos cores)
   - `ring_full.png`, `ring_track.png` (Trilhas dos anéis externos)
   - `prompt_bar.png` (Barra inferior de prompts de tecla)

---

## 4. Configuração do Tailwind CSS v3 (`tailwind.config.js`)

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}"
  ],
  theme: {
    extend: {
      colors: {
        blood: {
          DEFAULT: "var(--kit-accent)",
          deep: "var(--kit-accent-hover)",
        },
        paper: "var(--kit-text)",
        panel: {
          DEFAULT: "#0d0d0d",
          secondary: "#141414",
        },
        ink: "var(--kit-text)",
        dim: "var(--kit-dim)",
        faint: "var(--kit-faint)",
      },
      fontFamily: {
        display: ["RDR Lino", "Hapna Slab", "serif"],
        sans: ["Hapna Slab", "Georgia", "serif"],
        title: ["Redemption", "RDR Lino", "serif"],
        cat: ["RDR Catalogue", "RDR Lino", "serif"],
        mono: ["JetBrains Mono", "ui-monospace", "monospace"],
      },
      animation: {
        "kit-rise": "kit-rise 0.3s cubic-bezier(0.22, 1, 0.36, 1) both",
        "kit-slide": "kit-slide 0.2s ease-out both",
        "kit-dialog": "kit-dialog 0.25s cubic-bezier(0.22, 1, 0.36, 1) both",
      },
      keyframes: {
        "kit-rise": {
          "0%": { opacity: 0, transform: "translateY(12px)" },
          "100%": { opacity: 1, transform: "none" },
        },
        "kit-slide": {
          "0%": { opacity: 0, transform: "translateX(10px)" },
          "100%": { opacity: 1, transform: "none" },
        },
        "kit-dialog": {
          "0%": { opacity: 0, transform: "translateY(14px) scale(0.98)" },
          "100%": { opacity: 1, transform: "none" },
        },
      },
    },
  },
  plugins: [],
};
```
