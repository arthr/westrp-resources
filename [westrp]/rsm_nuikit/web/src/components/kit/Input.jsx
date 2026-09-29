import { Icon } from "./Surface.jsx";

// Text field on the dark selection plate; focus lifts it to the accent tint.
export function TextInput({ value, onChange, placeholder, icon, prefix, suffix, disabled = false, maxLength, inputMode, className = "" }) {
  return (
    <label className={`field tx-plate flex h-11 min-w-0 items-center gap-3 px-4 ${disabled ? "cursor-not-allowed opacity-45" : "cursor-text"} ${className}`}>
      {icon && <Icon name={icon} size={15} className="text-dim" />}
      {prefix && <span className="font-cat text-[14px] text-dim">{prefix}</span>}
      <input
        value={value}
        disabled={disabled}
        maxLength={maxLength}
        inputMode={inputMode}
        placeholder={placeholder}
        spellCheck={false}
        onChange={(e) => onChange(e.target.value)}
        className="min-w-0 flex-1 bg-transparent text-[14px] text-ink caret-accent outline-none placeholder:text-faint disabled:cursor-not-allowed"
      />
      {suffix}
    </label>
  );
}
