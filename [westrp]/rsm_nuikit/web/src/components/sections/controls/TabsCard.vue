<script setup>
import { ref } from "vue";
import { Card, Divider, Field, Tabs } from "../../kit";

const tab = ref("all");
const view = ref("grid");
const counts = { all: 42, food: 23, tonic: 3, kit: 1 };
const TABS = [
  { value: "all", label: "All", count: counts.all },
  { value: "food", label: "Provisions", count: counts.food },
  { value: "tonic", label: "Tonics", count: counts.tonic },
  { value: "kit", label: "Kit", count: counts.kit },
  { value: "gun", label: "Weapons", disabled: true },
];
const VIEWS = [
  { value: "grid", label: "Grid" },
  { value: "list", label: "List" },
];
</script>

<template>
  <Card title="Tabs" kicker="Chip plates · current tab takes the accent" body-class="flex flex-col gap-5">
    <Tabs v-model="tab" :items="TABS" />
    <p class="text-[13px] text-dim">
      Showing <span class="font-cat text-ink">{{ counts[tab] }}</span> items in this tab. Weapons is locked until the gunsmith opens.
    </p>
    <Divider />
    <Field label="Compact strip" hint="Small size for toolbars">
      <Tabs v-model="view" size="sm" :items="VIEWS" />
    </Field>
  </Card>
</template>
