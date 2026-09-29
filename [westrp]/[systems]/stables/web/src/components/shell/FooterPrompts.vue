<script setup>
import { useStable } from "../../state/stable.js";
import { KeyCap } from "../kit";

// Legenda de teclas na faixa de prompt do RDR, embaixo da câmera
const stable = useStable();
const HINTS = [
  { keys: ["A", "D"], label: "Girar" },
  { keys: ["Q", "E"], label: "Seção" },
];
</script>

<template>
  <footer class="tx-prompt flex items-center gap-5 py-2 pr-7 pl-3 2xl:gap-7">
    <span v-for="h in HINTS" :key="h.label" class="flex items-center gap-2 text-[13px] whitespace-nowrap text-dim">
      <KeyCap v-for="k in h.keys" :key="k" :k="k" :size="26" />
      <span class="ml-1">{{ h.label }}</span>
    </span>
    <span class="hidden text-[13px] whitespace-nowrap text-faint 2xl:inline">Arraste: girar · Roda: zoom</span>
    <button type="button" class="flex cursor-pointer items-center gap-2 text-[13px] whitespace-nowrap text-dim hover:text-ink" @click="stable.close()">
      <KeyCap k="Esc" :size="34" />
      <span class="ml-1">Sair</span>
    </button>
  </footer>
</template>
