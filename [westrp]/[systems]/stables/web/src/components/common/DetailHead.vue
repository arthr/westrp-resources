<script setup>
import { Divider } from "../kit";

// Topo do painel de detalhes: rótulo, nome grande e linha de apoio.
defineProps({
  kicker: { type: String, default: null },
  title: { type: String, required: true },
  sub: { type: String, default: null },
});
</script>

<template>
  <header class="flex shrink-0 flex-col gap-4">
    <div class="flex items-start justify-between gap-4">
      <div class="min-w-0">
        <p v-if="kicker" class="kit-heading truncate text-[10px] text-faint">{{ kicker }}</p>
        <h2 class="mt-2 font-title text-[clamp(30px,2.2vw,40px)] leading-[0.95] break-words text-ink">{{ title }}</h2>
        <p v-if="sub" class="mt-2 truncate text-[14px] text-dim">{{ sub }}</p>
      </div>
      <div v-if="$slots.right" class="flex shrink-0 flex-col items-end gap-2 pt-1"><slot name="right" /></div>
    </div>
    <Divider />
  </header>
</template>
