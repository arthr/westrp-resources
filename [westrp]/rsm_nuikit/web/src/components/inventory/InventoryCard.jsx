import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { useKit } from "../../state/KitStore.jsx";
import {
  ITEM_DEFS, CATEGORIES, SORTS, applyDrop, autoSort, firstEmpty, grabQty, planDrop, splitOff, takeFrom,
} from "../../state/inventory.js";
import { ArrowSelector, Button, Card, Divider, Icon, ItemSlot, Stepper, Tabs, Tag } from "../kit";

const MODES = [
  { value: "stack", label: "Stack" },
  { value: "half", label: "Half" },
  { value: "one", label: "One" },
  { value: "amount", label: "Amount" },
];
const MODE_NAMES = { stack: "the whole stack", half: "half the stack", one: "one item", amount: "the chosen amount" };
const DRAG_START = 5; // px de movimento antes de um clique virar arraste
const USABLE = ["provisions", "medicine"];

// Atalhos no momento de pegar: Shift = metade, Ctrl = um, Alt = quantidade.
const modeFromEvent = (e, mode) => (e.shiftKey ? "half" : e.ctrlKey || e.metaKey ? "one" : e.altKey ? "amount" : mode);

// O que está sob o ponteiro: índice do slot, "ground", ou null (fora de tudo).
function targetAt(x, y) {
  const el = document.elementFromPoint(x, y);
  const hit = el && el.closest("[data-slot],[data-zone]");
  if (!hit) return null;
  return hit.dataset.zone ? hit.dataset.zone : Number(hit.dataset.slot);
}

const resolve = (s) => (s ? { ...ITEM_DEFS[s.id], qty: s.qty } : null);

// A pilha na mão segue o ponteiro. Portal no body: dentro do painel (que tem
// transform) um position:fixed seria relativo ao painel, não à tela.
function DragGhost({ drag, item }) {
  return createPortal(
    <div
      aria-hidden
      className="pointer-events-none fixed z-[60]"
      style={{
        left: drag.x,
        top: drag.y,
        transform: "translate(-50%, -50%) scale(1.08)",
        filter: "drop-shadow(0 12px 18px rgb(0 0 0 / 0.65))",
      }}
    >
      <ItemSlot item={item} qty={drag.qty} selected tabIndex={-1} />
    </div>,
    document.body,
  );
}

