<script setup>
import { computed, onBeforeUnmount, ref } from "vue";
import { useKit } from "../../state/kit.js";
import {
  ITEM_DEFS, CATEGORIES, SORTS, applyDrop, autoSort, firstEmpty, grabQty, planDrop, splitOff, takeFrom,
} from "../../state/inventory.js";
import { ArrowSelector, Button, Card, Divider, Icon, ItemSlot, Stepper, Tabs, Tag } from "../kit";
import DragGhost from "./DragGhost.vue";

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
const itemArt = (def) => window.rsmAsset(`tex/items/${def.img}.png`);

const kit = useKit();
const slots = computed(() => kit.state.inventory.slots);
const sortBy = computed(() => kit.state.inventory.sortBy);
const mode = ref("stack");
const amount = ref(3);
const selected = ref(0);
const drag = ref(null); // { from, qty, x, y, over }
const status = ref("Drag a stack to move it. Drop it on a matching stack to combine them.");
let press = null; // { from, sx, sy, mode, qty, active }

// a animação de reorganizar só vale logo depois do auto-ordenar
const popTick = ref(0);
const popping = ref(false);
let popTimer = 0;
const playPop = () => {
  popTick.value += 1;
  popping.value = true;
  clearTimeout(popTimer);
  popTimer = setTimeout(() => {
    popping.value = false;
  }, 700);
};
onBeforeUnmount(() => clearTimeout(popTimer));

const setSlots = (next) => kit.dispatch({ type: "inventory/slots", slots: next });

// ── arrastar ──
const onPointerDown = (e, i) => {
  if (e.button !== 0) return;
  selected.value = i;
  if (!slots.value[i]) return;
  e.currentTarget.setPointerCapture(e.pointerId);
  press = { from: i, sx: e.clientX, sy: e.clientY, mode: modeFromEvent(e, mode.value), qty: 0, active: false };
};

const onPointerMove = (e) => {
  const p = press;
  if (!p) return;
  if (!p.active) {
    if (Math.hypot(e.clientX - p.sx, e.clientY - p.sy) < DRAG_START) return;
    p.active = true;
    p.qty = grabQty(p.mode, slots.value[p.from].qty, amount.value);
  }
  drag.value = { from: p.from, qty: p.qty, x: e.clientX, y: e.clientY, over: targetAt(e.clientX, e.clientY) };
};

const finish = (from, qty, over) => {
  const cur = slots.value;
  const def = ITEM_DEFS[cur[from].id];
  if (over === "ground") {
    setSlots(takeFrom(cur, from, qty));
    status.value = `Dropped ${qty} ${def.name} on the ground.`;
    kit.notify("warning", `Dropped ${def.name}`, `${qty} left on the ground at your feet.`);
    return;
  }
  if (typeof over !== "number") {
    status.value = `${def.name} went back to slot ${from + 1}.`;
    return;
  }
  const { slots: next, plan } = applyDrop(cur, from, over, qty);
  if (!plan.ok) {
    status.value = plan.kind === "same" ? `${def.name} went back to slot ${from + 1}.` : `${plan.hint}.`;
    return;
  }
  setSlots(next);
  selected.value = over;
  status.value = plan.done;
};

const endDrag = (e, cancelled) => {
  const p = press;
  press = null;
  drag.value = null;
  if (!p || !p.active) return;
  finish(p.from, p.qty, cancelled ? null : targetAt(e.clientX, e.clientY));
};
// perder a captura sem pointerup (janela perdeu o foco, etc.) cancela o arraste
const onLostCapture = (e) => {
  if (press) endDrag(e, true);
};
// Enter/Espaço no slot (clique sem ponteiro) também seleciona
const onSlotClick = (e, i) => {
  if (e.detail === 0) selected.value = i;
};

// ── ações do slot selecionado ──
const sel = computed(() => slots.value[selected.value]);
const selDef = computed(() => (sel.value ? ITEM_DEFS[sel.value.id] : null));
const canSplit = computed(() => !!sel.value && sel.value.qty > 1 && firstEmpty(slots.value) >= 0);

