<script setup>
import { computed } from "vue";
import CoreMeter from "../CoreMeter.vue";
import { hud } from "../../store/hud.js";
import { layout } from "../../store/layout.js";
import { t } from "../../locale.js";

// iconScale encaixa cada glifo no disco do core: fome e sede já vêm recortadas
// no desenho, o emote ocupa o quadro inteiro e os ícones rpg são desenhados
// pequenos dentro do deles. Todos terminam com ~45% do disco.
const NEEDS = [
  { key: "hunger", icon: "need-hunger", iconScale: 0.46 },
  { key: "thirst", icon: "need-thirst", iconScale: 0.46 },
  { key: "stress", icon: "need-stress", iconScale: 0.95, invert: true },
  { key: "hygiene", icon: "need-hygiene", iconScale: 0.95 },
  { key: "alcohol", icon: "need-alcohol", iconScale: 0.5, invert: true },
];

// Necessidade desligada no servidor chega como false e não é desenhada.
// Barras horizontais ficam uma embaixo da outra; os outros estilos, lado a lado.
const stacked = computed(() => layout.prefs.meterStyle === "bars-h");

const active = computed(() => NEEDS.filter((n) => typeof hud.needs[n.key] === "number"));
</script>

<template>
  <div class="flex" :class="stacked ? 'flex-col items-start gap-1.5' : 'items-start gap-2.5'">
    <CoreMeter
      v-for="n in active"
      :key="n.key"
      :icon="n.icon"
      :label="t(`need.${n.key}`)"
      :ring="hud.needs[n.key]"
      :icon-scale="n.iconScale"
      :invert="!!n.invert"
      size="3rem"
      :show-value="layout.prefs.values"
    />
  </div>
</template>
