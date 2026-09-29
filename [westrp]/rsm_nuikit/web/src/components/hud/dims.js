import { coreGroup } from "../kit/core.js";

export const CORE_BASE = 64; // tamanho base de um core no HUD, em px a 1920×1080

// Feed de notificações: no máximo 3 na tela, cada uma com altura fixa, então a
// área dele nunca cresce além do que o jogador posicionou.
export const TOAST_MAX = 3;
export const TOAST_H = 104;
export const TOAST_GAP = 10;

// Área exata de cada peça do HUD, em px a 1920×1080. O rsm_hud recebe estes
// tamanhos e desenha a moldura deles no /hudlayout: o que o jogador arrasta lá
// é exatamente o espaço que a peça ocupa aqui, então nada se sobrepõe.
export const WIDGET_DIMS = {
  toasts: [380, TOAST_MAX * TOAST_H + (TOAST_MAX - 1) * TOAST_GAP],
  help: [400, 96],
  money: [250, 56],
  objective: [480, 44],
};

// Peças que entram no /hudlayout do rsm_hud
export const HOST_PIECES = ["toasts", "help", "objective"];
// Com o rsm_hud rodando, quem desenha estas é ele
export const HOST_OWNED = ["cores", "money"];

// O tamanho dos cores depende do estilo escolhido.
export function widgetDims(id, coreStyle) {
  if (id === "cores") {
    const g = coreGroup(coreStyle, CORE_BASE);
    return [g.width, g.height];
  }
  return WIDGET_DIMS[id];
}

export const SAMPLE_CORES = [
  { icon: "core-health", ring: 82, core: 70 },
  { icon: "core-stamina", ring: 64, core: 92 },
  { icon: "core-deadeye", ring: 22, core: 40 },
];

export const clockText = ({ h, m }) => `${h % 12 || 12}:${String(m).padStart(2, "0")} ${h < 12 ? "AM" : "PM"}`;
