<script setup>
import Slider from "./Slider.vue";

// Slider with a label row and a value readout
const model = defineModel({ type: Number, required: true });
defineProps({
  label: { type: String, required: true },
  format: { type: Function, default: (v) => v },
  min: { type: Number, default: 0 },
  max: { type: Number, default: 100 },
  step: { type: Number, default: 1 },
  disabled: { type: Boolean, default: false },
  centered: { type: Boolean, default: false },
});
</script>

<template>
  <div class="flex min-w-0 flex-col gap-1.5">
    <div class="flex items-baseline justify-between gap-3">
      <span class="text-[13px] text-dim">{{ label }}</span>
      <span class="font-cat text-[13px] text-ink">{{ format(model) }}</span>
    </div>
    <Slider v-model="model" :label="label" :min="min" :max="max" :step="step" :disabled="disabled" :centered="centered" />
  </div>
</template>
