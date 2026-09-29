<script setup>
import { computed, onMounted, onUnmounted, watch } from "vue";
import "./assets.js";
import { IS_GAME } from "./nui.js";
import { hud, applyHudUpdate, startPreviewSimulation } from "./store/hud.js";
import { layout, openLayout, loadLayout } from "./store/layout.js";
import HudWidget from "./components/HudWidget.vue";
import PlayerCores from "./components/widgets/PlayerCores.vue";
import HorseCores from "./components/widgets/HorseCores.vue";
import NeedsBar from "./components/widgets/NeedsBar.vue";
import StatusEffects from "./components/widgets/StatusEffects.vue";
import MoneyPanel from "./components/widgets/MoneyPanel.vue";
import ClockWeather from "./components/widgets/ClockWeather.vue";
import LocationBanner from "./components/widgets/LocationBanner.vue";
import IdentityCard from "./components/widgets/IdentityCard.vue";
import VoiceIndicator from "./components/widgets/VoiceIndicator.vue";
import WeaponAmmo from "./components/widgets/WeaponAmmo.vue";
import WantedStatus from "./components/widgets/WantedStatus.vue";
import LayoutManager from "./components/layout/LayoutManager.vue";
import CenterGuides from "./components/layout/CenterGuides.vue";
import PreviewDock from "./components/PreviewDock.vue";

// The HUD is an always-on overlay: it never uses the gate's "open" action (that
// would paint the menu backdrop over the world). It reveals the page itself,
// with no NUI focus, and only the Layout Manager asks the client for focus.
const setPageVisible = (on) => {
  if (IS_GAME) document.documentElement.style.visibility = on ? "visible" : "hidden";
};

function onMessage(e) {
  const msg = (e && e.data) || {};
  switch (msg.action) {
    case "hud:show":
      hud.visible = true;
      setPageVisible(true);
      break;
    case "hud:hide":
      hud.visible = false;
      if (!layout.editing) setPageVisible(false);
      break;
    case "hud:update":
      applyHudUpdate(msg.data);
      break;
    case "hud:layout":
      setPageVisible(true);
      openLayout();
      break;
    case "hud:setLayout":
      loadLayout(msg.layout);
      break;
  }
}

// Leaving the Layout Manager while the HUD itself is switched off hides the page again.
watch(
  () => layout.editing,
  (editing) => {
    if (!editing && !hud.visible) setPageVisible(false);
  },
);

// Sem nenhuma necessidade ativa no servidor, o widget inteiro some.
const anyNeed = computed(() => Object.values(hud.needs).some((v) => typeof v === "number"));

let stopSim = null;
onMounted(() => {
  window.addEventListener("message", onMessage);
  if (!IS_GAME) stopSim = startPreviewSimulation();
});
onUnmounted(() => {
  window.removeEventListener("message", onMessage);
  if (stopSim) stopSim();
  stopSim = null;
});
</script>

<template>
  <div class="relative h-full w-full overflow-hidden">
    <!-- Layout Manager: a translucent scrim so the world stays visible behind the elements being placed. -->
    <div v-if="layout.editing" class="fixed inset-0 z-0 bg-[rgba(0,0,0,0.38)]" />

    <HudWidget id="identity"><IdentityCard /></HudWidget>
    <HudWidget id="location"><LocationBanner /></HudWidget>
    <HudWidget id="money"><MoneyPanel /></HudWidget>
    <HudWidget id="clock"><ClockWeather /></HudWidget>
    <HudWidget id="wanted" :active="hud.wanted.bounty > 0"><WantedStatus /></HudWidget>
    <HudWidget id="effects" :active="hud.effects.length > 0"><StatusEffects /></HudWidget>
    <HudWidget id="needs" :active="anyNeed"><NeedsBar /></HudWidget>
    <HudWidget id="cores"><PlayerCores /></HudWidget>
    <HudWidget id="horse" :active="hud.horse.mounted"><HorseCores /></HudWidget>
    <HudWidget id="weapon" :active="hud.weapon.drawn"><WeaponAmmo /></HudWidget>
    <HudWidget id="voice"><VoiceIndicator /></HudWidget>

    <template v-if="layout.editing">
      <CenterGuides />
      <LayoutManager />
    </template>
    <PreviewDock v-else-if="!IS_GAME" />
  </div>
</template>
