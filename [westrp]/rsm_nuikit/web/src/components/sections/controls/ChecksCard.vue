<script setup>
import { ref } from "vue";
import { Card, Checkbox, Divider, RadioGroup } from "../../kit";

const blips = ref(true);
const cine = ref(false);
const diff = ref("gunslinger");
const OPTIONS = [
  { value: "greenhorn", label: "Greenhorn", hint: "Forgiving aim assist" },
  { value: "gunslinger", label: "Gunslinger", hint: "Standard assist" },
  { value: "outlaw", label: "Outlaw", hint: "Free aim only", disabled: true },
];
</script>

<template>
  <Card title="Checks & Radios" kicker="Tick box and ring" body-class="flex flex-col gap-4">
    <Checkbox v-model="blips" label="Show map blips" hint="Stores, stables, post offices" />
    <Checkbox v-model="cine" label="Cinematic camera" hint="While riding on roads" />
    <Checkbox :model-value="false" disabled label="Hardcore mode" hint="Set by the server owner" />
    <Divider />
    <RadioGroup v-model="diff" :options="OPTIONS" />
  </Card>
</template>
