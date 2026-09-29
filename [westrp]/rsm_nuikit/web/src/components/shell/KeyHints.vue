<script setup>
import { computed } from "vue";
import { useKit } from "../../state/kit.js";
import { Button, KeyCap } from "../kit";

// Footer bar: the key legend RDR menus carry along their bottom edge.
const kit = useKit();

const HINTS = [
  { keys: ["Q", "E"], label: "Switch Section" },
  { keys: ["R", "G"], label: "Prompts (HUD Pieces)" },
  { keys: ["Esc"], label: "Close" },
];
const placementHint = computed(() =>
  kit.state.host.present ? "Players place HUD pieces with /hudlayout" : "HUD positions come from Config.Layout in config.lua",
);
</script>

<template>
  <footer class="flex items-center justify-between gap-6">
    <div class="flex flex-wrap items-center gap-7">
      <span v-for="h in HINTS" :key="h.label" class="flex items-center gap-2.5 text-[13px] text-dim">
        <KeyCap v-for="k in h.keys" :key="k" :k="k" :size="k.length > 1 ? 34 : 26" />
        {{ h.label }}
      </span>
      <span class="text-[13px] text-faint">{{ placementHint }}</span>
    </div>
    <Button variant="ghost" size="sm" icon="cross" @click="kit.closePanel()">Close</Button>
  </footer>
</template>
