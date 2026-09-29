<script setup>
import { computed } from "vue";
import Glyph from "../Glyph.vue";
import { hud } from "../../store/hud.js";
import { t } from "../../locale.js";

// $142.35 no estilo do RDR: dólares grandes, centavos pequenos e elevados.
const cash = computed(() => {
  const cents = Math.round((Number(hud.money.cash) || 0) * 100);
  return { dollars: Math.floor(cents / 100).toLocaleString("en-US"), cents: String(cents % 100).padStart(2, "0") };
});
const gold = computed(() => (Number(hud.money.gold) || 0).toFixed(2));
</script>

<template>
  <div class="skin skin-plate flex flex-col gap-1.5 px-[1.125rem] py-[0.65rem]" style="--skin-fill: rgb(var(--hud-surface-rgb) / calc(0.62 * var(--hud-surface-k)))">
    <div class="flex items-center justify-end gap-2.5">
      <Glyph name="g-cash" size="1.45rem" class="text-paper" />
      <span class="hud-text flex items-start font-num text-paper">
        <span class="text-[1.05rem] leading-none">$</span>
        <span class="text-[1.9rem] leading-none tracking-wide">{{ cash.dollars }}</span>
        <span class="pl-0.5 text-[0.95rem] leading-none">{{ cash.cents }}</span>
      </span>
    </div>
    <div class="flex items-center justify-end gap-2.5">
      <Glyph name="g-gold" size="1.3rem" class="text-dim" />
      <span class="hud-text flex items-baseline gap-1.5 font-num">
        <span class="text-[1.25rem] leading-none tracking-wide text-paper">{{ gold }}</span>
        <span class="font-display text-[0.6rem] uppercase tracking-[0.18em] text-dim">{{ t("money.gold") }}</span>
      </span>
    </div>
  </div>
</template>
