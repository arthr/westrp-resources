import { onBeforeUnmount, onMounted, ref } from "vue";

// Fator de escala das peças do HUD em relação a 1080p. Segue a mesma regra do
// rsm_hud (1rem = 1,4815 % da altura da tela, entre 9 e 32 px), então uma peça
// do kit tem sempre o tamanho da moldura que o jogador arrastou no /hudlayout.
const factor = () => Math.min(32, Math.max(9, window.innerHeight * 0.014815)) / 16;

export function useScreenScale() {
  const k = ref(factor());
  const onResize = () => {
    k.value = factor();
  };
  onMounted(() => {
    onResize();
    window.addEventListener("resize", onResize);
  });
  onBeforeUnmount(() => window.removeEventListener("resize", onResize));
  return k;
}
