<script setup>
import { computed } from "vue";
import Icon from "./Icon.vue";

// Status tag: active / inactive / locked / new / warning / neutral
const props = defineProps({ kind: { type: String, default: "neutral" } });

const TAGS = {
  active: { icon: "menu-icon-tick", plate: "rgb(var(--kit-accent-rgb) / 0.22)", text: "text-ink", label: "Active" },
  inactive: { icon: "cross", plate: "rgb(var(--kit-text-rgb) / 0.06)", text: "text-faint", label: "Inactive" },
  locked: { icon: "menu-icon-info-lock", plate: "rgb(var(--kit-text-rgb) / 0.1)", text: "text-dim", label: "Required" },
  new: { icon: "menu-icon-info-new", plate: "var(--kit-accent)", text: "text-on-accent", label: "New" },
  warning: { icon: "menu-icon-info-warning", plate: "rgb(var(--kit-accent-rgb) / 0.3)", text: "text-ink", label: "Warning" },
  neutral: { icon: null, plate: "rgb(var(--kit-text-rgb) / 0.08)", text: "text-dim", label: "" },
};
const t = computed(() => TAGS[props.kind] ?? TAGS.neutral);
</script>

<template>
  <span
    :class="['tx-chip kit-heading inline-flex h-6 shrink-0 items-center gap-1.5 px-2.5 text-[9.5px]', t.text]"
    :style="{ '--plate': t.plate }"
  >
    <Icon v-if="t.icon" :name="t.icon" :size="11" />
    <slot>{{ t.label }}</slot>
  </span>
</template>
