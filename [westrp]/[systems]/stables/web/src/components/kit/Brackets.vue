<script setup>
// The inventory selection brackets: all four corners, always on the same box.
defineProps({
  size: { type: Number, default: 14 },
  fill: { type: String, default: "var(--kit-accent)" },
});

const CORNERS = [
  ["tl", { top: "0", left: "0" }],
  ["tr", { top: "0", right: "0" }],
  ["bl", { bottom: "0", left: "0" }],
  ["br", { bottom: "0", right: "0" }],
];
</script>

<template>
  <span
    v-for="[c, pos] in CORNERS"
    :key="c"
    aria-hidden="true"
    class="ico pointer-events-none absolute"
    :style="{ ...pos, width: `${size}px`, height: `${size}px`, '--ico': `var(--tex-crafting-highlight-${c})`, '--ico-fill': fill }"
  />
</template>
