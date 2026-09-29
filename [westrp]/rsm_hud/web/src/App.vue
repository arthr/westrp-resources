<script setup>
import { computed, onMounted, onUnmounted, watch } from "vue";
import "./assets.js";
import { IS_GAME } from "./nui.js";
import { MIRROR } from "./mirror.js";
import { applyTheme } from "./theme.js";
import { hud, applyHudUpdate, showSamples, startPreviewSimulation } from "./store/hud.js";
import { layout, external, openLayout, loadLayout, registerExternal, applyPolicy, catalog } from "./store/layout.js";
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
  if (IS_GAME && !MIRROR) document.documentElement.style.visibility = on ? "visible" : "hidden";
};

// Tema e padrões publicados. A prévia do rsm_nuikit troca os dois por alguns
// segundos (o que ainda está sendo editado no estúdio) e depois volta a estes.
const published = { theme: false, policy: {} };
let previewing = false;

function setPreview(msg) {
  if (msg.on === true) {
    previewing = true;
    showSamples(true);
    applyTheme(msg.theme === undefined ? published.theme : msg.theme);
    if (msg.policy) applyPolicy(msg.policy);
    setPageVisible(true);
  } else if (previewing) {
    previewing = false;
    showSamples(false);
    applyTheme(published.theme);
    applyPolicy(published.policy);
    if (!hud.visible && !layout.editing) setPageVisible(false);
  }
}

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
    case "hud:external":
      registerExternal(msg.widgets);
      break;
    case "hud:policy":
      if (msg.policy && typeof msg.policy === "object") published.policy = msg.policy;
      if (!previewing) applyPolicy(msg.policy);
      break;
    // cores do tema (Color Manager do rsm_nuikit); false = cores próprias do HUD
    case "hud:theme":
      published.theme = msg.theme || false;
      if (!previewing) applyTheme(published.theme);
      break;
    case "hud:preview":
      setPreview(msg);
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
  if (!IS_GAME || MIRROR) stopSim = startPreviewSimulation();
  // conta ao client o que este HUD tem (quem apresenta/configura o HUD usa isso)
  else window.rsmNui.post("catalog", catalog());
  // espelho: avisa a página que o contém que já pode mandar tema, padrões e layout
  if (MIRROR && window.parent !== window) {
    window.parent.postMessage({ source: "rsm_hud", action: "mirror:ready", catalog: catalog() }, "*");
  }
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

    <!-- Peças de outros resources: só a área que ocupam (px em 1080p → rem), para
         arrastar no editor. O conteúdo de verdade é o próprio dono que desenha. -->
    <template v-for="s in external" :key="s.id">
      <HudWidget v-if="layout.widgets[s.id]" :id="s.id" ghost>
        <div :style="{ width: `${s.width / 16}rem`, height: `${s.height / 16}rem` }" />
      </HudWidget>
    </template>

    <template v-if="layout.editing">
      <CenterGuides />
      <LayoutManager />
    </template>
    <PreviewDock v-else-if="!IS_GAME && !MIRROR" />
  </div>
</template>
