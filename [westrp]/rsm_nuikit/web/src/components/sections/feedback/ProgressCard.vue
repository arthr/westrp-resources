<script setup>
import { ref } from "vue";
import { Card, Divider, ProgressBar, SliderField, StatBar } from "../../kit";

const value = ref(64);
const STATS = [
  ["Damage", 56],
  ["Range", 42],
  ["Fire rate", 50],
  ["Accuracy", 64],
  ["Reload", 38],
];
</script>

<template>
  <Card title="Progress" kicker="Bars and loaders" body-class="flex flex-col gap-5">
    <div class="flex flex-col gap-2">
      <div class="flex items-baseline justify-between text-[13px]">
        <span class="text-dim">Crafting Special Tonic</span>
        <span class="font-cat text-ink">{{ value }}%</span>
      </div>
      <ProgressBar :value="value" />
    </div>
    <SliderField v-model="value" label="Drive the bar" :format="(v) => `${v}%`" />
    <div class="flex flex-col gap-2">
      <span class="text-[13px] text-dim">Loading saved outfits…</span>
      <ProgressBar />
    </div>
    <Divider />
    <p class="kit-heading text-[10px] text-faint">Weapon stats · Cattleman Revolver</p>
    <div v-for="[label, v] in STATS" :key="label" class="flex items-center justify-between gap-4 text-[13px]">
      <span class="text-dim">{{ label }}</span>
      <StatBar :value="v" :width="208" />
    </div>
  </Card>
</template>
