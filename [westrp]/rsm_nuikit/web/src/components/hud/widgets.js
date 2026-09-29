// Cada peça do HUD, pelo mesmo id do registro de módulos. Sem dados (miniatura
// do Layout Manager) cada widget mostra um exemplo; no HUD de verdade recebe o
// que os outros resources mandaram.
import CoresWidget from "./widgets/CoresWidget.vue";
import PromptsWidget from "./widgets/PromptsWidget.vue";
import ToastsWidget from "./widgets/ToastsWidget.vue";
import HelpWidget from "./widgets/HelpWidget.vue";
import MoneyWidget from "./widgets/MoneyWidget.vue";
import ObjectiveWidget from "./widgets/ObjectiveWidget.vue";
import MenuWidget from "./widgets/MenuWidget.vue";

export const WIDGETS = {
  cores: CoresWidget,
  prompts: PromptsWidget,
  toasts: ToastsWidget,
  help: HelpWidget,
  money: MoneyWidget,
  objective: ObjectiveWidget,
  menus: MenuWidget,
};