const doUse = () => {
  const def = selDef.value;
  setSlots(takeFrom(slots.value, selected.value, 1));
  status.value = `Used 1 ${def.name}.`;
  kit.notify("success", `Used ${def.name}`, def.meta);
};
const doSplit = (n) => {
  const r = splitOff(slots.value, selected.value, n);
  if (r.error) {
    status.value = r.error;
    return;
  }
  setSlots(r.slots);
  status.value = r.text;
};
const doDrop = () => {
  const def = selDef.value;
  const qty = sel.value.qty;
  setSlots(takeFrom(slots.value, selected.value, qty));
  status.value = `Dropped ${qty} ${def.name} on the ground.`;
  kit.notify("warning", `Dropped ${def.name}`, `${qty} left on the ground at your feet.`);
};
const doSort = () => {
  const r = autoSort(slots.value, sortBy.value);
  const label = SORTS.find((s) => s.value === sortBy.value).label;
  setSlots(r.slots);
  selected.value = 0;
  playPop();
  status.value = `Sorted by ${label.toLowerCase()}${r.merged ? `, merged ${r.merged} stack${r.merged > 1 ? "s" : ""}` : ""}.`;
};

// ── o que mostrar enquanto arrasta ──
const dragItem = computed(() => (drag.value ? resolve(slots.value[drag.value.from]) : null));
const hoverPlan = computed(() => {
  const d = drag.value;
  return d && typeof d.over === "number" ? planDrop(slots.value, d.from, d.over, d.qty) : null;
});
const overGround = computed(() => !!drag.value && drag.value.over === "ground");
const liveStatus = computed(() => {
  const d = drag.value;
  if (!d) return status.value;
  if (overGround.value) return `Drop ${d.qty} ${dragItem.value.name} on the ground`;
  if (hoverPlan.value) return hoverPlan.value.hint;
  return `Carrying ${d.qty} ${dragItem.value.name}. Release outside the slots to cancel.`;
});

const used = computed(() => slots.value.filter(Boolean).length);
const total = computed(() => slots.value.reduce((n, s) => n + (s ? s.qty : 0), 0));

const slotViews = computed(() =>
  slots.value.map((s, i) => {
    const d = drag.value;
    const isSource = !!d && d.from === i;
    const over = !!d && d.over === i && !isSource;
    return {
      key: `${i}-${popTick.value}`,
      i,
      item: resolve(s),
      qty: s ? (isSource ? s.qty - d.qty : s.qty) : 0,
      lifted: isSource && d.qty >= s.qty,
      selected: !d && selected.value === i,
      drop: over ? (hoverPlan.value && hoverPlan.value.ok ? "valid" : "invalid") : null,
      popDelay: popping.value ? i * 14 : null,
      label: s ? `Slot ${i + 1}: ${ITEM_DEFS[s.id].name} ×${s.qty}` : `Slot ${i + 1}: empty`,
      cursor: s ? (isSource ? "cursor-grabbing" : "cursor-grab") : "cursor-default",
    };
  }),
);
</script>

