<script setup>
defineProps({ k: { type: String, required: true } });
</script>

<template>
  <span
    class="skin skin-key inline-flex h-[1.45rem] min-w-[1.45rem] items-center justify-center px-1.5 font-display text-[0.58rem] uppercase leading-none tracking-[0.08em] text-paper"
    style="--skin-fill: rgba(245, 243, 238, 0.16)"
  >{{ k }}</span>
</template>
