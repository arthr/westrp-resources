<script setup>
// Tab strip on chip plates; the current tab takes the accent plate.
const model = defineModel({ type: [String, Number], default: null });
defineProps({
  items: { type: Array, required: true },
  size: { type: String, default: "md" },
});
</script>

<template>
  <div role="tablist" class="flex flex-wrap items-center gap-1.5">
    <button
      v-for="it in items"
      :key="it.value"
      type="button"
      role="tab"
      :aria-selected="it.value === model"
      :disabled="it.disabled"
      :class="[
        'tx-chip kit-heading inline-flex cursor-pointer items-center gap-2 whitespace-nowrap outline-none transition-colors disabled:cursor-not-allowed disabled:opacity-40',
        size === 'sm' ? 'h-8 px-3.5 text-[10px]' : 'h-9 px-4.5 text-[11px]',
        it.value === model ? 'text-on-accent' : 'text-dim hover:text-ink focus-visible:text-ink',
      ]"
      :style="{ '--plate': it.value === model ? 'var(--kit-accent)' : 'rgb(var(--kit-text-rgb) / 0.06)' }"
      @click="model = it.value"
    >
      {{ it.label }}
      <span v-if="it.count != null" :class="it.value === model ? 'opacity-80' : 'text-faint'">{{ it.count }}</span>
    </button>
  </div>
</template>
