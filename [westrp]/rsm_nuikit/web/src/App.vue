<script setup>
import { computed, watch } from "vue";
import { hostCan, hostPolicy, hostTheme, provideKit } from "./state/kit.js";
import { useKeyNav } from "./lib/useKeyNav.js";
import { useNuiRouter } from "./lib/useNuiRouter.js";
import Shell from "./components/shell/Shell.vue";
import PreviewReopen from "./components/shell/PreviewReopen.vue";
import HudLayer from "./components/hud/HudLayer.vue";
import ToastStack from "./components/hud/ToastStack.vue";
import ConfirmDialog from "./components/hud/ConfirmDialog.vue";
import HudMirror from "./components/hud/HudMirror.vue";

// rsm_nuikit: a UI service. The HUD, notifications and Confirm dialogs are
// always available to other resources; the studio opens on top for staff.
const kit = provideKit();
useKeyNav(kit);
useNuiRouter(kit);

const isGame = window.rsmNui.isGame;

// Preview Placement no navegador: o rsm_hud de verdade (modo espelho) aparece
// atrás das peças do kit. No jogo quem mostra é o próprio rsm_hud do jogador.
const mirrorPreview = computed(() => {
  const s = kit.state;
  return !isGame && s.hud.samples && !s.studio.open && hostCan(s, "mirror") && s.host.page;
});

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
  <div v-if="mirrorPreview" class="pointer-events-none fixed inset-0 z-[5]">
    <HudMirror :page="kit.state.host.page" :theme="hostTheme(kit.state)" :policy="hostPolicy(kit.state)" fill />
  </div>
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
