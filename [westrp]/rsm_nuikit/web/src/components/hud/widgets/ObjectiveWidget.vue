<script setup>
defineProps({ text: { type: String, default: null } });
</script>

<template>
  <p class="flex h-full items-center justify-center text-center text-[20px] text-ink [text-shadow:0_2px_8px_rgb(0_0_0/0.9)]">
    <template v-if="text">{{ text }}</template>
    <template v-else>Ride to&nbsp;<span class="text-accent">Valentine</span>&nbsp;and meet the sheriff.</template>
  </p>
</template>
