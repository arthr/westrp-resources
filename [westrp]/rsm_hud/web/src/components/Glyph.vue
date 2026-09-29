<script setup>
// A masked game glyph, tinted by the parent's text colour. The drop shadow sits
// on the wrapper so it follows the glyph's shape instead of its box.
defineProps({
  name: { type: String, required: true },
  size: { type: String, default: "1.25rem" },
});
</script>

<template>
  <span class="hud-glyph inline-flex shrink-0" :style="{ width: size, height: size }" aria-hidden="true">
    <span class="tex block h-full w-full" :style="{ '--m': `var(--tex-${name})` }" />
  </span>
</template>
