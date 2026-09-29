<script setup>
import Icon from "./Icon.vue";

// Square icon-only button on the keycap frame
defineProps({
  icon: { type: String, required: true },
  label: { type: String, required: true },
  size: { type: Number, default: 40 },
  active: { type: Boolean, default: false },
});
</script>

<template>
  <button
    type="button"
    :aria-label="label"
    :title="label"
    :class="['btn tx-plate grid shrink-0 cursor-pointer place-items-center transition-colors', active && 'is-active']"
    :style="{ width: `${size}px`, height: `${size}px` }"
  >
    <Icon :name="icon" :size="Math.round(size * 0.45)" />
  </button>
</template>
