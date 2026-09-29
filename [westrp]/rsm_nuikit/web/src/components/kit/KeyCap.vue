<script setup>
// Keycap on the square frame; `fill` (0-1) rises from the bottom while held.
defineProps({
  k: { type: String, required: true },
  fill: { type: Number, default: 0 },
  size: { type: Number, default: 30 },
  dim: { type: Boolean, default: false },
});
</script>

<template>
  <span
    class="tx-key relative grid shrink-0 place-items-center overflow-hidden"
    :style="{ width: `${size}px`, height: `${size}px`, '--frame': dim ? 'var(--kit-faint)' : 'var(--kit-text)' }"
  >
    <span
      aria-hidden="true"
      class="absolute inset-[3px] origin-bottom"
      :style="{ background: 'var(--kit-accent)', transform: `scaleY(${fill})` }"
    />
    <span :class="['relative font-display text-[13px] leading-none', dim ? 'text-faint' : fill > 0.5 ? 'text-on-accent' : 'text-ink']">
      {{ k }}
    </span>
  </span>
</template>
