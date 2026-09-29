<script setup>
import { useKit } from "../../state/kit.js";
import { Button } from "../kit";

// Só no preview: com o estúdio fechado sobra o HUD, como o jogador vê.
// No jogo quem reabre é o /nuikit.
const kit = useKit();
</script>

<template>
  <div class="pointer-events-none fixed inset-x-0 top-[3vh] z-20 flex justify-center">
    <div class="tx-prompt pointer-events-auto flex items-center gap-5 py-2 pr-2 pl-6">
      <span class="text-[13px] text-dim">This is what players see. In game, staff reopen the studio with /nuikit.</span>
      <Button size="sm" variant="primary" @click="kit.dispatch({ type: 'studio/set', open: true })">Open Studio</Button>
    </div>
  </div>
</template>
