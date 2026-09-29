<script setup>
import { useAttrs } from "vue";
import Brackets from "./Brackets.vue";

// Colour swatch on the swatch plate (square art, never stretched).
// Com @click vira botão; sem, é só a amostra.
defineProps({
  color: { type: String, required: true },
  size: { type: Number, default: 36 },
  selected: { type: Boolean, default: false },
  label: { type: String, default: null },
});
const attrs = useAttrs();
</script>

<template>
  <component
    :is="attrs.onClick ? 'button' : 'span'"
    :type="attrs.onClick ? 'button' : undefined"
    :title="label ?? color"
    :aria-label="label ?? color"
    :class="['relative grid shrink-0 place-items-center', attrs.onClick && 'cursor-pointer']"
    :style="{ width: `${size + 10}px`, height: `${size + 10}px` }"
  >
    <span class="ico" :style="{ width: `${size}px`, height: `${size}px`, '--ico': 'var(--tex-swatch-bg-1a)', '--ico-fill': color }" />
    <Brackets v-if="selected" :size="10" fill="var(--kit-text)" />
  </component>
</template>
