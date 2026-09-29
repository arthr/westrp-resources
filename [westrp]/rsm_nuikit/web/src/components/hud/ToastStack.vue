<script setup>
import { computed } from "vue";
import { useKit } from "../../state/kit.js";
import { anchorBox } from "./anchor.js";
import ToastItem from "./ToastItem.vue";

// The live notification feed, placed wherever the Layout Manager anchors it.
// SetHudHidden também esconde o feed; as notificações esperam na fila.
const kit = useKit();

const GAP = 10; // gap-2.5 entre os toasts
const w = computed(() => kit.state.layout.widgets.toasts);
const fromBottom = computed(() => w.value.anchor[0] === "b");
const boxStyle = computed(() => {
  const b = anchorBox(w.value.anchor, w.value.x, w.value.y, kit.state.layout.safeZone);
  return {
    left: `${b.left}%`,
    top: `${b.top}%`,
    transform: `translate(${b.tx}%, ${b.ty}%) scale(${w.value.scale / 100})`,
    transformOrigin: b.origin,
  };
});

const ttlOf = (t) => Math.min(30000, Math.max(1500, t.duration ?? kit.state.notifyDuration));
const dismiss = (id) => kit.dispatch({ type: "toast/dismiss", id });

// Saída: o toast some encolhendo a própria altura (e o espaço até o vizinho),
// então os de baixo sobem deslizando em vez de pular.
const onLeave = (el, done) => {
  el.style.height = `${el.offsetHeight}px`;
  el.getBoundingClientRect();
  el.style.transition = "height .22s ease, margin .22s ease, opacity .18s ease, transform .18s ease";
  el.style.height = "0px";
  el.style.marginBottom = `-${GAP}px`;
  el.style.opacity = "0";
  el.style.transform = "scale(0.96)";
  setTimeout(done, 240);
};
</script>

<template>
  <div v-if="!kit.state.hud.hidden" class="pointer-events-none fixed z-40" :style="boxStyle">
    <TransitionGroup
      tag="div"
      :class="['flex gap-2.5', fromBottom ? 'flex-col-reverse' : 'flex-col']"
      enter-active-class="transition duration-300 ease-out"
      :enter-from-class="fromBottom ? 'opacity-0 translate-y-4' : 'opacity-0 -translate-y-4'"
      move-class="transition-transform duration-300 ease-out"
      @leave="onLeave"
    >
      <ToastItem v-for="t in kit.state.toasts" :key="t.id" :toast="t" :ttl="ttlOf(t)" @dismiss="dismiss" />
    </TransitionGroup>
  </div>
</template>
