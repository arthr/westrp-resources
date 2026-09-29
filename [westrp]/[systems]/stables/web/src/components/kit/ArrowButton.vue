<script setup>
import Icon from "./Icon.vue";

defineProps({
  dir: { type: String, required: true },
  label: { type: String, required: true },
  disabled: { type: Boolean, default: false },
});
</script>

<template>
  <button type="button" :aria-label="label" :disabled="disabled" class="arrow-btn grid h-7 w-7 shrink-0 cursor-pointer place-items-center">
    <Icon :name="`selection-arrow-${dir}`" :size="18" />
  </button>
</template>
