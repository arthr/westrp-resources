import { Icon } from "./Surface.jsx";
import { Counter } from "./Badges.jsx";

function ArrowButton({ dir, onClick, disabled, label }) {
  return (
    <button
      type="button"
      aria-label={label}
      disabled={disabled}
      onClick={onClick}
      className="arrow-btn grid h-7 w-7 shrink-0 cursor-pointer place-items-center"
    >
      <Icon name={`selection-arrow-${dir}`} size={18} />
    </button>
  );
}

const optValue = (o) => (typeof o === "object" ? o.value : o);
const optLabel = (o) => (typeof o === "object" ? o.label : o);

// The classic RDR menu row picker: ‹ value ›, wraps around.
export function ArrowSelector({ options, value, onChange, disabled = false, width = "9rem" }) {
  const i = Math.max(0, options.findIndex((o) => optValue(o) === value));
  const step = (d) => {
    const n = (i + d + options.length) % options.length;
    onChange(optValue(options[n]));
  };
  return (
    <div className={`flex items-center gap-1 ${disabled ? "opacity-45" : ""}`}>
      <ArrowButton dir="left" label="Previous" disabled={disabled} onClick={() => step(-1)} />
      <span className="kit-heading truncate text-center text-[12px] text-ink" style={{ width }}>
        {optLabel(options[i])}
      </span>
      <ArrowButton dir="right" label="Next" disabled={disabled} onClick={() => step(1)} />
    </div>
  );
}

// Quantity stepper: ‹ [n] › clamped to min/max
export function Stepper({ value, onChange, min = 0, max = 99, disabled = false }) {
  return (
    <div className={`flex items-center gap-2 ${disabled ? "opacity-45" : ""}`}>
      <ArrowButton dir="left" label="Decrease" disabled={disabled || value <= min} onClick={() => onChange(Math.max(min, value - 1))} />
      <Counter size="lg">{value}</Counter>
      <ArrowButton dir="right" label="Increase" disabled={disabled || value >= max} onClick={() => onChange(Math.min(max, value + 1))} />
    </div>
  );
}
