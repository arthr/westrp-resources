<script setup>
import { computed } from "vue";
import ArrowButton from "./ArrowButton.vue";

// The classic RDR menu row picker: ‹ value ›, wraps around.
const model = defineModel({ type: [String, Number], default: null });
const props = defineProps({
  options: { type: Array, required: true },
  disabled: { type: Boolean, default: false },
  width: { type: String, default: "9rem" },
});

const optValue = (o) => (typeof o === "object" ? o.value : o);
const optLabel = (o) => (typeof o === "object" ? o.label : o);

const index = computed(() => Math.max(0, props.options.findIndex((o) => optValue(o) === model.value)));
const step = (d) => {
  const n = (index.value + d + props.options.length) % props.options.length;
  model.value = optValue(props.options[n]);
};
</script>

<template>
  <div :class="['flex items-center gap-1', disabled && 'opacity-45']">
    <ArrowButton dir="left" label="Previous" :disabled="disabled" @click="step(-1)" />
    <span class="kit-heading truncate text-center text-[12px] text-ink" :style="{ width }">
      {{ optLabel(options[index]) }}
    </span>
    <ArrowButton dir="right" label="Next" :disabled="disabled" @click="step(1)" />
  </div>
</template>
