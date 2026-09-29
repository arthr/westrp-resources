<script setup>
import { computed } from "vue";
import { useStable } from "../../state/stable.js";
import { Icon } from "../kit";

// Só na prévia do navegador. No jogo quem mostra o resultado é o
// rsm_nuikit (Notify disparado pelo servidor), no lugar que o jogador
// escolheu no /hudlayout.
const stable = useStable();
const t = computed(() => stable.state.toast);
const ICONS = { success: "menu-icon-tick", error: "menu-icon-alert", warning: "menu-icon-info-warning", info: "menu-icon-circle" };
</script>

<template>
  <Transition
    enter-active-class="transition duration-200"
    enter-from-class="opacity-0 -translate-y-2"
    leave-active-class="transition duration-200"
    leave-to-class="opacity-0"
  >
    <div v-if="t" :key="t.id" class="pointer-events-none fixed inset-x-0 top-[3.2vh] z-40 flex justify-center">
      <div class="tx-toast flex w-[min(26rem,40vw)] items-center gap-4 px-7 py-4">
        <Icon :name="ICONS[t.kind] ?? ICONS.info" :size="26" :class="t.kind === 'error' || t.kind === 'warning' ? 'text-accent' : 'text-ink'" />
        <div class="min-w-0">
          <p class="kit-heading truncate text-[12px] text-ink">{{ t.title }}</p>
          <p class="mt-1 text-[13px] leading-snug text-dim">{{ t.body }}</p>
        </div>
      </div>
    </div>
  </Transition>
</template>
