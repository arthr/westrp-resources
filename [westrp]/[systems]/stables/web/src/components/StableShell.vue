<script setup>
import { computed } from "vue";
import { useStable } from "../state/stable.js";
import { Divider } from "./kit";
import StableHeader from "./shell/StableHeader.vue";
import SectionTabs from "./shell/SectionTabs.vue";
import StageArea from "./shell/StageArea.vue";
import FooterPrompts from "./shell/FooterPrompts.vue";
import ShopList from "./shop/ShopList.vue";
import ShopDetail from "./shop/ShopDetail.vue";
import RideList from "./stable/RideList.vue";
import RideDetail from "./stable/RideDetail.vue";
import TackList from "./tack/TackList.vue";
import TackDetail from "./tack/TackDetail.vue";
import TransferList from "./transfer/TransferList.vue";
import TransferDetail from "./transfer/TransferDetail.vue";

// Menu à esquerda, detalhes à direita e o meio livre para a câmera do animal.
const VIEWS = {
  shop: [ShopList, ShopDetail],
  stable: [RideList, RideDetail],
  tack: [TackList, TackDetail],
  transfer: [TransferList, TransferDetail],
};

const stable = useStable();
const view = computed(() => VIEWS[stable.state.tab] ?? VIEWS.shop);
</script>

<template>
  <div
    class="relative z-10 grid h-screen w-screen grid-cols-[clamp(400px,28vw,540px)_minmax(0,1fr)_clamp(340px,23vw,450px)] grid-rows-[minmax(0,1fr)_auto] gap-x-[2vw] gap-y-[2.2vh] px-[2.4vw] py-[3.4vh]"
  >
    <main class="tx-shell col-start-1 row-span-2 row-start-1 flex min-h-0 min-w-0 animate-kit-rise flex-col gap-5 px-9 pt-9 pb-8">
      <StableHeader />
      <SectionTabs />
      <Divider />
      <div :key="stable.state.tab" class="flex min-h-0 flex-1 animate-kit-slide flex-col">
        <component :is="view[0]" />
      </div>
    </main>

    <StageArea class="col-start-2 row-start-1" />

    <aside class="tx-shell col-start-3 row-span-2 row-start-1 flex min-h-0 min-w-0 animate-kit-rise flex-col px-9 pt-9 pb-8">
      <div :key="stable.state.tab" class="flex min-h-0 flex-1 animate-kit-slide flex-col">
        <component :is="view[1]" />
      </div>
    </aside>

    <div class="col-start-2 row-start-2 flex min-w-0 justify-center">
      <FooterPrompts />
    </div>
  </div>
</template>
