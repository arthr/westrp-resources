// Geometria dos Core Meters: estilos, tamanhos e agrupamento no HUD.

// Onde o desenho de cada ícone começa e termina, em % da altura da imagem
// 64×64 (medido na própria arte). Com isso 0% fica vazio e 100% cheio de
// verdade, e o ícone é centralizado mesmo quando a arte não é.
export const GLYPH = {
  "core-health": { top: 15.6, bottom: 95.3 },
  "core-stamina": { top: 6.3, bottom: 95.3 },
  "core-deadeye": { top: 17.2, bottom: 81.3 },
};

export const CORE_STYLES = [
  { value: "ring", label: "Ring" },
  { value: "half", label: "Half" },
  { value: "segmented", label: "Segmented" },
  { value: "barsH", label: "Bars H" },
  { value: "barsV", label: "Bars V" },
  { value: "numeric", label: "Numeric" },
];

const SEGMENTS = 12; // quantos gomos no estilo Segmented
const SEG_GAP = 9; // graus de folga entre gomos

// Tamanho exato de um core em cada estilo, a partir do tamanho base `s`.
// O Layout Manager usa isso para posicionar o grupo sem medir o DOM.
export function coreDims(variant, s) {
  switch (variant) {
    case "half":
      return [s, s * 0.62];
    case "barsH":
      return [s * 2.12, s * 0.5];
    case "barsV":
      return [s * 0.5, s * 1.5];
    case "numeric":
      return [s * 1.37, s * 0.5];
    default:
      return [s, s];
  }
}

// Como os três cores se agrupam no HUD: barras horizontais e números empilham
// em coluna; os estilos redondos e as barras verticais ficam lado a lado.
const GROUP = {
  barsH: { col: true, gap: 0.14 },
  numeric: { col: true, gap: 0.14 },
  barsV: { col: false, gap: 0.24 },
};
export function coreGroup(variant, s, n = 3) {
  const [w, h] = coreDims(variant, s);
  const g = GROUP[variant] ?? { col: false, gap: 0.16 };
  const gap = g.gap * s;
  return {
    col: g.col,
    gap,
    width: g.col ? w : n * w + (n - 1) * gap,
    height: g.col ? n * h + (n - 1) * gap : h,
  };
}

// Anel em gomos: cada gomo aceso ou apagado, com folga entre eles.
export function segmentGradient(value, on, off) {
  const seg = 360 / SEGMENTS;
  const lit = Math.ceil((value / 100) * SEGMENTS);
  const stops = [];
  for (let i = 0; i < SEGMENTS; i++) {
    const a = i * seg + SEG_GAP / 2;
    const b = (i + 1) * seg - SEG_GAP / 2;
    stops.push(`transparent ${i * seg}deg ${a}deg`, `${i < lit ? on : off} ${a}deg ${b}deg`, `transparent ${b}deg ${(i + 1) * seg}deg`);
  }
  return `conic-gradient(${stops.join(", ")})`;
}

// Barra (menu_bar) cheia até `value`, da esquerda para a direita.
export const barFill = (value, on, off) => `linear-gradient(90deg, ${on} ${value}%, ${off} ${value}%)`;
