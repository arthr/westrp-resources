<script setup>
import { computed } from "vue";
import CoreMeter from "../CoreMeter.vue";
import { hud } from "../../store/hud.js";
import { layout } from "../../store/layout.js";
import { t } from "../../locale.js";

const CORES = [
  { key: "health", icon: "core-health" },
  { key: "stamina", icon: "core-stamina" },
  { key: "deadeye", icon: "core-deadeye" },
];

// Barras horizontais ficam uma embaixo da outra; os outros estilos, lado a lado.
const stacked = computed(() => layout.prefs.meterStyle === "bars-h");
</script>

<template>
  <div class="flex" :class="stacked ? 'flex-col items-start gap-1.5' : 'items-start gap-3'">
    <CoreMeter
      v-for="c in CORES"
      :key="c.key"
      :icon="c.icon"
      :label="t(`core.${c.key}`)"
      :ring="hud.cores[c.key].ring"
      :core="hud.cores[c.key].core"
      :gold-core="!!hud.cores[c.key].goldCore"
      :gold-ring="!!hud.cores[c.key].goldRing"
      :gold-core-ending="!!hud.cores[c.key].goldCoreEnding"
      :gold-ring-ending="!!hud.cores[c.key].goldRingEnding"
      size="4.25rem"
      :show-value="layout.prefs.values"
    />
  </div>
</template>
