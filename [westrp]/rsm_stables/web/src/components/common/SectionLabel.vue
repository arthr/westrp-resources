<script setup>
// Título pequeno de bloco dentro do painel de detalhes
defineProps({ label: { type: String, required: true } });
</script>

<template>
  <div class="flex items-center justify-between gap-3">
    <h3 class="kit-heading text-[11px] text-dim">{{ label }}</h3>
    <span v-if="$slots.default" class="flex items-center gap-2 text-[12px] text-faint"><slot /></span>
  </div>
</template>
