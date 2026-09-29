import { useRef } from "react";
import { Icon } from "./Surface.jsx";

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

// Bar slider on the menu_bar art. `centered` fills from the middle (for ± offsets).
export function Slider({ value, onChange, min = 0, max = 100, step = 1, disabled = false, centered = false, label }) {
  const trackRef = useRef(null);
  const pct = ((value - min) / (max - min)) * 100;
  const zero = centered ? ((0 - min) / (max - min)) * 100 : 0;
  const lo = Math.min(zero, pct);
  const hi = Math.max(zero, pct);

  const setFromX = (clientX) => {
    const r = trackRef.current.getBoundingClientRect();
    const t = clamp((clientX - r.left) / r.width, 0, 1);
    const raw = min + t * (max - min);
    const next = clamp(Math.round(raw / step) * step, min, max);
    if (next !== value) onChange(Number(next.toFixed(4)));
  };

  const onPointerDown = (e) => {
    if (disabled) return;
    e.currentTarget.setPointerCapture(e.pointerId);
    setFromX(e.clientX);
  };
  const onPointerMove = (e) => {
    if (!disabled && e.currentTarget.hasPointerCapture(e.pointerId)) setFromX(e.clientX);
  };
  const onKeyDown = (e) => {
    if (disabled) return;
    if (e.key === "ArrowLeft" || e.key === "ArrowDown") {
      e.preventDefault();
      onChange(clamp(value - step, min, max));
    }
    if (e.key === "ArrowRight" || e.key === "ArrowUp") {
      e.preventDefault();
      onChange(clamp(value + step, min, max));
    }
  };

  const track = "rgb(var(--kit-text-rgb) / 0.14)";
  const fill = disabled ? "rgb(var(--kit-text-rgb) / 0.22)" : "var(--kit-accent)";

  return (
    <div
      ref={trackRef}
      role="slider"
      tabIndex={disabled ? -1 : 0}
      aria-label={label}
      aria-valuemin={min}
      aria-valuemax={max}
      aria-valuenow={value}
      aria-disabled={disabled}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onKeyDown={onKeyDown}
      className={`group relative flex h-7 w-full min-w-0 touch-none items-center outline-none select-none ${
        disabled ? "cursor-not-allowed opacity-55" : "cursor-pointer"
      }`}
    >
      <div
        className="tx-bar w-full"
        style={{ background: `linear-gradient(90deg, ${track} ${lo}%, ${fill} ${lo}%, ${fill} ${hi}%, ${track} ${hi}%)` }}
      />
      <span
        className="pointer-events-none absolute top-1/2 grid"
        style={{ left: `${pct}%`, transform: "translate(-50%, -50%)" }}
      >
        <Icon name="diamond" size={16} className={disabled ? "text-faint" : "text-ink group-focus-visible:text-accent"} />
      </span>
    </div>
  );
}

// Slider with a label row and a value readout
export function SliderField({ label, value, format = (v) => v, ...rest }) {
  return (
    <div className="flex min-w-0 flex-col gap-1.5">
      <div className="flex items-baseline justify-between gap-3">
        <span className="text-[13px] text-dim">{label}</span>
        <span className="font-cat text-[13px] text-ink">{format(value)}</span>
      </div>
      <Slider value={value} label={label} {...rest} />
    </div>
  );
}
