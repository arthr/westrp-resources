// Colour helpers for the Color Manager. Every theme token lives on <html> as a
// CSS variable, so the whole kit (and the HUD overlay) recolours live.

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

export function isHex(value) {
  return /^#[0-9a-f]{6}$/i.test(value);
}

export function hexToRgb(hex) {
  const h = hex.replace("#", "");
  return {
    r: parseInt(h.slice(0, 2), 16),
    g: parseInt(h.slice(2, 4), 16),
    b: parseInt(h.slice(4, 6), 16),
  };
}

export function rgbToHex({ r, g, b }) {
  const part = (n) => clamp(Math.round(n), 0, 255).toString(16).padStart(2, "0");
  return `#${part(r)}${part(g)}${part(b)}`.toUpperCase();
}

export function hexToHsl(hex) {
  const { r, g, b } = hexToRgb(hex);
  const rn = r / 255, gn = g / 255, bn = b / 255;
  const max = Math.max(rn, gn, bn), min = Math.min(rn, gn, bn);
  const l = (max + min) / 2;
  let h = 0, s = 0;
  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    if (max === rn) h = (gn - bn) / d + (gn < bn ? 6 : 0);
    else if (max === gn) h = (bn - rn) / d + 2;
    else h = (rn - gn) / d + 4;
    h *= 60;
  }
  return { h: Math.round(h) % 360, s: Math.round(s * 100), l: Math.round(l * 100) };
}

export function hslToHex({ h, s, l }) {
  const sn = s / 100, ln = l / 100;
  const k = (n) => (n + h / 30) % 12;
  const a = sn * Math.min(ln, 1 - ln);
  const f = (n) => ln - a * Math.max(-1, Math.min(k(n) - 3, Math.min(9 - k(n), 1)));
  return rgbToHex({ r: f(0) * 255, g: f(8) * 255, b: f(4) * 255 });
}

// Linear mix of two hex colours, t = 0 → a, t = 1 → b
export function mix(a, b, t) {
  const ca = hexToRgb(a), cb = hexToRgb(b);
  return rgbToHex({
    r: ca.r + (cb.r - ca.r) * t,
    g: ca.g + (cb.g - ca.g) * t,
    b: ca.b + (cb.b - ca.b) * t,
  });
}

// Relative luminance (WCAG) and contrast ratio
export function luminance(hex) {
  const { r, g, b } = hexToRgb(hex);
  const ch = (v) => {
    const c = v / 255;
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b);
}

export function contrast(a, b) {
  const la = luminance(a), lb = luminance(b);
  return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
}

// Texto sobre o destaque: branco ou quase-preto, o que tiver mais contraste.
export function onAccent(accent) {
  return contrast("#FFFFFF", accent) >= contrast("#0D0D0D", accent) ? "#FFFFFF" : "#0D0D0D";
}

const triplet = (hex) => {
  const { r, g, b } = hexToRgb(hex);
  return `${r} ${g} ${b}`;
};

// Writes the theme onto <html>; the CSS reads nothing else.
export function applyTheme({ accent, surface, text, surfaceAlpha }) {
  const style = document.documentElement.style;
  style.setProperty("--kit-accent", accent);
  style.setProperty("--kit-accent-rgb", triplet(accent));
  style.setProperty("--kit-accent-hover", mix(accent, "#000000", 0.18));
  style.setProperty("--kit-on-accent", onAccent(accent));
  style.setProperty("--kit-surface-rgb", triplet(surface));
  style.setProperty("--kit-surface-a", String(surfaceAlpha / 100));
  style.setProperty("--kit-text", text);
  style.setProperty("--kit-text-rgb", triplet(text));
  style.setProperty("--kit-dim", mix(text, surface, 0.4));
  style.setProperty("--kit-faint", mix(text, surface, 0.6));
}
