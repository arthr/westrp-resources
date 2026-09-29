import { Divider } from "../kit";

// Section header (title, hint, actions) over a body that scrolls inside itself.
export function SectionFrame({ title, hint, actions, children }) {
  return (
    <section className="flex min-h-0 min-w-0 flex-1 flex-col gap-5">
      <header className="flex items-end justify-between gap-6">
        <div className="min-w-0">
          <h2 className="kit-heading text-[24px] leading-none text-ink">{title}</h2>
          <p className="mt-2 text-[14px] text-dim">{hint}</p>
        </div>
        {actions && <div className="flex shrink-0 items-center gap-3">{actions}</div>}
      </header>
      <Divider />
      <div className="min-h-0 flex-1 overflow-y-auto pr-3 pb-2">{children}</div>
    </section>
  );
}
