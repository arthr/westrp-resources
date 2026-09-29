import { useKit } from "../../state/KitStore.jsx";
import { SECTIONS, THEME_PRESETS, LAYOUT_PRESETS } from "../../state/mock.js";
import { Button, Divider, Swatch, Counter, Tag } from "../kit";

export function Sidebar() {
  const { state, dispatch, dirty, publish, discard } = useKit();
  const active = state.modules.filter((m) => m.active).length;
  const theme = THEME_PRESETS.find((p) => p.id === state.theme.preset);
  const layout = LAYOUT_PRESETS[state.layout.preset];

  return (
    <aside className="flex min-h-0 min-w-0 flex-col gap-6">
      <div className="tx-header px-6 pt-6 pb-5 text-center">
        <p className="kit-heading text-[10px] text-faint">RedM · rsm_nuikit</p>
        <h1 className="mt-2 font-title text-[40px] leading-[0.9] text-ink">Components</h1>
        <p className="kit-heading mt-2 text-[10px] text-dim">Kit Studio</p>
      </div>

      <nav className="flex min-h-0 flex-1 flex-col gap-1.5 overflow-y-auto pr-1">
        {SECTIONS.map((s, i) => {
          const current = state.section === s.id;
          return (
            <button
              key={s.id}
              type="button"
              onClick={() => dispatch({ type: "section", id: s.id })}
              aria-current={current ? "page" : undefined}
              className={`row tx-plate flex shrink-0 cursor-pointer items-center gap-3.5 px-4 py-3 text-left transition-colors ${
                current ? "is-current" : "text-ink"
              }`}
            >
              <span className="w-6 shrink-0 font-cat text-[14px] opacity-60">{String(i + 1).padStart(2, "0")}</span>
              <span className="min-w-0">
                <span className="kit-heading block truncate text-[12px]">{s.label}</span>
                <span className="mt-0.5 block truncate text-[12px] opacity-65">{s.hint}</span>
              </span>
            </button>
          );
        })}
      </nav>

      <Divider />

      <div className="flex flex-col gap-3.5 text-[13px]">
        <div className="flex items-center justify-between gap-3">
          <span className="text-dim">Theme</span>
          <span className="flex items-center">
            <Swatch color={state.theme.accent} size={16} label="Accent" />
            <Swatch color={state.theme.text} size={16} label="Text" />
            <span className="kit-heading ml-1.5 text-[10px] text-ink">{theme ? theme.name : "Custom"}</span>
          </span>
        </div>
        <div className="flex items-center justify-between gap-3">
          <span className="text-dim">Layout</span>
          <span className="kit-heading text-[10px] text-ink">{layout ? layout.label : "Custom"}</span>
        </div>
        <div className="flex items-center justify-between gap-3">
          <span className="text-dim">Modules active</span>
          <Counter>
            {active}/{state.modules.length}
          </Counter>
        </div>
      </div>

      {/* nada muda para os jogadores até publicar; o servidor valida e salva */}
      <div className="flex flex-col gap-2.5">
        <div className="flex items-center justify-between gap-3 text-[13px]">
          <span className="text-dim">Server</span>
          <Tag kind={dirty ? "warning" : "active"}>{dirty ? "Unpublished" : "Published"}</Tag>
        </div>
        <div className="grid grid-cols-2 gap-2">
          <Button size="sm" onClick={discard} disabled={!dirty}>
            Discard
          </Button>
          <Button size="sm" variant="primary" onClick={publish} disabled={!dirty}>
            Publish
          </Button>
        </div>
      </div>
    </aside>
  );
}
