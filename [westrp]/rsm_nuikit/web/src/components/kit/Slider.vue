<script setup>
import { computed, ref } from "vue";
import Icon from "./Icon.vue";

// Bar slider on the menu_bar art. `centered` fills from the middle (for ± offsets).
const model = defineModel({ type: Number, required: true });
const props = defineProps({
  min: { type: Number, default: 0 },
  max: { type: Number, default: 100 },
  step: { type: Number, default: 1 },
  disabled: { type: Boolean, default: false },
  centered: { type: Boolean, default: false },
  label: { type: String, default: null },
});

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const track = ref(null);

const pct = computed(() => ((model.value - props.min) / (props.max - props.min)) * 100);
const barStyle = computed(() => {
  const zero = props.centered ? ((0 - props.min) / (props.max - props.min)) * 100 : 0;
  const lo = Math.min(zero, pct.value);
  const hi = Math.max(zero, pct.value);
  const bg = "rgb(var(--kit-text-rgb) / 0.14)";
  const fill = props.disabled ? "rgb(var(--kit-text-rgb) / 0.22)" : "var(--kit-accent)";
  return { background: `linear-gradient(90deg, ${bg} ${lo}%, ${fill} ${lo}%, ${fill} ${hi}%, ${bg} ${hi}%)` };
});

const setFromX = (clientX) => {
  const r = track.value.getBoundingClientRect();
  const t = clamp((clientX - r.left) / r.width, 0, 1);
  const raw = props.min + t * (props.max - props.min);
  const next = clamp(Math.round(raw / props.step) * props.step, props.min, props.max);
  if (next !== model.value) model.value = Number(next.toFixed(4));
};

const onPointerDown = (e) => {
  if (props.disabled) return;
  e.currentTarget.setPointerCapture(e.pointerId);
  setFromX(e.clientX);
};
const onPointerMove = (e) => {
  if (!props.disabled && e.currentTarget.hasPointerCapture(e.pointerId)) setFromX(e.clientX);
};
const onKeyDown = (e) => {
  if (props.disabled) return;
  if (e.key === "ArrowLeft" || e.key === "ArrowDown") {
    e.preventDefault();
    model.value = clamp(model.value - props.step, props.min, props.max);
  }
  if (e.key === "ArrowRight" || e.key === "ArrowUp") {
    e.preventDefault();
    model.value = clamp(model.value + props.step, props.min, props.max);
  }
};
</script>

<template>
  <div
    ref="track"
    role="slider"
    :tabindex="disabled ? -1 : 0"
    :aria-label="label"
    :aria-valuemin="min"
    :aria-valuemax="max"
    :aria-valuenow="model"
    :aria-disabled="disabled"
    :class="[
      'group relative flex h-7 w-full min-w-0 touch-none items-center outline-none select-none',
      disabled ? 'cursor-not-allowed opacity-55' : 'cursor-pointer',
    ]"
    @pointerdown="onPointerDown"
    @pointermove="onPointerMove"
    @keydown="onKeyDown"
  >
    <div class="tx-bar w-full" :style="barStyle" />
    <span class="pointer-events-none absolute top-1/2 grid" :style="{ left: `${pct}%`, transform: 'translate(-50%, -50%)' }">
      <Icon name="diamond" :size="16" :class="disabled ? 'text-faint' : 'text-ink group-focus-visible:text-accent'" />
    </span>
  </div>
</template>
