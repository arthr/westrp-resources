<script setup>
import { computed } from "vue";
import CoreMeter from "../CoreMeter.vue";
import Glyph from "../Glyph.vue";
import { hud } from "../../store/hud.js";
import { layout } from "../../store/layout.js";
import { t } from "../../locale.js";

// Barras horizontais ficam uma embaixo da outra; os outros estilos, lado a lado.
const stacked = computed(() => layout.prefs.meterStyle === "bars-h");
</script>

<template>
  <div class="flex flex-col items-start gap-1.5">
    <div class="hud-text flex items-center gap-1.5 pl-1">
      <Glyph name="g-horse" size="1.1rem" class="text-paper" />
      <span v-if="hud.horse.name" class="font-display text-[0.78rem] uppercase tracking-[0.16em] text-paper">{{ hud.horse.name }}</span>
      <span class="font-display text-[0.62rem] uppercase tracking-[0.14em] text-dim">{{ t("horse.bond") }} {{ hud.horse.bond }}</span>
    </div>
    <div class="flex" :class="stacked ? 'flex-col items-start gap-1.5' : 'items-start gap-2'">
      <CoreMeter
        icon="core-horse-health"
        :label="t('core.horseHealth')"
        :ring="hud.horse.health.ring"
        :core="hud.horse.health.core"
        :gold-core="!!hud.horse.health.goldCore"
        :gold-ring="!!hud.horse.health.goldRing"
        :gold-core-ending="!!hud.horse.health.goldCoreEnding"
        :gold-ring-ending="!!hud.horse.health.goldRingEnding"
        size="3.5rem"
        :show-value="layout.prefs.values"
      />
      <CoreMeter
        icon="core-horse-stamina"
        :label="t('core.horseStamina')"
        :ring="hud.horse.stamina.ring"
        :core="hud.horse.stamina.core"
        :gold-core="!!hud.horse.stamina.goldCore"
        :gold-ring="!!hud.horse.stamina.goldRing"
        :gold-core-ending="!!hud.horse.stamina.goldCoreEnding"
        :gold-ring-ending="!!hud.horse.stamina.goldRingEnding"
        size="3.5rem"
        :show-value="layout.prefs.values"
      />
    </div>
  </div>
</template>