export function InventoryCard() {
  const { state, dispatch, notify } = useKit();
  const { slots, sortBy } = state.inventory;
  const [mode, setMode] = useState("stack");
  const [amount, setAmount] = useState(3);
  const [selected, setSelected] = useState(0);
  const [drag, setDrag] = useState(null); // { from, qty, x, y, over }
  const [status, setStatus] = useState("Drag a stack to move it. Drop it on a matching stack to combine them.");
  const [popTick, setPopTick] = useState(0);
  const [popping, setPopping] = useState(false);
  const pressRef = useRef(null); // { from, sx, sy, mode, qty, active }

  // a animação de reorganizar só vale logo depois do auto-ordenar
  useEffect(() => {
    if (!popping) return undefined;
    const t = setTimeout(() => setPopping(false), 700);
    return () => clearTimeout(t);
  }, [popping, popTick]);

  const setSlots = (next) => dispatch({ type: "inventory/slots", slots: next });

  // ── arrastar ──
  const onPointerDown = (e, i) => {
    if (e.button !== 0) return;
    setSelected(i);
    if (!slots[i]) return;
    e.currentTarget.setPointerCapture(e.pointerId);
    pressRef.current = { from: i, sx: e.clientX, sy: e.clientY, mode: modeFromEvent(e, mode), qty: 0, active: false };
  };

  const onPointerMove = (e) => {
    const p = pressRef.current;
    if (!p) return;
    if (!p.active) {
      if (Math.hypot(e.clientX - p.sx, e.clientY - p.sy) < DRAG_START) return;
      p.active = true;
      p.qty = grabQty(p.mode, slots[p.from].qty, amount);
    }
    setDrag({ from: p.from, qty: p.qty, x: e.clientX, y: e.clientY, over: targetAt(e.clientX, e.clientY) });
  };

  const finish = (from, qty, over) => {
    const def = ITEM_DEFS[slots[from].id];
    if (over === "ground") {
      setSlots(takeFrom(slots, from, qty));
      setStatus(`Dropped ${qty} ${def.name} on the ground.`);
      notify("warning", `Dropped ${def.name}`, `${qty} left on the ground at your feet.`);
      return;
    }
    if (typeof over !== "number") {
      setStatus(`${def.name} went back to slot ${from + 1}.`);
      return;
    }
    const { slots: next, plan } = applyDrop(slots, from, over, qty);
    if (!plan.ok) {
      setStatus(plan.kind === "same" ? `${def.name} went back to slot ${from + 1}.` : `${plan.hint}.`);
      return;
    }
    setSlots(next);
    setSelected(over);
    setStatus(plan.done);
  };

  const endDrag = (e, cancelled) => {
    const p = pressRef.current;
    pressRef.current = null;
    setDrag(null);
    if (!p || !p.active) return;
    finish(p.from, p.qty, cancelled ? null : targetAt(e.clientX, e.clientY));
  };

  // ── ações do slot selecionado ──
  const sel = slots[selected];
  const selDef = sel ? ITEM_DEFS[sel.id] : null;
  const hasEmpty = firstEmpty(slots) >= 0;
  const canSplit = !!sel && sel.qty > 1 && hasEmpty;

  const doUse = () => {
    setSlots(takeFrom(slots, selected, 1));
    setStatus(`Used 1 ${selDef.name}.`);
    notify("success", `Used ${selDef.name}`, selDef.meta);
  };
  const doSplit = (n) => {
    const r = splitOff(slots, selected, n);
    if (r.error) {
      setStatus(r.error);
      return;
    }
    setSlots(r.slots);
    setStatus(r.text);
  };
  const doDrop = () => {
    setSlots(takeFrom(slots, selected, sel.qty));
    setStatus(`Dropped ${sel.qty} ${selDef.name} on the ground.`);
    notify("warning", `Dropped ${selDef.name}`, `${sel.qty} left on the ground at your feet.`);
  };
  const doSort = () => {
    const r = autoSort(slots, sortBy);
    const label = SORTS.find((s) => s.value === sortBy).label;
    setSlots(r.slots);
    setSelected(0);
    setPopTick((t) => t + 1);
    setPopping(true);
    setStatus(`Sorted by ${label.toLowerCase()}${r.merged ? `, merged ${r.merged} stack${r.merged > 1 ? "s" : ""}` : ""}.`);
  };

  // ── o que mostrar enquanto arrasta ──
  const dragItem = drag ? resolve(slots[drag.from]) : null;
  const hoverPlan = drag && typeof drag.over === "number" ? planDrop(slots, drag.from, drag.over, drag.qty) : null;
  const overGround = !!drag && drag.over === "ground";
  const liveStatus = drag
    ? overGround
      ? `Drop ${drag.qty} ${dragItem.name} on the ground`
      : hoverPlan
        ? hoverPlan.hint
        : `Carrying ${drag.qty} ${dragItem.name}. Release outside the slots to cancel.`
    : status;

  const used = slots.filter(Boolean).length;
  const total = slots.reduce((n, s) => n + (s ? s.qty : 0), 0);

  return (
    <Card
      title="Item Slots"
      kicker="Drag · stack · split · auto-sort"
      className="col-span-full"
      right={
        <>
          <span className="text-[13px] text-dim">Sort by</span>
          <ArrowSelector
            options={SORTS}
            value={sortBy}
            onChange={(by) => dispatch({ type: "inventory/sortBy", by })}
            width="6.5rem"
          />
          <Button size="sm" variant="primary" icon="menu-icon-tick" onClick={doSort}>
            Auto-Sort
          </Button>
        </>
      }
      bodyClass="flex flex-wrap items-start gap-8"
    >
      {/* grade */}
      <div className="flex min-w-0 max-w-[692px] flex-[1_1_30rem] flex-col gap-3">
        <div
          className="grid grid-cols-[repeat(auto-fill,76px)] justify-between gap-3 select-none"
          onContextMenu={(e) => e.preventDefault()}
        >
          {slots.map((s, i) => {
            const isSource = !!drag && drag.from === i;
            const lifted = isSource && drag.qty >= s.qty;
            const over = !!drag && drag.over === i && !isSource;
            return (
              <ItemSlot
                key={`${i}-${popTick}`}
                data-slot={i}
                item={resolve(s)}
                qty={s ? (isSource ? s.qty - drag.qty : s.qty) : 0}
                lifted={lifted}
                selected={!drag && selected === i}
                drop={over ? (hoverPlan && hoverPlan.ok ? "valid" : "invalid") : null}
                popDelay={popping ? i * 14 : undefined}
                aria-label={s ? `Slot ${i + 1}: ${ITEM_DEFS[s.id].name} ×${s.qty}` : `Slot ${i + 1}: empty`}
                className={`touch-none ${s ? (isSource ? "cursor-grabbing" : "cursor-grab") : "cursor-default"}`}
                onPointerDown={(e) => onPointerDown(e, i)}
                onPointerMove={onPointerMove}
                onPointerUp={(e) => endDrag(e, false)}
                onPointerCancel={(e) => endDrag(e, true)}
                onLostPointerCapture={(e) => pressRef.current && endDrag(e, true)}
                onClick={(e) => e.detail === 0 && setSelected(i)}
              />
            );
          })}
        </div>
        <div className="flex items-center justify-between gap-4 text-[12.5px] text-faint">
          <span>
            {used} of {slots.length} slots used · {total} items
          </span>
          <span>Shift half · Ctrl one · Alt amount</span>
        </div>
      </div>

      {/* painel lateral */}
      <div className="flex min-w-[18rem] flex-[1_1_18rem] flex-col gap-4">
        <div className="flex flex-col gap-2.5">
          <p className="kit-heading text-[10px] text-faint">Grab mode · a drag picks up {MODE_NAMES[mode]}</p>
          <Tabs size="sm" items={MODES} value={mode} onChange={setMode} />
          <div className="flex items-center justify-between gap-4">
            <span className="text-[13px] text-dim">Amount (Amount mode &amp; Split)</span>
            <Stepper value={amount} onChange={setAmount} min={1} max={20} />
          </div>
        </div>

        <Divider />

        {sel ? (
          <div className="flex flex-col gap-3.5">
            <div className="flex items-center gap-4">
              <img
                src={window.rsmAsset(`tex/items/${selDef.img}.png`)}
                alt=""
                draggable={false}
                className="h-14 w-14 shrink-0 object-contain"
              />
              <div className="min-w-0 flex-1">
                <p className="kit-heading truncate text-[13px] text-ink">{selDef.name}</p>
                <p className="mt-1 text-[13px] text-dim">{selDef.meta}</p>
              </div>
              <div className="flex shrink-0 flex-col items-end gap-1.5">
                <Tag kind="neutral">{CATEGORIES[selDef.cat]}</Tag>
                <span className="font-cat text-[13px] text-ink">
                  {sel.qty}/{selDef.max}
                </span>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <Button size="sm" onClick={() => doSplit(Math.floor(sel.qty / 2))} disabled={!canSplit}>
                Split Half
              </Button>
              <Button size="sm" onClick={() => doSplit(amount)} disabled={!canSplit}>
                Split ×{Math.min(amount, Math.max(1, sel.qty - 1))}
              </Button>
              <Button size="sm" variant="primary" onClick={doUse} disabled={!USABLE.includes(selDef.cat)}>
                Use One
              </Button>
              <Button size="sm" onClick={doDrop}>
                Drop Stack
              </Button>
            </div>
          </div>
        ) : (
          <p className="py-3 text-[13px] text-faint">Slot {selected + 1} is empty. Drag an item here, or pick a stack to see its actions.</p>
        )}

        <div
          data-zone="ground"
          className="tx-help flex items-center gap-3.5 px-5 py-4 transition-colors"
          style={{ "--plate": overGround ? "rgb(var(--kit-accent-rgb) / 0.3)" : "rgb(var(--kit-text-rgb) / 0.06)" }}
        >
          <Icon name="cross" size={20} className={overGround ? "text-accent" : "text-faint"} />
          <div className="min-w-0">
            <p className="kit-heading text-[11px] text-ink">Drop on the ground</p>
            <p className="text-[12px] text-faint">Drag here to drop what you are carrying.</p>
          </div>
        </div>

        <p aria-live="polite" className={`min-h-[2.6em] text-[13px] leading-snug ${hoverPlan && !hoverPlan.ok ? "text-accent" : "text-dim"}`}>
          {liveStatus}
        </p>
      </div>

      {drag && dragItem && <DragGhost drag={drag} item={dragItem} />}
    </Card>
  );
}
