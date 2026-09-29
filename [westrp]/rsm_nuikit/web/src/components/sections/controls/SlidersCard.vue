<script setup>
import { ref } from "vue";
import { Card, SliderField } from "../../kit";

const music = ref(70);
const sfx = ref(85);
const bet = ref(12.5);
const pct = (v) => `${v}%`;
</script>

<template>
  <Card title="Sliders" kicker="Bar track, diamond thumb" body-class="flex flex-col gap-5">
    <SliderField v-model="music" label="Music volume" :format="pct" />
    <SliderField v-model="sfx" label="Effects volume" :format="pct" />
    <SliderField v-model="bet" label="Poker bet" :min="0.5" :max="50" :step="0.5" :format="(v) => `$${v.toFixed(2)}`" />
    <SliderField :model-value="20" label="Controller dead zone" disabled :format="pct" />
  </Card>
</template>
