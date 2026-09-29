<script setup>
// Progress bar on the menu_bar art; omit value for the indeterminate loader.
defineProps({ value: { type: Number, default: null } });
const track = "rgb(var(--kit-text-rgb) / 0.14)";
</script>

<template>
  <div v-if="value == null" class="tx-bar relative w-full overflow-hidden" :style="{ background: track }">
    <span
      class="absolute inset-y-0 left-0 w-2/5"
      :style="{ background: 'var(--kit-accent)', animation: 'kit-load 1.5s ease-in-out infinite' }"
    />
  </div>
  <div
    v-else
    class="tx-bar w-full transition-[background]"
    :style="{ background: `linear-gradient(90deg, var(--kit-accent) ${value}%, ${track} ${value}%)` }"
  />
</template>
