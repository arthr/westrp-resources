<script setup>
// The game's tick box; the red tick shows when on.
const props = defineProps({
  modelValue: { type: Boolean, default: false },
  label: { type: String, default: "" },
});
const emit = defineEmits(["update:modelValue"]);
const flip = () => emit("update:modelValue", !props.modelValue);
</script>

<template>
  <button
    type="button"
    role="switch"
    :aria-checked="modelValue"
    :aria-label="label"
    class="relative h-[1.35rem] w-[1.35rem] shrink-0 cursor-pointer"
    @click.stop="flip"
  >
    <span class="tex absolute inset-0 text-[rgb(var(--hud-text-rgb)/0.55)]" style="--m: var(--tex-tick-box)" />
    <span v-if="modelValue" class="tex absolute -inset-0.5 text-red" style="--m: var(--tex-tick)" />
  </button>
</template>
