<script setup>
import { computed } from "vue";
import Glyph from "../Glyph.vue";
import { hud } from "../../store/hud.js";

const temp = computed(() => Math.round(Number(hud.world.temperature) || 0));
// The cold / hot glyphs only appear when the air is actually punishing.
const tempGlyph = computed(() => {
  const c = hud.world.unit === "F" ? ((temp.value - 32) * 5) / 9 : temp.value;
  if (c <= 12) return "fx-cold";
  if (c >= 30) return "fx-hot";
  return null;
});
</script>

<template>
  <div class="skin skin-plate flex items-center gap-4 px-[1.125rem] py-2" style="--skin-fill: rgba(1, 1, 1, 0.62)">
    <div class="flex flex-col items-end gap-1">
      <span class="hud-text font-num text-[1.9rem] leading-none tracking-wider text-paper">{{ hud.world.time }}</span>
      <span class="hud-text font-display text-[0.62rem] uppercase tracking-[0.2em] text-dim">{{ hud.world.day }}</span>
    </div>
    <span class="tex h-[2.6rem] w-[0.2rem] shrink-0 text-[rgba(245,243,238,0.25)] [mask-size:100%_100%] [-webkit-mask-size:100%_100%]" style="--m: var(--tex-vdivider)" />
    <div class="flex flex-col gap-1">
      <span class="hud-text font-display text-[0.7rem] uppercase tracking-[0.14em] text-paper">{{ hud.world.weather }}</span>
      <span class="flex items-center gap-1.5">
        <Glyph v-if="tempGlyph" :name="tempGlyph" size="1.2rem" :class="tempGlyph === 'fx-hot' ? 'text-red' : 'text-paper'" />
        <span class="hud-text font-num text-[1.05rem] leading-none text-paper">{{ temp }}°{{ hud.world.unit }}</span>
      </span>
    </div>
  </div>
</template>
