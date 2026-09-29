<script setup>
import Glyph from "../Glyph.vue";
import { hud } from "../../store/hud.js";
</script>

<template>
  <div class="flex flex-col items-center gap-1.5 px-2">
    <div class="flex items-center gap-2.5">
      <Glyph name="g-town" size="1.35rem" class="text-paper" />
      <span class="hud-text font-title text-[2.3rem] leading-none text-paper">{{ hud.location.town }}</span>
    </div>
    <span class="tex h-[0.18rem] w-[15rem] text-[rgba(245,243,238,0.55)] [mask-size:100%_100%] [-webkit-mask-size:100%_100%]" style="--m: var(--tex-divider)" />
    <span v-if="hud.location.region" class="hud-text font-display text-[0.66rem] uppercase tracking-[0.32em] text-dim">{{ hud.location.region }}</span>
  </div>
</template>
