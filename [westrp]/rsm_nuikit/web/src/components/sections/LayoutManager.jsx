import { useEffect, useRef, useState } from "react";
import { useKit } from "../../state/KitStore.jsx";
import { ANCHORS, ANCHOR_NAMES, LAYOUT_PRESETS, WIDGET_META } from "../../state/mock.js";
import { anchorBox, nearestAnchor } from "../hud/anchor.js";
import { WIDGETS, widgetDims } from "../hud/HudWidgets.jsx";
import { SectionFrame } from "../shell/SectionFrame.jsx";
import {
  ArrowSelector, Brackets, Button, Card, Checkbox, CORE_STYLES, Field, Icon, SliderField, Switch, Tabs, Tag,
} from "../kit";

const OFFSET = 40; // max ± offset, % of the screen
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const round1 = (v) => Math.round(v * 10) / 10;
const SCALES = Array.from({ length: 17 }, (_, i) => 60 + i * 5).map((v) => ({ value: v, label: `${v}%` }));

// ── mini screen ──────────────────────────────────────────────────────────────
function MiniScreen() {
  const { state, dispatch, isActive } = useKit();
  const { widgets, safeZone, selected, snap, grid } = state.layout;
  const canvasRef = useRef(null);
  const dragRef = useRef(null);
  const [width, setWidth] = useState(640);
  const [dragging, setDragging] = useState(null);

  useEffect(() => {
    const el = canvasRef.current;
    const ro = new ResizeObserver(([entry]) => setWidth(entry.contentRect.width));
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  const screenScale = width / 1920;

  const onDown = (e, id) => {
    dispatch({ type: "layout/select", id });
    e.currentTarget.setPointerCapture(e.pointerId);
    dragRef.current = { id, sx: e.clientX, sy: e.clientY, x0: widgets[id].x, y0: widgets[id].y, moved: false };
    setDragging(id);
  };

  const onMove = (e) => {
    const d = dragRef.current;
    if (!d) return;
    const r = canvasRef.current.getBoundingClientRect();
    const dx = ((e.clientX - d.sx) / r.width) * 100;
    const dy = ((e.clientY - d.sy) / r.height) * 100;
    // Só vira arraste depois de passar o limiar: um clique apenas seleciona.
    if (!d.moved && Math.abs(dx) + Math.abs(dy) <= 0.4) return;
    d.moved = true;
    dispatch({
      type: "layout/widget",
      id: d.id,
      patch: { x: round1(clamp(d.x0 + dx, -OFFSET, OFFSET)), y: round1(clamp(d.y0 + dy, -OFFSET, OFFSET)) },
    });
  };

  const onUp = (e) => {
    const d = dragRef.current;
    dragRef.current = null;
    setDragging(null);
    if (!d || !d.moved || !snap) return;
    const r = canvasRef.current.getBoundingClientRect();
    const el = e.currentTarget.getBoundingClientRect();
    const anchor = nearestAnchor((el.left + el.width / 2 - r.left) / r.width, (el.top + el.height / 2 - r.top) / r.height);
    dispatch({ type: "layout/widget", id: d.id, patch: { anchor, x: 0, y: 0 } });
  };

  return (
    <div
      ref={canvasRef}
      className="tx-frame relative aspect-video w-full overflow-hidden"
      style={{
        "--frame": "rgb(var(--kit-text-rgb) / 0.35)",
        background: "linear-gradient(rgb(0 0 0 / 0.3), rgb(0 0 0 / 0.3)), var(--rsm-backdrop) center / cover no-repeat",
      }}
    >
      {grid && (
        <>
          <div className="ln-v absolute inset-y-0 left-1/3" />
          <div className="ln-v absolute inset-y-0 left-2/3" />
          <div className="ln-h absolute inset-x-0 top-1/3" />
          <div className="ln-h absolute inset-x-0 top-2/3" />
        </>
      )}
      {/* safe zone */}
      <div
        className="tx-frame pointer-events-none absolute"
        style={{ inset: `${safeZone}%`, "--frame": "rgb(var(--kit-accent-rgb) / 0.55)" }}
      />
      {/* anchor points */}
      {ANCHORS.map((a) => {
        const b = anchorBox(a, 0, 0, safeZone);
        return (
          <span
            key={a}
            className="pointer-events-none absolute grid"
            style={{ left: `${b.left}%`, top: `${b.top}%`, transform: "translate(-50%, -50%)" }}
          >
            <Icon name="diamond" size={9} className="text-accent opacity-70" />
          </span>
        );
      })}

      {Object.entries(widgets).map(([id, w]) => {
        if (!isActive(id)) return null;
        const Widget = WIDGETS[id];
        const [dw, dh] = widgetDims(id, state.hud.coreStyle);
        const s = screenScale * (w.scale / 100);
        const b = anchorBox(w.anchor, w.x, w.y, safeZone);
        const isSel = selected === id;
        return (
          <div
            key={id}
            role="button"
            tabIndex={0}
            aria-label={`${WIDGET_META[id].label}, ${ANCHOR_NAMES[w.anchor]}`}
            onPointerDown={(e) => onDown(e, id)}
            onPointerMove={onMove}
            onPointerUp={onUp}
            onPointerCancel={onUp}
            onKeyDown={(e) => e.key === "Enter" && dispatch({ type: "layout/select", id })}
            className={`absolute touch-none outline-none select-none ${dragging === id ? "cursor-grabbing" : "cursor-grab"} ${
              isSel ? "z-10" : "opacity-85 hover:opacity-100"
            }`}
            style={{
              left: `${b.left}%`,
              top: `${b.top}%`,
              width: dw * s,
              height: dh * s,
              transform: `translate(${b.tx}%, ${b.ty}%)`,
            }}
          >
            <div className="pointer-events-none" style={{ width: dw, height: dh, transform: `scale(${s})`, transformOrigin: "top left" }}>
              <Widget />
            </div>
            {isSel && <Brackets size={10} />}
          </div>
        );
      })}
    </div>
  );
}

// ── anchor picker ────────────────────────────────────────────────────────────
function AnchorPicker({ value, onChange }) {
  return (
    <div className="grid w-max grid-cols-3 gap-2">
      {ANCHORS.map((a) => {
        const on = a === value;
        return (
          <button
            key={a}
            type="button"
            title={ANCHOR_NAMES[a]}
            aria-label={ANCHOR_NAMES[a]}
            aria-pressed={on}
            onClick={() => onChange(a)}
            className={`tx-frame group grid h-11 w-11 cursor-pointer place-items-center outline-none ${on ? "text-accent" : "text-faint hover:text-ink"}`}
            style={{ "--frame": on ? "var(--kit-accent)" : "rgb(var(--kit-text-rgb) / 0.2)" }}
          >
            <Icon name="diamond" size={on ? 14 : 9} />
          </button>
        );
      })}
    </div>
  );
}

// ── section ─────────────────────────────────────────────────────────────────
export function LayoutManager() {
  const { state, dispatch, isActive } = useKit();
  const { widgets, selected, preset, safeZone, snap, grid } = state.layout;
  const w = widgets[selected];
  const meta = WIDGET_META[selected];
  const module = state.modules.find((m) => m.id === selected);
  const update = (patch) => dispatch({ type: "layout/widget", id: selected, patch });

  const presetTabs = [
    ...Object.entries(LAYOUT_PRESETS).map(([id, p]) => ({ value: id, label: p.label })),
    ...(preset === "custom" ? [{ value: "custom", label: "Custom" }] : []),
  ];

  return (
    <SectionFrame
      title="Layout Manager"
      hint="Place every HUD piece on a 9-point anchor grid, nudge it with offsets and scale it, then Publish. Drag on the mini screen or use the inspector."
      actions={<Button onClick={() => dispatch({ type: "layout/preset", id: "classic" })}>Reset to Classic</Button>}
    >
      <div className="flex min-w-0 flex-col gap-6">
        {/* toolbar */}
        <div className="flex flex-wrap items-center justify-between gap-x-8 gap-y-4">
          <Tabs items={presetTabs} value={preset} onChange={(id) => id !== "custom" && dispatch({ type: "layout/preset", id })} />
          <div className="flex flex-wrap items-center gap-7">
            <Checkbox checked={snap} onChange={(v) => dispatch({ type: "layout/set", patch: { snap: v } })} label="Snap to anchors" />
            <Checkbox checked={grid} onChange={(v) => dispatch({ type: "layout/set", patch: { grid: v } })} label="Thirds grid" />
            <div className="w-52">
              <SliderField
                label="Safe zone"
                value={safeZone}
                min={0}
                max={10}
                step={0.5}
                format={(v) => `${v}%`}
                onChange={(v) => dispatch({ type: "layout/set", patch: { safeZone: v, preset: "custom" } })}
              />
            </div>
          </div>
        </div>

        <div className="grid min-w-0 grid-cols-2 gap-6 min-[1600px]:grid-cols-[minmax(0,15rem)_minmax(0,1fr)_minmax(0,19rem)]">
          {/* widget list */}
          <Card title="Widgets" kicker={`${Object.keys(widgets).length} HUD pieces`} bodyClass="flex flex-col gap-1.5">
            {Object.entries(widgets).map(([id, wd]) => {
              const on = isActive(id);
              return (
                <button
                  key={id}
                  type="button"
                  onClick={() => dispatch({ type: "layout/select", id })}
                  className={`row tx-plate flex cursor-pointer items-center justify-between gap-2 px-3.5 py-2.5 text-left ${
                    selected === id ? "is-selected" : ""
                  } ${on ? "text-ink" : "is-inactive"}`}
                >
                  <span className="min-w-0">
                    <span className="block truncate text-[14px]">{WIDGET_META[id].label}</span>
                    <span className="block text-[11.5px] text-faint">{on ? ANCHOR_NAMES[wd.anchor] : "Inactive"}</span>
                  </span>
                  <span className="kit-heading shrink-0 font-cat text-[11px] text-dim">{wd.anchor.toUpperCase()}</span>
                </button>
              );
            })}
          </Card>

          {/* mini screen */}
          <div className="order-first col-span-2 flex min-w-0 flex-col gap-3 min-[1600px]:order-none min-[1600px]:col-span-1">
            <MiniScreen />
            <div className="flex items-center justify-between gap-4 text-[12.5px] text-faint">
              <span>1920 × 1080 reference · safe zone in red · diamonds mark the anchors</span>
              <span className="font-cat text-dim">{Object.keys(widgets).filter(isActive).length} visible</span>
            </div>
          </div>

          {/* inspector */}
          <Card title={meta.label} kicker="Inspector" right={<Tag kind={module?.active ? "active" : "inactive"} />} bodyClass="flex flex-col gap-5">
            <Field label="Shown on HUD" hint={module?.locked ? "Required module" : meta.size}>
              <Switch
                on={!!module?.active}
                disabled={module?.locked}
                labels={["On", "Off"]}
                width="7.5rem"
                onChange={() => dispatch({ type: "module/toggle", id: selected })}
              />
            </Field>
            <div className="flex items-start justify-between gap-5">
              <div className="min-w-0">
                <p className="text-[14px] text-ink">Anchor</p>
                <p className="mt-0.5 text-[12px] text-faint">{ANCHOR_NAMES[w.anchor]}</p>
              </div>
              <AnchorPicker value={w.anchor} onChange={(a) => update({ anchor: a })} />
            </div>
            <SliderField label="Offset X" value={w.x} min={-OFFSET} max={OFFSET} step={0.5} centered format={(v) => `${v > 0 ? "+" : ""}${v}%`} onChange={(v) => update({ x: v })} />
            <SliderField label="Offset Y" value={w.y} min={-OFFSET} max={OFFSET} step={0.5} centered format={(v) => `${v > 0 ? "+" : ""}${v}%`} onChange={(v) => update({ y: v })} />
            <Field label="Scale">
              <ArrowSelector options={SCALES} value={w.scale} onChange={(v) => update({ scale: v })} width="4.5rem" />
            </Field>
            {selected === "cores" && (
              <Field label="Style">
                <ArrowSelector
                  options={CORE_STYLES}
                  value={state.hud.coreStyle}
                  onChange={(style) => dispatch({ type: "hud/coreStyle", style })}
                  width="6.5rem"
                />
              </Field>
            )}
            <Button size="sm" variant="ghost" onClick={() => update({ x: 0, y: 0, scale: 100 })}>
              Clear Offsets &amp; Scale
            </Button>
          </Card>
        </div>
      </div>
    </SectionFrame>
  );
}
