<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from "vue";
import { useKit } from "../../../state/kit.js";
import { ANCHORS, ANCHOR_NAMES, WIDGET_META } from "../../../state/mock.js";
import { anchorBox, nearestAnchor } from "../../hud/anchor.js";
import { widgetDims } from "../../hud/dims.js";
import { WIDGETS } from "../../hud/widgets.js";
import { Brackets, Icon } from "../../kit";

// Tela em miniatura (1920×1080 em escala): arrasta as peças do HUD, e com
// "Snap to anchors" ligado a peça solta cai na âncora mais próxima.
const OFFSET = 40; // max ± offset, % of the screen
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const round1 = (v) => Math.round(v * 10) / 10;

const kit = useKit();
const layout = computed(() => kit.state.layout);

const canvas = ref(null);
const width = ref(640);
const dragging = ref(null);
let drag = null; // { id, sx, sy, x0, y0, moved }

let ro = null;
onMounted(() => {
  ro = new ResizeObserver(([entry]) => {
    width.value = entry.contentRect.width;
  });
  ro.observe(canvas.value);
});
onBeforeUnmount(() => {
  if (ro) ro.disconnect();
});

const anchorDots = computed(() =>
  ANCHORS.map((a) => {
    const b = anchorBox(a, 0, 0, layout.value.safeZone);
    return { a, style: { left: `${b.left}%`, top: `${b.top}%`, transform: "translate(-50%, -50%)" } };
  }),
);

const pieces = computed(() => {
  const screenScale = width.value / 1920;
  const { widgets, safeZone } = layout.value;
  return Object.entries(widgets)
    .filter(([id]) => kit.isActive(id))
    .map(([id, w]) => {
      const [dw, dh] = widgetDims(id, kit.state.hud.coreStyle);
      const s = screenScale * (w.scale / 100);
      const b = anchorBox(w.anchor, w.x, w.y, safeZone);
      return {
        id,
        widget: WIDGETS[id],
        label: `${WIDGET_META[id].label}, ${ANCHOR_NAMES[w.anchor]}`,
        outer: {
          left: `${b.left}%`,
          top: `${b.top}%`,
          width: `${dw * s}px`,
          height: `${dh * s}px`,
          transform: `translate(${b.tx}%, ${b.ty}%)`,
        },
        inner: { width: `${dw}px`, height: `${dh}px`, transform: `scale(${s})`, transformOrigin: "top left" },
      };
    });
});

const select = (id) => kit.dispatch({ type: "layout/select", id });

const onDown = (e, id) => {
  select(id);
  e.currentTarget.setPointerCapture(e.pointerId);
  const w = layout.value.widgets[id];
  drag = { id, sx: e.clientX, sy: e.clientY, x0: w.x, y0: w.y, moved: false };
  dragging.value = id;
};

const onMove = (e) => {
  const d = drag;
  if (!d) return;
  const r = canvas.value.getBoundingClientRect();
  const dx = ((e.clientX - d.sx) / r.width) * 100;
  const dy = ((e.clientY - d.sy) / r.height) * 100;
  // Só vira arraste depois de passar o limiar: um clique apenas seleciona.
  if (!d.moved && Math.abs(dx) + Math.abs(dy) <= 0.4) return;
  d.moved = true;
  kit.dispatch({
    type: "layout/widget",
    id: d.id,
    patch: { x: round1(clamp(d.x0 + dx, -OFFSET, OFFSET)), y: round1(clamp(d.y0 + dy, -OFFSET, OFFSET)) },
  });
};

const onUp = (e) => {
  const d = drag;
  drag = null;
  dragging.value = null;
  if (!d || !d.moved || !layout.value.snap) return;
  const r = canvas.value.getBoundingClientRect();
  const el = e.currentTarget.getBoundingClientRect();
  const anchor = nearestAnchor((el.left + el.width / 2 - r.left) / r.width, (el.top + el.height / 2 - r.top) / r.height);
  kit.dispatch({ type: "layout/widget", id: d.id, patch: { anchor, x: 0, y: 0 } });
};
</script>

<template>
  <div
    ref="canvas"
    class="tx-frame relative aspect-video w-full overflow-hidden"
    :style="{
      '--frame': 'rgb(var(--kit-text-rgb) / 0.35)',
      background: 'linear-gradient(rgb(0 0 0 / 0.3), rgb(0 0 0 / 0.3)), var(--rsm-backdrop) center / cover no-repeat',
    }"
  >
    <template v-if="layout.grid">
      <div class="ln-v absolute inset-y-0 left-1/3" />
      <div class="ln-v absolute inset-y-0 left-2/3" />
      <div class="ln-h absolute inset-x-0 top-1/3" />
      <div class="ln-h absolute inset-x-0 top-2/3" />
    </template>
    <!-- safe zone -->
    <div
      class="tx-frame pointer-events-none absolute"
      :style="{ inset: `${layout.safeZone}%`, '--frame': 'rgb(var(--kit-accent-rgb) / 0.55)' }"
    />
    <!-- anchor points -->
    <span v-for="d in anchorDots" :key="d.a" class="pointer-events-none absolute grid" :style="d.style">
      <Icon name="diamond" :size="9" class="text-accent opacity-70" />
    </span>

    <div
      v-for="p in pieces"
      :key="p.id"
      role="button"
      tabindex="0"
      :aria-label="p.label"
      :class="[
        'absolute touch-none outline-none select-none',
        dragging === p.id ? 'cursor-grabbing' : 'cursor-grab',
        layout.selected === p.id ? 'z-10' : 'opacity-85 hover:opacity-100',
      ]"
      :style="p.outer"
      @pointerdown="onDown($event, p.id)"
      @pointermove="onMove"
      @pointerup="onUp"
      @pointercancel="onUp"
      @keydown.enter="select(p.id)"
    >
      <div class="pointer-events-none" :style="p.inner">
        <component :is="p.widget" />
      </div>
      <Brackets v-if="layout.selected === p.id" :size="10" />
    </div>
  </div>
</template>
