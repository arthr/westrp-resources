<script setup>
import { Swatch } from "../../kit";

defineProps({
  role: { type: Object, required: true },
  color: { type: String, required: true },
  current: { type: Boolean, default: false },
});
</script>

<template>
  <button type="button" :class="['row tx-plate flex cursor-pointer items-center gap-3.5 px-3.5 py-3 text-left', current && 'is-selected']">
    <Swatch :color="color" :size="30" />
    <span class="min-w-0 flex-1">
      <span class="flex items-baseline justify-between gap-2">
        <span class="kit-heading text-[12px] text-ink">{{ role.label }}</span>
        <span class="font-cat text-[12px] text-dim">{{ color }}</span>
      </span>
      <span class="mt-0.5 block text-[12px] leading-snug text-faint">{{ role.desc }}</span>
    </span>
  </button>
</template>
