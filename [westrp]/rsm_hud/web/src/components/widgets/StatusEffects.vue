<script setup>
import { computed } from "vue";
import { hud } from "../../store/hud.js";
import { layout } from "../../store/layout.js";
import { t } from "../../locale.js";

// Ícones de status do próprio RDR2. Efeitos nocivos em vermelho, o resto neutro.
const EFFECTS = {
  cold: { tex: "fx-cold", harmful: false },
  hot: { tex: "fx-hot", harmful: true },
  wounded: { tex: "fx-wounded", harmful: true },
  sick: { tex: "fx-sick", harmful: true },
  venom: { tex: "fx-venom", harmful: true },
  drained: { tex: "fx-drained", harmful: false },
  overfed: { tex: "fx-overfed", harmful: false },
  disoriented: { tex: "fx-disoriented", harmful: false },
};

// In the Layout Manager an empty list still needs something to place.
const list = computed(() => {
  const active = hud.effects.filter((k) => EFFECTS[k]);
  return active.length || !layout.editing ? active : ["cold", "wounded"];
});
</script>

<template>
  <div class="flex items-start gap-3">
    <div v-for="k in list" :key="k" class="flex w-[3.4rem] flex-col items-center gap-1">
      <div class="relative h-[2.6rem] w-[2.6rem]">
        <span class="tex absolute inset-0 text-[rgb(var(--hud-surface-rgb)/calc(0.72*var(--hud-surface-k)))]" style="--m: var(--tex-core-bg)" />
        <span class="hud-glyph absolute inset-0">
          <span
            class="tex absolute inset-0"
            :class="EFFECTS[k].harmful ? 'text-red' : 'text-paper'"
            :style="{ '--m': `var(--tex-${EFFECTS[k].tex})` }"
          />
        </span>
      </div>
      <span
        class="hud-text font-display text-[0.56rem] uppercase leading-none tracking-[0.12em]"
        :class="EFFECTS[k].harmful ? 'text-red' : 'text-dim'"
      >{{ t(`fx.${k}`) }}</span>
    </div>
  </div>
</template>
