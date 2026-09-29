<script setup>
import { computed } from "vue";
import { Icon } from "../kit";
import { px } from "../kit/surface.js";
import { TOAST_H } from "./dims.js";

// Feed notification on the toast plate. `ttl` (ms) draws the draining timer line.
// Altura fixa e texto em no máximo 2 linhas: o feed tem uma área exata no HUD.
const props = defineProps({
  type: { type: String, default: "info" },
  title: { type: String, default: "" },
  body: { type: String, default: "" },
  ttl: { type: Number, default: null },
  width: { type: [Number, String], default: 380 },
});

const ICONS = {
  info: { name: "menu-icon-invite-sent", tone: "text-ink" },
  success: { name: "menu-icon-tick", tone: "text-ink" },
  warning: { name: "menu-icon-alert", tone: "text-accent" },
  error: { name: "cross", tone: "text-accent" },
};
const icon = computed(() => ICONS[props.type] ?? ICONS.info);
const w = computed(() => (typeof props.width === "number" ? `${props.width}px` : props.width));
const h = px(TOAST_H);
</script>

<template>
  <div class="tx-toast flex items-center gap-4 py-3 pr-6 pl-5 text-left" :style="{ width: w, height: h }">
    <span class="grid h-11 w-11 shrink-0 place-items-center">
      <Icon :name="icon.name" :size="30" :class="icon.tone" />
    </span>
    <div class="min-w-0 flex-1">
      <p class="kit-heading truncate text-[12px] text-ink">{{ title }}</p>
      <p class="mt-1 line-clamp-2 text-[13px] leading-snug text-dim">{{ body }}</p>
      <div
        v-if="ttl"
        aria-hidden="true"
        class="ln-h mt-2.5 origin-left"
        :style="{ '--line-fill': 'var(--kit-accent)', animation: `kit-drain ${ttl}ms linear forwards` }"
      />
    </div>
  </div>
</template>
