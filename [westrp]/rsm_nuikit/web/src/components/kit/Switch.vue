<script setup>
// Two-state switch on chip plates: the lit half is the current state.
const model = defineModel({ type: Boolean, default: false });
defineProps({
  disabled: { type: Boolean, default: false },
  labels: { type: Array, default: () => ["Active", "Inactive"] },
  width: { type: String, default: "10.5rem" },
});
</script>

<template>
  <button
    type="button"
    role="switch"
    :aria-checked="model"
    :disabled="disabled"
    :class="['tx-chip grid shrink-0 grid-cols-2 gap-1 p-1 outline-none', disabled ? 'cursor-not-allowed opacity-50' : 'cursor-pointer']"
    :style="{ width, '--plate': 'rgb(0 0 0 / 0.4)' }"
    @click="model = !model"
  >
    <span
      :class="['tx-chip kit-heading py-1.5 text-center text-[9.5px]', model ? 'text-on-accent' : 'text-faint']"
      :style="{ '--plate': model ? 'var(--kit-accent)' : 'transparent' }"
    >
      {{ labels[0] }}
    </span>
    <span
      :class="['tx-chip kit-heading py-1.5 text-center text-[9.5px]', model ? 'text-faint' : 'text-ink']"
      :style="{ '--plate': model ? 'transparent' : 'rgb(var(--kit-text-rgb) / 0.16)' }"
    >
      {{ labels[1] }}
    </span>
  </button>
</template>
