<script setup>
defineProps({ fill: { type: String, default: null } });
</script>

<template>
  <div aria-hidden="true" class="ln-h w-full shrink-0" :style="fill ? { '--line-fill': fill } : undefined" />
</template>
