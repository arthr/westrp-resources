// Cada peça do HUD, pelo mesmo id do registro de módulos. Sem dados (exemplo
// do /hudlayout ou do Preview Placement) cada widget mostra um exemplo; no HUD
// de verdade recebe o que os outros resources mandaram. O feed de notificações
// tem o próprio componente (ToastStack).
import CoresWidget from "./widgets/CoresWidget.vue";
import HelpWidget from "./widgets/HelpWidget.vue";
import MoneyWidget from "./widgets/MoneyWidget.vue";
import ObjectiveWidget from "./widgets/ObjectiveWidget.vue";

export const WIDGETS = {
  cores: CoresWidget,
  help: HelpWidget,
  money: MoneyWidget,
  objective: ObjectiveWidget,
};
