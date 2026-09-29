import { coreGroup } from "../kit/core.js";

export const CORE_BASE = 64; // tamanho base de um core no HUD, em px a 1920×1080

// Real on-screen size of each HUD piece at 1920×1080. The Layout Manager
// scales these down onto its mini screen, so what you place is what you get.
export const WIDGET_DIMS = {
  prompts: [260, 96],
  toasts: [380, 96],
  help: [400, 96],
  money: [250, 56],
  objective: [480, 44],
  menus: [400, 520],
};

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
