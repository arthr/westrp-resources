<script setup>
import { ref } from "vue";
import { Card, TextInput } from "../../kit";

const name = ref("Hosea Matthews");
const amount = ref("25.00");
const q = ref("");
// só dígitos e ponto; o campo volta ao valor filtrado
const setAmount = (v) => {
  amount.value = v.replace(/[^\d.]/g, "");
};
</script>

<template>
  <Card title="Inputs" kicker="Fields on the dark plate" body-class="flex flex-col gap-4">
    <div class="flex flex-col gap-1.5">
      <span class="text-[13px] text-dim">Character name</span>
      <TextInput v-model="name" :max-length="24">
        <template #suffix><span class="font-cat text-[12px] text-faint">{{ name.length }}/24</span></template>
      </TextInput>
    </div>
    <div class="flex flex-col gap-1.5">
      <span class="text-[13px] text-dim">Deposit amount</span>
      <TextInput :model-value="amount" prefix="$" input-mode="decimal" @update:model-value="setAmount" />
    </div>
    <div class="flex flex-col gap-1.5">
      <span class="text-[13px] text-dim">Search</span>
      <TextInput v-model="q" placeholder="Search the catalogue…" />
    </div>
  </Card>
</template>
