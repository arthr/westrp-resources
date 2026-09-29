<script setup>
import ArrowButton from "./ArrowButton.vue";
import Counter from "./Counter.vue";

// Quantity stepper: ‹ [n] › clamped to min/max
const model = defineModel({ type: Number, required: true });
const props = defineProps({
  min: { type: Number, default: 0 },
  max: { type: Number, default: 99 },
  disabled: { type: Boolean, default: false },
});

const step = (d) => {
  model.value = Math.min(props.max, Math.max(props.min, model.value + d));
};
</script>

<template>
  <div :class="['flex items-center gap-2', disabled && 'opacity-45']">
    <ArrowButton dir="left" label="Decrease" :disabled="disabled || model <= min" @click="step(-1)" />
    <Counter size="lg">{{ model }}</Counter>
    <ArrowButton dir="right" label="Increase" :disabled="disabled || model >= max" @click="step(1)" />
  </div>
</template>
