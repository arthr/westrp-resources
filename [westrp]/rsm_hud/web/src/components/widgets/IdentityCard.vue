<script setup>
import Glyph from "../Glyph.vue";
import { hud } from "../../store/hud.js";
import { t } from "../../locale.js";
</script>

<template>
  <div class="skin skin-plate flex items-center gap-3.5 px-[1.125rem] py-2" style="--skin-fill: rgba(1, 1, 1, 0.62)">
    <span
      class="skin skin-key flex h-[2.4rem] min-w-[2.4rem] items-center justify-center px-2 font-num text-[1.15rem] leading-none text-paper"
      style="--skin-fill: rgba(203, 1, 1, 0.85)"
      :title="t('identity.id')"
    >{{ hud.player.id }}</span>
    <div class="flex min-w-0 flex-col gap-1">
      <span class="hud-text font-display text-[0.95rem] uppercase leading-none tracking-[0.12em] text-paper">{{ hud.player.name }}</span>
      <span class="flex items-center gap-1.5">
        <Glyph name="g-badge" size="0.8rem" class="text-red" />
        <span class="hud-text font-display text-[0.62rem] uppercase tracking-[0.16em] text-paper">{{ hud.player.job }}</span>
        <span v-if="hud.player.employer" class="hud-text text-[0.68rem] text-dim">· {{ hud.player.employer }}</span>
      </span>
    </div>
  </div>
</template>
