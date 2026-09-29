// Segmented weapon-stat bar at the art's own 13:1 ratio
export function StatBar({ value, width = 208, dim = false }) {
  const fill = dim ? "rgb(var(--kit-text-rgb) / 0.35)" : "var(--kit-text)";
  return (
    <div
      className="tx-stat shrink-0"
      style={{ width, background: `linear-gradient(90deg, ${fill} ${value}%, rgb(var(--kit-text-rgb) / 0.14) ${value}%)` }}
    />
  );
}

// Progress bar on the menu_bar art; omit value for the indeterminate loader.
export function ProgressBar({ value, className = "" }) {
  const track = "rgb(var(--kit-text-rgb) / 0.14)";
  if (value == null) {
    return (
      <div className={`tx-bar relative w-full overflow-hidden ${className}`} style={{ background: track }}>
        <span
          className="absolute inset-y-0 left-0 w-2/5"
          style={{ background: "var(--kit-accent)", animation: "kit-load 1.5s ease-in-out infinite" }}
        />
      </div>
    );
  }
  return (
    <div
      className={`tx-bar w-full transition-[background] ${className}`}
      style={{ background: `linear-gradient(90deg, var(--kit-accent) ${value}%, ${track} ${value}%)` }}
    />
  );
}
