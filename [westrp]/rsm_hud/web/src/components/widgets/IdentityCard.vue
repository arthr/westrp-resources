<script setup>
import Glyph from "../Glyph.vue";
import { hud } from "../../store/hud.js";
import { t } from "../../locale.js";
</script>

<template>
  <div class="skin skin-plate flex items-center gap-3.5 px-[1.125rem] py-2" style="--skin-fill: rgb(var(--hud-surface-rgb) / calc(0.62 * var(--hud-surface-k)))">
    <span
      class="skin skin-key flex h-[2.4rem] min-w-[2.4rem] items-center justify-center px-2 font-num text-[1.15rem] leading-none text-on-accent"
      style="--skin-fill: rgb(var(--hud-accent-rgb) / 0.85)"
      :title="t('identity.id')"
    >{{ hud.player.id }}</span>
    <div class="flex flex-col gap-1">
      <span class="hud-text font-display text-[0.95rem] uppercase leading-none tracking-[0.12em] text-paper">{{ hud.player.name }}</span>
      <span class="flex items-center gap-1.5">
        <Glyph name="g-badge" size="0.8rem" class="text-red" />
        <span class="hud-text font-display text-[0.62rem] uppercase tracking-[0.16em] text-paper">{{ hud.player.job }}</span>
        <span v-if="hud.player.employer" class="hud-text text-[0.68rem] text-dim">· {{ hud.player.employer }}</span>
      </span>
    </div>
  </div>
</template>
