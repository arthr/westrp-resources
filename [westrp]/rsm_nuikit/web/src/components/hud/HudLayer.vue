<script setup>
import { computed } from "vue";
import { placementOf, useKit } from "../../state/kit.js";
import { widgetDims } from "./dims.js";
import { WIDGETS } from "./widgets.js";
import Placed from "./Placed.vue";

// O HUD que os jogadores veem: só as peças que algum resource alimentou, cada
// uma onde o jogador a pôs no /hudlayout (ou onde o config.lua manda, sem o
// rsm_hud). Não pega o mouse e some com o estúdio aberto, com SetHudHidden ou
// quando o rsm_hud se esconde (/hud, pausa, carregamento). Com o /hudlayout
// aberto, cada peça aparece com um exemplo no lugar exato, mesmo sem dados.
const kit = useKit();

const pieces = computed(() => {
  const s = kit.state;
  if (s.studio.open || s.hud.hidden) return [];
  const samples = s.host.editing || s.hud.samples;
  if (!samples && s.host.present && !s.host.visible) return [];
  const list = [];
  const add = (id, has, data) => {
    if (!kit.isActive(id) || !(has || samples)) return;
    const place = placementOf(s, id);
    // oculta pelo jogador: some do HUD; no editor aparece apagada, como a moldura
    if (!place.visible && !samples) return;
    const [width, height] = widgetDims(id, s.hud.coreStyle);
    list.push({ id, width, height, place: place.visible ? place : { ...place, opacity: 0.35 }, data: has ? data : {} });
  };
  add("cores", s.hud.cores, { cores: s.hud.cores });
  add("money", s.hud.money, { money: s.hud.money, clock: s.hud.clock });
  add("help", s.hud.help, s.hud.help && { text: s.hud.help.text, k: s.hud.help.key });
  add("objective", s.hud.objective, { text: s.hud.objective });
  return list;
});
</script>

<template>
  <TransitionGroup
    enter-active-class="transition-opacity duration-250"
    enter-from-class="opacity-0"
    leave-active-class="transition-opacity duration-250"
    leave-to-class="opacity-0"
  >
    <Placed v-for="p in pieces" :key="p.id" :place="p.place" :width="p.width" :height="p.height">
      <component :is="WIDGETS[p.id]" v-bind="p.data" />
    </Placed>
  </TransitionGroup>
</template>
