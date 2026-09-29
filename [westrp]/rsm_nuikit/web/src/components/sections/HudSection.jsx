import { useCallback, useState } from "react";
import { useKit } from "../../state/KitStore.jsx";
import { WIDGETS } from "../hud/HudWidgets.jsx";
import { SectionFrame } from "../shell/SectionFrame.jsx";
import { Card, CoreMeter, CoreStylePicker, Counter, Divider, HoldPrompt, PressPrompt, Prompt, SliderField, Tag } from "../kit";

const CORES = [
  { id: "health", label: "Health", icon: "core-health" },
  { id: "stamina", label: "Stamina", icon: "core-stamina" },
  { id: "deadeye", label: "Dead Eye", icon: "core-deadeye" },
];

// Nome do valor externo em cada estilo (anel, barra ou número)
const OUTER = {
  ring: "Ring", half: "Ring", segmented: "Ring", barsH: "Bar", barsV: "Bar", numeric: "Value",
};
// Tamanho das pré-visualizações: as barras horizontais são largas, então um pouco menores
const PREVIEW = { barsH: 80 };

function CoresCard() {
  const { state, dispatch, isActive } = useKit();
  const variant = state.hud.coreStyle;
  const [vals, setVals] = useState({
    health: { ring: 82, core: 70 },
    stamina: { ring: 64, core: 92 },
    deadeye: { ring: 22, core: 40 },
  });
  const set = (id, key, v) => setVals((s) => ({ ...s, [id]: { ...s[id], [key]: v } }));
  const outer = OUTER[variant];
  return (
    <Card
      title="Core Meters"
      kicker={`${outer} is the outer value · the icon fills with the core`}
      right={<Tag kind={isActive("cores") ? "active" : "inactive"} />}
      bodyClass="grid gap-8 min-[1600px]:grid-cols-[minmax(0,22rem)_minmax(0,1fr)]"
    >
      <div className="flex min-w-0 flex-col gap-3">
        <p className="kit-heading text-[10px] text-faint">Core Style</p>
        <CoreStylePicker value={variant} onChange={(style) => dispatch({ type: "hud/coreStyle", style })} />
        <p className="text-[12.5px] leading-snug text-faint">The chosen style is what players see on the HUD, and what the Layout Manager places.</p>
      </div>
      <div className="grid min-w-0 grid-cols-3 gap-6">
        {CORES.map((c) => (
          <div key={c.id} className="flex min-w-0 flex-col items-center gap-4">
            <div className="grid h-[150px] w-full place-items-center">
              <CoreMeter variant={variant} icon={c.icon} ring={vals[c.id].ring} core={vals[c.id].core} size={PREVIEW[variant] ?? 96} />
            </div>
            <p className="kit-heading text-[12px] text-ink">{c.label}</p>
            <div className="flex w-full flex-col gap-3">
              <SliderField label={outer} value={vals[c.id].ring} onChange={(v) => set(c.id, "ring", v)} format={(v) => `${v}%`} />
              <SliderField label="Core" value={vals[c.id].core} onChange={(v) => set(c.id, "core", v)} format={(v) => `${v}%`} />
            </div>
          </div>
        ))}
      </div>
    </Card>
  );
}

function PromptsCard() {
  const { notify, isActive } = useKit();
  const [robbed, setRobbed] = useState(0);
  const on = isActive("prompts");
  const onComplete = useCallback(() => {
    setRobbed((n) => n + 1);
    notify("warning", "Register Robbed", "You took $18.40. The shopkeeper is running for the law.");
  }, [notify]);
  const onLedger = useCallback(() => {
    notify("info", "Ledger Opened", "General Store · Valentine · 14 items in stock.");
  }, [notify]);
  return (
    <Card title="Hold-Key Prompts" kicker="World interaction" right={<Tag kind={on ? "active" : "inactive"} />} bodyClass="flex flex-col gap-5">
      <div className="flex flex-col gap-2.5">
        <PressPrompt k="R" code="KeyR" label="Open Ledger" onPress={onLedger} disabled={!on} />
        <HoldPrompt k="G" code="KeyG" label="Hold to Rob Register" onComplete={onComplete} disabled={!on} />
        <Prompt k="F" label="Talk to Shopkeeper" dim />
      </div>
      <Divider />
      <div className="flex items-center justify-between gap-4 text-[13px]">
        <span className="text-dim">Tap R to open the ledger. Hold G (or press and hold with the mouse) to rob; let go early and it cancels. The dimmed prompt is unavailable.</span>
        <span className="flex shrink-0 items-center gap-2 text-faint">
          Completed <Counter size="sm">{robbed}</Counter>
        </span>
      </div>
    </Card>
  );
}

function StripCard({ id, title, kicker }) {
  const { isActive } = useKit();
  const Widget = WIDGETS[id];
  return (
    <Card title={title} kicker={kicker} right={<Tag kind={isActive(id) ? "active" : "inactive"} />}>
      <div className="flex h-[56px] items-center justify-center">
        <div className="h-full w-full max-w-[480px]">
          <Widget />
        </div>
      </div>
    </Card>
  );
}

export function HudSection() {
  return (
    <SectionFrame title="HUD Pieces" hint="Always-on overlay pieces. In game they render over the world without taking focus; place them in the Layout Manager.">
      <div className="flex min-w-0 flex-col gap-6">
        <CoresCard />
        <div className="grid min-w-0 grid-cols-[repeat(auto-fit,minmax(26rem,1fr))] gap-6">
          <PromptsCard />
          <div className="flex min-w-0 flex-col gap-6">
            <StripCard id="money" title="Money & Clock" kicker="Wallet · gold · time" />
            <StripCard id="objective" title="Objective Line" kicker="Mission text" />
          </div>
        </div>
      </div>
    </SectionFrame>
  );
}
