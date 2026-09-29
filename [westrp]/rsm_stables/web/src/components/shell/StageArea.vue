<script setup>
import { onBeforeUnmount, ref } from "vue";
import { useStable } from "../../state/stable.js";

// O meio da tela é a câmera do estábulo mostrando o animal (no jogo).
// Arrastar gira, a roda do mouse aproxima; o cliente move a câmera/ped.
const stable = useStable();
const dragging = ref(false);
let lastX = 0;
let acc = 0;
let timer = 0;

const flush = () => {
  timer = 0;
  if (Math.abs(acc) >= 1) stable.post("rotate", { delta: Math.round(acc) });
  acc = 0;
};

const onDown = (e) => {
  e.currentTarget.setPointerCapture(e.pointerId);
  dragging.value = true;
  lastX = e.clientX;
};
const onMove = (e) => {
  if (!dragging.value) return;
  acc += (e.clientX - lastX) * 0.4;
  lastX = e.clientX;
  if (!timer) timer = setTimeout(flush, 40);
};
const onUp = () => {
  dragging.value = false;
};
const onWheel = (e) => {
  stable.post("zoom", { delta: e.deltaY > 0 ? 1 : -1 });
};

onBeforeUnmount(() => clearTimeout(timer));
</script>

<template>
  <div
    :class="['min-h-0 min-w-0 touch-none select-none', dragging ? 'cursor-grabbing' : 'cursor-grab']"
    aria-label="Arraste para girar o animal"
    @pointerdown="onDown"
    @pointermove="onMove"
    @pointerup="onUp"
    @pointercancel="onUp"
    @wheel.passive="onWheel"
  />
</template>
