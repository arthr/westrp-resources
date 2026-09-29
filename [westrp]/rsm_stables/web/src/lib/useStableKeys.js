import { onBeforeUnmount, onMounted } from "vue";
import { isTyping } from "../components/kit/keys.js";

// Teclas do estábulo, lidas do estado NA HORA da tecla (nunca uma cópia velha):
//   Esc   fecha o diálogo aberto; sem diálogo, fecha o estábulo
//   Q / E troca de seção, como as abas dos menus do RDR
//   A / D gira o animal em exibição (segurar repete, com limite de ritmo)
export function useStableKeys(stable) {
  let lastRotate = 0;

  const onKey = (e) => {
    const { state } = stable;
    if (!state.open) return;
    if (e.key === "Escape") {
      e.preventDefault();
      if (state.dialog) state.dialog = null;
      else stable.close();
      return;
    }
    if (state.dialog || isTyping(e.target)) return;
    if (!e.repeat && (e.code === "KeyQ" || e.code === "KeyE")) {
      e.preventDefault();
      stable.stepTab(e.code === "KeyQ" ? -1 : 1);
      return;
    }
    if (e.code === "KeyA" || e.code === "KeyD") {
      const t = performance.now();
      if (t - lastRotate < 45) return;
      lastRotate = t;
      stable.post("rotate", { delta: e.code === "KeyA" ? -6 : 6 });
    }
  };

  onMounted(() => window.addEventListener("keydown", onKey));
  onBeforeUnmount(() => window.removeEventListener("keydown", onKey));
}
