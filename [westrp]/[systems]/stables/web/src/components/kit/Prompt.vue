<script setup>
import KeyCap from "./KeyCap.vue";

// Static prompt row: keycap + label on the prompt strip
defineProps({
  k: { type: String, required: true },
  label: { type: String, required: true },
  dim: { type: Boolean, default: false },
  fill: { type: Number, default: 0 },
});
</script>

<template>
  <div :class="['tx-prompt flex h-11 w-max min-w-[15rem] items-center gap-3 py-1.5 pr-6 pl-2', dim && 'opacity-60']">
    <KeyCap :k="k" :fill="fill" :dim="dim" />
    <span :class="['text-[14px]', dim ? 'text-faint' : 'text-ink']">{{ label }}</span>
  </div>
</template>
