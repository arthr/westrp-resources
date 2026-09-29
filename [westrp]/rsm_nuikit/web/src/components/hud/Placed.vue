<script setup>
import { computed } from "vue";
import { px } from "../kit/surface.js";
import { useScreenScale } from "../../lib/screen.js";

// Uma peça do HUD na posição que veio do rsm_hud (ou do config.lua). Mesma conta
// do HUD: x = 0 encosta à esquerda e 1 à direita (y igual, topo e base), e a
// peça nunca sai da tela em nenhuma resolução ou escala. A caixa tem o tamanho
// fixo da peça; o conteúdo nunca passa dela.
const props = defineProps({
  place: { type: Object, required: true }, // { x, y, scale, opacity }
  width: { type: Number, required: true },
  height: { type: Number, required: true },
  z: { type: Number, default: 30 },
  // dentro do palco da prévia (uma tela de 1920×1080 reduzida), a escala é a de 1080p
  fixedScale: { type: Number, default: null },
});

const screenK = useScreenScale();
const k = computed(() => props.fixedScale ?? screenK.value);

const outer = computed(() => ({ left: `${props.place.x * 100}%`, top: `${props.place.y * 100}%`, zIndex: props.z }));
const box = computed(() => {
  const { x, y, scale, opacity } = props.place;
  return {
    width: px(props.width),
    height: px(props.height),
    transform: `translate(${-x * 100}%, ${-y * 100}%) scale(${scale * k.value})`,
    transformOrigin: `${x * 100}% ${y * 100}%`,
    opacity,
  };
});
</script>

<template>
  <!-- o de fora só posiciona (e anima a entrada); o de dentro tem tamanho, escala e opacidade -->
  <div class="pointer-events-none fixed w-max" :style="outer">
    <div :style="box">
      <slot />
    </div>
  </div>
</template>
