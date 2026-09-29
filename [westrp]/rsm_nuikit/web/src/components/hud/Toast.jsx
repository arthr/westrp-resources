import { Icon } from "../kit";

const ICONS = {
  info: { name: "menu-icon-invite-sent", tone: "text-ink" },
  success: { name: "menu-icon-tick", tone: "text-ink" },
  warning: { name: "menu-icon-alert", tone: "text-accent" },
  error: { name: "cross", tone: "text-accent" },
};

// Feed notification on the toast plate. `ttl` (ms) draws the draining timer line.
export function Toast({ type = "info", title, body, ttl, width = 380 }) {
  const icon = ICONS[type] ?? ICONS.info;
  return (
    <div className="tx-toast flex items-center gap-4 py-4 pr-6 pl-5 text-left" style={{ width }}>
      <span className="grid h-11 w-11 shrink-0 place-items-center">
        <Icon name={icon.name} size={30} className={icon.tone} />
      </span>
      <div className="min-w-0 flex-1">
        <p className="kit-heading truncate text-[12px] text-ink">{title}</p>
        <p className="mt-1 text-[13px] leading-snug text-dim">{body}</p>
        {ttl && (
          <div
            aria-hidden
            className="ln-h mt-2.5 origin-left"
            style={{ "--line-fill": "var(--kit-accent)", animation: `kit-drain ${ttl}ms linear forwards` }}
          />
        )}
      </div>
    </div>
  );
}
