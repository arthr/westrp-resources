<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from "vue";
import { hostCan, hostPolicy, hostTheme, placementOf, useKit } from "../../state/kit.js";
import { HOST_OWNED, HOST_PIECES, widgetDims } from "./dims.js";
import { WIDGETS } from "./widgets.js";
import HudMirror from "./HudMirror.vue";
import Placed from "./Placed.vue";
import ToastSamples from "./ToastSamples.vue";

// Palco da prévia: a tela do jogador (1920×1080) reduzida para caber no cartão.
// Atrás, o cenário; no meio, o rsm_hud de verdade (espelho); por cima, as peças
// do kit, cada uma onde vai aparecer. Tudo com o rascunho do estúdio (tema,
// padrões do HUD, módulos), antes mesmo de publicar.
const props = defineProps({
  // "new": o que um personagem sem layout salvo vê (padrões do servidor)
  // "mine": o layout que o próprio jogador salvou no /hudlayout
  view: { type: String, default: "new" },
  savedLayout: { type: [Object, Boolean], default: false },
});

const kit = useKit();

// a caixa de 1920×1080 encolhe junto com o cartão; lá dentro 1rem = 16 px, como em 1080p
const box = ref(null);
const scale = ref(0);
let observer = null;
onMounted(() => {
  const measure = () => {
    scale.value = box.value ? box.value.clientWidth / 1920 : 0;
  };
  measure();
  if (typeof ResizeObserver === "function") {
    observer = new ResizeObserver(measure);
    observer.observe(box.value);
  }
});
onBeforeUnmount(() => observer?.disconnect());

const failed = ref(false);
const mirrorPage = computed(() => (hostCan(kit.state, "mirror") ? kit.state.host.page : null));
const theme = computed(() => hostTheme(kit.state));
const policy = computed(() => hostPolicy(kit.state));
const layout = computed(() => (props.view === "mine" ? props.savedLayout : false));

// no preview do navegador, o catálogo que o rsm_hud informa substitui a amostra
const onReady = (catalog) => {
  failed.value = false;
  if (!window.rsmNui.isGame && catalog) kit.dispatch({ type: "host/catalog", catalog });
};

// As peças do kit, com exemplo. Módulo inativo ou peça oculta pelo jogador não
// aparece, igual ao HUD de verdade.
const pieces = computed(() => {
  const s = kit.state;
  const ids = s.host.present ? HOST_PIECES : [...HOST_PIECES, ...HOST_OWNED];
  const list = [];
  for (const id of ids) {
    if (!kit.isActive(id)) continue;
    const place =
      props.view === "mine"
        ? placementOf(s, id)
        : { x: 0.5, y: 0.5, scale: 1, opacity: 1, visible: true, ...s.placement.defaults[id] };
    if (!place.visible) continue;
    const [width, height] = widgetDims(id, s.hud.coreStyle);
    list.push({ id, place, width, height });
  }
  return list;
});
</script>

<template>
  <div class="tx-frame p-2">
    <div ref="box" class="relative aspect-video w-full overflow-hidden">
      <div class="absolute inset-0 opacity-75 [background:var(--rsm-backdrop)_center/cover]" />
      <div class="absolute left-0 top-0 h-[1080px] w-[1920px] origin-top-left" :style="{ transform: `scale(${scale})` }">
        <HudMirror
          v-if="mirrorPage && !failed"
          :page="mirrorPage"
          :theme="theme"
          :policy="policy"
          :layout="layout"
          @ready="onReady"
          @fail="failed = true"
        />
        <Placed
          v-for="p in pieces"
          :key="p.id"
          :place="p.place"
          :width="p.width"
          :height="p.height"
          :fixed-scale="1"
          :z="p.id === 'toasts' ? 40 : 30"
        >
          <ToastSamples v-if="p.id === 'toasts'" :from-bottom="p.place.y >= 0.5" />
          <component :is="WIDGETS[p.id]" v-else />
        </Placed>
      </div>
    </div>
    <p v-if="failed" class="px-2 pt-2.5 text-[12px] leading-snug text-faint">
      {{ kit.state.host.name }} did not answer, so only the kit pieces are shown. Build its interface (web/dist) and reopen this section.
    </p>
  </div>
</template>
