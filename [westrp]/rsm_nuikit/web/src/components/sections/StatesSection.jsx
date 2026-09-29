import { useState } from "react";
import { useKit } from "../../state/KitStore.jsx";
import { SectionFrame } from "../shell/SectionFrame.jsx";
import { Button, Card, Checkbox, Counter, Divider, Icon, RowLine, Switch, Tabs, Tag } from "../kit";

function ModuleRow({ m, onToggle }) {
  return (
    <div className={`flex items-center gap-5 px-2 py-3.5 ${m.active ? "" : "opacity-70"}`}>
      <span className="grid h-9 w-9 shrink-0 place-items-center">
        <Icon
          name={m.locked ? "menu-icon-info-lock" : m.active ? "menu-icon-tick" : "cross"}
          size={m.locked ? 18 : 24}
          className={m.active ? (m.locked ? "text-dim" : "text-accent") : "text-faint"}
        />
      </span>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-3">
          <p className={`kit-heading truncate text-[13px] ${m.active ? "text-ink" : "text-dim"}`}>{m.name}</p>
          {m.locked && <Tag kind="locked" />}
        </div>
        <p className="mt-1 truncate text-[13px] text-faint">{m.desc}</p>
      </div>
      <Tag kind="neutral" className="w-[5.5rem] justify-center">
        {m.group}
      </Tag>
      <Switch on={m.active} disabled={m.locked} onChange={onToggle} />
    </div>
  );
}

// Every control in each of its states, side by side.
// `inert`: são estados congelados para consulta, não controles clicáveis.
function StateReference() {
  return (
    <div inert className="flex flex-col gap-6 select-none">
      <div className="flex flex-col gap-3">
        <p className="kit-heading text-[10px] text-faint">Buttons</p>
        <div className="grid grid-cols-2 gap-2.5">
          <Button size="sm">Default</Button>
          <Button size="sm" forceHover>
            Hover
          </Button>
          <Button size="sm" active>
            Active
          </Button>
          <Button size="sm" disabled>
            Inactive
          </Button>
          <Button size="sm" variant="primary">
            Primary
          </Button>
          <Button size="sm" variant="primary" disabled>
            Locked
          </Button>
        </div>
      </div>
      <Divider />
      <div className="flex flex-col gap-2">
        <p className="kit-heading mb-1 text-[10px] text-faint">Menu rows</p>
        <div className="row tx-plate flex items-center justify-between px-4 py-2.5 text-[14px] text-ink">
          Normal <span className="font-cat text-dim">$0.75</span>
        </div>
        <div className="row tx-plate is-current flex items-center justify-between px-4 py-2.5 text-[14px]">
          Selected <span className="font-cat">$1.20</span>
        </div>
        <div className="row tx-plate is-selected flex items-center justify-between px-4 py-2.5 text-[14px] text-ink">
          Marked <Counter size="sm">2</Counter>
        </div>
        <div className="row tx-plate is-inactive flex items-center justify-between px-4 py-2.5 text-[14px]">
          Inactive <span className="kit-heading text-[10px]">Sold out</span>
        </div>
        <div className="row tx-plate is-inactive flex items-center justify-between px-4 py-2.5 text-[14px]">
          Locked <Icon name="menu-icon-info-lock" size={16} className="text-faint" />
        </div>
      </div>
      <Divider />
      <div className="flex flex-col gap-3">
        <p className="kit-heading text-[10px] text-faint">Checks &amp; tags</p>
        <div className="flex flex-wrap gap-x-6 gap-y-3">
          <Checkbox checked={false} onChange={() => {}} label="Off" />
          <Checkbox checked onChange={() => {}} label="On" />
          <Checkbox checked disabled onChange={() => {}} label="Inactive" />
        </div>
        <div className="flex flex-wrap gap-2">
          <Tag kind="active" />
          <Tag kind="inactive" />
          <Tag kind="locked" />
          <Tag kind="new" />
          <Tag kind="warning" />
        </div>
      </div>
    </div>
  );
}

export function StatesSection() {
  const { state, dispatch, notify } = useKit();
  const [filter, setFilter] = useState("all");
  const mods = state.modules;
  const activeCount = mods.filter((m) => m.active).length;
  const shown = mods.filter((m) => filter === "all" || (filter === "active" ? m.active : !m.active));

  const toggle = (m) => {
    dispatch({ type: "module/toggle", id: m.id });
    notify(
      m.active ? "warning" : "success",
      m.active ? `${m.name} Inactive` : `${m.name} Active`,
      "Publish to apply it for every player.",
      { force: m.id === "toasts" },
    );
  };

  return (
    <SectionFrame
      title="Active / Inactive"
      hint="Switch whole components on or off for the server, then Publish. Required modules stay locked on; everything else follows your call, including the HUD layout."
      actions={
        <>
          <Button onClick={() => dispatch({ type: "module/all", active: false })}>Deactivate All</Button>
          <Button variant="primary" onClick={() => dispatch({ type: "module/all", active: true })}>
            Activate All
          </Button>
        </>
      }
    >
      <div className="grid min-w-0 grid-cols-1 gap-6 xl:grid-cols-[minmax(0,1fr)_minmax(0,22rem)]">
        <Card
          title="Module Registry"
          kicker={`${activeCount} of ${mods.length} active`}
          right={
            <Tabs
              size="sm"
              value={filter}
              onChange={setFilter}
              items={[
                { value: "all", label: "All", count: mods.length },
                { value: "active", label: "Active", count: activeCount },
                { value: "inactive", label: "Inactive", count: mods.length - activeCount },
              ]}
            />
          }
        >
          <div className="flex flex-col">
            {shown.map((m, i) => (
              <div key={m.id}>
                {i > 0 && <RowLine />}
                <ModuleRow m={m} onToggle={() => toggle(m)} />
              </div>
            ))}
            {shown.length === 0 && (
              <p className="py-10 text-center text-[14px] text-faint">Nothing {filter} right now.</p>
            )}
          </div>
        </Card>

        <Card title="State Reference" kicker="Every state, side by side" bodyClass="flex flex-col">
          <StateReference />
        </Card>
      </div>
    </SectionFrame>
  );
}
