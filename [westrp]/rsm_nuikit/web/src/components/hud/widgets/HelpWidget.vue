<script setup>
import { KeyCap } from "../../kit";

defineProps({
  text: { type: String, default: null },
  k: { type: String, default: null },
});
</script>

<template>
  <div class="tx-help flex h-full items-center gap-4 px-6">
    <KeyCap v-if="text ? k : true" :k="text ? k : 'G'" :size="26" />
    <p class="line-clamp-3 text-[14px] leading-snug text-ink">
      <template v-if="text">{{ text }}</template>
      <template v-else>Hold near a register to rob it. Lawmen in town <span class="text-accent">will notice</span>.</template>
    </p>
  </div>
</template>
