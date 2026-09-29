<script setup>
// Quantity counter on the counter plate
defineProps({
  size: { type: String, default: "md" },
  muted: { type: Boolean, default: false },
});

const DIMS = {
  lg: "h-8 min-w-8 px-2.5 text-[14px]",
  md: "h-6 min-w-6 px-2 text-[11px]",
  sm: "h-5 min-w-5 px-1.5 text-[10px]",
};
</script>

<template>
  <span
    :class="['tx-counter inline-grid shrink-0 place-items-center font-cat leading-none', muted ? 'text-ink' : 'text-on-accent', DIMS[size]]"
    :style="muted ? { '--plate': 'rgb(var(--kit-text-rgb) / 0.16)' } : undefined"
  >
    <slot />
  </span>
</template>
