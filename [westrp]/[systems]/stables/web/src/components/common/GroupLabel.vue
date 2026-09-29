<script setup>
// Rótulo de grupo dentro das listas (raça, tipo de animal…)
defineProps({
  label: { type: String, required: true },
  hint: { type: String, default: null },
});
</script>

<template>
  <div class="flex shrink-0 items-center justify-between gap-3 px-1 pt-3 pb-1.5">
    <span class="kit-heading shrink-0 text-[11px] text-dim">{{ label }}</span>
    <span v-if="hint || $slots.default" class="flex min-w-0 items-center justify-end gap-2 text-[12px] text-faint">
      <slot>{{ hint }}</slot>
    </span>
  </div>
</template>
