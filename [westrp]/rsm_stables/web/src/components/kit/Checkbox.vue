<script setup>
import Icon from "./Icon.vue";

// Checkbox: tick_box frame + tick mark
const model = defineModel({ type: Boolean, default: false });
defineProps({
  label: { type: String, default: null },
  hint: { type: String, default: null },
  disabled: { type: Boolean, default: false },
});
</script>

<template>
  <button
    type="button"
    role="checkbox"
    :aria-checked="model"
    :disabled="disabled"
    :class="['group flex min-w-0 items-center gap-3 text-left outline-none', disabled ? 'cursor-not-allowed opacity-45' : 'cursor-pointer']"
    @click="model = !model"
  >
    <span class="relative grid h-6 w-6 shrink-0 place-items-center">
      <Icon
        name="tick-box"
        :size="24"
        :class="disabled ? 'text-faint' : 'text-dim group-hover:text-ink group-focus-visible:text-accent'"
      />
      <Icon v-if="model" name="tick" :size="22" class="absolute -top-1 left-1 text-accent" />
    </span>
    <span v-if="label" class="min-w-0">
      <span class="block text-[14px] text-ink">{{ label }}</span>
      <span v-if="hint" class="block text-[12px] text-faint">{{ hint }}</span>
    </span>
  </button>
</template>
