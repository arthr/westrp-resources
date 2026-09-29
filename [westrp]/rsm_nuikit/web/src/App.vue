<script setup>
import { watch } from "vue";
import { provideKit } from "./state/kit.js";
import { useKeyNav } from "./lib/useKeyNav.js";
import { useNuiRouter } from "./lib/useNuiRouter.js";
import Shell from "./components/shell/Shell.vue";
import PreviewReopen from "./components/shell/PreviewReopen.vue";
import HudLayer from "./components/hud/HudLayer.vue";
import ToastStack from "./components/hud/ToastStack.vue";
import ConfirmDialog from "./components/hud/ConfirmDialog.vue";

// rsm_nuikit: a UI service. The HUD, notifications and Confirm dialogs are
// always available to other resources; the studio opens on top for staff.
const kit = provideKit();
useKeyNav(kit);
useNuiRouter(kit);

const isGame = window.rsmNui.isGame;

// no jogo, o estúdio aberto escurece levemente o mundo (a camada da página
// continua transparente; com ele fechado não há véu nenhum)
watch(
  () => kit.state.studio.open,
  (open) => {
    if (isGame) document.documentElement.classList.toggle("rsm-open", open);
  },
  { immediate: true },
);
</script>

<template>
  <HudLayer />
  <Transition
    enter-active-class="transition-opacity duration-200"
    enter-from-class="opacity-0"
    leave-active-class="transition-opacity duration-150"
    leave-to-class="opacity-0"
  >
    <Shell v-if="kit.state.studio.open" />
  </Transition>
  <PreviewReopen v-if="!kit.state.studio.open && !isGame" />
  <ToastStack />
  <ConfirmDialog />
</template>
