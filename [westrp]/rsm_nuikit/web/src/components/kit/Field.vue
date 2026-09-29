<script setup>
// A labelled row used inside cards: label on the left, control on the right.
defineProps({
  label: { type: String, required: true },
  hint: { type: String, default: null },
});
</script>

<template>
  <div class="flex min-w-0 items-center justify-between gap-5">
    <div class="min-w-0">
      <p class="text-[14px] text-ink">{{ label }}</p>
      <p v-if="hint" class="mt-0.5 text-[12px] text-faint">{{ hint }}</p>
    </div>
    <div class="flex shrink-0 items-center gap-3"><slot /></div>
  </div>
</template>
