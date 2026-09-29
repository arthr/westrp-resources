<script setup>
import { computed, ref } from "vue";

// A slider built from the game's stat bar: the bar art is the track, its mask
// variant is the red fill, and the tank marker is the thumb.
const props = defineProps({
  modelValue: { type: Number, required: true },
  min: { type: Number, default: 0 },
  max: { type: Number, default: 100 },
  step: { type: Number, default: 1 },
  label: { type: String, default: "" },
  unit: { type: String, default: "" },
});
const emit = defineEmits(["update:modelValue"]);

const track = ref(null);
let activePointer = null;

const pct = computed(() => ((props.modelValue - props.min) / (props.max - props.min)) * 100);

function snap(v) {
  const stepped = Math.round((v - props.min) / props.step) * props.step + props.min;
  return Math.min(props.max, Math.max(props.min, stepped));
}
function emitAt(clientX) {
  const r = track.value.getBoundingClientRect();
  const t = r.width ? (clientX - r.left) / r.width : 0;
  const v = snap(props.min + t * (props.max - props.min));
  if (v !== props.modelValue) emit("update:modelValue", v);
}
function onDown(e) {
  if (e.button !== 0) return;
  activePointer = e.pointerId;
  e.currentTarget.setPointerCapture(e.pointerId);
  emitAt(e.clientX);
}
function onMove(e) {
  if (activePointer === e.pointerId) emitAt(e.clientX);
}
function onEnd(e) {
  if (activePointer === e.pointerId) activePointer = null;
}
function onKey(e) {
  const dir = { ArrowLeft: -1, ArrowDown: -1, ArrowRight: 1, ArrowUp: 1 }[e.key];
  if (!dir) return;
  e.preventDefault();
  e.stopPropagation(); // keep the Layout Manager's arrow-nudge out of it
  emit("update:modelValue", snap(props.modelValue + dir * props.step));
}
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <div class="flex items-baseline justify-between">
      <span class="font-display text-[0.64rem] uppercase tracking-[0.18em] text-dim">{{ label }}</span>
      <span class="font-num text-[0.9rem] leading-none text-paper">{{ modelValue }}{{ unit }}</span>
    </div>
    <div
      ref="track"
      role="slider"
      tabindex="0"
      :aria-label="label"
      :aria-valuemin="min"
      :aria-valuemax="max"
      :aria-valuenow="modelValue"
      class="relative h-[2rem] cursor-pointer touch-none outline-none"
      @pointerdown="onDown"
      @pointermove="onMove"
      @pointerup="onEnd"
      @pointercancel="onEnd"
      @keydown="onKey"
    >
      <span class="skin absolute inset-x-0 top-0 h-[1rem]" style="--skin-mask: var(--tex-slider-track) 0 12 / 0 0.75rem stretch; --skin-fill: rgb(var(--hud-text-rgb) / 0.14)" />
      <span
        class="skin absolute inset-x-0 top-0 h-[1rem]"
        :style="{ '--skin-mask': 'var(--tex-slider-fill) 0 12 / 0 0.75rem stretch', '--skin-fill': 'var(--red)', clipPath: `inset(0 ${100 - pct}% 0 0)` }"
      />
      <span
        class="tex absolute top-[0.55rem] h-[1.25rem] w-[2.25rem] -translate-x-1/2 text-paper"
        :style="{ left: `${pct}%`, '--m': 'var(--tex-slider-thumb)' }"
      />
    </div>
  </div>
</template>
