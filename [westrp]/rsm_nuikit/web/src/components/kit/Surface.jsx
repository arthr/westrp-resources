// Surfaces, icons, lines and selection brackets. Every piece is RDR2 art
// tinted through a mask (see the .tx-* / .ico / .ln-* rules in styles.css).

export const texMask = (name, fit = "contain") => ({
  WebkitMask: `var(--tex-${name}) center / ${fit} no-repeat`,
  mask: `var(--tex-${name}) center / ${fit} no-repeat`,
});

export function Icon({ name, size = 20, fill, className = "", style }) {
  return (
    <span
      aria-hidden
      className={`ico inline-block ${className}`}
      style={{ width: size, height: size, "--ico": `var(--tex-${name})`, ...(fill ? { "--ico-fill": fill } : null), ...style }}
    />
  );
}

export function Divider({ className = "", fill }) {
  return <div aria-hidden className={`ln-h w-full shrink-0 ${className}`} style={fill ? { "--line-fill": fill } : undefined} />;
}

export function RowLine({ className = "" }) {
  return <div aria-hidden className={`ln-wide w-full shrink-0 ${className}`} />;
}

export function VDivider({ className = "" }) {
  return <div aria-hidden className={`ln-v shrink-0 self-stretch ${className}`} />;
}

// The inventory selection brackets: all four corners, always on the same box.
const CORNERS = [
  ["tl", { top: 0, left: 0 }],
  ["tr", { top: 0, right: 0 }],
  ["bl", { bottom: 0, left: 0 }],
  ["br", { bottom: 0, right: 0 }],
];

export function Brackets({ size = 14, fill = "var(--kit-accent)" }) {
  return CORNERS.map(([c, pos]) => (
    <span
      key={c}
      aria-hidden
      className="ico pointer-events-none absolute"
      style={{ ...pos, width: size, height: size, "--ico": `var(--tex-crafting-highlight-${c})`, "--ico-fill": fill }}
    />
  ));
}

export function Card({ title, kicker, right, children, className = "", bodyClass = "", solid = false }) {
  return (
    <section className={`${solid ? "tx-card-solid" : "tx-card"} flex min-h-0 min-w-0 flex-col gap-4 px-7 py-6 ${className}`}>
      {(title || right) && (
        <>
          <header className="flex items-start justify-between gap-4">
            <div className="min-w-0">
              {kicker && <p className="kit-heading mb-1 text-[10px] text-faint">{kicker}</p>}
              <h3 className="kit-heading text-[15px] leading-tight text-ink">{title}</h3>
            </div>
            {right && <div className="flex shrink-0 items-center gap-2">{right}</div>}
          </header>
          <Divider />
        </>
      )}
      <div className={`min-h-0 min-w-0 ${bodyClass}`}>{children}</div>
    </section>
  );
}

// A labelled row used inside cards: label on the left, control on the right.
export function Field({ label, hint, children, className = "" }) {
  return (
    <div className={`flex min-w-0 items-center justify-between gap-5 ${className}`}>
      <div className="min-w-0">
        <p className="text-[14px] text-ink">{label}</p>
        {hint && <p className="mt-0.5 text-[12px] text-faint">{hint}</p>}
      </div>
      <div className="flex shrink-0 items-center gap-3">{children}</div>
    </div>
  );
}
