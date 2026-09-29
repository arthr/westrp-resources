<script setup>
import Brackets from "./Brackets.vue";
import CoreMeter from "./CoreMeter.vue";
import { CORE_STYLES } from "./core.js";

// Seletor de estilo: seis cartões com a miniatura de cada estilo.
const model = defineModel({ type: String, required: true });

// Tamanho da miniatura de cada estilo nos cartões (cabe em 44px de altura).
const PREVIEW_SIZE = { half: 44, barsV: 28 };
</script>

<template>
  <div role="radiogroup" aria-label="Core style" class="grid grid-cols-3 gap-3">
    <button
      v-for="s in CORE_STYLES"
      :key="s.value"
      type="button"
      role="radio"
      :aria-checked="s.value === model"
      :class="[
        'tx-frame group relative flex h-[92px] min-w-0 cursor-pointer flex-col items-center justify-center gap-3 outline-none',
        s.value === model
          ? '[--frame:var(--kit-accent)]'
          : '[--frame:rgb(var(--kit-text-rgb)/0.18)] hover:[--frame:rgb(var(--kit-text-rgb)/0.42)] focus-visible:[--frame:rgb(var(--kit-text-rgb)/0.42)]',
      ]"
      @click="model = s.value"
    >
      <span class="grid h-11 place-items-center">
        <CoreMeter :variant="s.value" :size="PREVIEW_SIZE[s.value] ?? 34" :ring="70" :core="60" />
      </span>
      <span :class="['kit-heading text-[10px]', s.value === model ? 'text-ink' : 'text-dim group-hover:text-ink']">{{ s.label }}</span>
      <Brackets v-if="s.value === model" :size="12" />
    </button>
  </div>
</template>
