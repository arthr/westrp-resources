<script setup>
import { computed, reactive } from "vue";
import { useKit } from "../../../state/kit.js";
import { Card, CoreMeter, CoreStylePicker, SliderField, Tag } from "../../kit";

const CORES = [
  { id: "health", label: "Health", icon: "core-health" },
  { id: "stamina", label: "Stamina", icon: "core-stamina" },
  { id: "deadeye", label: "Dead Eye", icon: "core-deadeye" },
];
// Nome do valor externo em cada estilo (anel, barra ou número)
const OUTER = { ring: "Ring", half: "Ring", segmented: "Ring", barsH: "Bar", barsV: "Bar", numeric: "Value" };
// Tamanho das pré-visualizações: as barras horizontais são largas, então um pouco menores
const PREVIEW = { barsH: 80 };

const kit = useKit();
const variant = computed(() => kit.state.hud.coreStyle);
const outer = computed(() => OUTER[variant.value]);
const vals = reactive({
  health: { ring: 82, core: 70 },
  stamina: { ring: 64, core: 92 },
  deadeye: { ring: 22, core: 40 },
});
const pct = (v) => `${v}%`;
</script>

<template>
  <Card
    title="Core Meters"
    :kicker="`${outer} is the outer value · the icon fills with the core`"
    body-class="grid gap-8 min-[1600px]:grid-cols-[minmax(0,22rem)_minmax(0,1fr)]"
  >
    <template #right><Tag :kind="kit.isActive('cores') ? 'active' : 'inactive'" /></template>
    <div class="flex min-w-0 flex-col gap-3">
      <p class="kit-heading text-[10px] text-faint">Core Style</p>
      <CoreStylePicker :model-value="variant" @update:model-value="(style) => kit.dispatch({ type: 'hud/coreStyle', style })" />
      <p class="text-[12.5px] leading-snug text-faint">
        <template v-if="kit.hostOwns('cores')">{{ kit.state.host.name }} draws the cores while it runs; this style applies without it.</template>
        <template v-else>The chosen style is what players see on the HUD.</template>
      </p>
    </div>
    <div class="grid min-w-0 grid-cols-3 gap-6">
      <div v-for="c in CORES" :key="c.id" class="flex min-w-0 flex-col items-center gap-4">
        <div class="grid h-[150px] w-full place-items-center">
          <CoreMeter :variant="variant" :icon="c.icon" :ring="vals[c.id].ring" :core="vals[c.id].core" :size="PREVIEW[variant] ?? 96" />
        </div>
        <p class="kit-heading text-[12px] text-ink">{{ c.label }}</p>
        <div class="flex w-full flex-col gap-3">
          <SliderField v-model="vals[c.id].ring" :label="outer" :format="pct" />
          <SliderField v-model="vals[c.id].core" label="Core" :format="pct" />
        </div>
      </div>
    </div>
  </Card>
</template>
