<script setup>
import { computed } from "vue";
import { useKit } from "../../state/kit.js";
import SectionFrame from "../shell/SectionFrame.vue";
import HostHudCard from "./hud/HostHudCard.vue";
import PlacementCard from "./hud/PlacementCard.vue";
import CoresCard from "./hud/CoresCard.vue";
import PromptsCard from "./hud/PromptsCard.vue";
import StripCard from "./hud/StripCard.vue";

// Com o rsm_hud rodando, os recursos dele vêm primeiro e os cores e o dinheiro
// do kit saem daqui (quem desenha é o HUD). Sem ele, o kit mostra os próprios.
const kit = useKit();
const hosted = computed(() => kit.state.host.present && !!kit.state.host.catalog);
const hint = computed(() =>
  hosted.value
    ? `${kit.state.host.name} draws the player HUD: set its server defaults here, and each player places everything in /hudlayout.`
    : "Always-on overlay pieces. In game they render over the world without taking focus.",
);
</script>

<template>
  <SectionFrame title="HUD Pieces" :hint="hint">
    <div class="flex min-w-0 flex-col gap-6">
      <HostHudCard v-if="hosted" />
      <PlacementCard />
      <CoresCard v-if="!kit.hostOwns('cores')" />
      <div class="grid min-w-0 grid-cols-[repeat(auto-fit,minmax(26rem,1fr))] gap-6">
        <PromptsCard />
        <div class="flex min-w-0 flex-col gap-6">
          <StripCard v-if="!kit.hostOwns('money')" id="money" title="Money & Clock" kicker="Wallet · gold · time" />
          <StripCard id="objective" title="Objective Line" kicker="Mission text" />
        </div>
      </div>
    </div>
  </SectionFrame>
</template>
