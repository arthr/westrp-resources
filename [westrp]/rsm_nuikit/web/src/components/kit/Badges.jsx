import { Icon, Brackets } from "./Surface.jsx";

// Quantity counter on the counter plate
export function Counter({ children, size = "md", muted = false, className = "" }) {
  const dims = size === "lg" ? "h-8 min-w-8 px-2.5 text-[14px]" : size === "sm" ? "h-5 min-w-5 px-1.5 text-[10px]" : "h-6 min-w-6 px-2 text-[11px]";
  return (
    <span
      className={`tx-counter inline-grid shrink-0 place-items-center font-cat leading-none ${muted ? "text-ink" : "text-on-accent"} ${dims} ${className}`}
      style={muted ? { "--plate": "rgb(var(--kit-text-rgb) / 0.16)" } : undefined}
    >
      {children}
    </span>
  );
}

const TAGS = {
  active: { icon: "menu-icon-tick", plate: "rgb(var(--kit-accent-rgb) / 0.22)", text: "text-ink", label: "Active" },
  inactive: { icon: "cross", plate: "rgb(var(--kit-text-rgb) / 0.06)", text: "text-faint", label: "Inactive" },
  locked: { icon: "menu-icon-info-lock", plate: "rgb(var(--kit-text-rgb) / 0.1)", text: "text-dim", label: "Required" },
  new: { icon: "menu-icon-info-new", plate: "var(--kit-accent)", text: "text-on-accent", label: "New" },
  warning: { icon: "menu-icon-info-warning", plate: "rgb(var(--kit-accent-rgb) / 0.3)", text: "text-ink", label: "Warning" },
  neutral: { icon: null, plate: "rgb(var(--kit-text-rgb) / 0.08)", text: "text-dim", label: "" },
};

// Status tag: active / inactive / locked / new / warning / neutral
export function Tag({ kind = "neutral", children, className = "" }) {
  const t = TAGS[kind];
  return (
    <span
      className={`tx-chip kit-heading inline-flex h-6 shrink-0 items-center gap-1.5 px-2.5 text-[9.5px] ${t.text} ${className}`}
      style={{ "--plate": t.plate }}
    >
      {t.icon && <Icon name={t.icon} size={11} />}
      {children ?? t.label}
    </span>
  );
}

// Colour swatch on the swatch plate (square art, never stretched)
export function Swatch({ color, size = 36, selected = false, onClick, label }) {
  const El = onClick ? "button" : "span";
  return (
    <El
      type={onClick ? "button" : undefined}
      onClick={onClick}
      title={label ?? color}
      aria-label={label ?? color}
      className={`relative grid shrink-0 place-items-center ${onClick ? "cursor-pointer" : ""}`}
      style={{ width: size + 10, height: size + 10 }}
    >
      <span
        className="ico"
        style={{ width: size, height: size, "--ico": "var(--tex-swatch-bg-1a)", "--ico-fill": color }}
      />
      {selected && <Brackets size={10} fill="var(--kit-text)" />}
    </El>
  );
}