<template>
  <Card title="Item Slots" kicker="Drag · stack · split · auto-sort" class="col-span-full" body-class="flex flex-wrap items-start gap-8">
    <template #right>
      <span class="text-[13px] text-dim">Sort by</span>
      <ArrowSelector
        :options="SORTS"
        :model-value="sortBy"
        width="6.5rem"
        @update:model-value="(by) => kit.dispatch({ type: 'inventory/sortBy', by })"
      />
      <Button size="sm" variant="primary" icon="menu-icon-tick" @click="doSort">Auto-Sort</Button>
    </template>

    <!-- grade -->
    <div class="flex max-w-[692px] min-w-0 flex-[1_1_30rem] flex-col gap-3">
      <div class="grid grid-cols-[repeat(auto-fill,76px)] justify-between gap-3 select-none" @contextmenu.prevent>
        <ItemSlot
          v-for="v in slotViews"
          :key="v.key"
          :data-slot="v.i"
          :item="v.item"
          :qty="v.qty"
          :lifted="v.lifted"
          :selected="v.selected"
          :drop="v.drop"
          :pop-delay="v.popDelay"
          :aria-label="v.label"
          :class="['touch-none', v.cursor]"
          @pointerdown="onPointerDown($event, v.i)"
          @pointermove="onPointerMove"
          @pointerup="endDrag($event, false)"
          @pointercancel="endDrag($event, true)"
          @lostpointercapture="onLostCapture"
          @click="onSlotClick($event, v.i)"
        />
      </div>
      <div class="flex items-center justify-between gap-4 text-[12.5px] text-faint">
        <span>{{ used }} of {{ slots.length }} slots used · {{ total }} items</span>
        <span>Shift half · Ctrl one · Alt amount</span>
      </div>
    </div>

    <!-- painel lateral -->
    <div class="flex min-w-[18rem] flex-[1_1_18rem] flex-col gap-4">
      <div class="flex flex-col gap-2.5">
        <p class="kit-heading text-[10px] text-faint">Grab mode · a drag picks up {{ MODE_NAMES[mode] }}</p>
        <Tabs v-model="mode" size="sm" :items="MODES" />
        <div class="flex items-center justify-between gap-4">
          <span class="text-[13px] text-dim">Amount (Amount mode &amp; Split)</span>
          <Stepper v-model="amount" :min="1" :max="20" />
        </div>
      </div>

      <Divider />

      <div v-if="sel" class="flex flex-col gap-3.5">
        <div class="flex items-center gap-4">
          <img :src="itemArt(selDef)" alt="" draggable="false" class="h-14 w-14 shrink-0 object-contain" />
          <div class="min-w-0 flex-1">
            <p class="kit-heading truncate text-[13px] text-ink">{{ selDef.name }}</p>
            <p class="mt-1 text-[13px] text-dim">{{ selDef.meta }}</p>
          </div>
          <div class="flex shrink-0 flex-col items-end gap-1.5">
            <Tag kind="neutral">{{ CATEGORIES[selDef.cat] }}</Tag>
            <span class="font-cat text-[13px] text-ink">{{ sel.qty }}/{{ selDef.max }}</span>
          </div>
        </div>
        <div class="grid grid-cols-2 gap-2">
          <Button size="sm" :disabled="!canSplit" @click="doSplit(Math.floor(sel.qty / 2))">Split Half</Button>
          <Button size="sm" :disabled="!canSplit" @click="doSplit(amount)">Split ×{{ Math.min(amount, Math.max(1, sel.qty - 1)) }}</Button>
          <Button size="sm" variant="primary" :disabled="!USABLE.includes(selDef.cat)" @click="doUse">Use One</Button>
          <Button size="sm" @click="doDrop">Drop Stack</Button>
        </div>
      </div>
      <p v-else class="py-3 text-[13px] text-faint">Slot {{ selected + 1 }} is empty. Drag an item here, or pick a stack to see its actions.</p>

      <div
        data-zone="ground"
        class="tx-help flex items-center gap-3.5 px-5 py-4 transition-colors"
        :style="{ '--plate': overGround ? 'rgb(var(--kit-accent-rgb) / 0.3)' : 'rgb(var(--kit-text-rgb) / 0.06)' }"
      >
        <Icon name="cross" :size="20" :class="overGround ? 'text-accent' : 'text-faint'" />
        <div class="min-w-0">
          <p class="kit-heading text-[11px] text-ink">Drop on the ground</p>
          <p class="text-[12px] text-faint">Drag here to drop what you are carrying.</p>
        </div>
      </div>

      <p aria-live="polite" :class="['min-h-[2.6em] text-[13px] leading-snug', hoverPlan && !hoverPlan.ok ? 'text-accent' : 'text-dim']">
        {{ liveStatus }}
      </p>
    </div>

    <DragGhost v-if="drag && dragItem" :drag="drag" :item="dragItem" />
  </Card>
</template>
