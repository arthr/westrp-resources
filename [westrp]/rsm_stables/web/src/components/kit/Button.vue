<script setup>
import { computed } from "vue";
import Icon from "./Icon.vue";

// variant: primary | secondary | ghost · state: active, disabled (+ forced "hover" for the state reference)
const props = defineProps({
  variant: { type: String, default: "secondary" },
  size: { type: String, default: "md" },
  icon: { type: String, default: null },
  active: { type: Boolean, default: false },
  forceHover: { type: Boolean, default: false },
  type: { type: String, default: "button" },
});

const SIZES = {
  sm: "h-9 px-4 text-[11px] gap-2",
  md: "h-11 px-6 text-[12px] gap-2.5",
  lg: "h-13 px-8 text-[13px] gap-3",
};

const cls = computed(() => [
  "btn tx-plate kit-heading inline-flex shrink-0 cursor-pointer items-center justify-center whitespace-nowrap transition-colors active:translate-y-px",
  props.variant === "primary" ? "btn-primary" : props.variant === "ghost" ? "btn-ghost" : "",
  props.active && "is-active",
  props.forceHover && "is-hover",
  SIZES[props.size],
]);
</script>

<template>
  <button :type="type" :class="cls">
    <Icon v-if="icon" :name="icon" :size="size === 'sm' ? 14 : 16" />
    <slot />
  </button>
</template>
