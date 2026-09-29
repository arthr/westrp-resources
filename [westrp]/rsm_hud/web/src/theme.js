// Tema vindo de fora (o Color Manager do rsm_nuikit). Troca só as variáveis
// --hud-* do styles.css; sem tema (false), elas voltam aos valores de lá, que
// são o visual próprio do HUD. As derivadas usam a mesma conta do rsm_nuikit,
// então texto apagado, destaque escuro etc. batem com os painéis dele.

const HEX = /^#[0-9a-f]{6}$/i;
const VARS = [
  "--hud-accent",
  "--hud-accent-rgb",
  "--hud-accent-deep",
  "--hud-on-accent",
  "--hud-text",
  "--hud-text-rgb",
  "--hud-ink",
  "--hud-dim",
  "--hud-faint",
  "--hud-surface-rgb",
  "--hud-panel",
  "--hud-panel-rgb",
  "--hud-panel-2",
  "--hud-surface-k",
];
// a "Surface opacity" padrão do rsm_nuikit: nela as placas ficam como sempre foram
const BASE_ALPHA = 93;

const rgb = (hex) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
const toHex = (c) => `#${c.map((v) => Math.round(Math.min(255, Math.max(0, v))).toString(16).padStart(2, "0")).join("")}`.toUpperCase();
const mix = (a, b, t) => {
  const ca = rgb(a);
  const cb = rgb(b);
  return toHex(ca.map((v, i) => v + (cb[i] - v) * t));
};
const triplet = (hex) => rgb(hex).join(" ");
const lum = (hex) => {
  const ch = (v) => (v / 255 <= 0.03928 ? v / 255 / 12.92 : ((v / 255 + 0.055) / 1.055) ** 2.4);
  const [r, g, b] = rgb(hex);
  return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b);
};
const contrast = (a, b) => {
  const la = lum(a);
  const lb = lum(b);
  return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
};

// O Blood & Black do rsm_nuikit é o próprio tema deste HUD: recebê-lo não muda
// nada, o HUD fica exatamente com as cores do styles.css.
const OWN = { accent: "#CB0101", surface: "#0D0D0D", text: "#F5F3EE" };

// Tema válido → { variável: valor }; o próprio tema, ou qualquer coisa fora do
// formato → null (cores do styles.css).
export function themeVars(t) {
  if (!t || typeof t !== "object") return null;
  const { accent, surface, text } = t;
  if (![accent, surface, text].every((v) => typeof v === "string" && HEX.test(v))) return null;
  const alpha = typeof t.surfaceAlpha === "number" && Number.isFinite(t.surfaceAlpha) ? t.surfaceAlpha : BASE_ALPHA;
  const own = Object.entries(OWN).every(([k, v]) => t[k].toUpperCase() === v) && alpha === BASE_ALPHA;
  if (own) return null;
  return {
    "--hud-accent": accent,
    "--hud-accent-rgb": triplet(accent),
    "--hud-accent-deep": mix(accent, "#000000", 0.18),
    // texto sobre o destaque: o do tema ou quase-preto, o que for mais legível
    "--hud-on-accent": contrast(text, accent) >= contrast("#0D0D0D", accent) ? text : "#0D0D0D",
    "--hud-text": text,
    "--hud-text-rgb": triplet(text),
    "--hud-ink": mix(text, surface, 0.06),
    "--hud-dim": mix(text, surface, 0.4),
    "--hud-faint": mix(text, surface, 0.6),
    "--hud-surface-rgb": triplet(surface),
    "--hud-panel": surface,
    "--hud-panel-rgb": triplet(surface),
    "--hud-panel-2": mix(surface, text, 0.04),
    "--hud-surface-k": String(Math.min(100, Math.max(40, alpha)) / BASE_ALPHA),
  };
}

export function applyTheme(t) {
  const style = document.documentElement.style;
  const vars = themeVars(t);
  for (const name of VARS) {
    if (vars) style.setProperty(name, vars[name]);
    else style.removeProperty(name);
  }
}
