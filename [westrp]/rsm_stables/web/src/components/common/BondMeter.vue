<script setup>
import { Icon } from "../kit";

// Vínculo com o cavalo: quatro ferraduras do mapa do RDR, acesas até o nível
defineProps({
  level: { type: Number, required: true },
  size: { type: Number, default: 18 },
  // sobre a linha selecionada (plate de destaque) as ferraduras usam a cor do texto dela
  onAccent: { type: Boolean, default: false },
});
</script>

<template>
  <span class="flex shrink-0 items-center gap-1" :title="`Vínculo ${level} de 4`">
    <Icon
      v-for="i in 4"
      :key="i"
      :name="i <= level ? 'blip-horseshoe-4' : 'blip-horseshoe-0'"
      :size="size"
      :fill="i <= level ? (onAccent ? 'var(--kit-on-accent)' : 'var(--kit-accent)') : onAccent ? 'rgb(0 0 0 / 0.3)' : 'rgb(var(--kit-text-rgb) / 0.22)'"
    />
  </span>
</template>
