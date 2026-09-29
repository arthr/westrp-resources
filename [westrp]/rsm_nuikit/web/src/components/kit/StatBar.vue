<script setup>
// Segmented weapon-stat bar at the art's own 13:1 ratio
defineProps({
  value: { type: Number, required: true },
  width: { type: Number, default: 208 },
  dim: { type: Boolean, default: false },
});
</script>

<template>
  <div
    class="tx-stat shrink-0"
    :style="{
      width: `${width}px`,
      background: `linear-gradient(90deg, ${dim ? 'rgb(var(--kit-text-rgb) / 0.35)' : 'var(--kit-text)'} ${value}%, rgb(var(--kit-text-rgb) / 0.14) ${value}%)`,
    }"
  />
</template>
