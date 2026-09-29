<script setup>
import { computed } from "vue";
import { placementOf, useKit } from "../../state/kit.js";
import { px } from "../kit/surface.js";
import { TOAST_GAP, WIDGET_DIMS } from "./dims.js";
import Placed from "./Placed.vue";
import ToastItem from "./ToastItem.vue";
import ToastSamples from "./ToastSamples.vue";

// O feed de notificações, na área que o jogador posicionou no /hudlayout (ou
// no config.lua). No máximo 3 toasts de altura fixa, então o feed nunca passa
// dessa área. Na metade de baixo da tela eles se empilham a partir da base.
// SetHudHidden também esconde o feed; as notificações continuam contando.
const kit = useKit();
const [W, H] = WIDGET_DIMS.toasts;
const gap = px(TOAST_GAP);

const samples = computed(() => kit.state.host.editing || kit.state.hud.samples);
const base = computed(() => placementOf(kit.state, "toasts"));
const place = computed(() => (base.value.visible ? base.value : { ...base.value, opacity: 0.35 }));
const shown = computed(() => !kit.state.hud.hidden && kit.isActive("toasts") && (samples.value || base.value.visible));
const stackClass = computed(() => ["flex h-full overflow-hidden", base.value.y >= 0.5 ? "flex-col-reverse" : "flex-col"]);
const enterFrom = computed(() => (base.value.y >= 0.5 ? "opacity-0 translate-y-4" : "opacity-0 -translate-y-4"));

const ttlOf = (t) => Math.min(30000, Math.max(1500, t.duration ?? kit.state.notifyDuration));
const dismiss = (id) => kit.dispatch({ type: "toast/dismiss", id });

// Saída: o toast some encolhendo a própria altura (e o espaço até o vizinho),
// então os outros deslizam em vez de pular.
const onLeave = (el, done) => {
  el.style.height = `${el.offsetHeight}px`;
  el.getBoundingClientRect();
  el.style.transition = "height .22s ease, margin .22s ease, opacity .18s ease, transform .18s ease";
  el.style.height = "0px";
  el.style.marginBottom = `-${TOAST_GAP}px`;
  el.style.opacity = "0";
  el.style.transform = "scale(0.96)";
  setTimeout(done, 240);
};
</script>

<template>
  <Placed v-if="shown" :place="place" :width="W" :height="H" :z="40">
    <!-- /hudlayout aberto: exemplos fixos, para o jogador ver o feed cheio -->
    <ToastSamples v-if="samples" :from-bottom="base.y >= 0.5" />
    <TransitionGroup
      v-else
      tag="div"
      :class="stackClass"
      :style="{ gap }"
      enter-active-class="transition duration-300 ease-out"
      :enter-from-class="enterFrom"
      move-class="transition-transform duration-300 ease-out"
      @leave="onLeave"
    >
      <ToastItem v-for="t in kit.state.toasts" :key="t.id" :toast="t" :ttl="ttlOf(t)" @dismiss="dismiss" />
    </TransitionGroup>
  </Placed>
</template>
