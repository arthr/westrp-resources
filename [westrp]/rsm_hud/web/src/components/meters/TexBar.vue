<script setup>
import { computed } from "vue";

// Barra horizontal feita com a barra de atributos das armas do RDR2: a arte
// inteira é o trilho, a variante "mask" é o preenchimento, cortado no valor.
// Para barra vertical, o pai gira este componente.
// Atributo fortificado (Golden Core): preenchimento dourado com brilho pulsante.
const props = defineProps({
  pct: { type: Number, default: 0 },
  alert: { type: Boolean, default: false },
  gold: { type: Boolean, default: false },
  goldEnding: { type: Boolean, default: false },
  length: { type: String, required: true },
  thickness: { type: String, required: true },
});

const cut = computed(() => `inset(0 ${100 - Math.min(100, Math.max(0, props.pct))}% 0 0)`);
const fill = computed(() => (props.gold ? "var(--gold)" : props.alert ? "var(--red)" : "var(--text)"));
</script>

<template>
  <span class="hud-glyph relative block shrink-0" :style="{ width: length, height: thickness, '--bar-h': thickness }">
    <span class="skin skin-bar absolute inset-0" style="--skin-fill: rgba(245, 243, 238, 0.18)" />
    <span v-if="gold" class="gold-glow absolute inset-0" :class="{ ending: goldEnding }">
      <span
        class="skin skin-bar-fill absolute inset-0"
        :style="{ '--skin-fill': 'var(--gold-bright)', clipPath: cut }"
      />
    </span>
    <span
      class="skin skin-bar-fill absolute inset-0 transition-[clip-path] duration-500 ease-out"
      :style="{ '--skin-fill': fill, clipPath: cut }"
    />
  </span>
</template>
