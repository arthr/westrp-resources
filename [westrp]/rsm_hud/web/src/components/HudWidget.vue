<script setup>
import { computed } from "vue";
import { hud } from "../store/hud.js";
import { isDisabled, layout, placeWidget, widgetLabel } from "../store/layout.js";
import { t } from "../locale.js";

// One movable HUD element. Placement: the element's left edge sits at
// x * (screen - own width), so x = 0 is flush left, 1 flush right, and it can
// never leave the screen at any resolution or scale. In Layout Manager mode it
// becomes draggable (pointer capture keeps the drag on this element only).
// Largura: w-max prende a caixa na largura do próprio conteúdo. Sem isso, um
// elemento `fixed` com `left: x%` só recebe o espaço entre o left e a borda
// direita, e encolhe (quebrando linha) quanto mais perto ela estiver.
const props = defineProps({
  id: { type: String, required: true },
  // false while the element has nothing to show (not mounted, not wanted…)
  active: { type: Boolean, default: true },
  // peça de outro resource: quem desenha é o dono, aqui só existe no editor
  ghost: { type: Boolean, default: false },
});

const cfg = computed(() => layout.widgets[props.id]);
const selected = computed(() => layout.editing && layout.selected === props.id);
const live = computed(() => cfg.value.visible && props.active);
// desativado pelo servidor: some para todos, inclusive no editor
const shown = computed(() => !isDisabled(props.id) && (layout.editing || (!props.ghost && hud.visible && live.value)));
const tagBelow = computed(() => cfg.value.y < 0.14);

const style = computed(() => {
  const { x, y, scale, opacity } = cfg.value;
  return {
    left: `${x * 100}%`,
    top: `${y * 100}%`,
    transform: `translate(${-x * 100}%, ${-y * 100}%) scale(${scale})`,
    transformOrigin: `${x * 100}% ${y * 100}%`,
    opacity: layout.editing && !live.value ? 0.35 : opacity,
    zIndex: selected.value ? 12 : 10,
  };
});

// Corner pieces are slices of the game's selection highlight; the offsets put
// each bracket's outer corner just outside this element's box.
const corners = [
  { tex: "corner-tl", style: { left: "-1.15rem", top: "-0.75rem" } },
  { tex: "corner-tr", style: { right: "-1.125rem", top: "-0.75rem" } },
  { tex: "corner-bl", style: { left: "-1.1rem", bottom: "-0.675rem" } },
  { tex: "corner-br", style: { right: "-1.175rem", bottom: "-0.875rem" } },
];

let drag = null;

function onDown(e) {
  if (!layout.editing || e.button !== 0) return;
  layout.selected = props.id;
  const r = e.currentTarget.getBoundingClientRect();
  drag = { pid: e.pointerId, sx: e.clientX, sy: e.clientY, left: r.left, top: r.top, w: r.width, h: r.height };
  e.currentTarget.setPointerCapture(e.pointerId);
  layout.dragging = props.id;
  e.preventDefault();
}

function onMove(e) {
  if (!drag || e.pointerId !== drag.pid) return;
  placeWidget(props.id, drag.left + e.clientX - drag.sx, drag.top + e.clientY - drag.sy, drag.w, drag.h);
}

function onEnd(e) {
  if (!drag || e.pointerId !== drag.pid) return;
  drag = null;
  layout.dragging = null;
  layout.guides = { v: false, h: false };
}
</script>

<template>
  <div
    v-show="shown"
    :data-widget="id"
    class="fixed w-max"
    :class="layout.editing ? (layout.dragging === id ? 'cursor-grabbing' : 'cursor-grab') : 'pointer-events-none'"
    :style="style"
    @pointerdown="onDown"
    @pointermove="onMove"
    @pointerup="onEnd"
    @pointercancel="onEnd"
    @lostpointercapture="onEnd"
  >
    <div class="enter">
      <slot />
    </div>

    <template v-if="layout.editing">
      <span
        class="skin skin-outline pointer-events-none absolute -inset-2"
        :style="{ '--skin-fill': selected ? 'rgb(var(--hud-accent-rgb) / 0.85)' : 'rgb(var(--hud-text-rgb) / 0.28)' }"
      />
      <template v-if="selected">
        <span
          v-for="c in corners"
          :key="c.tex"
          class="tex pointer-events-none absolute h-[1.2rem] w-[1.2rem] text-red"
          :style="{ ...c.style, '--m': `var(--tex-${c.tex})` }"
        />
      </template>
      <span
        class="skin skin-key pointer-events-none absolute left-1/2 flex -translate-x-1/2 items-center gap-1.5 whitespace-nowrap px-2.5 py-1 font-display text-[0.6rem] uppercase tracking-[0.18em]"
        :class="[tagBelow ? 'top-[calc(100%+0.9rem)]' : 'bottom-[calc(100%+0.9rem)]', selected ? 'text-on-accent' : 'text-dim']"
        :style="{ '--skin-fill': selected ? 'rgb(var(--hud-accent-rgb) / 0.9)' : 'rgb(var(--hud-surface-rgb) / calc(0.78 * var(--hud-surface-k)))' }"
      >
        {{ widgetLabel(id) }}
        <span v-if="!live" class="text-[rgb(var(--hud-text-rgb)/0.6)]">· {{ t("lm.hidden") }}</span>
      </span>
    </template>
  </div>
</template>
