// Tab strip on chip plates; the current tab takes the accent plate.
export function Tabs({ items, value, onChange, size = "md", className = "" }) {
  const pad = size === "sm" ? "h-8 px-3.5 text-[10px]" : "h-9 px-4.5 text-[11px]";
  return (
    <div role="tablist" className={`flex flex-wrap items-center gap-1.5 ${className}`}>
      {items.map((it) => {
        const on = it.value === value;
        return (
          <button
            key={it.value}
            type="button"
            role="tab"
            aria-selected={on}
            disabled={it.disabled}
            onClick={() => onChange(it.value)}
            className={`tx-chip kit-heading inline-flex cursor-pointer items-center gap-2 whitespace-nowrap outline-none transition-colors disabled:cursor-not-allowed disabled:opacity-40 ${pad} ${
              on ? "text-on-accent" : "text-dim hover:text-ink focus-visible:text-ink"
            }`}
            style={{ "--plate": on ? "var(--kit-accent)" : "rgb(var(--kit-text-rgb) / 0.06)" }}
          >
            {it.label}
            {it.count != null && <span className={on ? "opacity-80" : "text-faint"}>{it.count}</span>}
          </button>
        );
      })}
    </div>
  );
}
