import { texMask, Brackets } from "./Surface.jsx";

// Onde o desenho de cada ícone começa e termina, em % da altura da imagem
// 64×64 (medido na própria arte). Com isso 0% fica vazio e 100% cheio de
// verdade, e o ícone é centralizado mesmo quando a arte não é.
const GLYPH = {
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
function segmentGradient(value, on, off) {
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

// Ícone do core: a própria arte é a máscara e o gradiente é o nível.
function CoreIcon({ icon, core, className = "", style }) {
  const g = GLYPH[icon] ?? { top: 0, bottom: 100 };
  const level = 100 - g.bottom + (core / 100) * (g.bottom - g.top);
  const shiftY = 50 - (g.top + g.bottom) / 2;
  const low = core <= 15;
  return (
    <span
      className={`core-icon ${className}`}
      style={{
        ...style,
        transform: `translateY(${shiftY}%)`,
        "--ico": `var(--tex-${icon})`,
        "--core-fill": `${level}%`,
        "--core-on": low ? "var(--kit-accent)" : "var(--kit-text)",
        animation: low ? "kit-pulse 1.1s ease-in-out infinite" : undefined,
      }}
    />
  );
}

// Barra (menu_bar) cheia até `value`, da esquerda para a direita.
const barFill = (value, on, off) => `linear-gradient(90deg, ${on} ${value}%, ${off} ${value}%)`;

// RDR core in six styles. The ring / bar / number shows `ring`; the icon fills
// from the bottom with `core`. Both 0-100; low values turn to the accent.
export function CoreMeter({ icon = "core-health", ring = 100, core = 100, size = 64, variant = "ring" }) {
  const [w, h] = coreDims(variant, size);
  const ringLow = ring <= 25;
  const on = ringLow ? "var(--kit-accent)" : "var(--kit-text)";
  const off = "rgb(var(--kit-text-rgb) / 0.22)";
  const box = { width: w, height: h };
  const small = { width: size * 0.5, height: size * 0.5 };

  if (variant === "half") {
    // meio-anel por cima (das 9 às 3 horas), ícone apoiado na base do arco
    const disc = { width: size, height: size };
    return (
      <div className="relative shrink-0 overflow-hidden" style={box}>
        <span
          className="absolute top-0 left-0"
          style={{ ...disc, ...texMask("ring-track"), background: `conic-gradient(from 270deg, ${off} 0deg 180deg, transparent 180deg)` }}
        />
        <span
          className="absolute top-0 left-0"
          style={{ ...disc, ...texMask("ring-full"), background: `conic-gradient(from 270deg, ${on} 0deg ${ring * 1.8}deg, transparent ${ring * 1.8}deg)` }}
        />
        <CoreIcon icon={icon} core={core} className="absolute" style={{ left: size * 0.3, top: size * 0.2, width: size * 0.4, height: size * 0.4 }} />
      </div>
    );
  }

  if (variant === "segmented") {
    return (
      <div className="relative shrink-0" style={box}>
        <span className="absolute inset-0" style={{ ...texMask("ring-full"), background: segmentGradient(ring, on, off) }} />
        <CoreIcon icon={icon} core={core} className="absolute" style={{ inset: "24%" }} />
      </div>
    );
  }

  if (variant === "barsH") {
    return (
      <div className="flex shrink-0 items-center" style={{ ...box, gap: size * 0.12 }}>
        <CoreIcon icon={icon} core={core} className="relative shrink-0" style={small} />
        <div className="tx-bar min-w-0 flex-1" style={{ background: barFill(ring, on, off) }} />
      </div>
    );
  }

  if (variant === "barsV") {
    // a mesma arte da barra, girada 90°: a proporção da arte continua intacta
    const len = size * 0.9;
    return (
      <div className="flex shrink-0 flex-col items-center" style={{ ...box, gap: size * 0.1 }}>
        <CoreIcon icon={icon} core={core} className="relative shrink-0" style={small} />
        <div className="relative shrink-0" style={{ width: 12, height: len }}>
          <div
            className="tx-bar absolute"
            style={{
              width: len,
              left: (12 - len) / 2,
              top: (len - 12) / 2,
              transform: "rotate(-90deg)",
              background: barFill(ring, on, off),
            }}
          />
        </div>
      </div>
    );
  }

  if (variant === "numeric") {
    return (
      <div className="flex shrink-0 items-center" style={{ ...box, gap: size * 0.12 }}>
        <CoreIcon icon={icon} core={core} className="relative shrink-0" style={small} />
        <span
          className={`tx-chip grid shrink-0 place-items-center font-cat leading-none ${ringLow ? "text-accent" : "text-ink"}`}
          style={{ width: size * 0.75, height: size * 0.5, fontSize: size * 0.26, "--plate": "rgb(var(--kit-text-rgb) / 0.1)" }}
        >
          {Math.round(ring)}
        </span>
      </div>
    );
  }

  // ring (padrão)
  return (
    <div className="relative shrink-0" style={box}>
      <span className="absolute inset-0" style={{ ...texMask("ring-track"), background: off }} />
      <span className="absolute inset-0" style={{ ...texMask("ring-full"), background: `conic-gradient(${on} ${ring * 3.6}deg, transparent 0deg)` }} />
      <CoreIcon icon={icon} core={core} className="absolute" style={{ inset: "24%" }} />
    </div>
  );
}

// Tamanho da miniatura de cada estilo nos cartões do seletor (cabe em 44px de altura).
const PREVIEW_SIZE = { half: 44, barsV: 28 };

// Seletor de estilo: seis cartões com a miniatura de cada estilo.
export function CoreStylePicker({ value, onChange }) {
  return (
    <div role="radiogroup" aria-label="Core style" className="grid grid-cols-3 gap-3">
      {CORE_STYLES.map((s) => {
        const on = s.value === value;
        return (
          <button
            key={s.value}
            type="button"
            role="radio"
            aria-checked={on}
            onClick={() => onChange(s.value)}
            className={`tx-frame group relative flex h-[92px] min-w-0 cursor-pointer flex-col items-center justify-center gap-3 outline-none ${
              on
                ? "[--frame:var(--kit-accent)]"
                : "[--frame:rgb(var(--kit-text-rgb)/0.18)] hover:[--frame:rgb(var(--kit-text-rgb)/0.42)] focus-visible:[--frame:rgb(var(--kit-text-rgb)/0.42)]"
            }`}
          >
            <span className="grid h-11 place-items-center">
              <CoreMeter variant={s.value} size={PREVIEW_SIZE[s.value] ?? 34} ring={70} core={60} />
            </span>
            <span className={`kit-heading text-[10px] ${on ? "text-ink" : "text-dim group-hover:text-ink"}`}>{s.label}</span>
            {on && <Brackets size={12} />}
          </button>
        );
      })}
    </div>
  );
}
