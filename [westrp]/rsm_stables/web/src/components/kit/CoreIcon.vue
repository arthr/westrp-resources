<script setup>
import { computed } from "vue";
import { GLYPH } from "./core.js";

// Ícone do core: a própria arte é a máscara e o gradiente é o nível.
const props = defineProps({
  icon: { type: String, required: true },
  core: { type: Number, required: true },
});

const style = computed(() => {
  const g = GLYPH[props.icon] ?? { top: 0, bottom: 100 };
  const level = 100 - g.bottom + (props.core / 100) * (g.bottom - g.top);
  const low = props.core <= 15;
  return {
    transform: `translateY(${50 - (g.top + g.bottom) / 2}%)`,
    "--ico": `var(--tex-${props.icon})`,
    "--core-fill": `${level}%`,
    "--core-on": low ? "var(--kit-accent)" : "var(--kit-text)",
    animation: low ? "kit-pulse 1.1s ease-in-out infinite" : undefined,
  };
});
</script>

<template>
  <span class="core-icon" :style="style" />
</template>
