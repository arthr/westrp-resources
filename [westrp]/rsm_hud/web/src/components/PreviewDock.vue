<script setup>
import { onMounted, onUnmounted } from "vue";
import KeyCap from "./layout/KeyCap.vue";
import { openLayout } from "../store/layout.js";
import { t } from "../locale.js";

// Só na prévia do navegador: no jogo o editor abre com /hudlayout.
function onKey(e) {
  if (e.key === "l" || e.key === "L") openLayout();
}
onMounted(() => window.addEventListener("keydown", onKey));
onUnmounted(() => window.removeEventListener("keydown", onKey));
</script>

<template>
  <button
    type="button"
    class="skin skin-plate fixed left-1/2 top-[44%] z-20 flex -translate-x-1/2 cursor-pointer items-center gap-3 px-[1.125rem] py-2 [--skin-fill:rgba(1,1,1,0.66)] hover:[--skin-fill:rgba(1,1,1,0.8)]"
    @click="openLayout"
  >
    <KeyCap k="L" />
    <span class="hud-text font-display text-[0.72rem] uppercase tracking-[0.2em] text-paper">{{ t("lm.title") }}</span>
  </button>
</template>
