<script setup>
import { computed } from "vue";
import { useKit } from "../../state/kit.js";
import { anchorBox } from "./anchor.js";
import { widgetDims } from "./dims.js";
import { WIDGETS } from "./widgets.js";

// O HUD que os jogadores veem: só as peças que algum resource alimentou, cada
// uma onde o Layout Manager mandou. Não pega o mouse e some com o estúdio aberto
// (como o HUD do jogo some nos menus) ou quando um resource pede SetHudHidden.
const kit = useKit();

const pieces = computed(() => {
  const { hud, layout, studio } = kit.state;
  if (studio.open || hud.hidden) return [];
  const list = [];
  if (hud.cores && kit.isActive("cores")) list.push(["cores", { cores: hud.cores }]);
  if (hud.help && kit.isActive("help")) list.push(["help", { text: hud.help.text, k: hud.help.key }]);
  if (hud.money && kit.isActive("money")) list.push(["money", { money: hud.money, clock: hud.clock }]);
  if (hud.objective && kit.isActive("objective")) list.push(["objective", { text: hud.objective }]);
  return list.map(([id, data]) => {
    const w = layout.widgets[id];
    const b = anchorBox(w.anchor, w.x, w.y, layout.safeZone);
    const [dw, dh] = widgetDims(id, hud.coreStyle);
    return {
      id,
      data,
      widget: WIDGETS[id],
      pos: { left: `${b.left}%`, top: `${b.top}%` },
      box: {
        width: `${dw}px`,
        height: `${dh}px`,
        transform: `translate(${b.tx}%, ${b.ty}%) scale(${w.scale / 100})`,
        transformOrigin: b.origin,
      },
    };
  });
});
</script>

<template>
  <TransitionGroup
    enter-active-class="transition-opacity duration-250"
    enter-from-class="opacity-0"
    leave-active-class="transition-opacity duration-250"
    leave-to-class="opacity-0"
  >
    <div v-for="p in pieces" :key="p.id" class="pointer-events-none fixed z-30" :style="p.pos">
      <!-- o transform fica num filho: o de fora só anima a opacidade -->
      <div :style="p.box">
        <component :is="p.widget" v-bind="p.data" />
      </div>
    </div>
  </TransitionGroup>
</template>
