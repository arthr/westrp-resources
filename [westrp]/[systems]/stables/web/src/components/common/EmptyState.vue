<script setup>
import { Icon } from "../kit";

// Aviso de lista vazia, com ação opcional logo abaixo
defineProps({
  icon: { type: String, default: "blip-stable" },
  title: { type: String, required: true },
  body: { type: String, default: null },
});
</script>

<template>
  <div class="tx-help flex flex-col items-center gap-3 px-8 py-8 text-center">
    <Icon :name="icon" :size="30" class="text-dim" />
    <p class="kit-heading text-[12px] text-ink">{{ title }}</p>
    <p v-if="body" class="max-w-[22rem] text-[13px] leading-relaxed text-faint">{{ body }}</p>
    <div v-if="$slots.default" class="mt-1"><slot /></div>
  </div>
</template>
