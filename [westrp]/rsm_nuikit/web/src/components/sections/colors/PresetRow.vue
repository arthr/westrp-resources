<script setup>
import { Brackets, Swatch } from "../../kit";

defineProps({
  preset: { type: Object, required: true },
  current: { type: Boolean, default: false },
});
</script>

<template>
  <button
    type="button"
    :class="['row tx-plate relative flex cursor-pointer items-center justify-between gap-3 px-3.5 py-2.5 text-left', current && 'is-selected']"
  >
    <span class="kit-heading truncate text-[11px] text-ink">{{ preset.name }}</span>
    <span class="flex shrink-0">
      <Swatch :color="preset.accent" :size="16" />
      <Swatch :color="preset.surface" :size="16" />
      <Swatch :color="preset.text" :size="16" />
    </span>
    <Brackets v-if="current" :size="10" />
  </button>
</template>
