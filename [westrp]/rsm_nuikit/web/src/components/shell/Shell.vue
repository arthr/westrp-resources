<script setup>
import { computed } from "vue";
import { useKit } from "../../state/kit.js";
import { Divider, VDivider } from "../kit";
import Sidebar from "./Sidebar.vue";
import KeyHints from "./KeyHints.vue";
import ColorManager from "../sections/ColorManager.vue";
import StatesSection from "../sections/StatesSection.vue";
import ControlsSection from "../sections/ControlsSection.vue";
import FeedbackSection from "../sections/FeedbackSection.vue";
import HudSection from "../sections/HudSection.vue";
import ServiceSection from "../sections/ServiceSection.vue";

const VIEWS = {
  colors: ColorManager,
  states: StatesSection,
  controls: ControlsSection,
  feedback: FeedbackSection,
  hud: HudSection,
  service: ServiceSection,
};

const kit = useKit();
const view = computed(() => VIEWS[kit.state.section]);
</script>

<template>
  <div class="relative z-20 flex h-screen w-screen items-center justify-center p-[3vh]">
    <main class="tx-shell flex h-[min(92vh,1000px)] w-[min(95vw,1760px)] min-w-0 animate-kit-rise flex-col px-12 pt-11 pb-10">
      <div class="grid min-h-0 flex-1 grid-cols-[clamp(230px,15vw,280px)_4px_minmax(0,1fr)] gap-8">
        <Sidebar />
        <VDivider />
        <!-- a chave remonta a seção a cada troca, e a entrada toca de novo -->
        <div :key="kit.state.section" class="flex min-h-0 min-w-0 animate-kit-slide flex-col">
          <component :is="view" />
        </div>
      </div>
      <Divider class="mt-6 mb-5" />
      <KeyHints />
    </main>
  </div>
</template>
