<script setup>
import { computed } from "vue";
import { hud } from "../../store/hud.js";
import { t } from "../../locale.js";

const bounty = computed(() => (Number(hud.wanted.bounty) || 0).toFixed(2));
</script>

<template>
  <!-- A caixa segue a proporção da arte recortada (452×152), então a placa nunca distorce. -->
  <div class="relative flex aspect-[452/152] w-[16.5rem] flex-col items-center justify-center gap-1">
    <span class="tex absolute inset-0 text-[rgb(var(--hud-accent-rgb)/0.82)]" style="--m: var(--tex-wanted-plate)" />
    <span class="hud-text relative font-title text-[2rem] leading-none text-on-accent">{{ t("wanted.title") }}</span>
    <span class="relative flex items-baseline gap-2">
      <span class="hud-text font-num text-[1.05rem] leading-none text-on-accent">${{ bounty }}</span>
      <span class="hud-text font-display text-[0.6rem] uppercase tracking-[0.18em] text-on-accent">{{ hud.wanted.region }}</span>
    </span>
  </div>
</template>
