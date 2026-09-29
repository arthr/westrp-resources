<script setup>
import Icon from "./Icon.vue";

// Radio group: ring track + filled dot on the chosen option
const model = defineModel({ type: [String, Number], default: null });
defineProps({
  options: { type: Array, required: true },
  disabled: { type: Boolean, default: false },
});
</script>

<template>
  <div role="radiogroup" class="flex flex-col gap-2.5">
    <button
      v-for="o in options"
      :key="o.value"
      type="button"
      role="radio"
      :aria-checked="o.value === model"
      :disabled="disabled || o.disabled"
      :class="['group flex items-center gap-3 text-left outline-none', disabled || o.disabled ? 'cursor-not-allowed opacity-45' : 'cursor-pointer']"
      @click="model = o.value"
    >
      <span class="relative grid h-6 w-6 shrink-0 place-items-center">
        <Icon name="ring-track" :size="22" :class="o.value === model ? 'text-accent' : 'text-dim group-hover:text-ink'" />
        <Icon v-if="o.value === model" name="menu-icon-circle" :size="10" class="absolute text-accent" />
      </span>
      <span class="min-w-0">
        <span :class="['block text-[14px]', o.value === model ? 'text-ink' : 'text-dim']">{{ o.label }}</span>
        <span v-if="o.hint" class="block text-[12px] text-faint">{{ o.hint }}</span>
      </span>
    </button>
  </div>
</template>
