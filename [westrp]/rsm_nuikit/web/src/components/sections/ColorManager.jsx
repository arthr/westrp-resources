import { useState } from "react";
import { useKit } from "../../state/KitStore.jsx";
import { ROLES, ROLE_SWATCHES, THEME_PRESETS } from "../../state/mock.js";
import { contrast, hexToHsl, hslToHex, isHex, onAccent } from "../../lib/theme.js";
import { SectionFrame } from "../shell/SectionFrame.jsx";
import {
  Brackets, Button, Card, Checkbox, Divider, Field, ProgressBar, SliderField, Swatch, Switch, Tag, TextInput,
} from "../kit";

function PresetRow({ preset, current, onPick }) {
  return (
    <button
      type="button"
      onClick={onPick}
      className={`row tx-plate relative flex cursor-pointer items-center justify-between gap-3 px-3.5 py-2.5 text-left ${current ? "is-selected" : ""}`}
    >
      <span className="kit-heading truncate text-[11px] text-ink">{preset.name}</span>
      <span className="flex shrink-0">
        <Swatch color={preset.accent} size={16} />
        <Swatch color={preset.surface} size={16} />
        <Swatch color={preset.text} size={16} />
      </span>
      {current && <Brackets size={10} />}
    </button>
  );
}

function RoleRow({ role, color, current, onPick }) {
  return (
    <button
      type="button"
      onClick={onPick}
      className={`row tx-plate flex cursor-pointer items-center gap-3.5 px-3.5 py-3 text-left ${current ? "is-selected" : ""}`}
    >
      <Swatch color={color} size={30} />
      <span className="min-w-0 flex-1">
        <span className="flex items-baseline justify-between gap-2">
          <span className="kit-heading text-[12px] text-ink">{role.label}</span>
          <span className="font-cat text-[12px] text-dim">{color}</span>
        </span>
        <span className="mt-0.5 block text-[12px] leading-snug text-faint">{role.desc}</span>
      </span>
    </button>
  );
}

// Custom mixer: HSL sliders + hex field for the selected role. The hex field
// holds a draft only while it is invalid, so half-typed values never reach the theme.
function Mixer({ role, color, onChange }) {
  // HSL fica em estado local: um hex cinza não guarda matiz, então derivar
  // sempre do hex fazia o matiz voltar a 0° ao zerar a saturação.
  const [hsl, setHslState] = useState(() => hexToHsl(color));
  const [synced, setSynced] = useState(color);
  if (color !== synced) {
    setSynced(color);
    if (hslToHex(hsl) !== color) setHslState(hexToHsl(color));
  }
  const [draft, setDraft] = useState(null);
  const shown = draft ?? color;
  const setHsl = (patch) => {
    const next = { ...hsl, ...patch };
    const hex = hslToHex(next);
    setDraft(null);
    setHslState(next);
    setSynced(hex);
    onChange(hex);
  };

  return (
    <div className="flex flex-col gap-5">
      <div className="flex items-center gap-5">
        <Swatch color={color} size={84} />
        <div className="flex min-w-0 flex-1 flex-col gap-2">
          <p className="kit-heading text-[11px] text-dim">{role.label} colour</p>
          <TextInput
            value={shown}
            maxLength={7}
            onChange={(v) => {
              const next = (v.startsWith("#") ? v : `#${v}`).toUpperCase();
              if (isHex(next)) {
                setDraft(null);
                onChange(next);
              } else {
                setDraft(next);
              }
            }}
          />
          <p className={`text-[12px] ${isHex(shown) ? "text-faint" : "text-accent"}`}>
            {isHex(shown) ? "Six-digit hex, e.g. #CB0101" : "Not a valid hex yet"}
          </p>
        </div>
      </div>
      <div className="flex flex-wrap gap-0.5">
        {ROLE_SWATCHES[role.id].map((c) => (
          <Swatch
            key={c}
            color={c}
            size={30}
            selected={c === color}
            onClick={() => {
              setDraft(null);
              onChange(c);
            }}
          />
        ))}
      </div>
      <Divider />
      <SliderField label="Hue" value={hsl.h} min={0} max={359} format={(v) => `${v}°`} onChange={(v) => setHsl({ h: v })} />
      <SliderField label="Saturation" value={hsl.s} min={0} max={100} format={(v) => `${v}%`} onChange={(v) => setHsl({ s: v })} />
      <SliderField label="Lightness" value={hsl.l} min={0} max={100} format={(v) => `${v}%`} onChange={(v) => setHsl({ l: v })} />
    </div>
  );
}

function ContrastRow({ label, ratio }) {
  const pass = ratio >= 4.5;
  const large = ratio >= 3;
  return (
    <div className="flex items-center justify-between gap-3 text-[13px]">
      <span className="text-dim">{label}</span>
      <span className="flex items-center gap-2.5">
        <span className="font-cat text-[14px] text-ink">{ratio.toFixed(2)}:1</span>
        <Tag kind={pass ? "active" : large ? "warning" : "inactive"}>{pass ? "AA" : large ? "Large only" : "Fail"}</Tag>
      </span>
    </div>
  );
}

