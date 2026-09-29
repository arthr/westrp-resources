<script setup>
import { computed } from "vue";
import Glyph from "../Glyph.vue";
import { hud } from "../../store/hud.js";
import { t } from "../../locale.js";

const range = computed(() => Math.min(3, Math.max(1, Number(hud.voice.range) || 2)));
</script>

<template>
  <div class="flex items-center gap-2.5 px-1">
    <span :class="hud.voice.talking ? 'talking text-red' : 'text-paper'" class="inline-flex transition-colors duration-200">
      <Glyph :name="hud.voice.talking ? 'g-speaker' : 'g-speaker-off'" size="1.8rem" />
    </span>
    <div class="flex flex-col gap-1">
      <span class="flex items-center gap-1">
        <span
          v-for="n in 3"
          :key="n"
          class="tex h-[0.45rem] w-[0.45rem]"
          :class="n <= range ? (hud.voice.talking ? 'text-red' : 'text-paper') : 'text-[rgba(245,243,238,0.22)]'"
          style="--m: var(--tex-dot)"
        />
      </span>
      <span class="hud-text font-display text-[0.62rem] uppercase tracking-[0.18em] text-dim">{{ t(`voice.${range}`) }}</span>
    </div>
  </div>
</template>
