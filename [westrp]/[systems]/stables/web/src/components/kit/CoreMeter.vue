<script setup>
import { computed } from "vue";
import CoreIcon from "./CoreIcon.vue";
import { barFill, coreDims, segmentGradient } from "./core.js";
import { px, texMask } from "./surface.js";

// RDR core in six styles. The ring / bar / number shows `ring`; the icon fills
// from the bottom with `core`. Both 0-100; low values turn to the accent.
const props = defineProps({
  icon: { type: String, default: "core-health" },
  ring: { type: Number, default: 100 },
  core: { type: Number, default: 100 },
  size: { type: Number, default: 64 },
  variant: { type: String, default: "ring" },
});

const OFF = "rgb(var(--kit-text-rgb) / 0.22)";
const ringLow = computed(() => props.ring <= 25);
const on = computed(() => (ringLow.value ? "var(--kit-accent)" : "var(--kit-text)"));
const box = computed(() => {
  const [w, h] = coreDims(props.variant, props.size);
  return { width: px(w), height: px(h) };
});
const small = computed(() => ({ width: px(props.size * 0.5), height: px(props.size * 0.5) }));
const disc = computed(() => ({ width: px(props.size), height: px(props.size) }));
const bar = computed(() => ({ background: barFill(props.ring, on.value, OFF) }));
// barsV: a mesma arte da barra, girada 90°; a proporção da arte continua intacta
const len = computed(() => props.size * 0.9);
</script>

<template>
  <!-- meio-anel por cima (das 9 às 3 horas), ícone apoiado na base do arco -->
  <div v-if="variant === 'half'" class="relative shrink-0 overflow-hidden" :style="box">
    <span
      class="absolute top-0 left-0"
      :style="{ ...disc, ...texMask('ring-track'), background: `conic-gradient(from 270deg, ${OFF} 0deg 180deg, transparent 180deg)` }"
    />
    <span
      class="absolute top-0 left-0"
      :style="{ ...disc, ...texMask('ring-full'), background: `conic-gradient(from 270deg, ${on} 0deg ${ring * 1.8}deg, transparent ${ring * 1.8}deg)` }"
    />
    <CoreIcon
      :icon="icon"
      :core="core"
      class="absolute"
      :style="{ left: px(size * 0.3), top: px(size * 0.2), width: px(size * 0.4), height: px(size * 0.4) }"
    />
  </div>

  <div v-else-if="variant === 'segmented'" class="relative shrink-0" :style="box">
    <span class="absolute inset-0" :style="{ ...texMask('ring-full'), background: segmentGradient(ring, on, OFF) }" />
    <CoreIcon :icon="icon" :core="core" class="absolute" :style="{ inset: '24%' }" />
  </div>

  <div v-else-if="variant === 'barsH'" class="flex shrink-0 items-center" :style="{ ...box, gap: px(size * 0.12) }">
    <CoreIcon :icon="icon" :core="core" class="relative shrink-0" :style="small" />
    <div class="tx-bar min-w-0 flex-1" :style="bar" />
  </div>

  <div v-else-if="variant === 'barsV'" class="flex shrink-0 flex-col items-center" :style="{ ...box, gap: px(size * 0.1) }">
    <CoreIcon :icon="icon" :core="core" class="relative shrink-0" :style="small" />
    <div class="relative shrink-0" :style="{ width: '12px', height: px(len) }">
      <div
        class="tx-bar absolute"
        :style="{ ...bar, width: px(len), left: px((12 - len) / 2), top: px((len - 12) / 2), transform: 'rotate(-90deg)' }"
      />
    </div>
  </div>

  <div v-else-if="variant === 'numeric'" class="flex shrink-0 items-center" :style="{ ...box, gap: px(size * 0.12) }">
    <CoreIcon :icon="icon" :core="core" class="relative shrink-0" :style="small" />
    <span
      :class="['tx-chip grid shrink-0 place-items-center font-cat leading-none', ringLow ? 'text-accent' : 'text-ink']"
      :style="{
        width: px(size * 0.75),
        height: px(size * 0.5),
        fontSize: px(size * 0.26),
        '--plate': 'rgb(var(--kit-text-rgb) / 0.1)',
      }"
    >
      {{ Math.round(ring) }}
    </span>
  </div>

  <!-- ring (padrão) -->
  <div v-else class="relative shrink-0" :style="box">
    <span class="absolute inset-0" :style="{ ...texMask('ring-track'), background: OFF }" />
    <span class="absolute inset-0" :style="{ ...texMask('ring-full'), background: `conic-gradient(${on} ${ring * 3.6}deg, transparent 0deg)` }" />
    <CoreIcon :icon="icon" :core="core" class="absolute" :style="{ inset: '24%' }" />
  </div>
</template>
