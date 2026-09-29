<script setup>
import SectionFrame from "../shell/SectionFrame.vue";
import CoresCard from "./hud/CoresCard.vue";
import PromptsCard from "./hud/PromptsCard.vue";
import StripCard from "./hud/StripCard.vue";
</script>

<template>
  <SectionFrame
    title="HUD Pieces"
    hint="Always-on overlay pieces. In game they render over the world without taking focus; place them in the Layout Manager."
  >
    <div class="flex min-w-0 flex-col gap-6">
      <CoresCard />
      <div class="grid min-w-0 grid-cols-[repeat(auto-fit,minmax(26rem,1fr))] gap-6">
        <PromptsCard />
        <div class="flex min-w-0 flex-col gap-6">
          <StripCard id="money" title="Money & Clock" kicker="Wallet · gold · time" />
          <StripCard id="objective" title="Objective Line" kicker="Mission text" />
        </div>
      </div>
    </div>
  </SectionFrame>
</template>
