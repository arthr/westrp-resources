<script setup>
import { computed, ref, watch } from "vue";
import Glyph from "../Glyph.vue";
import { hud } from "../../store/hud.js";
import { itemArt } from "../../assets.js";

const lowClip = computed(() => hud.weapon.clip <= Math.ceil((hud.weapon.clipSize || 6) / 4));

// Arma sem arte (ou arquivo que falhou) mostra só nome e munição.
const artFailed = ref(false);
watch(() => hud.weapon.icon, () => (artFailed.value = false));

// Os ícones são recortados na área pintada, então cada um tem a sua proporção
// (revólver largo e baixo, rifle quase quadrado). A arte cabe num envelope de
// 4,2 × 3,2rem sem sobra vertical; a largura vem da própria imagem.
const artAspect = ref(1);
function onArtLoad(e) {
  const img = e.target;
  if (img.naturalWidth && img.naturalHeight) artAspect.value = img.naturalWidth / img.naturalHeight;
}
const artHeight = computed(() => `min(3.2rem, calc(4.2rem / ${artAspect.value}))`);
</script>

<template>
  <div class="skin skin-plate flex items-center gap-4 px-[1.125rem] py-2" style="--skin-fill: rgb(var(--hud-surface-rgb) / calc(0.62 * var(--hud-surface-k)))">
    <img
      v-if="hud.weapon.icon && !artFailed"
      :src="itemArt(hud.weapon.icon)"
      :alt="hud.weapon.name"
      class="w-auto shrink-0"
      :style="{ height: artHeight }"
      draggable="false"
      @load="onArtLoad"
      @error="artFailed = true"
    />
    <div class="flex flex-col items-end gap-1.5">
      <span class="hud-text font-display text-[0.66rem] uppercase tracking-[0.16em] text-dim">{{ hud.weapon.name }}</span>
      <span class="flex items-center gap-2">
        <Glyph name="g-ammo" size="1.2rem" class="text-paper" />
        <span class="hud-text font-num text-[1.7rem] leading-none" :class="lowClip ? 'text-red' : 'text-paper'">{{ hud.weapon.clip }}</span>
        <span class="hud-text font-num text-[1rem] leading-none text-dim">/ {{ hud.weapon.reserve }}</span>
      </span>
    </div>
  </div>
</template>
