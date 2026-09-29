import { Icon } from "./Surface.jsx";

// Checkbox: tick_box frame + tick mark
export function Checkbox({ checked, onChange, label, hint, disabled = false }) {
  return (
    <button
      type="button"
      role="checkbox"
      aria-checked={checked}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={`group flex min-w-0 items-center gap-3 text-left outline-none ${disabled ? "cursor-not-allowed opacity-45" : "cursor-pointer"}`}
    >
      <span className="relative grid h-6 w-6 shrink-0 place-items-center">
        <Icon
          name="tick-box"
          size={24}
          className={disabled ? "text-faint" : "text-dim group-hover:text-ink group-focus-visible:text-accent"}
        />
        {checked && <Icon name="tick" size={22} className="absolute -top-1 left-1 text-accent" />}
      </span>
      {label && (
        <span className="min-w-0">
          <span className="block text-[14px] text-ink">{label}</span>
          {hint && <span className="block text-[12px] text-faint">{hint}</span>}
        </span>
      )}
    </button>
  );
}

// Radio group: ring track + filled dot on the chosen option
export function RadioGroup({ options, value, onChange, disabled = false }) {
  return (
    <div role="radiogroup" className="flex flex-col gap-2.5">
      {options.map((o) => {
        const on = o.value === value;
        return (
          <button
            key={o.value}
            type="button"
            role="radio"
            aria-checked={on}
            disabled={disabled || o.disabled}
            onClick={() => onChange(o.value)}
            className={`group flex items-center gap-3 text-left outline-none ${
              disabled || o.disabled ? "cursor-not-allowed opacity-45" : "cursor-pointer"
            }`}
          >
            <span className="relative grid h-6 w-6 shrink-0 place-items-center">
              <Icon name="ring-track" size={22} className={on ? "text-accent" : "text-dim group-hover:text-ink"} />
              {on && <Icon name="menu-icon-circle" size={10} className="absolute text-accent" />}
            </span>
            <span className="min-w-0">
              <span className={`block text-[14px] ${on ? "text-ink" : "text-dim"}`}>{o.label}</span>
              {o.hint && <span className="block text-[12px] text-faint">{o.hint}</span>}
            </span>
          </button>
        );
      })}
    </div>
  );
}

// Two-state switch on chip plates: the lit half is the current state.
export function Switch({ on, onChange, disabled = false, labels = ["Active", "Inactive"], width = "10.5rem" }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={on}
      disabled={disabled}
      onClick={() => onChange(!on)}
      className={`tx-chip grid shrink-0 grid-cols-2 gap-1 p-1 outline-none ${disabled ? "cursor-not-allowed opacity-50" : "cursor-pointer"}`}
      style={{ width, "--plate": "rgb(0 0 0 / 0.4)" }}
    >
      <span
        className={`tx-chip kit-heading py-1.5 text-center text-[9.5px] ${on ? "text-on-accent" : "text-faint"}`}
        style={{ "--plate": on ? "var(--kit-accent)" : "transparent" }}
      >
        {labels[0]}
      </span>
      <span
        className={`tx-chip kit-heading py-1.5 text-center text-[9.5px] ${on ? "text-faint" : "text-ink"}`}
        style={{ "--plate": on ? "transparent" : "rgb(var(--kit-text-rgb) / 0.16)" }}
      >
        {labels[1]}
      </span>
    </button>
  );
}
