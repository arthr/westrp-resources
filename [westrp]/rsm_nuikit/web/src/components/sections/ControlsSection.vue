<script setup>
import SectionFrame from "../shell/SectionFrame.vue";
import InventoryCard from "../inventory/InventoryCard.vue";
import ButtonsCard from "./controls/ButtonsCard.vue";
import SelectorsCard from "./controls/SelectorsCard.vue";
import ChecksCard from "./controls/ChecksCard.vue";
import SlidersCard from "./controls/SlidersCard.vue";
import InputsCard from "./controls/InputsCard.vue";
import TabsCard from "./controls/TabsCard.vue";
</script>

<template>
  <SectionFrame title="Controls" hint="Every input the kit ships, each in its live and inactive form. Everything here is clickable.">
    <div class="grid min-w-0 grid-cols-[repeat(auto-fit,minmax(24rem,1fr))] gap-6">
      <InventoryCard />
      <ButtonsCard />
      <SelectorsCard />
      <ChecksCard />
      <SlidersCard />
      <InputsCard />
      <TabsCard />
    </div>
  </SectionFrame>
</template>
