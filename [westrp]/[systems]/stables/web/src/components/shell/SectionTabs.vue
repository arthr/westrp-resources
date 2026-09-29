<script setup>
import { computed } from "vue";
import { useStable } from "../../state/stable.js";
import { TABS } from "../../lib/labels.js";
import { KeyCap, Tabs } from "../kit";

// Abas das seções com Q / E nas pontas, como nos menus do RDR
const stable = useStable();
const tab = computed({
  get: () => stable.state.tab,
  set: (v) => stable.setTab(v),
});
const items = computed(() =>
  TABS.map((t) => ({
    ...t,
    count: t.value === "transfer" && stable.offers.value.length ? stable.offers.value.length : null,
  })),
);
</script>

<template>
  <nav class="flex shrink-0 items-center justify-center gap-3">
    <button type="button" class="hidden shrink-0 cursor-pointer min-[1800px]:block" aria-label="Seção anterior" @click="stable.stepTab(-1)">
      <KeyCap k="Q" :size="26" />
    </button>
    <Tabs v-model="tab" :items="items" size="sm" class="justify-center" />
    <button type="button" class="hidden shrink-0 cursor-pointer min-[1800px]:block" aria-label="Próxima seção" @click="stable.stepTab(1)">
      <KeyCap k="E" :size="26" />
    </button>
  </nav>
</template>