// A small menu built from the kit, so every change is visible in context.
function LivePreview() {
  const { notify } = useKit();
  const [on, setOn] = useState(true);
  const [check, setCheck] = useState(true);
  const rows = ["Coffee", "Canned Beans", "Whiskey"];
  const [sel, setSel] = useState(1);
  const price = (0.75 + sel * 0.45) * (check ? 2 : 1);
  const buy = () =>
    notify("success", `Bought ${rows[sel]}`, `${check ? "A double" : "A single"} for $${price.toFixed(2)}, ${on ? "put on your tab" : "paid in cash"}.`);
  return (
    <div className="flex flex-col gap-4">
      <div className="tx-header px-5 py-3.5 text-center">
        <p className="font-title text-[28px] leading-none text-ink">Saloon</p>
      </div>
      <div className="flex flex-col gap-1.5">
        {rows.map((r, i) => (
          <button
            key={r}
            type="button"
            onClick={() => setSel(i)}
            className={`row tx-plate flex cursor-pointer items-center justify-between px-4 py-2.5 text-[14px] ${sel === i ? "is-current" : "text-ink"}`}
          >
            <span>{r}</span>
            <span className="font-cat">${(0.75 + i * 0.45).toFixed(2)}</span>
          </button>
        ))}
      </div>
      <Field label="Tab open">
        <Switch on={on} onChange={setOn} labels={["Yes", "No"]} width="7rem" />
      </Field>
      <Checkbox checked={check} onChange={setCheck} label="Pour a double" />
      <ProgressBar value={62} />
      <div className="flex gap-2.5">
        <Button variant="primary" size="sm" className="flex-1" onClick={buy}>
          Buy
        </Button>
        <Button size="sm" className="flex-1" onClick={() => notify("info", "Left the Saloon", "Back out on the Valentine boardwalk.")}>
          Back
        </Button>
      </div>
    </div>
  );
}

export function ColorManager() {
  const { state, dispatch } = useKit();
  const t = state.theme;
  const role = ROLES.find((r) => r.id === t.role);
  const setColor = (hex) => dispatch({ type: "theme/set", patch: { [t.role]: hex } });
  const presetName = THEME_PRESETS.find((p) => p.id === t.preset)?.name ?? "Custom";

  return (
    <SectionFrame
      title="Color Manager"
      hint="Every surface, fill and state in the kit reads from these three roles. Pick a preset or mix your server's own colours, then Publish."
      actions={<Button onClick={() => dispatch({ type: "theme/preset", id: "blood" })}>Reset to Blood &amp; Black</Button>}
    >
      <div className="grid min-w-0 grid-cols-[minmax(0,20rem)_minmax(0,1fr)] gap-6 min-[1600px]:grid-cols-[minmax(0,20rem)_minmax(0,1fr)_minmax(0,19rem)]">
        <div className="flex min-w-0 flex-col gap-6">
          <Card title="Theme Presets" kicker={presetName} bodyClass="flex flex-col gap-1.5">
            {THEME_PRESETS.map((p) => (
              <PresetRow key={p.id} preset={p} current={t.preset === p.id} onPick={() => dispatch({ type: "theme/preset", id: p.id })} />
            ))}
          </Card>
          <Card title="Roles" kicker="Select one to edit" bodyClass="flex flex-col gap-1.5">
            {ROLES.map((r) => (
              <RoleRow key={r.id} role={r} color={t[r.id]} current={t.role === r.id} onPick={() => dispatch({ type: "theme/role", role: r.id })} />
            ))}
          </Card>
        </div>

        <div className="flex min-w-0 flex-col gap-6">
          <Card title={`Mix ${role.label}`} kicker="Custom mixer">
            <Mixer key={role.id} role={role} color={t[role.id]} onChange={setColor} />
          </Card>
          <Card title="Surface & Legibility" kicker="Checks against WCAG" bodyClass="flex flex-col gap-4">
            <SliderField
              label="Panel opacity"
              value={t.surfaceAlpha}
              min={70}
              max={100}
              format={(v) => `${v}%`}
              onChange={(v) => dispatch({ type: "theme/set", patch: { surfaceAlpha: v }, keepPreset: true })}
            />
            <Divider />
            <ContrastRow label="Text on surface" ratio={contrast(t.text, t.surface)} />
            <ContrastRow label="Accent on surface" ratio={contrast(t.accent, t.surface)} />
            <ContrastRow label="Label on accent button" ratio={contrast(onAccent(t.accent), t.accent)} />
          </Card>
        </div>

        <Card title="Live Preview" kicker="Updates as you mix" solid className="col-span-2 min-[1600px]:col-span-1" bodyClass="flex flex-col">
          <LivePreview />
        </Card>
      </div>
    </SectionFrame>
  );
}
