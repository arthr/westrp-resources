<script setup>
import { StatBar } from "../kit";

// Atributos na barra segmentada de armas do RDR (13:1, nunca esticada)
defineProps({
  stats: { type: Object, required: true },
  rows: { type: Array, required: true },
});
</script>

<template>
  <div class="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-x-5 gap-y-3">
    <template v-for="[key, label] in rows" :key="key">
      <span class="truncate text-[13px] text-dim">{{ label }}</span>
      <StatBar :value="stats[key] ?? 0" :width="192" />
    </template>
  </div>
</template>
