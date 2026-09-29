import { Icon } from "./Surface.jsx";

const SIZES = {
  sm: "h-9 px-4 text-[11px] gap-2",
  md: "h-11 px-6 text-[12px] gap-2.5",
  lg: "h-13 px-8 text-[13px] gap-3",
};

// variant: primary | secondary | ghost · state: active, disabled (+ forced "hover" for the state reference)
export function Button({
  variant = "secondary",
  size = "md",
  icon,
  active = false,
  forceHover = false,
  className = "",
  children,
  type = "button",
  ...rest
}) {
  const v = variant === "primary" ? "btn-primary" : variant === "ghost" ? "btn-ghost" : "";
  return (
    <button
      type={type}
      className={`btn tx-plate kit-heading inline-flex shrink-0 cursor-pointer items-center justify-center whitespace-nowrap transition-colors active:translate-y-px ${v} ${
        active ? "is-active" : ""
      } ${forceHover ? "is-hover" : ""} ${SIZES[size]} ${className}`}
      {...rest}
    >
      {icon && <Icon name={icon} size={size === "sm" ? 14 : 16} />}
      {children}
    </button>
  );
}

// Square icon-only button on the keycap frame
export function IconButton({ icon, label, size = 40, active = false, className = "", ...rest }) {
  return (
    <button
      type="button"
      aria-label={label}
      title={label}
      className={`btn tx-plate grid shrink-0 cursor-pointer place-items-center transition-colors ${active ? "is-active" : ""} ${className}`}
      style={{ width: size, height: size }}
      {...rest}
    >
      <Icon name={icon} size={Math.round(size * 0.45)} />
    </button>
  );
}
