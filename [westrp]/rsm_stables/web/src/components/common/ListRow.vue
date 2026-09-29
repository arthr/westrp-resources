<script setup>
// Linha de lista no plate de seleção do RDR: a atual ganha o plate de destaque.
defineProps({
  current: { type: Boolean, default: false },
  inactive: { type: Boolean, default: false },
  title: { type: String, required: true },
  sub: { type: String, default: null },
});
</script>

<template>
  <button
    type="button"
    :aria-current="current ? 'true' : undefined"
    :class="[
      'row tx-plate flex w-full shrink-0 cursor-pointer items-center gap-3.5 px-4 py-2.5 text-left transition-colors',
      current ? 'is-current' : inactive ? 'is-inactive' : 'text-ink',
    ]"
  >
    <slot name="lead" />
    <span class="min-w-0 flex-1">
      <span class="block truncate text-[14px]">{{ title }}</span>
      <span v-if="sub" :class="['mt-0.5 block truncate text-[12px]', current ? 'opacity-80' : 'text-faint']">{{ sub }}</span>
    </span>
    <span v-if="$slots.trail" class="flex shrink-0 items-center gap-2"><slot name="trail" /></span>
  </button>
</template>
